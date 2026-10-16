import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/ai_models/mia_answer_model.dart';
import 'package:mama_meow/models/ai_models/question_asnwer_ai_model.dart';
import 'package:mama_meow/screens/navigationbar/home/voice_recorder_controller.dart';
import 'package:mama_meow/screens/navigationbar/home/widgets/ask_input_card.dart';
import 'package:mama_meow/screens/navigationbar/home/widgets/mia_answer_card.dart';
import 'package:mama_meow/screens/navigationbar/home/widgets/past_questions_list.dart';
import 'package:mama_meow/screens/navigationbar/home/widgets/quick_questions_card.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/gpt_service/gpt_service.dart';
import 'package:mama_meow/service/gpt_service/question_ai_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/service/review_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

/// Ask Meow sekmesi: yapay zekâ asistanına soru sorma.
class AskMeowView extends StatefulWidget {
  const AskMeowView({super.key});

  @override
  State<AskMeowView> createState() => _AskMeowViewState();
}

class _AskMeowViewState extends State<AskMeowView> {
  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.cosyIvory,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  final TextEditingController _controller = TextEditingController();
  final VoiceRecorderController _voice = VoiceRecorderController();
  final InAppPurchaseService _iap = InAppPurchaseService();
  StreamSubscription<User?>? _authSub;

  final List<QuickQuestionModel> _quickQuestions = [
    const QuickQuestionModel(
      emoji: "💩",
      question: "Is my baby's poop color normal? 🙀",
    ),
    const QuickQuestionModel(
      emoji: "🌙",
      question: "How often should I feed my newborn? 🐾",
    ),
    const QuickQuestionModel(
      emoji: "💝",
      question: "Breastfeeding problems and solutions? 🐱",
    ),
    const QuickQuestionModel(
      emoji: "🍼",
      question: "Baby sleep regression - what to do? 😹",
    ),
  ];

  Uint8List? _imageBytes;
  String? _imageMimeType;

  MiaAnswer? _miaAnswer;

  /// Ekranda kullanıcı balonu olarak gösterilen (sorulan / cevaplanan) soru.
  String? _askedQuestion;
  List<String> _suggestions = [];
  bool _isLoading = false;

  /// Giriş / paywall / soru akışı sürerken ikinci bir akışı engeller.
  bool _askFlowActive = false;

  bool _isUserPremium = false;
  bool _authInitialized = false;
  String? _uid;
  List<QuestionAnswerAiModel> _history = [];

  @override
  void initState() {
    super.initState();
    analyticService.screenView('home_screen');
    // Sekme durumu girişten sonra da korunduğu için oturum değişimini
    // dinleyip geçmişi ve premium durumunu yeniden yükle. İlk olay mevcut
    // kullanıcıyla hemen gelir.
    _authSub = authenticationService.firebaseAuth.authStateChanges().listen(
      _onAuthChanged,
    );
    _iap.premiumNotifier.addListener(_onPremiumChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _iap.premiumNotifier.removeListener(_onPremiumChanged);
    _voice.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Oturum / premium
  // ---------------------------------------------------------------------------

  void _onAuthChanged(User? user) {
    if (!mounted) return;
    final isInitial = !_authInitialized;
    _authInitialized = true;
    final changed = user?.uid != _uid;
    _uid = user?.uid;
    if (user == null && changed) {
      // Çıkış: önceki kullanıcının cevaplarını gösterme.
      setState(() {
        _history = [];
        _miaAnswer = null;
        _askedQuestion = null;
        _suggestions = [];
        _isUserPremium = false;
      });
      return;
    }
    _loadHistory();
    // Oturum içi girişte RevenueCat kullanıcısı giriş akışında değişir;
    // burada sorgulamak eski (anonim) bilgiyi getirebilir. Değişiklik
    // premiumNotifier ile gelir.
    if (isInitial) {
      _refreshPremium();
    } else {
      _onPremiumChanged();
    }
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    final premium =
        authenticationService.getUser() != null && _iap.premiumNotifier.value;
    if (premium != _isUserPremium) setState(() => _isUserPremium = premium);
  }

  Future<void> _refreshPremium() async {
    var premium = false;
    if (authenticationService.getUser() != null) {
      try {
        premium = await _iap.isPremium();
      } catch (e) {
        debugPrint('isPremium failed: $e');
      }
    }
    if (mounted) setState(() => _isUserPremium = premium);
  }

  Future<void> _loadHistory() async {
    final uid = authenticationService.getUser()?.uid;
    if (uid == null) {
      if (mounted) setState(() => _history = []);
      return;
    }
    try {
      final list = await questionAIService.getAIQuestionList();
      // Bu arada oturum değiştiyse eski kullanıcının listesini yazma.
      if (!mounted || authenticationService.getUser()?.uid != uid) return;
      setState(() => _history = list);
    } catch (e) {
      debugPrint('getAIQuestionList failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Soru sorma
  // ---------------------------------------------------------------------------

  /// Giriş → premium → soru akışı. Giriş ya da satın alma başarılı olursa
  /// bekleyen soru otomatik sorulur.
  Future<void> _ask([String? presetQuestion]) async {
    if (_isLoading || _askFlowActive || _voice.isTranscribing) return;
    if (presetQuestion != null) _controller.text = presetQuestion;

    _askFlowActive = true;
    try {
      if (authenticationService.getUser() == null) {
        final signedIn = await context.pushNamed<bool>('login');
        if (!mounted || signedIn != true) return;
        await _refreshPremium();
        if (!mounted) return;
      }

      if (!_isUserPremium) {
        final purchased = await context.pushNamed<bool>('premiumPaywall');
        if (!mounted || purchased != true) return;
        await _refreshPremium();
        if (!mounted || !_isUserPremium) return;
      }

      final question = (presetQuestion ?? _controller.text).trim();
      if (question.isEmpty) return;
      await _sendQuestion(question);
    } finally {
      _askFlowActive = false;
    }
  }

  Future<void> _sendQuestion(String question) async {
    setState(() {
      _isLoading = true;
      _askedQuestion = question;
    });

    MiaAnswer? answer;
    try {
      await analyticService.askMia(question);
      answer = await GptService().askMia(
        question,
        imageBytes: _imageBytes,
        imageMimeType: _imageMimeType ?? "image/png",
      );
    } catch (e) {
      debugPrint('askMia failed: $e');
    }

    if (answer == null) {
      await analyticService.aiAnswerFailed('no_answer');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _miaAnswer = null;
        _askedQuestion = null;
        _suggestions = [];
      });
      // Soruyu geri koy ki tek dokunuşla yeniden gönderebilsin.
      _controller.text = question;
      customSnackBar.error(
        "Mia couldn't answer right now. Please check your connection and try again.",
      );
      return;
    }

    var suggestions = const <String>[];
    try {
      suggestions = await GptService().getSuggestions(question: question);
    } catch (e) {
      debugPrint('getSuggestions failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _miaAnswer = answer;
      _suggestions = suggestions;
      _imageBytes = null;
      _imageMimeType = null;
      _isLoading = false;
    });

    // Cevap gösterildi; geçmiş kaydı başarısız olsa da cevap ekranda kalır.
    try {
      await questionAIService.addAIQuestion(
        QuestionAnswerAiModel(
          question: question,
          miaAnswer: answer,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _loadHistory();
    } catch (e) {
      debugPrint('Saving question history failed: $e');
    }

    try {
      await analyticService.aiAnswerSuccess();
      // Mutlu an: birkaç başarılı cevaptan sonra mağaza puanı iste.
      await reviewService.recordPositiveMomentAndMaybeAsk();
    } catch (e) {
      debugPrint('Post-answer hooks failed: $e');
    }
  }

  void _shareAnswer(BuildContext anchorContext) {
    final a = _miaAnswer;
    if (a == null) return;
    final buffer = StringBuffer()..writeln(a.quick);
    if (a.detailed.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(a.detailed.replaceAll(r'\n', '\n'));
    }
    buffer
      ..writeln()
      ..writeln(globalFunctions.appInviteText());
    globalFunctions.shareText(buffer.toString(), context: anchorContext);
  }

  // ---------------------------------------------------------------------------
  // Görsel & ses
  // ---------------------------------------------------------------------------

  Future<void> _pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;

      // Kaliteyi düşür: PNG ise JPEG'e çevirip boyutu ciddi düşürür.
      final compressed = await FlutterImageCompress.compressWithList(
        await image.readAsBytes(),
        quality: 40,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );
      if (!mounted) return;
      setState(() {
        _imageBytes = compressed;
        _imageMimeType = 'image/jpeg';
      });
    } catch (e) {
      debugPrint('pickImage failed: $e');
      customSnackBar.warning(
        "Couldn't load this photo. Please try another one.",
      );
    }
  }

  void _removeImage() => setState(() {
    _imageBytes = null;
    _imageMimeType = null;
  });

  Future<void> _onMicPressed() async {
    if (_voice.isTranscribing) return;

    if (_voice.isRecording) {
      final text = await _voice.stopAndTranscribe();
      if (!mounted) return;
      if (text == null) {
        customSnackBar.warning("Couldn't transcribe, please try again");
        return;
      }
      _controller.text = text;
      return;
    }

    final result = await _voice.start();
    if (!mounted) return;
    switch (result) {
      case VoiceStartResult.started:
        break;
      case VoiceStartResult.permissionDenied:
        customSnackBar.warning("Microphone permission was not granted.");
      case VoiceStartResult.failed:
        customSnackBar.warning("Couldn't start recording. Please try again.");
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final answer = _miaAnswer;
    final asked = _askedQuestion;
    final showConversation = _isLoading || answer != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.cosyIvory,
        body: SafeArea(
          child: Column(
            children: [
              const _Header(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuickQuestionsCard(
                        questions: _quickQuestions,
                        enabled: !_isLoading,
                        onShuffle: () => setState(_quickQuestions.shuffle),
                        onQuestionTap: _ask,
                      ),
                      // ------ Sohbet: soru balonu + cevap ------
                      if (showConversation) ...[
                        const SizedBox(height: 24),
                        if (asked != null) ...[
                          AskedQuestionBubble(question: asked),
                          const SizedBox(height: 12),
                        ],
                        if (_isLoading)
                          const MiaThinkingCard()
                        else if (answer != null)
                          MiaAnswerCard(
                            answer: answer,
                            suggestions: _suggestions,
                            onSuggestionTap: _ask,
                            onShare: _shareAnswer,
                          ),
                      ],
                      const SizedBox(height: 28),
                      PastQuestionsList(items: _history),
                    ],
                  ),
                ),
              ),
              // Giriş çubuğu ekranın altında sabit durur.
              AskInputCard(
                controller: _controller,
                voice: _voice,
                isLoading: _isLoading,
                imageBytes: _imageBytes,
                onPickImage: _pickImage,
                onRemoveImage: _removeImage,
                onMicPressed: _onMicPressed,
                onAsk: _ask,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Üst başlık: şeftali daire içinde maskot + başlık ve alt başlık.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cosyIvory,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.peachTint,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/happy.png",
                color: AppColors.deepCharcoal,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Ask Meow",
                    style: TextStyle(
                      fontSize: 24,
                      height: 30 / 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepCharcoal,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Your Baby's AI Cat Companion",
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoalSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
