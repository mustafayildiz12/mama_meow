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

  factory MiaAnswer.fromMap(Map<String, dynamic> m) {
    return MiaAnswer(
      quick: (m['quick_answer'] ?? '') as String,
      detailed: (m['detailed_info'] ?? '') as String,
      actions: ((m['actions'] ?? []) as List).map((e) => '$e').toList(),
      followUp: (m['follow_up_question'] ?? '') as String,
      disclaimer: (m['disclaimer'] ?? '') as String,
      sources: ((m['sources'] ?? []) as List)
          .map((e) => MiaSource.fromMap(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: (m['last_updated'] ?? '') as String,
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

  factory MiaSource.fromMap(Map<String, dynamic> m) => MiaSource(
    title: (m['title'] ?? '') as String,
    publisher: (m['publisher'] ?? '') as String,
    url: (m['url'] ?? '') as String,
    year: m['year'] is int ? m['year'] as int : null,
  );

  Map<String, dynamic> toJson() {
    return {'title': title, 'publisher': publisher, 'url': url, 'year': year};
  }
}
