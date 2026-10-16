import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

class QuickQuestionModel {
  final String emoji;
  final String question;

  const QuickQuestionModel({required this.emoji, required this.question});
}

/// Dekoratif emojiler yalnızca gösterimde atılır; soru metni (gönderilen
/// veri) olduğu gibi kalır.
final RegExp _decorativeEmoji = RegExp(
  r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]',
  unicode: true,
);

String _displayText(String text) => text
    .replaceAll(_decorativeEmoji, '')
    .replaceAll(RegExp(r'\s{2,}'), ' ')
    .trim();

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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.activeBerry,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quick questions',
                  style: TextStyle(
                    fontSize: 17,
                    height: 24 / 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepCharcoal,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Shuffle questions',
                icon: const Icon(Icons.shuffle_rounded),
                color: AppColors.deepCharcoal,
                onPressed: onShuffle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < questions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _QuickQuestionTile(
                    question: questions[i],
                    onTap: enabled
                        ? () => onQuestionTap(questions[i].question)
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  "Tap a question to ask Meow instantly",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tam genişlikte, pembe zeminli hap şeklinde soru satırı.
class _QuickQuestionTile extends StatelessWidget {
  const _QuickQuestionTile({required this.question, required this.onTap});

  final QuickQuestionModel question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        color: AppColors.pinkTint,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText(question.question),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepCharcoal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.north_east,
                  size: 18,
                  color: AppColors.deepCharcoal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
