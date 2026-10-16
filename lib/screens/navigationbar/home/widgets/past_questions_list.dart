import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/ai_models/question_asnwer_ai_model.dart';
import 'package:mama_meow/screens/navigationbar/home/widgets/mia_answer_card.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

/// Kullanıcının daha önce sorduğu sorular (açılır kartlar).
class PastQuestionsList extends StatelessWidget {
  const PastQuestionsList({super.key, required this.items});

  final List<QuestionAnswerAiModel> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: "Past questions"),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No AI questions found",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoalSoft,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _PastQuestionTile(item: items[index]),
          ),
      ],
    );
  }
}

/// Beyaz, ince çizgili açılır soru kartı.
class _PastQuestionTile extends StatelessWidget {
  const _PastQuestionTile({required this.item});

  final QuestionAnswerAiModel item;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.hairline),
    );
    return ExpansionTile(
      backgroundColor: AppColors.cottonWhite,
      collapsedBackgroundColor: AppColors.cottonWhite,
      shape: shape,
      collapsedShape: shape,
      clipBehavior: Clip.antiAlias,
      iconColor: AppColors.charcoalSoft,
      collapsedIconColor: AppColors.charcoalSoft,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: const IconSquircle(
        size: 40,
        radius: 14,
        background: AppColors.pinkTint,
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: AppColors.activeBerry,
        ),
      ),
      title: Text(
        item.question,
        style: const TextStyle(
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w700,
          color: AppColors.deepCharcoal,
        ),
      ),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Text(
          "Tap to view answer",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoalSoft,
          ),
        ),
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const Divider(height: 1),
        const SizedBox(height: 14),
        MiaAnswerCard(answer: item.miaAnswer, framed: false),
      ],
    );
  }
}
