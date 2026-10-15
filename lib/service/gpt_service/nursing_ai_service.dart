import 'dart:convert';

import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_computed.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Emzirme raporu AI cevabı (ortak model).
typedef NursingAiInsight = AiReportInsight;
typedef NursingAiSource = AiSource;

class NursingAIService {
  static const String _systemPrompt = '''
You are "Coo Care Baby Tracker", a pediatric nutritionist & lactation expert.

GOAL
- You will receive ONE REDUCED, PRE-COMPUTED JSON summary of feeding logs (nursing + bottle) for the selected interval.
- Interpret it and produce a concise, supportive report for a parent. Output will be embedded in a PDF above a table.

IMPORTANT (NO MATH)
- Do NOT recalculate totals, averages, or percentages.
- Treat the numbers as ground truth. Focus on interpretation.
- Fields that are missing were not measured; do not assume they are zero.

STYLE
- Output Language: Use the provided "userLanguage" if present (e.g., "en", "tr-TR"). If missing, use English.
- Supportive, nourishing, calm tone.
- Short bullet points, scannable.
- No diagnosis, no medical certainty.

DATA RULES
- Use ONLY the provided JSON.
- If missing info, say "Not enough data to conclude".
- If sessions < 2, emphasize limitations and gentle tips.

SAFETY
- If strong side imbalance, very long gaps between feeds, or unusual patterns are implied,
  mention gently and suggest contacting a lactation consultant or pediatrician if concerned.
- Always include: "Not medical advice."

$kAiReportOutputFormat''';

  /// [nursings] verilirse (veya [c] `fromNursings` ile kurulduysa) taraf
  /// dakikaları, süt türüne göre hacim ve beslenme aralığı kayıtlardan kesin
  /// hesaplanır; aksi halde bu alanlar payload'a hiç konmaz.
  Future<NursingAiInsight?> analyze({
    required ReportPeriod mode,
    required String rangeLabel,
    required NursingReportComputed c,
    List<NursingModel>? nursings,
    String userLanguage = "en",
    List<String> notes = const [],
    int maxTokens = kMaxAiTokens,
    double temperature = 0.4,
  }) {
    return requestAiReport(
      tag: 'nursingReport',
      systemPrompt: '$_systemPrompt${babyPersonalization()}',
      // ✅ Reduced payload from computed (NO raw list)
      buildUserContent: () => jsonEncode(
        NursingAiCompute.buildPayload(
          period: reportPeriodLabel(mode),
          rangeLabel: rangeLabel,
          c: c,
          exact:
              c.exact ??
              (nursings == null
                  ? null
                  : NursingExactStats.fromNursings(nursings)),
          userLanguage: userLanguage,
          notes: notes,
          babyName: currentBabyName,
        ).toMap(),
      ),
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}

class NursingAiPayload {
  final String period;
  final String rangeLabel;
  final String userLanguage;
  final String? babyName;

  final int sessionCount;

  /// Toplam hacim (ml; oz kayıtlar dönüştürülmüş).
  final int totalVolumeMl;

  /// Süt türüne göre hacim (ml); kayıtlar yoksa null (ölçülmedi).
  final int? breastMilkMl;
  final int? formulaMl;
  final int? otherMilkMl;

  // method split counts
  final int nursingCount;
  final int bottleCount;
  final String nursingPct;
  final String bottlePct;

  // milk variety pct (hacim yoksa sayı bazlı)
  final String breastMilkPct;
  final String formulaPct;
  final String milkPctBasis; // "volume" | "count"

  /// Emzirme süresi ortalaması (dakika).
  final int avgNursingDurationMins;

  // side balance
  final int leftCount;
  final int rightCount;
  final int? leftMins; // kayıtlardan kesin; yoksa null
  final int? rightMins;
  final String dominantSide; // Left/Right/Balanced/Not enough data

  // routine
  final double? avgIntervalHours; // hesaplanamazsa null
  final String mostActiveHours;

  final List<String> notes;

  NursingAiPayload({
    required this.period,
    required this.rangeLabel,
    required this.userLanguage,
    required this.babyName,
    required this.sessionCount,
    required this.totalVolumeMl,
    required this.breastMilkMl,
    required this.formulaMl,
    required this.otherMilkMl,
    required this.nursingCount,
    required this.bottleCount,
    required this.nursingPct,
    required this.bottlePct,
    required this.breastMilkPct,
    required this.formulaPct,
    required this.milkPctBasis,
    required this.avgNursingDurationMins,
    required this.leftCount,
    required this.rightCount,
    required this.leftMins,
    required this.rightMins,
    required this.dominantSide,
    required this.avgIntervalHours,
    required this.mostActiveHours,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    "period": period,
    "rangeLabel": rangeLabel,
    "userLanguage": userLanguage,
    "babyName": babyName,
    "stats": {
      "sessions": sessionCount,
      "totalVolume": totalVolumeMl,
      "unit": "ml",
      "methods": {
        "nursing_count": nursingCount,
        "bottle_count": bottleCount,
        "nursing_pct": nursingPct,
        "bottle_pct": bottlePct,
      },
      "milkVarieties": {
        "breast_milk_ml": ?breastMilkMl,
        "formula_ml": ?formulaMl,
        "other_milk_ml": ?otherMilkMl,
        "breast_milk_pct": breastMilkPct,
        "formula_pct": formulaPct,
        "pct_basis": milkPctBasis,
      },
      "avgNursingDurationMins": avgNursingDurationMins,
      "sideBalance": {
        "left_count": leftCount,
        "right_count": rightCount,
        "left_mins": ?leftMins,
        "right_mins": ?rightMins,
        "dominant_side": dominantSide,
      },
    },
    "patterns": {
      "mostActiveHours": mostActiveHours,
      "avgIntervalHours": ?avgIntervalHours,
    },
    "notes": notes,
  };
}

class NursingAiCompute {
  static NursingAiPayload buildPayload({
    required String period,
    required String rangeLabel,
    required NursingReportComputed c,
    required String userLanguage,
    required List<String> notes,
    required String? babyName,
    NursingExactStats? exact,
  }) {
    // 1) Method split: nursing vs bottle (counts)
    final nursingCount = _pickCount(c.feedingTypeCounts, const [
      "nursing",
      "breast",
    ]);
    final bottleCount = _pickCount(c.feedingTypeCounts, const ["bottle"]);
    final totalMethod = nursingCount + bottleCount;

    // 2) Volumes. amountTypeTotals anahtarları birimdir ("ml"/"oz"), süt
    //    türü değil → tür ayrımı yalnızca kayıt bazlı [exact] ile yapılır.
    final totalVolumeMl = exact != null
        ? exact.totalVolumeMl.round()
        : _unitTotalsToMl(c.amountTypeTotals).round();
    final breastMl = exact?.breastMilkMl.round();
    final formulaMl = exact?.formulaMl.round();
    final otherMl = exact?.otherMilkMl.round();

    // milk pct: hacim varsa hacimden, yoksa sayılardan
    final volumeSplit = (breastMl ?? 0) + (formulaMl ?? 0) + (otherMl ?? 0);
    final String breastMilkPct;
    final String formulaPct;
    final String pctBasis;
    if (volumeSplit > 0) {
      breastMilkPct = _pctStr(breastMl ?? 0, volumeSplit);
      formulaPct = _pctStr(formulaMl ?? 0, volumeSplit);
      pctBasis = "volume";
    } else {
      final bmCount = _pickCount(c.milkTypeCounts, const ["breast"]);
      final fCount = _pickCount(c.milkTypeCounts, const ["formula"]);
      final total = c.milkTypeCounts.values.fold<int>(0, (a, b) => a + b);
      breastMilkPct = _pctStr(bmCount, total);
      formulaPct = _pctStr(fCount, total);
      pctBasis = "count";
    }

    // 3) Duration: yalnızca süreli emzirme oturumları
    final avgNursingDurationMins =
        exact?.avgNursingDurationMins ?? c.avgDuration;

    // 4) Side balance: kayıt bazlı kesin dakikalar (yoksa sayılar)
    final leftCount = _sideCount(c.sideCounts, "left");
    final rightCount = _sideCount(c.sideCounts, "right");
    final dominantSide = exact != null
        ? _dominantSide(exact.leftMinutes, exact.rightMinutes, tolerance: 10)
        : _dominantSide(leftCount, rightCount, tolerance: 1);

    final finalNotes = <String>[
      ...notes,
      if (c.sessionCount < 2) "Not enough sessions for strong conclusions.",
    ];

    return NursingAiPayload(
      period: period,
      rangeLabel: rangeLabel,
      userLanguage: userLanguage,
      babyName: babyName,
      sessionCount: c.sessionCount,
      totalVolumeMl: totalVolumeMl,
      breastMilkMl: breastMl,
      formulaMl: formulaMl,
      otherMilkMl: otherMl,
      nursingCount: nursingCount,
      bottleCount: bottleCount,
      nursingPct: _pctStr(nursingCount, totalMethod),
      bottlePct: _pctStr(bottleCount, totalMethod),
      breastMilkPct: breastMilkPct,
      formulaPct: formulaPct,
      milkPctBasis: pctBasis,
      avgNursingDurationMins: avgNursingDurationMins,
      leftCount: leftCount,
      rightCount: rightCount,
      leftMins: exact?.leftMinutes,
      rightMins: exact?.rightMinutes,
      dominantSide: dominantSide,
      avgIntervalHours: exact?.avgIntervalHours,
      mostActiveHours: best4HourWindow(c.distHourCount),
      notes: finalNotes,
    );
  }

  // -----------------------
  // Helpers
  // -----------------------

  static int _pickCount(Map<String, int> m, List<String> keys) {
    var sum = 0;
    for (final e in m.entries) {
      final k = e.key.toLowerCase().trim();
      if (keys.any(k.contains)) sum += e.value;
    }
    return sum;
  }

  static int _sideCount(Map<String, int> m, String side) {
    var sum = 0;
    for (final e in m.entries) {
      if (e.key.toLowerCase().trim() == side) sum += e.value;
    }
    return sum;
  }

  static String _pctStr(int part, int total) {
    if (total <= 0) return "0%";
    return "${((part / total) * 100).round()}%";
  }

  static String _dominantSide(int left, int right, {required int tolerance}) {
    if (left == 0 && right == 0) return "Not enough data";
    if ((left - right).abs() <= tolerance) return "Balanced";
    return left > right ? "Left" : "Right";
  }

  /// Birim anahtarlı toplamları ("ml"/"oz") ml'ye çevirip toplar.
  static double _unitTotalsToMl(Map<String, double> amountTypeTotals) {
    var totalMl = 0.0;
    for (final e in amountTypeTotals.entries) {
      final isOz = e.key.toLowerCase().trim() == 'oz';
      totalMl += isOz ? e.value * NursingModel.ozToMl : e.value;
    }
    return totalMl;
  }
}
