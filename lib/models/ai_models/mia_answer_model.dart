import 'package:mama_meow/models/ai_models/lenient_json.dart';

class MiaAnswer {
  final String quick;
  final String detailed;
  final List<String> actions;
  final String followUp;
  final String disclaimer;
  final List<MiaSource> sources;
  final String lastUpdated;

  MiaAnswer({
    required this.quick,
    required this.detailed,
    required this.actions,
    required this.followUp,
    required this.disclaimer,
    required this.sources,
    required this.lastUpdated,
  });

  /// Model çıktısı / RTDB kaydı hoşgörülü okunur: dizi gelen metin alanları
  /// birleştirilir, kaynaklar Map ya da düz metin olabilir, eksikler boş kalır.
  factory MiaAnswer.fromMap(Map<dynamic, dynamic> raw) {
    final m = jsonMap(raw) ?? const <String, dynamic>{};
    return MiaAnswer(
      quick: jsonString(m['quick_answer']),
      detailed: jsonString(m['detailed_info']),
      actions: jsonStringList(m['actions']),
      followUp: jsonString(m['follow_up_question']),
      disclaimer: jsonString(m['disclaimer']),
      sources: jsonList(
        m['sources'],
      ).map(MiaSource.tryFrom).whereType<MiaSource>().toList(),
      lastUpdated: jsonString(m['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quick_answer': quick,
      'detailed_info': detailed,
      'actions': actions,
      'follow_up_question': followUp,
      'disclaimer': disclaimer,
      'sources': sources.map((s) => s.toJson()).toList(),
      'last_updated': lastUpdated,
    };
  }
}

class MiaSource {
  final String title;
  final String publisher;
  final String url;
  final int? year;

  MiaSource({
    required this.title,
    required this.publisher,
    required this.url,
    this.year,
  });

  factory MiaSource.fromMap(Map<dynamic, dynamic> raw) {
    final m = jsonMap(raw) ?? const <String, dynamic>{};
    return MiaSource(
      title: jsonString(m['title']),
      publisher: jsonString(m['publisher']),
      url: jsonString(m['url']),
      year: jsonInt(m['year']),
    );
  }

  /// Map ya da düz metin (başlık veya URL) kabul eder; boşsa null.
  static MiaSource? tryFrom(Object? v) {
    if (v is Map) {
      final s = MiaSource.fromMap(v);
      final empty =
          s.title.trim().isEmpty &&
          s.publisher.trim().isEmpty &&
          s.url.trim().isEmpty;
      return empty ? null : s;
    }
    final text = jsonString(v).trim();
    if (text.isEmpty) return null;
    final isUrl = text.startsWith('http://') || text.startsWith('https://');
    return MiaSource(
      title: isUrl ? '' : text,
      publisher: '',
      url: isUrl ? text : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'publisher': publisher, 'url': url, 'year': year};
  }
}
