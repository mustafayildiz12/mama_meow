import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/ai_models/question_asnwer_ai_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

class QuestionAIService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  Future<void> addAIQuestion(QuestionAnswerAiModel questionAi) async {
    try {
      final user = authenticationService.getUser()!;

      await _realtimeDatabase
          .ref('questionAi')
          .child(user.uid)
          .child(questionAi.createdAt.toString())
          .set(questionAi.toJson());
    } catch (e) {
      print(e.toString());
    }
  }

  Future<List<QuestionAnswerAiModel>> getAIQuestionList() async {
    final List<QuestionAnswerAiModel> aiQuestions = [];
    final user = authenticationService.getUser()!;
    final ref = _realtimeDatabase.ref('questionAi').child(user.uid);
    final snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        // jsonEncode + jsonDecode ile DERİN normalizasyon (Map<String, dynamic>)
        final normalized = jsonDecode(jsonEncode(snapshot.value));

        if (normalized is Map<String, dynamic>) {
          for (final value in normalized.values) {
            if (value is Map<String, dynamic>) {
              aiQuestions.add(QuestionAnswerAiModel.fromJson(value));
            }
          }
        } else if (normalized is List) {
          for (final item in normalized) {
            if (item is Map<String, dynamic>) {
              aiQuestions.add(QuestionAnswerAiModel.fromJson(item));
            }
          }
        }
      }
    } catch (e) {
      print('getAIQuestionList error: $e');
    }
    aiQuestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return aiQuestions;
  }
}

final QuestionAIService questionAIService = QuestionAIService();
