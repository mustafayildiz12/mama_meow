import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/ai_models/question_asnwer_ai_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// Ask Meow soru/cevap geçmişi: `questionAi/<uid>/<createdAtMs>`.
class QuestionAIService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Geçmiş listesinde gösterilen en fazla kayıt.
  static const int historyLimit = 50;

  /// Soru/cevabı kaydeder. Giriş yoksa kaydetmez (loglar); offline'da kısa
  /// bir beklemeden sonra döner (yazma bağlantı gelince senkronlanır).
  Future<void> addAIQuestion(QuestionAnswerAiModel questionAi) async {
    final user = authenticationService.getUser();
    if (user == null) {
      developer.log(
        'addAIQuestion skipped: no signed-in user',
        name: 'QuestionAIService',
      );
      return;
    }
    try {
      await ActivityRtdb.write(
        _realtimeDatabase
            .ref('questionAi')
            .child(user.uid)
            .child(questionAi.createdAt.toString())
            .set(questionAi.toJson()),
        label: 'questionAi add',
      );
    } catch (e, st) {
      ActivityRtdb.reportNonFatal(e, st, reason: 'addAIQuestion failed');
    }
  }

  /// Son [historyLimit] soru/cevap, en yeni önce. Giriş yoksa boş liste.
  Future<List<QuestionAnswerAiModel>> getAIQuestionList() async {
    final user = authenticationService.getUser();
    if (user == null) return [];

    final snapshot = await _realtimeDatabase
        .ref('questionAi')
        .child(user.uid)
        .orderByKey()
        .limitToLast(historyLimit)
        .get();

    final aiQuestions = <QuestionAnswerAiModel>[];
    for (final child in snapshot.children) {
      final value = child.value;
      if (value is! Map) continue;
      try {
        aiQuestions.add(QuestionAnswerAiModel.fromJson(value));
      } catch (e, st) {
        ActivityRtdb.reportNonFatal(
          e,
          st,
          reason: 'Skipped malformed questionAi record (${child.key})',
        );
      }
    }
    aiQuestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return aiQuestions;
  }
}

final QuestionAIService questionAIService = QuestionAIService();
