import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mama_meow/models/podcast_model.dart';

/// Learn sekmesindeki podcast listesini RTDB'den okur. (Yükleme/yönetim
/// kodu kullanılmadığı için kaldırıldı; içerik Firebase konsolundan eklenir.)
class PodcastService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// `podcasts` düğümündeki yayınları döner. Ses adresi olmayan veya
  /// okunamayan kayıtlar atlanır.
  Future<List<Podcast>> getPodcastList() async {
    final snapshot = await _realtimeDatabase.ref('podcasts').get();
    final raw = snapshot.value;
    // Kaynak veri Map ({id: {...}}) veya List ([null, {...}]) olabilir.
    final Iterable<Object?> items = switch (raw) {
      Map() => raw.values,
      List() => raw,
      _ => const [],
    };

    final podcasts = <Podcast>[];
    for (final item in items) {
      if (item is! Map) continue;
      try {
        final podcast = Podcast.fromJson(Map<String, dynamic>.from(item));
        if (podcast.audioUrl.isNotEmpty) podcasts.add(podcast);
      } catch (e) {
        debugPrint("Skipping malformed podcast: $e");
      }
    }
    return podcasts;
  }
}

final PodcastService podcastService = PodcastService();
