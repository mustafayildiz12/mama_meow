import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_page.dart';

class DiaperAIService {
  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  // ✅ Reduced JSON + No Math standard prompt
  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱, an evidence-informed diaper report assistant.

GOAL
- You will receive ONE REDUCED, PRE-COMPUTED JSON summary of diaper data for the selected interval.
- Interpret it and produce concise, supportive insights for a parent.
- Output will be embedded in a PDF above a table.

IMPORTANT (NO MATH)
- Do NOT recalculate totals, averages, or percentages.
- Treat all numbers as ground truth. Focus on interpretation.

STYLE
- Output Language: Use the provided "userLanguage" if present (e.g., "en", "tr-TR"). If missing, use English.
- Short bullets, scannable.
- Supportive, non-judgmental.
- No diagnosis, no medical certainty.

DATA RULES
- Use ONLY provided JSON.
- If missing info, say "Not enough data to conclude".
- If total changes < 2, focus on limitations and gentle tips.

SAFETY
- If very long gaps or unusual patterns are implied, mention gently and recommend consulting a pediatrician if concerned.
- Always include: "Not medical advice."

OUTPUT FORMAT (STRICT JSON ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1","bullet 2","bullet 3","bullet 4"],
  "patterns": ["pattern 1","pattern 2","pattern 3"],
  "watch_outs": ["watch out 1","watch out 2"],
  "action_plan": ["action 1","action 2","action 3","action 4"],
  "confidence_note": "string",
  "disclaimer": "string (include Not medical advice...)",
  "echo": {
    "period": "Daily|Weekly|Monthly",
    "totalChanges": 0,
    "lastChangeLabel": "string",
    "avgGapMinutes": 0,
    "maxGapMinutes": 0,
    "maxGapHours": 0,
    "mostFrequentTimeWindow": "string",
    "typeCounts": {},
    "hourDistribution": {}
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
    final ageText = _babyAgeKey != null ? (map[_babyAgeKey] ?? _babyAgeKey) : null;

    if (_babyName != null && ageText != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName and age range is $ageText. Use baby's name gently if helpful.";
    } else if (_babyName != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName. Use baby's name gently if helpful.";
    } else if (ageText != null) {
      return "\n\nPERSONALIZATION: Baby age range is $ageText. Tailor suggestions gently to age.";
    }
    return '';
  }

  Future<DiaperAiInsight?> analyze({
    required DiaperReportMode mode,
    required String rangeLabel,
    required DiaperReportComputed c,
    String userLanguage = "en",
    List<String> notes = const [],
    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      // ✅ Reduced payload from computed
      final payload = DiaperAiCompute.buildPayload(
        period: _modeText(mode),
        rangeLabel: rangeLabel,
        c: c,
        userLanguage: userLanguage,
        notes: notes,
        babyName: _babyName,
        babyAgeRange: _babyAgeKey,
      );

      // ✅ Send as pure JSON (not long text)
      final userJson = jsonEncode(payload.toMap());

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
      return DiaperAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _modeText(DiaperReportMode mode) => switch (mode) {
        DiaperReportMode.today => "Daily",
        DiaperReportMode.week => "Weekly",
        DiaperReportMode.month => "Monthly",
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

/// ------------------------------
/// Payload + Compute (developer-side)
/// ------------------------------

class DiaperAiPayload {
  final String period; // Daily/Weekly/Monthly
  final String rangeLabel;
  final String userLanguage;

  final String? babyName;
  final String? babyAgeRange;

  final int totalChanges;
  final String lastChangeLabel;

  final int avgGapMinutes;
  final int maxGapMinutes;

  /// developer-side convenience (no AI math)
  final int maxGapHours;

  final String mostFrequentTimeWindow; // e.g. "06:00 - 10:00"
  final Map<String, int> typeCounts;
  final Map<String, int> hourDistribution; // "00".."23" -> count

  final List<String> notes;

  DiaperAiPayload({
    required this.period,
    required this.rangeLabel,
    required this.userLanguage,
    required this.babyName,
    required this.babyAgeRange,
    required this.totalChanges,
    required this.lastChangeLabel,
    required this.avgGapMinutes,
    required this.maxGapMinutes,
    required this.maxGapHours,
    required this.mostFrequentTimeWindow,
    required this.typeCounts,
    required this.hourDistribution,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
        "period": period,
        "rangeLabel": rangeLabel,
        "userLanguage": userLanguage,
        "babyName": babyName,
        "babyAgeRange": babyAgeRange,
        "stats": {
          "totalChanges": totalChanges,
          "lastChangeLabel": lastChangeLabel,
          "avgGapMinutes": avgGapMinutes,
          "maxGapMinutes": maxGapMinutes,
          "maxGapHours": maxGapHours,
        },
        "patterns": {
          "mostFrequentTimeWindow": mostFrequentTimeWindow,
        },
        "distributions": {
          "typeCounts": typeCounts,
          "hourDistribution": hourDistribution,
        },
        "notes": notes,
      };
}

class DiaperAiCompute {
  static DiaperAiPayload buildPayload({
    required String period,
    required String rangeLabel,
    required DiaperReportComputed c,
    required String userLanguage,
    required List<String> notes,
    required String? babyName,
    required String? babyAgeRange,
  }) {
    // hourDistribution: ensure keys "00".."23" exist (stable payload)
    final hourDist = <String, int>{};
    for (int h = 0; h < 24; h++) {
      final key = h.toString().padLeft(2, '0');
      hourDist[key] = c.distHourCount[key] ?? 0;
    }

    // best 4-hour window (00-03, 04-07, ... 20-23)
    final bestWindow = _best4HourWindow(hourDist);

    final maxGapHours = (c.maxGapMinutes <= 0) ? 0 : ((c.maxGapMinutes / 60).ceil());

    return DiaperAiPayload(
      period: period,
      rangeLabel: rangeLabel,
      userLanguage: userLanguage,
      babyName: babyName,
      babyAgeRange: babyAgeRange,
      totalChanges: c.totalCount,
      lastChangeLabel: c.lastChangeLabel,
      avgGapMinutes: c.avgGapMinutes,
      maxGapMinutes: c.maxGapMinutes,
      maxGapHours: maxGapHours,
      mostFrequentTimeWindow: bestWindow,
      typeCounts: Map<String, int>.from(c.typeCounts),
      hourDistribution: hourDist,
      notes: notes,
    );
  }

  static String _best4HourWindow(Map<String, int> hourDist) {
    int bestSum = -1;
    int bestStart = 0;

    for (int start = 0; start <= 20; start += 4) {
      int sum = 0;
      for (int h = start; h < start + 4; h++) {
        final key = h.toString().padLeft(2, '0');
        sum += hourDist[key] ?? 0;
      }
      if (sum > bestSum) {
        bestSum = sum;
        bestStart = start;
      }
    }

    final end = bestStart + 4;
    final s = bestStart.toString().padLeft(2, '0');
    final e = end.toString().padLeft(2, '0');
    // "05:00 - 09:00" format
    return "$s:00 - $e:00";
  }
}

/// ------------------------------
/// Insight model (+ echo optional)
/// ------------------------------

class DiaperAiInsight {
  final String aiTitle;
  final List<String> aiSummaryBullets;
  final List<String> patterns;
  final List<String> watchOuts;
  final List<String> actionPlan;
  final String confidenceNote;
  final String disclaimer;
  final List<DiaperAiSource> sources;
  final String lastUpdated;

  final Map<String, dynamic>? echo; // ✅ optional echo

  DiaperAiInsight({
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

  factory DiaperAiInsight.fromMap(Map<String, dynamic> m) {
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
        .map((e) => DiaperAiSource.fromMap(e.cast<String, dynamic>()))
        .toList();

    return DiaperAiInsight(
      aiTitle: (m['ai_title'] ?? '').toString(),
      aiSummaryBullets: ls('ai_summary_bullets'),
      patterns: ls('patterns'),
      watchOuts: ls('watch_outs'),
      actionPlan: ls('action_plan'),
      confidenceNote: (m['confidence_note'] ?? '').toString(),
      disclaimer: (m['disclaimer'] ?? '').toString(),
      sources: sources,
      lastUpdated: (m['last_updated'] ?? '').toString(),
      echo: (m['echo'] is Map) ? (m['echo'] as Map).cast<String, dynamic>() : null,
    );
  }
}

class DiaperAiSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  DiaperAiSource({
    required this.title,
    required this.publisher,
    required this.url,
    required this.year,
  });

  factory DiaperAiSource.fromMap(Map<String, dynamic> m) {
    final y = m['year'];
    return DiaperAiSource(
      title: (m['title'] ?? '').toString(),
      publisher: (m['publisher'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      year: (y is num) ? y.toInt() : int.tryParse((y ?? '').toString()),
    );
  }
}
