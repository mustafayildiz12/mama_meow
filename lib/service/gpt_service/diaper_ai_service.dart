import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_page.dart'; // apiValue, askMiaModel, currentMeowUser vs.

class DiaperAIService {
  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱, an evidence-informed diaper report assistant inside a mother-baby app.

GOAL
- Analyze diaper changes (types & timing) for the selected interval.
- Provide a concise, supportive summary for a parent for embedding in a PDF.

STYLE
- English, short bullet points.
- Supportive, non-judgmental.
- No diagnosis; no medical certainty.

DATA RULES
- Use only the provided data.
- If limited data, say "Not enough data to conclude".
- Focus on patterns: timing clusters, long gaps, changes in mix of types.

SAFETY
- If very long gaps or unusual patterns, mention gently and recommend consulting a pediatrician if concerned.

OUTPUT FORMAT (STRICT JSON ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1","bullet 2","bullet 3","bullet 4"],
  "patterns": ["pattern 1","pattern 2","pattern 3"],
  "watch_outs": ["watch out 1","watch out 2"],
  "action_plan": ["action 1","action 2","action 3","action 4"],
  "confidence_note": "string (1 short line about data limits)",
  "disclaimer": "string (include Not medical advice...)",
  "sources": [
    {"title":"string","publisher":"string","url":"https://...","year":2023}
  ],
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
      return "\n\nIMPORTANT PERSONALIZATION: The user's baby is named $_babyName and is $ageText. Personalize gently and use the baby's name when helpful.";
    } else if (_babyName != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The user's baby is named $_babyName. Personalize gently and use the baby's name when helpful.";
    } else {
      return "\n\nIMPORTANT PERSONALIZATION: The user's baby is $ageText. Personalize gently based on age.";
    }
  }

  Future<DiaperAiInsight?> analyze({
    required DiaperReportMode mode,
    required String rangeLabel,
    required DiaperReportComputed c,
    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      final userPrompt = _buildUserPrompt(
        mode: mode,
        rangeLabel: rangeLabel,
        c: c,
      );

      final body = {
        "model": askMiaModel,
        "messages": [
          {"role": "system", "content": system},
          {
            "role": "user",
            "content": [
              {"type": "text", "text": userPrompt},
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
      return DiaperAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _buildUserPrompt({
    required DiaperReportMode mode,
    required String rangeLabel,
    required DiaperReportComputed c,
  }) {
    String modeText = switch (mode) {
      DiaperReportMode.today => "daily",
      DiaperReportMode.week => "weekly",
      DiaperReportMode.month => "monthly",
    };

    String mapLinesInt(Map<String, int> m, {int limit = 60}) {
      final entries = m.entries.toList();
      if (entries.length <= limit) {
        return entries.map((e) => "- ${e.key}: ${e.value}").join("\n");
      }
      return entries.take(30).map((e) => "- ${e.key}: ${e.value}").join("\n");
    }

    return '''
Analyze the selected diaper report and produce AI insights for a PDF.

REPORT_MODE: $modeText
RANGE_LABEL: $rangeLabel

DIAPER_METRICS:
- total_changes: ${c.totalCount}
- last_change_time: ${c.lastChangeLabel}
- avg_gap_minutes: ${c.avgGapMinutes}
- max_gap_minutes: ${c.maxGapMinutes}

DISTRIBUTION_BY_HOUR (hour -> count):
${mapLinesInt(c.distHourCount)}

TYPE_COUNTS (type -> count):
${mapLinesInt(c.typeCounts)}

INSTRUCTIONS:
- Keep it short for PDF: 4 summary bullets, 3 patterns, 2 watch-outs, 4 action steps.
- If gaps look long or inconsistent, mention gently (no diagnosis).
- Always include "Not medical advice."
''';
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
