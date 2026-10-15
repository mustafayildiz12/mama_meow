import 'dart:convert';

import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_computed.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Süt sağma raporu AI cevabı (ortak model).
typedef PumpingAiInsight = AiReportInsight;
typedef PumpingAiSource = AiSource;

class PumpingAIService {
  static const String _systemPrompt = '''
You are "Coo Care Baby Tracker", a lactation consultant & postpartum support expert.

GOAL
- You will receive ONE REDUCED, PRE-COMPUTED JSON summary of pumping data for the selected interval.
- Interpret it and produce short, supportive, empowering insights for a mother.
- Output will be embedded in a PDF above a table. Keep it scannable.

IMPORTANT (NO MATH)
- Do NOT recalculate totals, averages, or percentages.
- Treat the numbers as ground truth. Focus on interpretation.

STYLE
- Output Language: Use the provided "userLanguage" if present (e.g., "en", "tr-TR"). If missing, use English.
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

$kAiReportOutputFormat''';

  Future<PumpingAiInsight?> analyzePumpingReport({
    required ReportPeriod mode,
    required String rangeLabel,

    /// Geriye dönük uyumluluk için duruyor; payload [computed]'dan kurulur.
    required List<PumpingModel> pumpings,

    // ✅ Asıl kaynak: pre-computed
    required PumpingReportComputed computed,

    String userLanguage = "en",
    List<String> notes = const [],
    int maxTokens = kMaxAiTokens,
    double temperature = 0.4,
  }) {
    final personalization = babyPersonalization(
      instruction:
          'This is context only. Keep the focus on pumping support for the mother.',
    );
    return requestAiReport(
      tag: 'pumpingReport',
      systemPrompt: '$_systemPrompt$personalization',
      buildUserContent: () => jsonEncode(
        _buildReducedPayload(
          mode: mode,
          rangeLabel: rangeLabel,
          computed: computed,
          userLanguage: userLanguage,
          notes: notes,
        ),
      ),
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  Map<String, dynamic> _buildReducedPayload({
    required ReportPeriod mode,
    required String rangeLabel,
    required PumpingReportComputed computed,
    required String userLanguage,
    required List<String> notes,
  }) {
    // side %
    final totalSideMin = computed.leftMinutes + computed.rightMinutes;
    int pct(int part) =>
        totalSideMin == 0 ? 0 : ((part * 100) / totalSideMin).round();

    return {
      "userLanguage": userLanguage,
      "period": reportPeriodLabel(mode),
      "rangeLabel": rangeLabel,
      "sessions": computed.sessions,
      "stats": {
        "totalMinutes": computed.totalMinutes,
        "avgSessionTime": computed.avgSessionMinutes,
        "sideSplitPercent": {
          "left": pct(computed.leftMinutes),
          "right": pct(computed.rightMinutes),
        },
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
}
