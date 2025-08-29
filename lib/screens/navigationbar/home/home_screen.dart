import 'package:flutter/material.dart';

class MamaMeowHomePage extends StatefulWidget {
  const MamaMeowHomePage({super.key});

  @override
  State<MamaMeowHomePage> createState() => _MamaMeowHomePageState();
}

class _MamaMeowHomePageState extends State<MamaMeowHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F5),
      body: AskMeowView(),
    );
  }
}

class AskMeowView extends StatelessWidget {
  const AskMeowView({super.key});

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
                        Row(
                          children: const [
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
                          onPressed: () {},
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.teal,
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.mic,
                                color: Colors.deepPurple,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
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

            const SizedBox(height: 24),
            const Text(
              "No questions yet. Ask Meow something!",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _quickQuestionTile(String emoji, String question, List<Color> colors) {
    return Container(
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
    );
  }
}
