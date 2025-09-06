import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/service/gpt_service.dart';

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

  @override
  void dispose() {
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
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.teal,
                              ),
                              onPressed: () async {
                                XFile? image = await pickImage();

                                Uint8List? imageByte = await image
                                    ?.readAsBytes();
                                String? mimeTypeImage = image?.mimeType;

                                setState(() {
                                  imageBytes = imageByte;
                                  mimeType = mimeTypeImage;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.mic,
                                color: Colors.deepPurple,
                              ),
                              onPressed: () {
                                // ileride: ses kaydı + whisper
                              },
                            ),
                          ],
                        ),
                        Spacer(),
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
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _ask(null),
                          icon: const Icon(Icons.send),
                          label: const Text("Ask"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF472B6),
                            disabledBackgroundColor: const Color(
                              0xFFF472B6,
                            ).withOpacity(0.5),
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
}
