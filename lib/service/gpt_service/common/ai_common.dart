import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/ai_models/ai_report_insight.dart';
import 'package:mama_meow/service/gpt_service/openai_proxy_service.dart';
import 'package:mama_meow/utils/date_range.dart';

/// AI servislerinin ortak yardımcıları: JSON çözme, hata loglama,
/// kişiselleştirme, dönem metni ve rapor isteği.

/// Proxy'nin `response_format` alanı: modeli tek bir JSON nesnesine zorlar.
/// OpenAI, bu modda mesajlarda "JSON" kelimesinin geçmesini şart koşar.
const Map<String, dynamic> kJsonObjectResponseFormat = {'type': 'json_object'};

/// Sunucu (functions/src/index.ts) max token'ı 800 ile sınırlar.
const int kMaxAiTokens = 800;

/// Konsola ve Crashlytics'e (non-fatal) loglar; asla fırlatmaz.
void reportAiNonFatal(
  Object error,
  StackTrace stackTrace, {
  required String reason,
}) {
  developer.log(
    reason,
    name: 'AiService',
    error: error,
    stackTrace: stackTrace,
  );
  if (kIsWeb) return; // Crashlytics web'i desteklemiyor.
  try {
    unawaited(
      FirebaseCrashlytics.instance
          .recordError(error, stackTrace, reason: reason, fatal: false)
          .catchError((Object _) {}),
    );
  } catch (_) {
    // Firebase hazır değilse sessizce geç.
  }
}

/// Model çıktısını JSON nesnesine çevirir.
///
/// ``` çitlerini temizler; başında/sonunda açıklama metni varsa ilk `{` ile
/// son `}` arasını dener. Başarısızsa null döner ve hatayı (cevap içeriği
/// olmadan, yalnızca uzunluğu ile) loglar.
Map<String, dynamic>? decodeJsonObject(String raw, {String tag = 'ai'}) {
  final text = _stripJsonFences(raw);
  if (text.isEmpty) {
    developer.log('$tag: empty model output', name: 'AiService');
    return null;
  }

  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (e, st) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        decoded = jsonDecode(text.substring(start, end + 1));
      } on FormatException {
        decoded = null;
      }
    }
    if (decoded == null) {
      reportAiNonFatal(
        e,
        st,
        reason: '$tag: model output is not valid JSON (length=${raw.length})',
      );
      return null;
    }
  }

  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  reportAiNonFatal(
    FormatException('Expected a JSON object, got ${decoded.runtimeType}'),
    StackTrace.current,
    reason: '$tag: model output is not a JSON object',
  );
  return null;
}

String _stripJsonFences(String s) {
  var t = s.trim();
  if (t.startsWith('```')) {
    t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    t = t.replaceFirst(RegExp(r'\s*```$'), '');
  }
  return t.trim();
}

/// Profildeki bebek adı (çağrı anında okunur; boşsa null).
String? get currentBabyName {
  final n = currentMeowUser?.babyName?.trim();
  return (n == null || n.isEmpty) ? null : n;
}

/// Profildeki yaş aralığı anahtarı ('newborn', 'infant' ...; boşsa null).
String? get currentBabyAgeRange {
  final a = currentMeowUser?.ageRange?.trim();
  return (a == null || a.isEmpty) ? null : a;
}

const Map<String, String> _ageRangeTexts = {
  'newborn': '0-3 months old',
  'infant': '3-12 months old',
  'toddler': '1-3 years old',
  'preschool': '3-5 years old',
  'school': '5+ years old',
  'expecting': 'expecting (not born yet)',
};

/// Sistem prompt'una eklenecek kişiselleştirme paragrafı.
///
/// [currentMeowUser] her çağrıda okunur (profil yüklenince/düzenlenince eski
/// değer kalmaz). Ad ve yaş yoksa boş döner.
String babyPersonalization({
  String instruction =
      "Use the baby's name naturally when helpful and tailor suggestions gently to the age.",
}) {
  final name = currentBabyName;
  final ageKey = currentBabyAgeRange;
  final age = ageKey == null ? null : (_ageRangeTexts[ageKey] ?? ageKey);
  if (name == null && age == null) return '';

  final facts = <String>[
    if (name != null) "the baby's name is $name",
    if (age != null)
      ageKey == 'expecting' ? 'the parent is $age' : 'the baby is $age',
  ].join(' and ');
  final sentence = '${facts[0].toUpperCase()}${facts.substring(1)}.';
  return '\n\nPERSONALIZATION: $sentence $instruction';
}

/// Rapor dönemi metni: Daily / Weekly / Monthly.
String reportPeriodLabel(ReportPeriod period) => switch (period) {
  ReportPeriod.today => 'Daily',
  ReportPeriod.week => 'Weekly',
  ReportPeriod.month => 'Monthly',
};

/// 4 saatlik pencerelerden (00-04, 04-08, ... 20-24) en yoğununu döner,
/// ör. "08:00 - 12:00". [hourCounts] anahtarları "00".."23".
String best4HourWindow(Map<String, int> hourCounts) {
  var bestSum = -1;
  var bestStart = 0;
  for (var start = 0; start <= 20; start += 4) {
    var sum = 0;
    for (var h = start; h < start + 4; h++) {
      sum += hourCounts[h.toString().padLeft(2, '0')] ?? 0;
    }
    if (sum > bestSum) {
      bestSum = sum;
      bestStart = start;
    }
  }
  String hh(int h) => '${h.toString().padLeft(2, '0')}:00';
  return '${hh(bestStart)} - ${hh(bestStart + 4)}';
}

/// Tüm rapor prompt'larının ortak çıktı şeması; [AiReportInsight.fromMap]
/// tam olarak bu alanları okur.
const String kAiReportOutputFormat = r'''
OUTPUT FORMAT (STRICT JSON OBJECT ONLY, NO EXTRA TEXT)
{
  "ai_title": "string",
  "ai_summary_bullets": ["bullet 1", "bullet 2", "bullet 3", "bullet 4"],
  "patterns": ["pattern 1", "pattern 2", "pattern 3"],
  "watch_outs": ["watch out 1", "watch out 2"],
  "action_plan": ["action 1", "action 2", "action 3", "action 4"],
  "confidence_note": "string (1 short line about data limits)",
  "disclaimer": "string (include Not medical advice...)",
  "sources": [{"title": "string", "publisher": "string", "url": "https://...", "year": 2023}],
  "last_updated": "YYYY-MM-DD"
}
- At most 2 sources.
- Plain text only inside strings: no emojis, no markdown (the PDF font cannot render emojis).
''';

/// Rapor AI isteği: payload'ı kurar, JSON modunda proxy'yi çağırır ve cevabı
/// hoşgörülü çözer. Her hata durumunda null döner; sebep loglanır.
///
/// [buildUserContent] (genelde `jsonEncode(payload)`) burada çağrılır ki
/// hesaplama hataları da raporu düşürmek yerine null'a dönüşsün.
Future<AiReportInsight?> requestAiReport({
  required String tag,
  required String systemPrompt,
  required String Function() buildUserContent,
  int maxTokens = kMaxAiTokens,
  double temperature = 0.4,
}) async {
  final String userContent;
  try {
    userContent = buildUserContent();
  } catch (e, st) {
    reportAiNonFatal(e, st, reason: '$tag: payload build failed');
    return null;
  }

  final String raw;
  try {
    raw = await openAiProxyService.chat(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContent},
      ],
      model: askMiaModel,
      maxTokens: maxTokens.clamp(1, kMaxAiTokens),
      temperature: temperature,
      responseFormat: kJsonObjectResponseFormat,
    );
  } catch (e, st) {
    // Proxy callable hatalarını zaten Crashlytics'e kaydediyor.
    developer.log(
      '$tag request failed',
      name: 'AiService',
      error: e,
      stackTrace: st,
    );
    return null;
  }

  final map = decodeJsonObject(raw, tag: tag);
  if (map == null) return null;
  try {
    return AiReportInsight.fromMap(map);
  } catch (e, st) {
    reportAiNonFatal(e, st, reason: '$tag: insight parse failed');
    return null;
  }
}
