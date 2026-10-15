import 'dart:convert';

import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Uyku raporu AI cevabı (ortak model).
typedef SleepAiInsight = AiReportInsight;
typedef SleepAiSource = AiSource;

class SleepAIService {
  static const String _systemPrompt = '''
You are "Coo Care Baby Tracker", an evidence-informed baby sleep report assistant.

GOAL
- You will receive a REDUCED, PRE-COMPUTED JSON summary of sleep data for the selected interval.
- Interpret it and write concise, supportive insights for a parent. Output goes into a PDF.

IMPORTANT (NO MATH)
- Do NOT recalculate totals or averages.
- Treat numbers as ground truth. Focus on interpretation.
- "totalSessions" counts sleeps; a sleep that crossed midnight is already merged into one session.

STYLE
- English
- Short bullet points
- Supportive, non-judgmental
- No diagnosis, no medical certainty

DATA RULES
- Use ONLY the provided JSON.
- If missing info, say "Not enough data to conclude".

SAFETY
- If red flags are implied, mention gently and recommend consulting a pediatrician.
- Always include: "Not medical advice."

$kAiReportOutputFormat''';

  Future<SleepAiInsight?> analyzeSleepReport({
    required ReportPeriod mode,
    required String rangeLabel,
    required List<SleepModel> sleeps,
    List<String> notes = const [],
    int maxTokens = kMaxAiTokens,
    double temperature = 0.4,
  }) {
    return requestAiReport(
      tag: 'sleepReport',
      systemPrompt: '$_systemPrompt${babyPersonalization()}',
      // ✅ REDUCED JSON payload (pre-computed)
      buildUserContent: () => jsonEncode({
        'reportMode': reportPeriodLabel(mode),
        'rangeLabel': rangeLabel,
        'payload': SleepAiCompute.buildPayload(
          sleeps: sleeps,
          babyName: currentBabyName,
          babyAgeRange: currentBabyAgeRange,
          notes: notes,
        ).toMap(),
      }),
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}

class SleepAiPayload {
  final String? babyName;
  final String? babyAgeRange;

  /// Gece yarısında bölünmüş kayıtlar birleştirilmiş uyku sayısı.
  final int totalSessions;

  /// computed basic sleep duration
  final int totalSleepMinutes;
  final int avgSleepMinutes;

  final SleepAiStats stats;
  final List<String> notes;

  SleepAiPayload({
    required this.babyName,
    required this.babyAgeRange,
    required this.totalSessions,
    required this.totalSleepMinutes,
    required this.avgSleepMinutes,
    required this.stats,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    "babyName": babyName,
    "babyAgeRange": babyAgeRange,
    "totalSessions": totalSessions,
    "totalSleepMinutes": totalSleepMinutes,
    "avgSleepMinutes": avgSleepMinutes,
    "stats": stats.toMap(),
    "notes": notes,
  };
}

class SleepAiStats {
  /// howItHappened frequency
  final Map<String, int> methodPreference;

  /// endOfSleep / mood at wake up
  final Map<String, int> moodAtWakeUp;

  /// fall-asleep time analysis
  final String avgFallAsleepTimeLabel; // "under 10 min", "10-30 min", ">30 min"
  final int avgFallAsleepMinutes; // computed numeric average
  final bool fastFallingAsleep; // derived flag

  SleepAiStats({
    required this.methodPreference,
    required this.moodAtWakeUp,
    required this.avgFallAsleepTimeLabel,
    required this.avgFallAsleepMinutes,
    required this.fastFallingAsleep,
  });

  Map<String, dynamic> toMap() => {
    "methodPreference": methodPreference,
    "moodAtWakeUp": moodAtWakeUp,
    "avgFallAsleepTime": avgFallAsleepTimeLabel,
    "avgFallAsleepMinutes": avgFallAsleepMinutes,
    "fastFallingAsleep": fastFallingAsleep,
  };
}

/// --- Map/Reduce helpers ---
class SleepAiCompute {
  static SleepAiPayload buildPayload({
    required List<SleepModel> sleeps,
    required String? babyName,
    required String? babyAgeRange,
    List<String> notes = const [],
  }) {
    final methodPref = <String, int>{};
    final moodWake = <String, int>{};
    final fallAsleepMinutesList = <int>[];
    var totalSleepMin = 0;

    // Gece yarısında ikiye bölünmüş kayıtlar tek uyku sayılır; aksi halde
    // gece uykuları ortalamayı yarıya düşürür ve etiketler iki kez sayılır.
    final sessions = mergeSleepSessions(sleeps);

    for (final session in sessions) {
      final s = session.first; // etiketler parçalarda aynı

      final how = _canonicalHowItHappened(s.howItHappened);
      if (how != null) methodPref[how] = (methodPref[how] ?? 0) + 1;

      final mood = _canonicalMood(session.last.endOfSleep);
      if (mood != null) moodWake[mood] = (moodWake[mood] ?? 0) + 1;

      totalSleepMin += session.durationMinutes;

      final fallMin = _startOfSleepToMinutes(s.startOfSleep);
      if (fallMin != null) fallAsleepMinutesList.add(fallMin);
    }

    final totalSessions = sessions.length;
    final avgSleepMinutes = totalSessions == 0
        ? 0
        : (totalSleepMin / totalSessions).round();

    final avgFallMin = fallAsleepMinutesList.isEmpty
        ? 0
        : (fallAsleepMinutesList.reduce((a, b) => a + b) /
                  fallAsleepMinutesList.length)
              .round();

    return SleepAiPayload(
      babyName: babyName,
      babyAgeRange: babyAgeRange,
      totalSessions: totalSessions,
      totalSleepMinutes: totalSleepMin,
      avgSleepMinutes: avgSleepMinutes,
      stats: SleepAiStats(
        methodPreference: methodPref,
        moodAtWakeUp: moodWake,
        avgFallAsleepTimeLabel: _minutesToFallAsleepLabel(avgFallMin),
        avgFallAsleepMinutes: avgFallMin,
        fastFallingAsleep: fallAsleepMinutesList.isNotEmpty && avgFallMin <= 20,
      ),
      notes: notes,
    );
  }

  /// add_sleep_bottom_sheet.dart `SleepOptions.howItHappenedOptions` birebir.
  static const Map<String, String> _howItHappenedKeys = {
    'nursing': 'nursing',
    'on own in bed': 'on_own',
    'warm or health': 'warm_or_health',
    'next to caregiver': 'next_to_caregiver',
    'co-sleep': 'co_sleep',
    'bottle': 'bottle',
    'stroller': 'stroller',
    'car': 'car_ride',
    'swing': 'swing',
  };

  static String? _canonicalHowItHappened(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;
    return _howItHappenedKeys[s] ?? s.replaceAll(' ', '_');
  }

  static String? _canonicalMood(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;

    if (s.contains('content') || s.contains('happy') || s.contains('calm')) {
      return 'content';
    }
    if (s.contains('cry') || s.contains('fussy') || s.contains('upset')) {
      return 'crying';
    }
    if (s.contains('neutral')) return 'neutral';

    return s.replaceAll(' ', '_');
  }

  /// startOfSleep → dakika ağırlığı. Seçenekler (SleepOptions):
  /// "under 10 min to fall asleep" → 10, "10-30 min" → 20,
  /// "more than 30 min" → 45. Ruh hali seçenekleri (upset/crying/content)
  /// süre değildir → null.
  static int? _startOfSleepToMinutes(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;

    switch (s) {
      case 'under 10 min to fall asleep':
        return 10;
      case '10-30 min':
        return 20;
      case 'more than 30 min':
        return 45;
      case 'upset':
      case 'crying':
      case 'content':
        return null;
    }

    // Eski/serbest metinler için yedek kurallar
    if (s.contains('under') && s.contains('10')) return 10;
    if (s.contains('more than') || s.contains('over')) return 45;
    if (s.contains('10') && s.contains('30')) return 20;
    final numMatch = RegExp(r'(\d{1,3})').firstMatch(s);
    if (numMatch != null) {
      final n = int.tryParse(numMatch.group(1)!);
      if (n != null && n > 0 && n < 300) return n;
    }
    return null;
  }

  static String _minutesToFallAsleepLabel(int minutes) {
    if (minutes <= 0) return "not enough data";
    if (minutes <= 10) return "under 10 min";
    if (minutes <= 30) return "10-30 min";
    return ">30 min";
  }
}
