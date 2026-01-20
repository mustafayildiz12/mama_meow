import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/sleep_report_page.dart';

class TrackerAIService {
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱, an evidence-informed baby sleep report assistant inside a mother-baby app.

GOAL
- Analyze the user's selected sleep report interval (daily/weekly/monthly) and produce a concise, practical summary for a parent.
- The output will be embedded into a PDF report above a table. Keep it short, scannable, and non-judgmental.

STYLE
- Write in English.
- Use short bullet points, no long paragraphs.
- Be supportive and encouraging (warm but not overly chatty).
- Avoid diagnosis. Never claim medical certainty.

DATA RULES (IMPORTANT)
- You will receive structured sleep report data for the selected interval.
- Only use the provided data. If something is missing or uncertain, say "Not enough data to conclude".
- If the dataset is too small (e.g., fewer than 2 sleeps), focus on gentle suggestions and note the limitation.

SAFETY
- If you detect possible red flags (very low total sleep, extremely fragmented sleep, large day-night reversal patterns, or caregiver concern implied), mention it gently and recommend consulting a pediatrician.
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
  "sources": [
    {"title": "string", "publisher": "string", "url": "https://...", "year": 2023}
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
    final ageText = _babyAgeKey != null
        ? (map[_babyAgeKey] ?? _babyAgeKey)
        : null;

    if (_babyName != null && ageText != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The user's baby is named $_babyName and is $ageText. Personalize gently and use the baby's name when helpful.";
    } else if (_babyName != null) {
      return "\n\nIMPORTANT PERSONALIZATION: The user's baby is named $_babyName. Personalize gently and use the baby's name when helpful.";
    } else {
      return "\n\nIMPORTANT PERSONALIZATION: The user's baby is $ageText. Personalize gently based on age.";
    }
  }

  /// Sleep report için AI analizi üretir.
  /// - mode: today/week/month
  /// - rangeLabel: ekranda gösterdiğin tarih aralığı
  /// - sleeps: ham kayıtlar (opsiyonel ama faydalı)
  /// - metrics: senin hesapladığın özet metrikler
  /// - dist maps: senin hesapladığın dağılımlar (counts/minutes)
  Future<SleepAiInsight?> analyzeSleepReport({
    required SleepReportMode mode,
    required String rangeLabel,
    required List<SleepModel> sleeps,

    // ÖZET METRİKLER (sen hesaplayıp veriyorsun)
    required int totalSleepMinutes,
    required int sleepCount,
    required int avgSleepMinutes,
    required int longestSleepMinutes,
    required String lastEndTime,

    // DAĞILIMLAR
    required Map<String, int> distributionStartHourMinutes, // "00" -> dakika
    required Map<String, int> howItHappenedCounts,
    required Map<String, int> startMoodCounts,
    required Map<String, int> endMoodCounts,

    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      final userText = _buildSleepReportUserPrompt(
        mode: mode,
        rangeLabel: rangeLabel,
        totalSleepMinutes: totalSleepMinutes,
        sleepCount: sleepCount,
        avgSleepMinutes: avgSleepMinutes,
        longestSleepMinutes: longestSleepMinutes,
        lastEndTime: lastEndTime,
        distributionStartHourMinutes: distributionStartHourMinutes,
        howItHappenedCounts: howItHappenedCounts,
        startMoodCounts: startMoodCounts,
        endMoodCounts: endMoodCounts,
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

  // -----------------------
  // Prompt Builder
  // -----------------------

  String _buildSleepReportUserPrompt({
    required SleepReportMode mode,
    required String rangeLabel,
    required int totalSleepMinutes,
    required int sleepCount,
    required int avgSleepMinutes,
    required int longestSleepMinutes,
    required String lastEndTime,
    required Map<String, int> distributionStartHourMinutes,
    required Map<String, int> howItHappenedCounts,
    required Map<String, int> startMoodCounts,
    required Map<String, int> endMoodCounts,
  }) {
    String modeText = switch (mode) {
      SleepReportMode.today => "daily",
      SleepReportMode.week => "weekly",
      SleepReportMode.month => "monthly",
    };

    String mapLines(Map<String, int> m, {int limit = 60}) {
      // Çok uzamasın diye küçük maplerde hepsini, büyükse non-zero'ları dök
      final entries = m.entries.toList();

      // Saat dağılımı gibi 24 item varsa hepsini basabiliriz:
      if (entries.length <= limit) {
        return entries.map((e) => "- ${e.key}: ${e.value}").join("\n");
      }

      // büyük map ise ilk 30 item
      return entries.take(30).map((e) => "- ${e.key}: ${e.value}").join("\n");
    }

    return '''
Analyze the selected sleep report and produce AI insights for a PDF.

REPORT_MODE: $modeText
RANGE_LABEL: $rangeLabel

SLEEP_METRICS:
- total_sleep_minutes: $totalSleepMinutes
- sleep_count: $sleepCount
- avg_sleep_minutes: $avgSleepMinutes
- longest_sleep_minutes: $longestSleepMinutes
- last_end_time: $lastEndTime

DISTRIBUTION_START_HOUR_MINUTES (hour -> total minutes):
${mapLines(distributionStartHourMinutes)}

HOW_IT_HAPPENED_COUNTS:
${mapLines(howItHappenedCounts)}

START_MOOD_COUNTS:
${mapLines(startMoodCounts)}

END_MOOD_COUNTS:
${mapLines(endMoodCounts)}

INSTRUCTIONS:
- Keep it short for PDF: 4 summary bullets, 3 patterns, 2 watch-outs, 4 action steps.
- If data seems incomplete, mention it in confidence_note.
- Avoid medical claims; include Not medical advice.
''';
  }

  // -----------------------
  // JSON fence stripper
  // -----------------------

  String _stripJsonFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      // ```json ... ```
      t = t.replaceAll(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceAll(RegExp(r'\s*```$'), '');
    }
    return t.trim();
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
}
