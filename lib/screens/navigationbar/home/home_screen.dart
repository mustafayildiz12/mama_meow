import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/service/gpt_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class MamaMeowHomePage extends StatefulWidget {
  const MamaMeowHomePage({super.key});

  @override
  State<MamaMeowHomePage> createState() => _MamaMeowHomePageState();
}

class _MamaMeowHomePageState extends State<MamaMeowHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF1F5),
      body: AskMeowView(),
    );
  }
}

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

  String? _answer;
  bool _isLoading = false;

  final AudioRecorder _rec = AudioRecorder();

  bool _isRecording = false;
  String? currentPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double _amp = 0.0; // -160..0 dB civarı gelir, biz basit normalize edeceğiz

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _rec.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    child: const Icon(
                      Icons.pets,
                      size: 48,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ask Meow",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                          icon: const Icon(
                            Icons.shuffle,
                            color: Color(0xFFEC4899),
                          ),
                          onPressed: () {
                            // gelecekte: listeyi karıştır
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _quickQuestionTile(
                          '💩',
                          "Is my baby's poop color normal? 🙀",
                          [Colors.blue.shade100, Colors.purple.shade100],
                        ),
                        _quickQuestionTile(
                          '🌙',
                          "How often should I feed my newborn? 🐾",
                          [Colors.green.shade100, Colors.teal.shade100],
                        ),
                        _quickQuestionTile(
                          '💝',
                          "Breastfeeding problems and solutions? 🐱",
                          [Colors.red.shade100, Colors.pink.shade100],
                        ),
                        _quickQuestionTile(
                          '🍼',
                          "Baby sleep regression - what to do? 😹",
                          [Colors.orange.shade100, Colors.yellow.shade100],
                        ),
                      ],
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
                      decoration: InputDecoration(
                        hintText: "Ask me anything about babies and moms! 😸🐾",
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
                          onPressed: () async {
                            XFile? image = await pickImage();

                            Uint8List? imageByte = await image?.readAsBytes();
                            String? mimeTypeImage = image?.mimeType;

                            setState(() {
                              imageBytes = imageByte;
                              mimeType = mimeTypeImage;
                            });
                          },
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
                          onPressed: onMicPressed,
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
                                    onTap: () {
                                      setState(() {
                                        imageBytes = null;
                                        mimeType = null;
                                      });
                                    },
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

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  Widget _quickQuestionTile(String emoji, String question, List<Color> colors) {
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
          gradient: LinearGradient(colors: colors),
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

  Widget _answerCard() {
    if (_answer == null && !_isLoading) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Cevap
              MarkdownBody(
                data: _answer!,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: const TextStyle(fontSize: 15, height: 1.4)),
              ),

              const SizedBox(height: 16),

              // Öneriler
              if (_suggestions.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.lightbulb, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      "Maybe these also help:",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Future<void> _ask(String? presetQuestion) async {
    final q = (presetQuestion ?? _controller.text).trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoading = true;
      _answer ??= ''; // alanı göster
    });

    try {
      final res = await _gpt.askMia(
        q,
        imageBytes: imageBytes,
        imageMimeType: mimeType ?? "image/png",
      );
      setState(() => _answer = res);

      // önerileri getir
      final sug = await _gpt.getSuggestions(question: q, language: "English");
      setState(() => _suggestions = sug);
    } catch (e) {
      setState(() => _answer = 'Bir hata oluştu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> recordAndTranscribe() async {
    final record = AudioRecorder();

    // İzin
    if (!await record.hasPermission()) {
      // izin diyaloğunu tetikleyebilirsin
      return;
    }

    // ... kullanıcı kayıt ediyor, sonra:
    final path = await record.stop(); // kayıt biter ve dosya yolu döner
    if (path == null) return;

    final bytes = await File(path).readAsBytes();

    // Kayıt başlat (AAC ile m4a kapsayıcı, yaygın ve iyi kalite)
    await record.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    // AAC/m4a → `audio/mp4` kullan
    final result = await _gpt.transcribeAudio(
      bytes,
      filename: 'recording.m4a',
      mimeType: 'audio/mp4',
    );

    setState(() => _answer = result);
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

    await _ask(text);
  }

  Future<void> onMicPressed() async {
    if (_isRecording) {
      await _stopAndTranscribe();
    } else {
      await _startRecording();
    }
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
