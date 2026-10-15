import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

class QuickQuestionModel {
  final String emoji;
  final String question;

  const QuickQuestionModel({required this.emoji, required this.question});
}

/// Hazır soruların listesi. [enabled] false iken (cevap beklenirken)
/// sorular tıklanamaz.
class QuickQuestionsCard extends StatelessWidget {
  const QuickQuestionsCard({
    super.key,
    required this.questions,
    required this.enabled,
    required this.onShuffle,
    required this.onQuestionTap,
  });

  final List<QuickQuestionModel> questions;
  final bool enabled;
  final VoidCallback onShuffle;
  final ValueChanged<String> onQuestionTap;

  static List<Color>? _colorsFor(int index) => switch (index) {
    0 => [Colors.blue.shade100, Colors.purple.shade100],
    1 => [Colors.green.shade100, Colors.teal.shade100],
    2 => [Colors.red.shade100, Colors.pink.shade100],
    3 => [Colors.orange.shade100, Colors.yellow.shade100],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.pink500),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Quick Questions 😸',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Shuffle questions',
                  icon: const Icon(Icons.shuffle, color: AppColors.pink500),
                  onPressed: onShuffle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < questions.length; i++)
              _QuickQuestionTile(
                question: questions[i],
                colors: _colorsFor(i),
                onTap: enabled
                    ? () => onQuestionTap(questions[i].question)
                    : null,
              ),
            const SizedBox(height: 8),
            const Text(
              "😺 Tap a question to ask Meow instantly 🐾",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickQuestionTile extends StatelessWidget {
  const _QuickQuestionTile({
    required this.question,
    required this.colors,
    required this.onTap,
  });

  final QuickQuestionModel question;
  final List<Color>? colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors;
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradientColors != null
                ? LinearGradient(colors: gradientColors)
                : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pink200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
