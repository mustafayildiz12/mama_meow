import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_page.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';

class NursingAIService {
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱, an evidence-informed breastfeeding and nursing report assistant.

GOAL
- Analyze nursing sessions (breastfeeding & bottle) for the selected interval.
- Produce a concise, supportive summary for a parent. This will be embedded in a PDF.

STYLE
- Write in English.
- Short bullet points, no long paragraphs.
- Supportive and non-judgmental.
- Avoid diagnosis. Never claim medical certainty.

DATA RULES
- Only use the provided data.
- If something is missing or uncertain, say "Not enough data to conclude".

SAFETY
- If strong side imbalance, very long/short sessions, or unusual patterns are detected,
  mention gently and recommend consulting a lactation consultant or pediatrician.

OUTPUT FORMAT (STRICT JSON ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1", "bullet 2", "bullet 3", "bullet 4"],
  "patterns": ["pattern 1", "pattern 2", "pattern 3"],
  "watch_outs": ["watch out 1", "watch out 2"],
  "action_plan": ["action 1", "action 2", "action 3", "action 4"],
  "confidence_note": "string",
  "disclaimer": "string (include Not medical advice...)",
  "sources": [
    {"title": "string", "publisher": "string", "url": "https://...", "year": 2023}
  ],
  "last_updated": "YYYY-MM-DD"
}
''';

  // -------------------------
  // Personalization (baby name + age)
  // -------------------------
  String _buildPersonalization() {
    if (_babyName == null && _babyAgeKey == null) return '';

    final ageMap = <String, String>{
      'newborn': '0–3 months old',
      'infant': '3–12 months old',
      'toddler': '1–3 years old',
      'preschool': '3–5 years old',
      'school': '5+ years old',
      'expecting': 'expecting (not born yet)',
    };

    final ageText = _babyAgeKey != null
        ? (ageMap[_babyAgeKey] ?? _babyAgeKey)
        : null;

    if (_babyName != null && ageText != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The baby's name is $_babyName and the baby is $ageText. Use the baby's name gently when helpful.";
    } else if (_babyName != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The baby's name is $_babyName. Use the baby's name gently when helpful.";
    } else {
      return "\n\nIMPORTANT PERSONALIZATION: The baby is $ageText. Personalize insights based on age.";
    }
  }

  // -------------------------
  // MAIN ANALYZE METHOD
  // -------------------------
  Future<NursingAiInsight?> analyze({
    required NursingReportMode mode,
    required String rangeLabel,
    required NursingReportComputed c,
    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final systemPrompt = '$_systemPrompt${_buildPersonalization()}';

      final userPrompt = _buildUserPrompt(
        mode: mode,
        rangeLabel: rangeLabel,
        c: c,
      );

      final body = {
        "model": askMiaModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
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

      return NursingAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // -------------------------
  // USER PROMPT BUILDER
  // -------------------------
  String _buildUserPrompt({
    required NursingReportMode mode,
    required String rangeLabel,
    required NursingReportComputed c,
  }) {
    return '''
Analyze the selected nursing report and produce AI insights for a PDF.

REPORT_MODE: ${mode.name}
RANGE_LABEL: $rangeLabel

SESSIONS:
- count: ${c.sessionCount}
- total_duration_minutes: ${c.totalDuration}
- avg_duration_minutes: ${c.avgDuration}
- last_time: ${c.lastTimeLabel}

DISTRIBUTION_BY_HOUR (hour -> count):
${c.distHourCount.entries.map((e) => "- ${e.key}: ${e.value}").join("\n")}

SIDE_COUNTS:
${c.sideCounts.entries.map((e) => "- ${e.key}: ${e.value}").join("\n")}

FEEDING_TYPE_COUNTS:
${c.feedingTypeCounts.entries.map((e) => "- ${e.key}: ${e.value}").join("\n")}

MILK_TYPE_COUNTS:
${c.milkTypeCounts.entries.map((e) => "- ${e.key}: ${e.value}").join("\n")}

AMOUNT_TOTALS:
${c.amountTypeTotals.entries.map((e) => "- ${e.key}: ${e.value}").join("\n")}

INSTRUCTIONS:
- Keep it short for PDF: 4 summary bullets, 3 patterns, 2 watch-outs, 4 action steps.
- If data seems incomplete, mention it in confidence_note.
- Avoid medical claims; include Not medical advice.
''';
  }

  // -------------------------
  // JSON FENCE STRIPPER
  // -------------------------
  String _stripJsonFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceAll(RegExp(r'\s*```$'), '');
    }
    return t.trim();
  }
}

class NursingAiInsight {
  final String aiTitle;
  final List<String> aiSummaryBullets;
  final List<String> patterns;
  final List<String> watchOuts;
  final List<String> actionPlan;
  final String confidenceNote;
  final String disclaimer;
  final List<NursingAiSource> sources;
  final String lastUpdated;

  NursingAiInsight({
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

  factory NursingAiInsight.fromMap(Map<String, dynamic> m) {
    List<String> ls(String k) =>
        (m[k] is List) ? (m[k] as List).map((e) => "$e").toList() : [];

    final src = (m['sources'] is List) ? (m['sources'] as List) : const [];
    return NursingAiInsight(
      aiTitle: "${m['ai_title'] ?? ''}",
      aiSummaryBullets: ls('ai_summary_bullets'),
      patterns: ls('patterns'),
      watchOuts: ls('watch_outs'),
      actionPlan: ls('action_plan'),
      confidenceNote: "${m['confidence_note'] ?? ''}",
      disclaimer: "${m['disclaimer'] ?? ''}",
      lastUpdated: "${m['last_updated'] ?? ''}",
      sources: src
          .whereType<Map>()
          .map((e) => NursingAiSource.fromMap(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class NursingAiSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  NursingAiSource({
    required this.title,
    required this.publisher,
    required this.url,
    required this.year,
  });

  factory NursingAiSource.fromMap(Map<String, dynamic> m) {
    return NursingAiSource(
      title: "${m['title'] ?? ''}",
      publisher: "${m['publisher'] ?? ''}",
      url: "${m['url'] ?? ''}",
      year: m['year'] is num ? (m['year'] as num).toInt() : null,
    );
  }
}
