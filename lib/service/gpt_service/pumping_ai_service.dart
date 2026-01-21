import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_page.dart'; // PumpingReportMode
import 'package:mama_meow/models/activities/pumping_model.dart';

class PumpingAIService {
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  static const String _systemPrompt = r'''
You are "MamaMeow" 🐱, a lactation consultant & postpartum support expert.

GOAL
- You will receive ONE REDUCED, PRE-COMPUTED JSON summary of pumping data for the selected interval.
- Interpret it and produce short, supportive, empowering insights for a mother.
- Output will be embedded in a PDF above a table. Keep it scannable.

IMPORTANT (NO MATH)
- Do NOT recalculate totals, averages, or percentages.
- Treat the numbers as ground truth. Focus on interpretation.

STYLE
- Output Language: Use the provided "userLanguage" if present (e.g., "en", "tr-TR"). If missing, use English.
- Use emojis lightly.
- Warm, professional, empowering.
- No diagnosis, no medical certainty.

DATA RULES
- Use ONLY provided JSON.
- If missing info, say "Not enough data to conclude".
- If sessions < 2, focus on limitations and gentle tips.

SAFETY
- If there are long gaps between sessions (e.g., very high "longestGapHours"),
  mention gently that long gaps can be uncomfortable and consider speaking with a lactation consultant.
- Always include: "Not medical advice."

OUTPUT FORMAT (STRICT JSON ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1", "bullet 2", "bullet 3", "bullet 4"],
  "patterns": ["pattern 1", "pattern 2", "pattern 3"],
  "watch_outs": ["watch out 1", "watch out 2"],
  "action_plan": ["action 1", "action 2", "action 3", "action 4"],
  "confidence_note": "string",
  "disclaimer": "string (include Not medical advice...)",
  "echo": {
    "sessions": 0,
    "totalMinutes": 0,
    "avgSessionMinutes": 0,
    "leftMinutes": 0,
    "rightMinutes": 0,
    "frequencyPerDay": 0,
    "mostFrequentTime": "string",
    "longestGapHours": 0
  },
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
    final ageText = _babyAgeKey != null
        ? (map[_babyAgeKey] ?? _babyAgeKey)
        : null;

    if (_babyName != null && ageText != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName, age range is $ageText (context only). Keep focus on pumping support for the mother.";
    } else if (_babyName != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName (context only). Keep focus on pumping support for the mother.";
    } else if (ageText != null) {
      return "\n\nPERSONALIZATION: Baby age range is $ageText (context only). Keep focus on pumping support for the mother.";
    }
    return '';
  }

  Future<PumpingAiInsight?> analyzePumpingReport({
    required PumpingReportMode mode,
    required String rangeLabel,

    // 🔸 Ham liste dursun (PDF tabloda vs işe yarıyor) ama AI payload'da kullanmayacağız.
    required List<PumpingModel> pumpings,

    // ✅ Asıl kaynak: pre-computed
    required PumpingReportComputed computed,

    String userLanguage = "en",
    List<String> notes = const [],
    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      // ✅ payload artık computed'den geliyor (NO MATH kuralına tam uyum)
      final payload = _buildReducedPayload(
        mode: mode,
        rangeLabel: rangeLabel,
        computed: computed,
        userLanguage: userLanguage,
        notes: notes,
      );

      final userJson = jsonEncode(payload);

      final body = {
        "model": askMiaModel,
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": userJson},
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
      return PumpingAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _buildReducedPayload({
    required PumpingReportMode mode,
    required String rangeLabel,
    required PumpingReportComputed computed,
    required String userLanguage,
    required List<String> notes,
  }) {
    final period = _modeText(mode);

    // side %
    final totalSideMin = (computed.leftMinutes + computed.rightMinutes);
    final leftPct = totalSideMin == 0
        ? 0
        : ((computed.leftMinutes * 100) / totalSideMin).round();
    final rightPct = totalSideMin == 0
        ? 0
        : ((computed.rightMinutes * 100) / totalSideMin).round();

    return {
      "userLanguage": userLanguage,
      "period": period,
      "rangeLabel": rangeLabel,
      "sessions": computed.sessions,
      "stats": {
        "totalMinutes": computed.totalMinutes,
        "avgSessionTime": computed.avgSessionMinutes,
        "sideSplitPercent": {"left": leftPct, "right": rightPct},
        "sides": {
          "leftMinutes": computed.leftMinutes,
          "rightMinutes": computed.rightMinutes,
        },
        "frequencyPerDay": computed.frequencyPerDay,
      },
      "patterns": {
        "mostFrequentTime": computed.mostFrequentTime,
        "longestGapHours": computed.longestGapHours,
        "lastSessionTime": computed.lastSessionTime,
      },
      "notes": notes,
    };
  }

  String _modeText(PumpingReportMode mode) => switch (mode) {
    PumpingReportMode.today => "Daily",
    PumpingReportMode.week => "Weekly",
    PumpingReportMode.month => "Monthly",
  };

  String _stripJsonFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceAll(RegExp(r'\s*```$'), '');
    }
    return t.trim();
  }
}

/// ----------------------------
/// Reduced payload
/// ----------------------------

class PumpingAiPayload {
  final String period; // Daily/Weekly/Monthly
  final String userLanguage; // en / tr-TR ...
  final int sessions;

  final PumpingAiStats stats;
  final PumpingAiPatterns patterns;
  final List<String> notes;

  PumpingAiPayload({
    required this.period,
    required this.userLanguage,
    required this.sessions,
    required this.stats,
    required this.patterns,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    "period": period,
    "userLanguage": userLanguage,
    "sessions": sessions,
    "stats": stats.toMap(),
    "patterns": patterns.toMap(),
    "notes": notes,
  };
}

class PumpingAiStats {
  final int totalMinutes;
  final int avgSessionTime;

  final int leftMinutes;
  final int rightMinutes;

  final int frequencyPerDay;

  PumpingAiStats({
    required this.totalMinutes,
    required this.avgSessionTime,
    required this.leftMinutes,
    required this.rightMinutes,
    required this.frequencyPerDay,
  });

  Map<String, dynamic> toMap() => {
    "totalMinutes": totalMinutes,
    "avgSessionTime": avgSessionTime,
    "sides": {"leftMinutes": leftMinutes, "rightMinutes": rightMinutes},
    "frequencyPerDay": frequencyPerDay,
  };
}

class PumpingAiPatterns {
  final String mostFrequentTime; // "05:00 - 09:00"
  final int longestGapHours;

  PumpingAiPatterns({
    required this.mostFrequentTime,
    required this.longestGapHours,
  });

  Map<String, dynamic> toMap() => {
    "mostFrequentTime": mostFrequentTime,
    "longestGapHours": longestGapHours,
  };
}

/// ----------------------------
/// Compute (developer does math)
/// ----------------------------

class PumpingAiCompute {
  static PumpingAiPayload buildPayload({
    required List<PumpingModel> pumpings,
    required String period,
    required String userLanguage,
    List<String> notes = const [],
  }) {
    final sessions = pumpings.length;

    final totalMinutes = pumpings.fold<int>(0, (sum, p) => sum + p.duration);
    final avgSession = sessions == 0 ? 0 : (totalMinutes / sessions).round();

    int leftMinutes = 0;
    int rightMinutes = 0;

    // hourly activity (minutes)
    final byHourMinutes = List<int>.filled(24, 0);

    // timestamps (for gaps)
    final times = <DateTime>[];

    for (final p in pumpings) {
      if (p.isLeft) {
        leftMinutes += p.duration;
      } else {
        rightMinutes += p.duration;
      }

      final dt =
          _tryParseDateTime(p.createdAt) ?? _fallbackTimeOnly(p.startTime);
      if (dt != null) {
        byHourMinutes[dt.hour] += p.duration;
        times.add(dt);
      }
    }

    // Most frequent time bucket: 4 buckets
    final mostFrequentTime = _mostActiveBucket(byHourMinutes);

    // Longest gap in hours
    times.sort();
    int longestGapHours = 0;
    for (int i = 1; i < times.length; i++) {
      final gapH = times[i].difference(times[i - 1]).inHours.abs();
      if (gapH > longestGapHours) longestGapHours = gapH;
    }

    // Frequency per day (rough): sessions / distinct days
    final daySet = <String>{};
    for (final dt in times) {
      daySet.add(
        "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}",
      );
    }
    final days = daySet.isEmpty ? 1 : daySet.length;
    final frequencyPerDay = sessions == 0 ? 0 : (sessions / days).round();

    return PumpingAiPayload(
      period: period,
      userLanguage: userLanguage,
      sessions: sessions,
      stats: PumpingAiStats(
        totalMinutes: totalMinutes,
        avgSessionTime: avgSession,
        leftMinutes: leftMinutes,
        rightMinutes: rightMinutes,
        frequencyPerDay: frequencyPerDay,
      ),
      patterns: PumpingAiPatterns(
        mostFrequentTime: mostFrequentTime,
        longestGapHours: longestGapHours,
      ),
      notes: notes,
    );
  }

  static DateTime? _tryParseDateTime(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _fallbackTimeOnly(String hhmm) {
    try {
      final p = hhmm.split(':');
      if (p.length < 2) return null;
      final h = int.parse(p[0]);
      final m = int.parse(p[1]);
      return DateTime(2000, 1, 1, h, m);
    } catch (_) {
      return null;
    }
  }

  static String _mostActiveBucket(List<int> byHourMinutes) {
    int sum(int start, int endInclusive) {
      var s = 0;
      for (int h = start; h <= endInclusive; h++) s += byHourMinutes[h];
      return s;
    }

    final morning = sum(5, 9); // 05-09
    final day = sum(10, 16); // 10-16
    final evening = sum(17, 21); // 17-21
    final night = sum(22, 23) + sum(0, 4); // 22-04

    final entries = <String, int>{
      "05:00 - 09:00": morning,
      "10:00 - 16:00": day,
      "17:00 - 21:00": evening,
      "22:00 - 04:00": night,
    };

    final best = entries.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.key;
  }
}

/// ----------------------------
/// Insight + Source models
/// ----------------------------

class PumpingAiInsight {
  final String aiTitle;
  final List<String> aiSummaryBullets;
  final List<String> patterns;
  final List<String> watchOuts;
  final List<String> actionPlan;
  final String confidenceNote;
  final String disclaimer;
  final Map<String, dynamic>? echo;
  final List<PumpingAiSource> sources;
  final String lastUpdated;

  PumpingAiInsight({
    required this.aiTitle,
    required this.aiSummaryBullets,
    required this.patterns,
    required this.watchOuts,
    required this.actionPlan,
    required this.confidenceNote,
    required this.disclaimer,
    required this.sources,
    required this.lastUpdated,
    this.echo,
  });

  factory PumpingAiInsight.fromMap(Map<String, dynamic> m) {
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
        .map((e) => PumpingAiSource.fromMap(e.cast<String, dynamic>()))
        .toList();

    return PumpingAiInsight(
      aiTitle: (m['ai_title'] ?? '').toString(),
      aiSummaryBullets: ls('ai_summary_bullets'),
      patterns: ls('patterns'),
      watchOuts: ls('watch_outs'),
      actionPlan: ls('action_plan'),
      confidenceNote: (m['confidence_note'] ?? '').toString(),
      disclaimer: (m['disclaimer'] ?? '').toString(),
      echo: (m['echo'] is Map)
          ? (m['echo'] as Map).cast<String, dynamic>()
          : null,
      sources: sources,
      lastUpdated: (m['last_updated'] ?? '').toString(),
    );
  }
}

class PumpingAiSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  PumpingAiSource({
    required this.title,
    required this.publisher,
    required this.url,
    required this.year,
  });

  factory PumpingAiSource.fromMap(Map<String, dynamic> m) {
    final y = m['year'];
    return PumpingAiSource(
      title: (m['title'] ?? '').toString(),
      publisher: (m['publisher'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      year: (y is num) ? y.toInt() : int.tryParse((y ?? '').toString()),
    );
  }
}
