class Podcast {
  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final String category;
  final String description;
  final String audioUrl;
  final String icon;
  final String source;
  final String creator;

  Podcast({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.category,
    required this.source,
    required this.creator,
    required this.description,
    required this.audioUrl,
    required this.icon,
  });

  /// JSON'dan model oluşturma. Eksik alanlar boş metin olur; tek bir eksik
  /// alan yüzünden tüm liste düşmesin.
  factory Podcast.fromJson(Map<String, dynamic> json) {
    String str(String key) => json[key]?.toString() ?? '';
    return Podcast(
      id: str('id'),
      title: str('title'),
      subtitle: str('subtitle'),
      duration: str('duration'),
      category: str('category'),
      description: str('description'),
      audioUrl: str('audioUrl'),
      icon: str('icon'),
      source: str('source'),
      creator: str('creator'),
    );
  }

  /// Modeli JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'duration': duration,
      'category': category,
      'description': description,
      'audioUrl': audioUrl,
      'icon': icon,
      'source': source,
      'creator': creator,
    };
  }
}
