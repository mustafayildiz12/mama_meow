import 'dart:convert';

import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_computed.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Bez raporu AI cevabı (ortak model).
typedef DiaperAiInsight = AiReportInsight;
typedef DiaperAiSource = AiSource;

class DiaperAIService {
  // ✅ Reduced JSON + No Math standard prompt
  static const String _systemPrompt = '''
You are "Coo Care Baby Tracker", an evidence-informed diaper report assistant.

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

$kAiReportOutputFormat''';

  Future<DiaperAiInsight?> analyze({
    required ReportPeriod mode,
    required String rangeLabel,
    required DiaperReportComputed c,
    String userLanguage = "en",
    List<String> notes = const [],
    int maxTokens = kMaxAiTokens,
    double temperature = 0.4,
  }) {
    return requestAiReport(
      tag: 'diaperReport',
      systemPrompt: '$_systemPrompt${babyPersonalization()}',
      // ✅ Reduced payload from computed, sent as pure JSON
      buildUserContent: () => jsonEncode(
        DiaperAiCompute.buildPayload(
          period: reportPeriodLabel(mode),
          rangeLabel: rangeLabel,
          c: c,
          userLanguage: userLanguage,
          notes: notes,
          babyName: currentBabyName,
          babyAgeRange: currentBabyAgeRange,
        ).toMap(),
      ),
      maxTokens: maxTokens,
      temperature: temperature,
    );
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

  /// developer-side convenience (no AI math), 1 ondalık (61 dk → 1.0)
  final double maxGapHours;

  final String mostFrequentTimeWindow; // e.g. "08:00 - 12:00"
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
    "patterns": {"mostFrequentTimeWindow": mostFrequentTimeWindow},
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
    final hourDist = <String, int>{
      for (var h = 0; h < 24; h++)
        h.toString().padLeft(2, '0'):
            c.distHourCount[h.toString().padLeft(2, '0')] ?? 0,
    };

    final maxGapHours = c.maxGapMinutes <= 0
        ? 0.0
        : double.parse((c.maxGapMinutes / 60).toStringAsFixed(1));

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
      mostFrequentTimeWindow: best4HourWindow(hourDist),
      typeCounts: Map<String, int>.from(c.typeCounts),
      hourDistribution: hourDist,
      notes: notes,
    );
  }
}
