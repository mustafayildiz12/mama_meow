import 'package:mama_meow/models/ai_models/mia_answer_model.dart';

class QuestionAnswerAiModel {
  final String question;
  final MiaAnswer miaAnswer;
  final int createdAt; 

  QuestionAnswerAiModel({
    required this.question,
    required this.miaAnswer,
    required this.createdAt,
  });

  factory QuestionAnswerAiModel.fromJson(Map<String, dynamic> m) {
    // createdAt değeri yoksa 0 döndür, backward compatibility
    final createdAtValue = (m['createdAt'] is int)
        ? m['createdAt'] as int
        : int.tryParse('${m['createdAt']}') ?? 0;

    if (m['miaAnswer'] is Map) {
      return QuestionAnswerAiModel(
        question: (m['question'] ?? '') as String,
        miaAnswer: MiaAnswer.fromMap(m['miaAnswer'] as Map<String, dynamic>),
        createdAt: createdAtValue,
      );
    }

    return QuestionAnswerAiModel(
      question: (m['question'] ?? '') as String,
      miaAnswer: MiaAnswer.fromMap(m),
      createdAt: createdAtValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'miaAnswer': miaAnswer.toJson(),
      'createdAt': createdAt,
    };
  }
}
