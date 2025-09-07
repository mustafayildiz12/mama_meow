class Podcast {
  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final String category;
  final String description;
  final String audioUrl;
  final String icon;

  Podcast({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.category,

    required this.description,
    required this.audioUrl,
    required this.icon,
  });

  /// JSON'dan model oluşturma
  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      duration: json['duration'] as String,
      category: json['category'] as String,

      description: json['description'] as String,
      audioUrl: json['audioUrl'] as String,
      icon: json['icon'] as String,
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
    };
  }
}
