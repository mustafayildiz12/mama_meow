import 'dart:convert';

import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/service/gpt_service/common/ai_common.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Ek gıda raporu AI cevabı (ortak model).
typedef SolidAiInsight = AiReportInsight;
typedef SolidAiSource = AiSource;

class SolidAIService {
  /// ✅ Optimized prompt (NO MATH, precomputed JSON)
  static const String _systemPrompt = '''
You are "Coo Care Baby Tracker", a Pediatric Nutritionist & Baby-Led Weaning (BLW) expert.

GOAL
- You will receive a REDUCED, PRE-COMPUTED JSON summary of solid food logs for a selected period.
- Interpret it and produce organized, encouraging insights.
- Output will be embedded in a PDF, so keep it scannable and short.

IMPORTANT (NO MATH)
- Do NOT recalculate totals or averages.
- Treat numbers and lists as ground truth. Focus on interpretation.

REQUIREMENTS
- Flavor Profile: one summary bullet describes the baby's current palate in 1 line.
- Safety First: if allergy/sensitivity alerts exist, mention clearly as top priority.
- Actionable Tip: suggest a pairing or texture variety based on favorites/disliked list.
- Time Pattern: use "timeAnalysis". "bucketCounts" counts all meals by time of day;
  "lovedBucketCounts" counts only meals rated "love it". Call a time "most successful"
  only if lovedBucketCounts supports it; otherwise just describe when meals happen.

STYLE
- English
- Organized, short bullet points
- Supportive, informative, non-judgmental
- Avoid diagnosis, never claim medical certainty

DATA RULES
- Use ONLY provided JSON.
- If missing info, say "Not enough data to conclude".

SAFETY
- If any allergy/sensitivity items exist, clearly recommend contacting pediatrician/allergist.
- Always include: "Not medical advice."

$kAiReportOutputFormat''';

  /// ✅ solids list -> compute -> send ONE JSON payload
  Future<SolidAiInsight?> analyzeSolidReport({
    required ReportPeriod mode,
    required String rangeLabel,
    required List<SolidModel> solids,

    /// opsiyonel notlar (teething, travel, etc.)
    List<String> notes = const [],

    /// hedef çeşit sayısı (ürün tarafı)
    int targetVariety = 37,

    int maxTokens = kMaxAiTokens,
    double temperature = 0.4,
  }) {
    final period = reportPeriodLabel(mode);
    return requestAiReport(
      tag: 'solidReport',
      systemPrompt:
          '$_systemPrompt${babyPersonalization(instruction: "Use the baby's name naturally when helpful and tailor tips gently to the age.")}',
      buildUserContent: () {
        final payload = SolidAiCompute.buildPayload(
          solids: solids,
          babyName: currentBabyName,
          period: period,
          targetVariety: targetVariety,
          notes: notes,
        );
        // ✅ AI'ya düz JSON veriyoruz (koca liste değil)
        return jsonEncode({
          "babyName": payload.babyName,
          "period": period,
          "rangeLabel": rangeLabel,
          "payload": payload.toMap(),
        });
      },
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}

/// ===============================
/// PAYLOAD MODELS (Reduced JSON)
/// ===============================
class SolidAiPayload {
  final String? babyName;
  final String period; // "Daily/Weekly/Monthly"
  final SolidAiStats stats;
  final SolidAiPreferences preferences;
  final SolidAiTime timeAnalysis;
  final SolidAiDiversity diversity;
  final List<String> notes;

  SolidAiPayload({
    required this.babyName,
    required this.period,
    required this.stats,
    required this.preferences,
    required this.timeAnalysis,
    required this.diversity,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    "babyName": babyName,
    "period": period,
    "stats": stats.toMap(),
    "preferences": preferences.toMap(),
    "timeAnalysis": timeAnalysis.toMap(),
    "diversity": diversity.toMap(),
    "notes": notes,
  };
}

class SolidAiStats {
  final int totalMeals;
  final int uniqueFoods;
  final Map<String, int>
  reactionsCount; // loveIt/meh/hatedIt/allergicOrSensitivity/none

  SolidAiStats({
    required this.totalMeals,
    required this.uniqueFoods,
    required this.reactionsCount,
  });

  Map<String, dynamic> toMap() => {
    "totalMeals": totalMeals,
    "uniqueFoods": uniqueFoods,
    "reactionsCount": reactionsCount,
  };
}

class SolidAiPreferences {
  final List<String> favorites; // top3
  final List<String> disliked; // top N
  final List<String> sensitivities; // allergicOrSensitivity foods
  final Map<String, dynamic> preferenceMapping;
  // e.g. { "banana": {"count": 5, "dominantReaction":"loveIt"} }

  SolidAiPreferences({
    required this.favorites,
    required this.disliked,
    required this.sensitivities,
    required this.preferenceMapping,
  });

  Map<String, dynamic> toMap() => {
    "favorites": favorites,
    "disliked": disliked,
    "sensitivities": sensitivities,
    "preferenceMapping": preferenceMapping,
  };
}

class SolidAiDiversity {
  final int uniqueFoods;
  final int targetVariety;

  SolidAiDiversity({required this.uniqueFoods, required this.targetVariety});

  Map<String, dynamic> toMap() => {
    "uniqueFoods": uniqueFoods,
    "targetVariety": targetVariety,
  };
}

class SolidAiTime {
  /// human-ready summary
  final String summary;

  /// Tüm öğünler: morning/afternoon/evening/night
  final Map<String, int> bucketCounts;

  /// Yalnızca "love it" tepkili öğünler
  final Map<String, int> lovedBucketCounts;

  SolidAiTime({
    required this.summary,
    required this.bucketCounts,
    this.lovedBucketCounts = const {},
  });

  Map<String, dynamic> toMap() => {
    "summary": summary,
    "bucketCounts": bucketCounts,
    "lovedBucketCounts": lovedBucketCounts,
  };
}

/// ===============================
/// COMPUTE (Map/Reduce) — NO AI MATH
/// ===============================
class SolidAiCompute {
  static SolidAiPayload buildPayload({
    required List<SolidModel> solids,
    required String? babyName,
    required String period,
    required int targetVariety,
    List<String> notes = const [],
  }) {
    // food -> count
    final foodCounts = <String, int>{};

    // food -> reaction -> count
    final foodReactionCounts = <String, Map<String, int>>{};

    // reaction total counts
    final reactionsCount = <String, int>{
      "loveIt": 0,
      "meh": 0,
      "hatedIt": 0,
      "allergicOrSensitivity": 0,
      "none": 0,
    };

    // time buckets (tüm öğünler / sevilen öğünler)
    Map<String, int> emptyBuckets() => {
      "morning": 0, // 05-11
      "afternoon": 0, // 12-16
      "evening": 0, // 17-21
      "night": 0, // 22-04
    };
    final bucketCounts = emptyBuckets();
    final lovedBucketCounts = emptyBuckets();

    // sensitivities set
    final sensitivities = <String>{};

    for (final s in solids) {
      final food = _cleanFoodName(s.solidName);
      if (food.isEmpty) continue;

      foodCounts[food] = (foodCounts[food] ?? 0) + 1;

      final rx = _reactionKey(s.reactions);
      reactionsCount[rx] = (reactionsCount[rx] ?? 0) + 1;

      final perFood = foodReactionCounts[food] ??= <String, int>{};
      perFood[rx] = (perFood[rx] ?? 0) + 1;

      if (rx == "allergicOrSensitivity") sensitivities.add(food);

      // Zaman deseni: kaydetme anı değil, kullanıcının seçtiği yeme saati
      final at = s.eventAt;
      if (at != null) {
        final bucket = _timeBucket(at.hour);
        bucketCounts[bucket] = bucketCounts[bucket]! + 1;
        if (rx == "loveIt") {
          lovedBucketCounts[bucket] = lovedBucketCounts[bucket]! + 1;
        }
      }
    }

    final uniqueFoods = foodCounts.length;

    // preferenceMapping: food -> {count, dominantReaction}
    final preferenceMapping = <String, dynamic>{
      for (final entry in foodCounts.entries)
        entry.key: {
          "count": entry.value,
          "dominantReaction": _dominantReaction(
            foodReactionCounts[entry.key] ?? const <String, int>{},
          ),
        },
    };

    return SolidAiPayload(
      babyName: babyName,
      period: period,
      stats: SolidAiStats(
        totalMeals: solids.length,
        uniqueFoods: uniqueFoods,
        reactionsCount: _trimZeroCounts(reactionsCount),
      ),
      preferences: SolidAiPreferences(
        // favorites: top by loveIt (tie-break: count)
        favorites: _topFoodsByReaction(
          foodReactionCounts: foodReactionCounts,
          reactionKey: "loveIt",
          fallbackCounts: foodCounts,
          limit: 3,
        ),
        // disliked: foods with hatedIt reactions
        disliked: _topFoodsByReaction(
          foodReactionCounts: foodReactionCounts,
          reactionKey: "hatedIt",
          fallbackCounts: foodCounts,
          limit: 5,
        ),
        sensitivities: sensitivities.toList()..sort(),
        preferenceMapping: preferenceMapping,
      ),
      timeAnalysis: SolidAiTime(
        summary: _buildTimeSummary(bucketCounts, lovedBucketCounts),
        bucketCounts: bucketCounts,
        lovedBucketCounts: lovedBucketCounts,
      ),
      diversity: SolidAiDiversity(
        uniqueFoods: uniqueFoods,
        targetVariety: targetVariety,
      ),
      notes: notes,
    );
  }

  static String _cleanFoodName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    // Title case (PDF-friendly)
    return t
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map(
          (w) => w.length == 1
              ? w.toUpperCase()
              : (w[0].toUpperCase() + w.substring(1).toLowerCase()),
        )
        .join(' ');
  }

  static String _reactionKey(Reaction? r) => switch (r) {
    Reaction.loveIt => "loveIt",
    Reaction.meh => "meh",
    Reaction.hatedIt => "hatedIt",
    Reaction.allergicOrSensitivity => "allergicOrSensitivity",
    null => "none",
  };

  static String _dominantReaction(Map<String, int> rxMap) {
    if (rxMap.isEmpty) return "none";
    return rxMap.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  static List<String> _topFoodsByReaction({
    required Map<String, Map<String, int>> foodReactionCounts,
    required String reactionKey,
    required Map<String, int> fallbackCounts,
    required int limit,
  }) {
    final scored =
        foodReactionCounts.entries
            .map((e) => MapEntry(e.key, e.value[reactionKey] ?? 0))
            .where((e) => e.value > 0)
            .toList()
          ..sort((a, b) {
            final c = b.value.compareTo(a.value);
            if (c != 0) return c;
            // tie-breaker: total count
            return (fallbackCounts[b.key] ?? 0).compareTo(
              fallbackCounts[a.key] ?? 0,
            );
          });
    return scored.take(limit).map((e) => e.key).toList();
  }

  static String _timeBucket(int hour) {
    if (hour >= 5 && hour <= 11) return "morning";
    if (hour >= 12 && hour <= 16) return "afternoon";
    if (hour >= 17 && hour <= 21) return "evening";
    return "night";
  }

  static const Map<String, String> _bucketLabels = {
    "morning": "morning (around 05:00-11:59)",
    "afternoon": "afternoon (around 12:00-16:59)",
    "evening": "evening (around 17:00-21:59)",
    "night": "night (around 22:00-04:59)",
  };

  static String? _topBucket(Map<String, int> buckets) {
    if (buckets.values.every((v) => v == 0)) return null;
    return buckets.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  static String _buildTimeSummary(
    Map<String, int> all,
    Map<String, int> loved,
  ) {
    final topAll = _topBucket(all);
    if (topAll == null) return "Not enough data to conclude a time pattern.";

    final parts = <String>[
      "Most meals are logged in the ${_bucketLabels[topAll]}.",
    ];
    final topLoved = _topBucket(loved);
    if (topLoved != null) {
      parts.add(
        "Meals rated 'love it' are most common in the ${_bucketLabels[topLoved]}.",
      );
    } else {
      parts.add(
        "No 'love it' reactions yet, so the most successful time cannot be determined.",
      );
    }
    return parts.join(' ');
  }

  static Map<String, int> _trimZeroCounts(Map<String, int> m) => {
    for (final e in m.entries)
      if (e.value > 0) e.key: e.value,
  };
}
