import 'package:mama_meow/models/ai_models/mia_answer_model.dart';

class QuestionAnswerAiModel {
  final String question;
  final MiaAnswer miaAnswer;

  QuestionAnswerAiModel({required this.question, required this.miaAnswer});

  factory QuestionAnswerAiModel.fromJson(Map<String, dynamic> m) {
    // KAYIT ŞEKLİNE GÖRE İKİ SENARYOYU DA DESTEKLE
    // 1) { question: "...", miaAnswer: { quick_answer: "...", ... } }
    if (m['miaAnswer'] is Map) {
      return QuestionAnswerAiModel(
        question: (m['question'] ?? '') as String,
        miaAnswer: MiaAnswer.fromMap(m['miaAnswer'] as Map<String, dynamic>),
      );
    }
    // 2) (eski) Tüm alanlar kökte snake_case ise:
    return QuestionAnswerAiModel(
      question: (m['question'] ?? '') as String,
      miaAnswer: MiaAnswer.fromMap(m),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'miaAnswer': miaAnswer.toJson(), // <-- ÖNEMLİ
    };
  }
}
