import 'package:mama_meow/models/ai_models/lenient_json.dart';

/// Rapor AI servislerinin (uyku, emzirme, bez, mama, ilaç, süt sağma) ortak
/// cevap modeli. Aktiviteye özel tipler (ör. `SleepAiInsight`) bunun
/// typedef'idir.
class AiReportInsight {
  final String aiTitle;
  final List<String> aiSummaryBullets;
  final List<String> patterns;
  final List<String> watchOuts;
  final List<String> actionPlan;
  final String confidenceNote;
  final String disclaimer;
  final List<AiSource> sources;
  final String lastUpdated;

  const AiReportInsight({
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

  /// Model çıktısını hoşgörülü okur (dizi yerine metin vb. kabul edilir).
  factory AiReportInsight.fromMap(Map<String, dynamic> m) {
    return AiReportInsight(
      aiTitle: jsonString(m['ai_title']).trim(),
      aiSummaryBullets: jsonStringList(m['ai_summary_bullets']),
      patterns: jsonStringList(m['patterns']),
      watchOuts: jsonStringList(m['watch_outs']),
      actionPlan: jsonStringList(m['action_plan']),
      confidenceNote: jsonString(m['confidence_note']).trim(),
      disclaimer: jsonString(m['disclaimer']).trim(),
      sources: AiSource.listFrom(m['sources']),
      lastUpdated: jsonString(m['last_updated']).trim(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ai_title': aiTitle,
    'ai_summary_bullets': aiSummaryBullets,
    'patterns': patterns,
    'watch_outs': watchOuts,
    'action_plan': actionPlan,
    'confidence_note': confidenceNote,
    'disclaimer': disclaimer,
    'sources': sources.map((s) => s.toMap()).toList(),
    'last_updated': lastUpdated,
  };
}

/// AI cevabındaki kaynak satırı.
class AiSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  const AiSource({
    required this.title,
    required this.publisher,
    required this.url,
    this.year,
  });

  factory AiSource.fromMap(Map<String, dynamic> m) => AiSource(
    title: jsonString(m['title']).trim(),
    publisher: jsonString(m['publisher']).trim(),
    url: jsonString(m['url']).trim(),
    year: jsonInt(m['year']),
  );

  /// Map ya da düz metin (başlık veya URL) kabul eder; boşsa null.
  static AiSource? tryFrom(Object? v) {
    final map = jsonMap(v);
    if (map != null) {
      final s = AiSource.fromMap(map);
      return s.isEmpty ? null : s;
    }
    final text = jsonString(v).trim();
    if (text.isEmpty) return null;
    final isUrl = text.startsWith('http://') || text.startsWith('https://');
    return AiSource(
      title: isUrl ? '' : text,
      publisher: '',
      url: isUrl ? text : '',
    );
  }

  static List<AiSource> listFrom(Object? v) {
    final raw = v is List ? v : (v == null ? const [] : [v]);
    return raw.map(tryFrom).whereType<AiSource>().toList();
  }

  bool get isEmpty =>
      title.isEmpty && publisher.isEmpty && url.isEmpty && year == null;

  Map<String, dynamic> toMap() => {
    'title': title,
    'publisher': publisher,
    'url': url,
    'year': year,
  };

  /// PDF'de tek satır: "Başlık • Yayıncı • 2023 • https://..."
  String get displayLine => [
    if (title.isNotEmpty) title,
    if (publisher.isNotEmpty) publisher,
    if (year != null) '$year',
    if (url.isNotEmpty) url,
  ].join(' • ');
}
