import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/sleep_report_page.dart';

class SleepAIService {
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱, an evidence-informed baby sleep report assistant.

GOAL
- You will receive a REDUCED, PRE-COMPUTED JSON summary of sleep data for the selected interval.
- Interpret it and write concise, supportive insights for a parent. Output goes into a PDF.

IMPORTANT (NO MATH)
- Do NOT recalculate totals or averages.
- Treat numbers as ground truth. Focus on interpretation.

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

OUTPUT FORMAT (STRICT JSON ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1", "bullet 2", "bullet 3", "bullet 4"],
  "patterns": ["pattern 1", "pattern 2", "pattern 3"],
  "watch_outs": ["watch out 1", "watch out 2"],
  "action_plan": ["action 1", "action 2", "action 3", "action 4"],
  "confidence_note": "string (1 short line about data limits)",
  "disclaimer": "string (include Not medical advice...)",
  "computed_flags": {"fast_falling_asleep": true},
  "computed_numbers": {"avg_fall_asleep_minutes": 20, "avg_sleep_minutes": 95},
  "sources": [{"title":"string","publisher":"string","url":"https://...","year":2023}],
  "last_updated": "YYYY-MM-DD"
}
''';

  String _buildPersonalization() {
    if (_babyName == null && _babyAgeKey == null) return '';
    final map = <String, String>{
      'newborn': '0-3 months old',
      'infant': '3-12 months old',
      'toddler': '1-3 years old',
      'preschool': '3-5 years old',
      'school': '5+ years old',
      'expecting': 'expecting (not born yet)',
    };
    final ageText = _babyAgeKey != null ? (map[_babyAgeKey] ?? _babyAgeKey) : null;

    if (_babyName != null && ageText != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The baby's name is $_babyName and age range is $ageText. Use the baby's name naturally (optional).";
    } else if (_babyName != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The baby's name is $_babyName. Use the baby's name naturally (optional).";
    } else {
      return "\n\nIMPORTANT PERSONALIZATION: Baby age range is $ageText. Tailor suggestions gently to age.";
    }
  }

  Future<SleepAiInsight?> analyzeSleepReport({
    required SleepReportMode mode,
    required String rangeLabel,
    required List<SleepModel> sleeps,
    List<String> notes = const [],
    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      // ✅ REDUCED JSON payload (pre-computed)
      final payload = SleepAiCompute.buildPayload(
        sleeps: sleeps,
        babyName: _babyName,
        babyAgeRange: _babyAgeKey,
        notes: notes,
      );

      final userText = _buildUserPromptAsJson(
        mode: mode,
        rangeLabel: rangeLabel,
        payload: payload,
      );

      final body = {
        "model": askMiaModel,
        "messages": [
          {"role": "system", "content": system},
          {
            "role": "user",
            "content": [
              {"type": "text", "text": userText},
            ],
          },
        ],
        "max_tokens": maxTokens,
        "temperature": temperature,
      };

      final resp = await http
          .post(
            Uri.parse(_chatUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $apiValue",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final raw = (data['choices'] as List?)?.isNotEmpty == true
          ? (data['choices'][0]['message']['content'] as String? ?? '')
          : '';

      if (raw.trim().isEmpty) return null;

      final cleaned = _stripJsonFences(raw);
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return SleepAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _buildUserPromptAsJson({
    required SleepReportMode mode,
    required String rangeLabel,
    required SleepAiPayload payload,
  }) {
    final modeText = switch (mode) {
      SleepReportMode.today => "daily",
      SleepReportMode.week => "weekly",
      SleepReportMode.month => "monthly",
    };

    final obj = <String, dynamic>{
      "reportMode": modeText,
      "rangeLabel": rangeLabel,
      "payload": payload.toMap(),
    };

    // ✅ AI'ya düz JSON veriyoruz (koca liste değil)
    return jsonEncode(obj);
  }

  String _stripJsonFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceAll(RegExp(r'\s*```$'), '');
    }
    return t.trim();
  }
}


class SleepAiPayload {
  final String? babyName;
  final String? babyAgeRange;

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
  final String avgFallAsleepTimeLabel; // "under 10 min", "10-30 min"...
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

    int totalSleepMin = 0;

    // fall asleep time minutes list (startOfSleep -> numeric weights)
    final fallAsleepMinutesList = <int>[];

    for (final s in sleeps) {
      // howItHappened freq
      final how = _canonicalHowItHappened(s.howItHappened);
      if (how != null) {
        methodPref[how] = (methodPref[how] ?? 0) + 1;
      }

      // mood at wake-up (endOfSleep)
      final mood = _canonicalMood(s.endOfSleep);
      if (mood != null) {
        moodWake[mood] = (moodWake[mood] ?? 0) + 1;
      }

      // duration (startTime/endTime)
      final dur = _durationMinutes(s.sleepDate, s.startTime, s.endTime);
      if (dur > 0) totalSleepMin += dur;

      // startOfSleep -> numeric
      final fallMin = _startOfSleepToMinutes(s.startOfSleep);
      if (fallMin != null) fallAsleepMinutesList.add(fallMin);
    }

    final totalSessions = sleeps.length;
    final avgSleepMinutes =
        totalSessions == 0 ? 0 : (totalSleepMin / totalSessions).round();

    final avgFallMin = fallAsleepMinutesList.isEmpty
        ? 0
        : (fallAsleepMinutesList.reduce((a, b) => a + b) /
                fallAsleepMinutesList.length)
            .round();

    final avgFallLabel = _minutesToFallAsleepLabel(avgFallMin);
    final fastFalling =
        (fallAsleepMinutesList.isNotEmpty) ? (avgFallMin <= 20) : false;

    return SleepAiPayload(
      babyName: babyName,
      babyAgeRange: babyAgeRange,
      totalSessions: totalSessions,
      totalSleepMinutes: totalSleepMin,
      avgSleepMinutes: avgSleepMinutes,
      stats: SleepAiStats(
        methodPreference: methodPref,
        moodAtWakeUp: moodWake,
        avgFallAsleepTimeLabel: avgFallLabel,
        avgFallAsleepMinutes: avgFallMin,
        fastFallingAsleep: fastFalling,
      ),
      notes: notes,
    );
  }

  static int _durationMinutes(String sleepDate, String startHHmm, String endHHmm) {
    DateTime? combine(String dateStr, String hhmm) {
      try {
        // sleepDate bazen "yyyy-MM-dd ..." gibi geliyor, ilk parçayı al
        final dateOnly = dateStr.split(' ').first;
        final ymd = DateTime.parse(dateOnly); // yyyy-MM-dd
        final p = hhmm.split(':');
        final h = int.tryParse(p[0]) ?? 0;
        final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
        return DateTime(ymd.year, ymd.month, ymd.day, h, m);
      } catch (_) {
        return null;
      }
    }

    final start = combine(sleepDate, startHHmm);
    var end = combine(sleepDate, endHHmm);
    if (start == null || end == null) return 0;

    // gece sarkması
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    final diff = end.difference(start).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  static String? _canonicalHowItHappened(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;

    // burada senin app’teki stringlere göre genişlet
    if (s.contains('own') || s.contains('self') || s.contains('on_own')) {
      return 'on_own';
    }
    if (s.contains('stroller')) return 'stroller';
    if (s.contains('nursing') || s.contains('breast')) return 'nursing';
    if (s.contains('rock') || s.contains('rocking')) return 'rocking';
    if (s.contains('carrier')) return 'carrier';
    if (s.contains('car')) return 'car_ride';

    // bilinmeyenleri normalize edip anahtar yapalım:
    return s.replaceAll(' ', '_');
  }

  static String? _canonicalMood(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;

    // örnek canonical
    if (s.contains('content') || s.contains('happy') || s.contains('calm')) {
      return 'content';
    }
    if (s.contains('cry') || s.contains('fussy') || s.contains('upset')) {
      return 'crying';
    }
    if (s.contains('neutral')) return 'neutral';

    return s.replaceAll(' ', '_');
  }

  /// startOfSleep -> numeric weight
  /// "under 10 min" -> 10
  /// "10-30 min" -> 20
  /// "30-60 min" -> 45
  /// "over 60 min" -> 75
  static int? _startOfSleepToMinutes(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return null;

    if (s.contains('under') && s.contains('10')) return 10;
    if (s.contains('10') && s.contains('30')) return 20;
    if (s.contains('30') && s.contains('60')) return 45;
    if (s.contains('over') && s.contains('60')) return 75;

    // bazen "15 min" gibi gelebilir
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
    if (minutes <= 60) return "30-60 min";
    return "over 60 min";
  }
}

class SleepAiInsight {
  final String aiTitle;
  final List<String> aiSummaryBullets;
  final List<String> patterns;
  final List<String> watchOuts;
  final List<String> actionPlan;
  final String confidenceNote;
  final String disclaimer;
  final List<SleepAiSource> sources;
  final String lastUpdated;

  // ✅ NEW (optional)
  final Map<String, dynamic>? computedFlags;
  final Map<String, dynamic>? computedNumbers;

  SleepAiInsight({
    required this.aiTitle,
    required this.aiSummaryBullets,
    required this.patterns,
    required this.watchOuts,
    required this.actionPlan,
    required this.confidenceNote,
    required this.disclaimer,
    required this.sources,
    required this.lastUpdated,
    this.computedFlags,
    this.computedNumbers,
  });

  factory SleepAiInsight.fromMap(Map<String, dynamic> m) {
    List<String> ls(String key) {
      final v = m[key];
      if (v is List) {
        return v
            .map((e) => (e ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
      return const [];
    }

    final src = (m['sources'] is List) ? (m['sources'] as List) : const [];
    final sources = src
        .whereType<Map>()
        .map((e) => SleepAiSource.fromMap(e.cast<String, dynamic>()))
        .toList();

    return SleepAiInsight(
      aiTitle: (m['ai_title'] ?? '').toString(),
      aiSummaryBullets: ls('ai_summary_bullets'),
      patterns: ls('patterns'),
      watchOuts: ls('watch_outs'),
      actionPlan: ls('action_plan'),
      confidenceNote: (m['confidence_note'] ?? '').toString(),
      disclaimer: (m['disclaimer'] ?? '').toString(),
      sources: sources,
      lastUpdated: (m['last_updated'] ?? '').toString(),
      computedFlags: (m['computed_flags'] is Map)
          ? (m['computed_flags'] as Map).cast<String, dynamic>()
          : null,
      computedNumbers: (m['computed_numbers'] is Map)
          ? (m['computed_numbers'] as Map).cast<String, dynamic>()
          : null,
    );
  }
}

class SleepAiSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  SleepAiSource({
    required this.title,
    required this.publisher,
    required this.url,
    required this.year,
  });

  factory SleepAiSource.fromMap(Map<String, dynamic> m) {
    final y = m['year'];
    return SleepAiSource(
      title: (m['title'] ?? '').toString(),
      publisher: (m['publisher'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      year: (y is num) ? y.toInt() : int.tryParse((y ?? '').toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "title": title,
        "publisher": publisher,
        "url": url,
        "year": year,
      };
}

