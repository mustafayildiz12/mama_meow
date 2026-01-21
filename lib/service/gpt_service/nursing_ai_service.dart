import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_computed.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_page.dart';




class NursingAIService {
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱, a pediatric nutritionist & lactation expert.

GOAL
- You will receive ONE REDUCED, PRE-COMPUTED JSON summary of feeding logs (nursing + bottle) for the selected interval.
- Interpret it and produce a concise, supportive report for a parent. Output will be embedded in a PDF above a table.

IMPORTANT (NO MATH)
- Do NOT recalculate totals, averages, or percentages.
- Treat the numbers as ground truth. Focus on interpretation.

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
    "totalVolumeMl": 0,
    "breastMilkMl": 0,
    "formulaMl": 0,
    "nursingCount": 0,
    "bottleCount": 0,
    "nursingPct": "0%",
    "bottlePct": "0%",
    "avgNursingDurationMins": 0,
    "avgBottleAmountMl": 0,
    "leftTotalMins": 0,
    "rightTotalMins": 0,
    "dominantSide": "Left|Right|Balanced",
    "avgIntervalHours": 0,
    "mostActiveHours": "string"
  },
  "sources": [{"title":"string","publisher":"string","url":"https://...","year":2023}],
  "last_updated": "YYYY-MM-DD"
}
''';

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
      return "\n\nPERSONALIZATION: Baby name is $_babyName and age range is $ageText. Use the baby's name gently if helpful.";
    } else if (_babyName != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName. Use the baby's name gently if helpful.";
    } else if (ageText != null) {
      return "\n\nPERSONALIZATION: Baby age range is $ageText. Tailor suggestions gently to age.";
    }
    return '';
  }

  Future<NursingAiInsight?> analyze({
    required NursingReportMode mode,
    required String rangeLabel,
    required NursingReportComputed c,
    String userLanguage = "en",
    List<String> notes = const [],
    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final systemPrompt = '$_systemPrompt${_buildPersonalization()}';

      // ✅ Reduced payload from computed (NO raw list)
      final payload = NursingAiCompute.buildPayload(
        period: _modeText(mode),
        rangeLabel: rangeLabel,
        c: c,
        userLanguage: userLanguage,
        notes: notes,
        babyName: _babyName,
      );

      final userJson = jsonEncode(payload.toMap());

      final body = {
        "model": askMiaModel,
        "messages": [
          {"role": "system", "content": systemPrompt},
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
      return NursingAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _modeText(NursingReportMode mode) => switch (mode) {
    NursingReportMode.today => "Daily",
    NursingReportMode.week => "Weekly",
    NursingReportMode.month => "Monthly",
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

class NursingAiPayload {
  final String period;
  final String rangeLabel;
  final String userLanguage;
  final String? babyName;

  // volumes in ml (normalized)
  final int totalVolumeMl;
  final int breastMilkMl;
  final int formulaMl;

  // method split counts
  final int nursingCount;
  final int bottleCount;

  // percentages as strings (no AI math)
  final String nursingPct;
  final String bottlePct;

  // milk variety pct (if volumes unknown, we still give count-based pct as fallback)
  final String breastMilkPct;
  final String formulaPct;

  // durations
  final int
  avgNursingDurationMins; // we only have c.avgDuration, so we use that

  // side balance (computed has only counts -> we estimate minutes)
  final int leftCount;
  final int rightCount;
  final int leftEstimatedMins;
  final int rightEstimatedMins;
  final bool sideMinutesAreEstimated;
  final String dominantSide; // Left/Right/Balanced/Not enough data

  // routine
  final double avgIntervalHours; // not available => 0.0
  final String mostActiveHours;

  final List<String> notes;

  NursingAiPayload({
    required this.period,
    required this.rangeLabel,
    required this.userLanguage,
    required this.babyName,
    required this.totalVolumeMl,
    required this.breastMilkMl,
    required this.formulaMl,
    required this.nursingCount,
    required this.bottleCount,
    required this.nursingPct,
    required this.bottlePct,
    required this.breastMilkPct,
    required this.formulaPct,
    required this.avgNursingDurationMins,
    required this.leftCount,
    required this.rightCount,
    required this.leftEstimatedMins,
    required this.rightEstimatedMins,
    required this.sideMinutesAreEstimated,
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
      "totalVolume": totalVolumeMl,
      "unit": "ml",
      "methods": {
        "nursing_count": nursingCount,
        "bottle_count": bottleCount,
        "nursing_pct": nursingPct,
        "bottle_pct": bottlePct,
      },
      "milkVarieties": {
        "breast_milk_ml": breastMilkMl,
        "formula_ml": formulaMl,
        "breast_milk_pct": breastMilkPct,
        "formula_pct": formulaPct,
      },
      "avgNursingDurationMins": avgNursingDurationMins,
      "sideBalance": {
        "left_count": leftCount,
        "right_count": rightCount,
        "left_estimated_mins": leftEstimatedMins,
        "right_estimated_mins": rightEstimatedMins,
        "minutes_estimated": sideMinutesAreEstimated,
        "dominant_side": dominantSide,
      },
    },
    "patterns": {
      "mostActiveHours": mostActiveHours,
      "avgIntervalHours": avgIntervalHours,
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
  }) {
    // -----------------------
    // 1) Method split: nursing vs bottle (counts)
    // -----------------------
    final nursingCount = _pickCount(c.feedingTypeCounts, const [
      "nursing",
      "breast",
    ]);
    final bottleCount = _pickCount(c.feedingTypeCounts, const ["bottle"]);

    final totalMethod = nursingCount + bottleCount;
    final nursingPct = _pctStr(nursingCount, totalMethod);
    final bottlePct = _pctStr(bottleCount, totalMethod);

    // -----------------------
    // 2) Amounts: normalize to ml from amountTypeTotals (Map<String,double>)
    //    We try to extract breast milk vs formula volumes if keys contain hints.
    // -----------------------
    final amount = _parseAmountsToMl(c.amountTypeTotals);

    final totalVolumeMl = amount.totalMl.round();
    final breastMilkMl = amount.breastMilkMl.round();
    final formulaMl = amount.formulaMl.round();

    // milk pct:
    // - if we have volume split => use it
    // - else fallback to count-based milkTypeCounts
    String breastMilkPct;
    String formulaPct;

    final totalMilkVol = breastMilkMl + formulaMl;
    if (totalMilkVol > 0) {
      breastMilkPct = _pctStr(breastMilkMl, totalMilkVol);
      formulaPct = _pctStr(formulaMl, totalMilkVol);
    } else {
      final bmCount = _pickCount(c.milkTypeCounts, const ["breast"]);
      final fCount = _pickCount(c.milkTypeCounts, const ["formula"]);
      final total = bmCount + fCount;
      breastMilkPct = total == 0 ? "0%" : _pctStr(bmCount, total);
      formulaPct = total == 0 ? "0%" : _pctStr(fCount, total);
    }

    // -----------------------
    // 3) avg nursing duration
    // -----------------------
    final avgNursingDurationMins = c.avgDuration;

    // -----------------------
    // 4) Side balance
    // Computed only has sideCounts (count). We estimate minutes with avgDuration.
    // -----------------------
    final leftCount = _pickCount(c.sideCounts, const ["left", "l"]);
    final rightCount = _pickCount(c.sideCounts, const ["right", "r"]);

    final leftEstimatedMins = leftCount * avgNursingDurationMins;
    final rightEstimatedMins = rightCount * avgNursingDurationMins;

    final dominantSide = _dominantSide(leftEstimatedMins, rightEstimatedMins);

    // -----------------------
    // 5) Routine
    // avgIntervalHours not available in computed => 0.0
    // mostActiveHours from distHourCount
    // -----------------------
    final mostActiveHours = _best4HourWindowFromCounts(c.distHourCount);

    // add an auto-note if we had to estimate side minutes
    final finalNotes = <String>[
      ...notes,
      if ((leftCount + rightCount) > 0)
        "Note: Side minutes are estimated from side counts × average duration (proxy).",
      if (c.sessionCount < 2) "Not enough sessions for strong conclusions.",
    ];

    return NursingAiPayload(
      period: period,
      rangeLabel: rangeLabel,
      userLanguage: userLanguage,
      babyName: babyName,
      totalVolumeMl: totalVolumeMl,
      breastMilkMl: breastMilkMl,
      formulaMl: formulaMl,
      nursingCount: nursingCount,
      bottleCount: bottleCount,
      nursingPct: nursingPct,
      bottlePct: bottlePct,
      breastMilkPct: breastMilkPct,
      formulaPct: formulaPct,
      avgNursingDurationMins: avgNursingDurationMins,
      leftCount: leftCount,
      rightCount: rightCount,
      leftEstimatedMins: leftEstimatedMins,
      rightEstimatedMins: rightEstimatedMins,
      sideMinutesAreEstimated: true,
      dominantSide: dominantSide,
      avgIntervalHours: 0.0,
      mostActiveHours: mostActiveHours,
      notes: finalNotes,
    );
  }

  // -----------------------
  // Helpers
  // -----------------------

  static int _pickCount(Map<String, int> m, List<String> keys) {
    int sum = 0;
    for (final e in m.entries) {
      final k = e.key.toLowerCase().trim();
      if (keys.any((x) => k.contains(x))) sum += e.value;
    }
    return sum;
  }

  static String _pctStr(int part, int total) {
    if (total <= 0) return "0%";
    final p = ((part / total) * 100).round();
    return "$p%";
  }

  static String _dominantSide(int leftMins, int rightMins) {
    if (leftMins == 0 && rightMins == 0) return "Not enough data";
    final diff = (leftMins - rightMins).abs();
    if (diff <= 10) return "Balanced";
    return leftMins > rightMins ? "Left" : "Right";
  }

  static String _best4HourWindowFromCounts(Map<String, int> distHourCount) {
    int bestSum = -1;
    int bestStart = 0;

    for (int start = 0; start <= 20; start += 4) {
      int sum = 0;
      for (int h = start; h < start + 4; h++) {
        final key = h.toString().padLeft(2, '0');
        sum += distHourCount[key] ?? 0;
      }
      if (sum > bestSum) {
        bestSum = sum;
        bestStart = start;
      }
    }

    final end = bestStart + 4;
    final s = bestStart.toString().padLeft(2, '0');
    final e = end.toString().padLeft(2, '0');
    return "$s:00 - $e:00";
  }

  // ---- Amount parsing & normalization ----

  static const double _ozToMl = 29.5735;

  static _Amounts _parseAmountsToMl(Map<String, double> amountTypeTotals) {
    double totalMl = 0;
    double breastMilkMl = 0;
    double formulaMl = 0;

    for (final e in amountTypeTotals.entries) {
      final key = e.key.toLowerCase().trim();
      final val = e.value;

      // unit detection (best-effort)
      final isOz = key.contains('oz');
      final isMl = key.contains('ml') || !isOz; // default to ml if unknown

      final ml = isOz ? (val * _ozToMl) : val;
      totalMl += ml;

      // type detection (best-effort)
      final isBreast =
          key.contains('breast') ||
          key.contains('bm') ||
          key.contains('breastmilk');
      final isFormula = key.contains('formula') || key.contains('fm');

      if (isBreast) breastMilkMl += ml;
      if (isFormula) formulaMl += ml;

      // If keys are only "ml"/"oz", we cannot split by type -> leave breast/formula as 0.
    }

    // If we couldn’t split but we still have totalMl, keep breast/formula as 0.
    return _Amounts(
      totalMl: totalMl,
      breastMilkMl: breastMilkMl,
      formulaMl: formulaMl,
    );
  }
}

class _Amounts {
  final double totalMl;
  final double breastMilkMl;
  final double formulaMl;

  _Amounts({
    required this.totalMl,
    required this.breastMilkMl,
    required this.formulaMl,
  });
}
