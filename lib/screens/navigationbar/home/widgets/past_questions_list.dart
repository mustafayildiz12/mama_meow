import 'package:flutter/material.dart';
import 'package:mama_meow/models/ai_models/question_asnwer_ai_model.dart';
import 'package:mama_meow/screens/navigationbar/home/widgets/mia_answer_card.dart';

/// Kullanıcının daha önce sorduğu sorular (açılır kartlar).
class PastQuestionsList extends StatelessWidget {
  const PastQuestionsList({super.key, required this.items});

  final List<QuestionAnswerAiModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text("No AI questions found"));
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: shape,
          collapsedShape: shape,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            item.question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            "Tap to view answer",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          children: [MiaAnswerCard(answer: item.miaAnswer)],
        );
      },
    );
  }
}
