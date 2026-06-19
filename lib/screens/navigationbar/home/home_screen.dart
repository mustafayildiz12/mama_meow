import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/ai_models/mia_answer_model.dart';
import 'package:mama_meow/models/ai_models/question_asnwer_ai_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/gpt_service/question_ai_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/service/review_service.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/service/gpt_service/gpt_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

class AskMeowView extends StatefulWidget {
  const AskMeowView({super.key});

  @override
  State<AskMeowView> createState() => _AskMeowViewState();
}

class _AskMeowViewState extends State<AskMeowView> {
  final _controller = TextEditingController();
  final _gpt = GptService();

  List<String> _suggestions = [];

  Uint8List? imageBytes;
  String? mimeType;

  MiaAnswer? _miaAnswer;
  bool _isLoading = false;

  final AudioRecorder _rec = AudioRecorder();

  bool _isRecording = false;
  String? currentPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double _amp = 0.0; // -160..0 dB civarı gelir, biz basit normalize edeceğiz

  bool isUserPremium = false;

  List<QuestionAnswerAiModel> questionAnswerAiList = [];

  List<QuickQuestionModel> quickQuestionList = [
    QuickQuestionModel(
      emoji: "💩",
      question: "Is my baby's poop color normal? 🙀",
    ),
    QuickQuestionModel(
      emoji: "🌙",
      question: "How often should I feed my newborn? 🐾",
    ),
    QuickQuestionModel(
      emoji: "💝",
      question: "Breastfeeding problems and solutions? 🐱",
    ),
    QuickQuestionModel(
      emoji: "🍼",
      question: "Baby sleep regression - what to do? 😹",
    ),
  ];

  @override
  void initState() {
    analyticService.screenView('home_screen');
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFFF1F5),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    checkUserPremium();
    getUserPastQuestions();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _rec.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> getUserPastQuestions() async {
    final user = authenticationService.getUser();
    if (user == null) {
      setState(() {
        questionAnswerAiList = [];
      });
      return;
    }
    List<QuestionAnswerAiModel> aa = await questionAIService
        .getAIQuestionList();
    setState(() {
      questionAnswerAiList = aa;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF1F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFBCFE8), Color(0xFFF9A8D4)],
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          "assets/happy.png",
                          color: AppColors.pink500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ask Meow",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Your Baby's AI Cat Companion",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick questions
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.favorite, color: Color(0xFFEC4899)),
                              SizedBox(width: 8),
                              Text(
                                'Quick Questions 😸',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Shuffle questions',
                            icon: const Icon(
                              Icons.shuffle,
                              color: Color(0xFFEC4899),
                            ),
                            onPressed: () =>
                                setState(() => quickQuestionList.shuffle()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(quickQuestionList.length, (
                          index,
                        ) {
                          QuickQuestionModel question =
                              quickQuestionList[index];
                          return _quickQuestionTile(
                            question.emoji,
                            question.question,
                            quickColors(index),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "😺 Questions change each time you visit Ask Meow 🐾",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Ask anything box
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        onTapOutside: (event) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        decoration: InputDecoration(
                          hintText:
                              "Ask me anything about babies and moms! 😸🐾",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFBCFE8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFF472B6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.teal,
                            ),
                            onPressed: !_isLoading
                                ? () async {
                                    await pickAndCompressImage();
                                  }
                                : null,
                          ),
                          IconButton.filledTonal(
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                _isRecording
                                    ? Colors.red.shade400
                                    : Colors.deepPurple.shade100,
                              ),
                            ),
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: _isRecording
                                  ? Colors.white
                                  : Colors.deepPurple,
                            ),
                            onPressed: !_isLoading ? onMicPressed : null,
                          ),

                          // Kayıt göstergesi: süre + seviye çubuğu + "REC" noktası
                          _isRecording
                              ? Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Row(
                                      key: const ValueKey('rec'),
                                      children: [
                                        // Kırmızı yanıp sönen nokta
                                        _BlinkingDot(),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDuration(_elapsed),
                                          style: const TextStyle(
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: _amp, // 0..1
                                              minHeight: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Spacer(),
                          if (imageBytes != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: MemoryImage(imageBytes!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: InkWell(
                                      onTap: !_isLoading
                                          ? () {
                                              setState(() {
                                                imageBytes = null;
                                                mimeType = null;
                                              });
                                            }
                                          : null,
                                      child: Icon(
                                        Icons.cancel,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!_isRecording)
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _ask(null),
                              icon: const Icon(Icons.send),
                              label: const Text("Ask"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF472B6),
                                disabledBackgroundColor: const Color(
                                  0xFFF472B6,
                                ).withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Answer area
              _answerCard(),

              const SizedBox(height: 16),
              if (questionAnswerAiList.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questionAnswerAiList.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = questionAnswerAiList[index];
                    final answer = item.miaAnswer;

                    return ExpansionTile(
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        item.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "Tap to view answer",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [_answerCardPast(answer)],
                    );
                  },
                )
              else
                const Center(child: Text("No AI questions found")),
            ],
          ),
        ),
      ),
    );
  }

  List<Color>? quickColors(int index) {
    if (index == 0) {
      return [Colors.blue.shade100, Colors.purple.shade100];
    } else if (index == 1) {
      return [Colors.green.shade100, Colors.teal.shade100];
    } else if (index == 2) {
      return [Colors.red.shade100, Colors.pink.shade100];
    } else if (index == 3) {
      return [Colors.orange.shade100, Colors.yellow.shade100];
    }
    return null;
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  Widget _quickQuestionTile(
    String emoji,
    String question,
    List<Color>? colors,
  ) {
    return InkWell(
      onTap: () async {
        _controller.text = question;
        await _ask(question);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: colors != null ? LinearGradient(colors: colors) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFBCFE8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAnswer() {
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
    globalFunctions.shareText(buffer.toString());
  }

  Widget _answerCard() {
    // Cevap yok ve yükleme de yoksa hiçbir şey gösterme.
    if (_miaAnswer == null && !_isLoading) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isTR = Localizations.localeOf(context).languageCode == 'tr';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) ...[
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      isTR ? "Mia düşünüyor…" : "Mia is thinking…",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else if (_miaAnswer != null) ...[
              // ------ PART 1: Quick Answer ------
              Text(
                _miaAnswer!.quick,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 4),
              // Cevabı paylaş (büyüme kancası: ebeveynler tavsiyeyi yayar).
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _shareAnswer,
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(isTR ? "Paylaş" : "Share"),
                ),
              ),
              const SizedBox(height: 6),

              // ------ PART 2: Detailed Info ------
              if (_miaAnswer!.detailed.trim().isNotEmpty) ...[
                Text(
                  isTR ? "Detaylı Bilgi" : "Detailed Info",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                // İstersen MarkdownBody kullanabilirsin:
                // MarkdownBody(data: _miaAnswer!.detailed, selectable: true)
                Text(_miaAnswer!.detailed.replaceAll(r'\n', '\n')),
                const SizedBox(height: 12),
              ],

              // ------ Actions (3 madde) ------
              if (_miaAnswer!.actions.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _miaAnswer!.actions.map((a) {
                    return Chip(
                      label: Row(
                        children: [
                          Expanded(
                            child: Text(
                              a,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // ------ Follow-up question ------
              if (_miaAnswer!.followUp.trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.question_answer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _miaAnswer!.followUp,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ------ Sources ------
              if (_miaAnswer!.sources.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.link, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      isTR ? "Kaynaklar" : "Sources",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._miaAnswer!.sources.map((s) => _SourceTile(item: s)),
                const SizedBox(height: 8),
              ],

              // ------ Disclaimer + Last updated ------
              Text(
                _miaAnswer!.disclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              if (_miaAnswer!.lastUpdated.isNotEmpty)
                Text(
                  "${isTR ? "Son güncelleme" : "Last updated"}: ${_miaAnswer!.lastUpdated}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black45,
                  ),
                ),

              const SizedBox(height: 12),
            ],
            // ---- Öneriler (her iki durumda da) ----
            if (!_isLoading && _suggestions.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    isTR
                        ? "Bunlar da işine yarayabilir:"
                        : "Maybe these also help:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _suggestions
                    .map(
                      (s) => InkWell(
                        onTap: () async {
                          _controller.text = s;
                          await _ask(s);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text("👉 $s"),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerCardPast(MiaAnswer? miaAnswerCard) {
    // Hiçbir cevap yok ve yükleme de yoksa gizle
    if (miaAnswerCard == null) {
      return CircularProgressIndicator();
    }

    final theme = Theme.of(context);
    final isTR = Localizations.localeOf(context).languageCode == 'tr';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------ PART 1: Quick Answer ------
            Text(
              miaAnswerCard.quick,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),

            // ------ PART 2: Detailed Info ------
            if (miaAnswerCard.detailed.trim().isNotEmpty) ...[
              Text(
                isTR ? "Detaylı Bilgi" : "Detailed Info",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              // İstersen MarkdownBody kullanabilirsin:
              // MarkdownBody(data: _miaAnswer!.detailed, selectable: true)
              Text(miaAnswerCard.detailed.replaceAll(r'\n', '\n')),
              const SizedBox(height: 12),
            ],

            // ------ Actions (3 madde) ------
            if (miaAnswerCard.actions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: miaAnswerCard.actions.map((a) {
                  return Chip(
                    label: Row(
                      children: [
                        Expanded(
                          child: Text(
                            a,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // ------ Follow-up question ------
            if (miaAnswerCard.followUp.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.question_answer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        miaAnswerCard.followUp,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ------ Sources ------
            if (miaAnswerCard.sources.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.link, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isTR ? "Kaynaklar" : "Sources",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...miaAnswerCard.sources.map((s) => _SourceTile(item: s)),
              const SizedBox(height: 8),
            ],

            // ------ Disclaimer + Last updated ------
            Text(
              miaAnswerCard.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 4),
            if (miaAnswerCard.lastUpdated.isNotEmpty)
              Text(
                "${isTR ? "Son güncelleme" : "Last updated"}: ${miaAnswerCard.lastUpdated}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                ),
              ),

            const SizedBox(height: 12),

            // ---- Öneriler (her iki durumda da) ----
            if (_suggestions.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    isTR
                        ? "Bunlar da işine yarayabilir:"
                        : "Maybe these also help:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _suggestions
                    .map(
                      (s) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text("👉 $s"),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> pickAndCompressImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final Uint8List originalBytes = await image.readAsBytes();

    // 🔽 kaliteyi düşür
    final Uint8List
    compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality:
          40, // 0-100 arası; 40 gayet yeterli kalite / performans dengesi sağlar
      minWidth: 800, // uzun kenarı küçültmek
      minHeight: 800,
      format:
          CompressFormat.jpeg, // PNG ise JPEG’e çevirip boyutu ciddi düşürür
    );

    setState(() {
      imageBytes = compressedBytes;
      mimeType = 'image/jpeg'; // sıkıştırmada format değiştiyse
    });

    debugPrint('Orijinal boyut: ${originalBytes.lengthInBytes / 1024} KB');
    debugPrint(
      'Sıkıştırılmış boyut: ${compressedBytes.lengthInBytes / 1024} KB',
    );
  }

  Future<void> checkUserPremium() async {
    final user = authenticationService.getUser();
    if (user == null) {
      setState(() {
        isUserPremium = false;
      });
      return;
    }
    InAppPurchaseService iap = InAppPurchaseService();
    bool isP = await iap.isPremium();
    setState(() {
      isUserPremium = isP;
    });
  }

  Future<void> _ask(String? presetQuestion) async {
    final user = authenticationService.getUser();
    if (user == null) {
      context.pushNamed("login");
      return;
    }

    if (!isUserPremium) {
      await context.pushNamed("premiumPaywall").then((v) async {
        if (v != null && v == true) {
          await checkUserPremium();
        }
      });
    } else {
      final q = (presetQuestion ?? _controller.text).trim();
      if (q.isEmpty) return;

      setState(() {
        _isLoading = true;
      });

      try {
        await analyticService.askMia(q);
        final res = await _gpt.askMia(
          q,
          imageBytes: imageBytes,
          imageMimeType: mimeType ?? "image/png",
        );
        setState(() => _miaAnswer = res);

        // önerileri getir
        final sug = await _gpt.getSuggestions(question: q, language: "English");
        setState(() {
          _suggestions = sug;
          imageBytes = null;
        });

        int createdAt = DateTime.now().millisecondsSinceEpoch;

        QuestionAnswerAiModel qa = QuestionAnswerAiModel(
          question: q,
          miaAnswer: _miaAnswer!,
          createdAt: createdAt,
        );

        await questionAIService.addAIQuestion(qa);
        await getUserPastQuestions();
        await analyticService.aiAnswerSuccess();
        // Mutlu an: birkaç başarılı cevaptan sonra mağaza puanı iste.
        await reviewService.recordPositiveMomentAndMaybeAsk();
      } catch (e) {
        await analyticService.aiAnswerFailed(e.toString());
        setState(() => _miaAnswer = null);
        // Sessiz hata yerine kullanıcıyı bilgilendir; soruyu geri koy ki
        // tek dokunuşla yeniden gönderebilsin.
        if (mounted) {
          _controller.text = q;
          customSnackBar.error(
            "Mia couldn't answer right now. Please check your connection and try again.",
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final extension = image.name.split('.').last.toLowerCase();
      final allowedExtensions = ['png', 'jpg', 'jpeg', 'gif', 'webp'];

      if (!allowedExtensions.contains(extension)) {
        // Uygun olmayan format
        print("Geçersiz dosya formatı: $extension");
        return null;
      }
    }

    return image;
  }

  Future<void> _startRecording() async {
    // İzin kontrolü
    final hasPerm = await _rec.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon izni verilmedi.')),
        );
      }
      return;
    }

    // Kayıt dosya yolu (m4a kapsayıcı, AAC)
    final dir = await getTemporaryDirectory();
    final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = p.join(dir.path, fileName);

    // Kayıt başlat
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    // Amplitude stream (isteğe bağlı görsel geri bildirim)
    _ampSub?.cancel();
    _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 120)).listen((
      a,
    ) {
      // a.current genelde -45..-5 dB gibi değerler; 0'a yakın daha yüksek seviye
      final normalized = (a.current + 60) / 60; // -60..0 dB -> 0..1 arası
      setState(() => _amp = normalized.clamp(0, 1));
    });

    // Süre sayacı
    _timer?.cancel();
    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    setState(() {
      _isRecording = true;
      currentPath = path;
    });
  }

  Future<void> _stopAndTranscribe() async {
    final path = await _rec.stop(); // kaydı durdurur ve dosya yolunu döndürür
    _timer?.cancel();
    _ampSub?.cancel();

    setState(() {
      _isRecording = false;
      _amp = 0;
    });

    if (path == null) return;

    // Dosyayı oku
    final bytes = await File(path).readAsBytes();

    // m4a/AAC için doğru MIME:
    const mime = 'audio/mp4';

    // Transcribe
    final text = await _gpt.transcribeAudio(
      bytes,
      filename: p.basename(path),
      mimeType: mime,
    );

    _controller.text = text;
  }

  Future<void> onMicPressed() async {
    if (_isRecording) {
      await _stopAndTranscribe();
    } else {
      await _startRecording();
    }
  }
}

class QuickQuestionModel {
  final String emoji;
  final String question;

  QuickQuestionModel({required this.emoji, required this.question});
}

// ---- Kaynak ListTile ----
class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.item});
  final MiaSource item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleBits = <String>[
      if (item.publisher.isNotEmpty) item.publisher,
      if (item.year != null) "${item.year}",
    ];
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
      subtitle: subtitleBits.isEmpty ? null : Text(subtitleBits.join(" • ")),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () async {
        await launchUrl(
          Uri.parse(item.url),
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => __BlinkingDotState();
}

class __BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
