import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_report_page.dart';
import 'package:mama_meow/models/activities/solid_model.dart';

class SolidAIService {
  final String? _babyName = currentMeowUser?.babyName;
  final String? _babyAgeKey = currentMeowUser?.ageRange;

  static const String _chatUrl = 'https://api.openai.com/v1/chat/completions';
  final Duration _timeout = const Duration(seconds: 60);

  /// ✅ Optimized prompt (NO MATH, precomputed JSON)
  static final String _systemPrompt = r'''
You are "MamaMeow" 🐱 — a Pediatric Nutritionist & Baby-Led Weaning (BLW) expert.

GOAL
- You will receive a REDUCED, PRE-COMPUTED JSON summary of solid food logs for a selected period.
- Interpret it and produce organized, encouraging insights WITH emojis.
- Output will be embedded in a PDF, so keep it scannable and short.

IMPORTANT (NO MATH)
- Do NOT recalculate totals or averages.
- Treat numbers and lists as ground truth. Focus on interpretation.

REQUIREMENTS
- Flavor Profile: describe the baby's current palate in 1 line.
- Safety First: if allergy/sensitivity alerts exist, mention clearly as top priority.
- Actionable Tip: suggest a pairing or texture variety based on favorites/disliked list.
- Time Pattern: mention when meals seem most successful (AM vs PM).

STYLE
- English
- Organized bullet points with emojis
- Supportive, informative, non-judgmental
- Avoid diagnosis, never claim medical certainty

DATA RULES
- Use ONLY provided JSON.
- If missing info, say "Not enough data to conclude".

SAFETY
- If any allergy/sensitivity items exist, clearly recommend contacting pediatrician/allergist.
- Always include: "Not medical advice."

OUTPUT FORMAT (STRICT JSON ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1", "bullet 2", "bullet 3", "bullet 4"],
  "patterns": ["pattern 1", "pattern 2", "pattern 3"],
  "watch_outs": ["watch out 1", "watch out 2"],
  "action_plan": ["action 1", "action 2", "action 3", "action 4"],
  "flavor_profile": "string (1 short line)",
  "confidence_note": "string (1 short line about data limits)",
  "disclaimer": "string (include Not medical advice...)",
  "computed": {
    "time_analysis": "string",
    "diversity_score": {"uniqueFoods": 12, "targetVariety": 37},
    "favorites": ["string","string","string"],
    "disliked": ["string","string"],
    "sensitivities": ["string"]
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
    final ageText = _babyAgeKey != null
        ? (map[_babyAgeKey] ?? _babyAgeKey)
        : null;

    if (_babyName != null && ageText != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName and age range is $ageText. Use the baby's name naturally (optional).";
    } else if (_babyName != null) {
      return "\n\nPERSONALIZATION: Baby name is $_babyName. Use the baby's name naturally (optional).";
    } else {
      return "\n\nPERSONALIZATION: Baby age range is $ageText. Tailor tips gently to age.";
    }
  }

  /// ✅ NEW: solids list -> compute -> send ONE JSON payload
  Future<SolidAiInsight?> analyzeSolidReport({
    required SolidReportMode mode,
    required String rangeLabel,
    required List<SolidModel> solids,

    /// opsiyonel notlar (teething, travel, etc.)
    List<String> notes = const [],

    /// hedef çeşit sayısı (ürün tarafı)
    int targetVariety = 37,

    int maxTokens = 650,
    double temperature = 0.4,
  }) async {
    try {
      final system = '$_systemPrompt${_buildPersonalization()}';

      final payload = SolidAiCompute.buildPayload(
        solids: solids,
        babyName: _babyName,
        period: mode.name, // today/week/month gibi
        targetVariety: targetVariety,
        notes: notes,
      );

      final userText = _buildUserPromptAsJson(
        mode: mode,
        rangeLabel: rangeLabel,
        payload: payload,
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
      return SolidAiInsight.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _buildUserPromptAsJson({
    required SolidReportMode mode,
    required String rangeLabel,
    required SolidAiPayload payload,
  }) {
    final periodText = switch (mode) {
      SolidReportMode.today => "Daily",
      SolidReportMode.week => "Weekly",
      SolidReportMode.month => "Monthly",
    };

    final obj = <String, dynamic>{
      "babyName": payload.babyName,
      "period": periodText,
      "rangeLabel": rangeLabel,
      "payload": payload.toMap(),
    };

    // ✅ AI'ya düz JSON veriyoruz (koca liste değil)
    return jsonEncode(obj);
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

/// ===============================
/// PAYLOAD MODELS (Reduced JSON)
/// ===============================
class SolidAiPayload {
  final String? babyName;
  final String period; // "Daily/Weekly/Monthly" text or mode.name
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
  reactionsCount; // loveIt/meh/hatedIt/allergicOrSensitivity

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
  /// human-ready summary: "Most successful meals are recorded around 10:00 AM"
  final String summary;
  final Map<String, int> bucketCounts; // morning/afternoon/evening/night

  SolidAiTime({required this.summary, required this.bucketCounts});

  Map<String, dynamic> toMap() => {
    "summary": summary,
    "bucketCounts": bucketCounts,
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
      "other": 0,
    };

    // time buckets
    final bucketCounts = <String, int>{
      "morning": 0, // 05-11
      "afternoon": 0, // 12-16
      "evening": 0, // 17-21
      "night": 0, // 22-04
    };

    // sensitivities set
    final sensitivities = <String>{};

    for (final s in solids) {
      // ---- Food name ----
      final food = _cleanFoodName(_readFoodName(s));
      if (food.isEmpty) continue;

      foodCounts[food] = (foodCounts[food] ?? 0) + 1;

      // ---- Reaction canonical ----
      final rx = _canonicalReaction(_readReaction(s));
      reactionsCount[rx] = (reactionsCount[rx] ?? 0) + 1;

      (foodReactionCounts[food] ??= <String, int>{});
      foodReactionCounts[food]![rx] = (foodReactionCounts[food]![rx] ?? 0) + 1;

      // ---- Safety list ----
      if (rx == "allergicOrSensitivity") {
        sensitivities.add(food);
      }

      // ---- Time pattern ----
      final dt = _readDateTime(s);
      if (dt != null) {
        final bucket = _timeBucket(dt.hour);
        bucketCounts[bucket] = (bucketCounts[bucket] ?? 0) + 1;
      }
    }

    final uniqueFoods = foodCounts.keys.length;

    // preferenceMapping: food -> {count, dominantReaction}
    final preferenceMapping = <String, dynamic>{};
    for (final entry in foodCounts.entries) {
      final food = entry.key;
      final count = entry.value;
      final rxMap = foodReactionCounts[food] ?? const <String, int>{};
      final domRx = _dominantReaction(rxMap);
      preferenceMapping[food] = {"count": count, "dominantReaction": domRx};
    }

    // favorites: top by loveIt (fallback count)
    final favorites = _topFoodsByReaction(
      foodReactionCounts: foodReactionCounts,
      reactionKey: "loveIt",
      fallbackCounts: foodCounts,
      limit: 3,
    );

    // disliked: foods where hatedIt dominates or high hatedIt
    final disliked = _topFoodsByReaction(
      foodReactionCounts: foodReactionCounts,
      reactionKey: "hatedIt",
      fallbackCounts: foodCounts,
      limit: 5,
    );

    final timeSummary = _buildTimeSummary(bucketCounts);

    return SolidAiPayload(
      babyName: babyName,
      period: period,
      stats: SolidAiStats(
        totalMeals: solids.length,
        uniqueFoods: uniqueFoods,
        reactionsCount: _trimReactionCounts(reactionsCount),
      ),
      preferences: SolidAiPreferences(
        favorites: favorites,
        disliked: disliked,
        sensitivities: sensitivities.toList()..sort(),
        preferenceMapping: preferenceMapping,
      ),
      timeAnalysis: SolidAiTime(
        summary: timeSummary,
        bucketCounts: bucketCounts,
      ),
      diversity: SolidAiDiversity(
        uniqueFoods: uniqueFoods,
        targetVariety: targetVariety,
      ),
      notes: notes,
    );
  }

  /// ----------- Adapt these readers to your SolidModel fields -----------
  static String _readFoodName(SolidModel s) {
    // most likely: s.solidName
    // change if your field differs
    return (s.solidName).toString();
  }

  static dynamic _readReaction(SolidModel s) {
    // most likely: s.reactions (enum/int/string)
    // change if your field differs
    return s.reactions;
  }

  static DateTime? _readDateTime(SolidModel s) {
    // most likely: s.createdAt is ISO
    try {
      if ((s.createdAt).toString().trim().isEmpty) return null;
      return DateTime.tryParse((s.createdAt).toString());
    } catch (_) {
      return null;
    }
  }

  /// -------------------------------------------------------------------

  static String _cleanFoodName(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    // Title case (optional). Keep simple, PDF-friendly.
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

  static String _canonicalReaction(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.isEmpty) return "none";

    // adjust mapping to your app's exact values
    if (s.contains('love')) return "loveIt";
    if (s.contains('meh') || s.contains('ok') || s.contains('neutral')) {
      return "meh";
    }
    if (s.contains('hate') || s.contains('refus') || s.contains('spit')) {
      return "hatedIt";
    }
    if (s.contains('allerg') || s.contains('sensit') || s.contains('rash')) {
      return "allergicOrSensitivity";
    }

    return "other";
  }

  static String _dominantReaction(Map<String, int> rxMap) {
    if (rxMap.isEmpty) return "none";
    final entries = rxMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  static List<String> _topFoodsByReaction({
    required Map<String, Map<String, int>> foodReactionCounts,
    required String reactionKey,
    required Map<String, int> fallbackCounts,
    required int limit,
  }) {
    final scored = <String, int>{};
    for (final food in foodReactionCounts.keys) {
      final rx = foodReactionCounts[food] ?? const <String, int>{};
      final score = rx[reactionKey] ?? 0;
      scored[food] = score;
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        // tie-breaker: total count
        return (fallbackCounts[b.key] ?? 0).compareTo(
          fallbackCounts[a.key] ?? 0,
        );
      });

    // remove zero-score items
    final out = <String>[];
    for (final e in sorted) {
      if (e.value <= 0) continue;
      out.add(e.key);
      if (out.length >= limit) break;
    }
    return out;
  }

  static String _timeBucket(int hour) {
    if (hour >= 5 && hour <= 11) return "morning";
    if (hour >= 12 && hour <= 16) return "afternoon";
    if (hour >= 17 && hour <= 21) return "evening";
    return "night";
  }

  static String _buildTimeSummary(Map<String, int> bucketCounts) {
    if (bucketCounts.values.every((v) => v == 0)) {
      return "Not enough data to conclude a time pattern.";
    }
    final entries = bucketCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.first;
    final label = switch (top.key) {
      "morning" => "morning (around 05:00–11:59)",
      "afternoon" => "afternoon (around 12:00–16:59)",
      "evening" => "evening (around 17:00–21:59)",
      _ => "night (around 22:00–04:59)",
    };
    return "Most successful meals are recorded in the $label.";
  }

  static Map<String, int> _trimReactionCounts(Map<String, int> m) {
    // PDF payload clean: remove zeros
    final out = <String, int>{};
    for (final e in m.entries) {
      if (e.value > 0) out[e.key] = e.value;
    }
    return out;
  }
}

/// ===============================
/// AI RESPONSE MODEL
/// ===============================
class SolidAiInsight {
  final String aiTitle;
  final List<String> aiSummaryBullets;
  final List<String> patterns;
  final List<String> watchOuts;
  final List<String> actionPlan;
  final String flavorProfile;
  final String confidenceNote;
  final String disclaimer;
  final Map<String, dynamic>?
  computed; // favorites/disliked/sensitivities/time_analysis/diversity_score
  final List<SolidAiSource> sources;
  final String lastUpdated;

  SolidAiInsight({
    required this.aiTitle,
    required this.aiSummaryBullets,
    required this.patterns,
    required this.watchOuts,
    required this.actionPlan,
    required this.flavorProfile,
    required this.confidenceNote,
    required this.disclaimer,
    required this.computed,
    required this.sources,
    required this.lastUpdated,
  });

  factory SolidAiInsight.fromMap(Map<String, dynamic> m) {
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
        .map((e) => SolidAiSource.fromMap(e.cast<String, dynamic>()))
        .toList();

    return SolidAiInsight(
      aiTitle: (m['ai_title'] ?? '').toString(),
      aiSummaryBullets: ls('ai_summary_bullets'),
      patterns: ls('patterns'),
      watchOuts: ls('watch_outs'),
      actionPlan: ls('action_plan'),
      flavorProfile: (m['flavor_profile'] ?? '').toString(),
      confidenceNote: (m['confidence_note'] ?? '').toString(),
      disclaimer: (m['disclaimer'] ?? '').toString(),
      computed: (m['computed'] is Map)
          ? (m['computed'] as Map).cast<String, dynamic>()
          : null,
      sources: sources,
      lastUpdated: (m['last_updated'] ?? '').toString(),
    );
  }
}

class SolidAiSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  SolidAiSource({
    required this.title,
    required this.publisher,
    required this.url,
    required this.year,
  });

  factory SolidAiSource.fromMap(Map<String, dynamic> m) {
    final y = m['year'];
    return SolidAiSource(
      title: (m['title'] ?? '').toString(),
      publisher: (m['publisher'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      year: (y is num) ? y.toInt() : int.tryParse((y ?? '').toString()),
    );
  }
}
