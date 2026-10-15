import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_compute.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/utils/date_range.dart';

/// İlaç raporu AI cevabı (ortak model).
typedef MedicineAiInsight = AiReportInsight;
typedef MedicineAiSource = AiSource;

class MedicineAIService {
  static const String _systemPrompt = '''
You are "Coo Care Baby Tracker", an evidence-informed baby medication report assistant inside a mother-baby app.

GOAL
- Analyze the user's selected medicine report interval (daily/weekly/monthly).
- Produce a concise, practical, non-judgmental summary for a parent.
- The output will be embedded into a PDF report above a table.

STYLE
- Write in English.
- Use short bullet points, no long paragraphs.
- Be supportive and encouraging (warm but not overly chatty).
- Avoid diagnosis. Never claim medical certainty.

DATA RULES (IMPORTANT)
- You will receive structured medication report data for the selected interval.
- Only use the provided data. If something is missing or uncertain, say "Not enough data to conclude".
- Amount totals are per medicine and unit; never add up amounts of different medicines.
- If the dataset is small (e.g., fewer than 2 entries), focus on gentle suggestions and note the limitation.

SAFETY
- Medication is high-stakes: never instruct dosing changes.
- If you detect potential concerns (very frequent dosing, multiple medicines, unusual timing, caregiver concern implied),
  mention gently and recommend confirming the plan with the pediatrician/pharmacist.
- Always include: "Not medical advice."

$kAiReportOutputFormat''';

  Future<MedicineAiInsight?> analyze({
    required ReportPeriod mode,
    required String rangeLabel,
    required MedicineReportComputed c,
    int maxTokens = kMaxAiTokens,
    double temperature = 0.4,
  }) {
    return requestAiReport(
      tag: 'medicineReport',
      systemPrompt:
          '$_systemPrompt${babyPersonalization(instruction: "Personalize gently and use the baby's name when helpful.")}',
      buildUserContent: () =>
          _buildUserPrompt(mode: mode, rangeLabel: rangeLabel, c: c),
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  String _buildUserPrompt({
    required ReportPeriod mode,
    required String rangeLabel,
    required MedicineReportComputed c,
  }) {
    String lines(Iterable<String> items, {int limit = 30}) {
      final list = items.toList();
      return (list.length <= limit * 2 ? list : list.take(limit)).join("\n");
    }

    final activeHours = c.distHourCount.entries
        .where((e) => e.value > 0)
        .map((e) => "- ${e.key}: ${e.value}");

    return '''
Analyze the selected medicine report and produce AI insights for a PDF. Respond with the JSON object described in the system prompt.

REPORT_MODE: ${reportPeriodLabel(mode).toLowerCase()}
RANGE_LABEL: $rangeLabel

MEDICINE_METRICS:
- total_entries: ${c.totalCount}
- unique_medicines: ${c.uniqueMedicineCount}
- last_time: ${c.lastTimeLabel}

DISTRIBUTION_BY_HOUR (hour -> count, hours with no doses omitted):
${lines(activeHours)}

MEDICINE_COUNTS (medicine -> count):
${lines(c.medicineCounts.entries.map((e) => "- ${e.key}: ${e.value}"))}

AMOUNT_TOTALS (medicine | unit -> total amount over doses):
${lines(_amountTotalsByMedicine(c.details))}

INSTRUCTIONS:
- Keep it short for PDF: 4 summary bullets, 3 patterns, 2 watch-outs, 4 action steps.
- Never give dosing instructions or tell to change medication.
- If data seems incomplete, mention it in confidence_note.
- Always include Not medical advice.
''';
  }

  /// İlaç + birim bazında toplam miktar; farklı ilaçların dozları toplanmaz.
  static List<String> _amountTotalsByMedicine(List<MedicineDetail> details) {
    final totals =
        <String, ({String name, String unit, num total, int doses})>{};
    for (final d in details) {
      final name = d.name.trim();
      final unit = d.amountType.trim();
      final key = '${name.toLowerCase()}|${unit.toLowerCase()}';
      final prev = totals[key];
      totals[key] = (
        name: prev?.name ?? name,
        unit: prev?.unit ?? unit,
        total: (prev?.total ?? 0) + d.amount,
        doses: (prev?.doses ?? 0) + 1,
      );
    }
    String fmt(num v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
    return [
      for (final t in totals.values)
        "- ${t.name} | ${t.unit.isEmpty ? '-' : t.unit}: ${fmt(t.total)} (${t.doses} doses)",
    ];
  }
}
