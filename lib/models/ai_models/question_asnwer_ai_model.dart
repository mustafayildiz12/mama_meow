import 'package:mama_meow/models/ai_models/lenient_json.dart';
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

  /// RTDB'den gelen `Map<Object?, Object?>` dahil her Map kabul edilir
  /// (derin kopya gerekmez).
  factory QuestionAnswerAiModel.fromJson(Map<dynamic, dynamic> raw) {
    final m = jsonMap(raw) ?? const <String, dynamic>{};
    // createdAt değeri yoksa 0 döndür, backward compatibility
    final createdAtValue = jsonInt(m['createdAt']) ?? 0;
    final answer = m['miaAnswer'];

    return QuestionAnswerAiModel(
      question: jsonString(m['question']),
      // Eski kayıtlarda cevap alanları kökte duruyor.
      miaAnswer: MiaAnswer.fromMap(answer is Map ? answer : m),
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
