class AppUpdateInfo {
  final String version; // "1.0.5"
  final List<String> highlights; // madde listesi
  final bool isPublished; // yayında mı?
  final int? publishedAt; // ms since epoch (server timestamp)
  final bool forceUpdate; // zorunlu mu?

  AppUpdateInfo({
    required this.version,
    required this.highlights,
    required this.isPublished,
    this.publishedAt,
    this.forceUpdate = false,
  });

  factory AppUpdateInfo.fromMap(Map<dynamic, dynamic> m) {
    final List<String> hl =
        (m['highlights'] as List?)?.map((e) => '$e').toList() ?? [];
    return AppUpdateInfo(
      version: '${m['version'] ?? ''}',
      highlights: hl,
      isPublished: m['isPublished'] == true,
      publishedAt: (m['publishedAt'] is int) ? m['publishedAt'] as int : null,
      forceUpdate: m['forceUpdate'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'version': version,
    'highlights': highlights,
    'isPublished': isPublished,
    'publishedAt': publishedAt,
    'forceUpdate': forceUpdate,
  };
}
