import 'package:audio_service/audio_service.dart';
import 'package:mama_meow/models/podcast_model.dart';

extension PodcastMediaItem on Podcast {
  MediaItem toMediaItem() => MediaItem(
    id: audioUrl, // oynatılacak URL
    album: category,
    title: title,
    artist: creator,
    duration: _parseDuration(duration), // istersen null bırakabilirsin
    artUri: Uri.tryParse(icon),
    extras: {
      "podcastId": id,
      "subtitle": subtitle,
      "icon": icon,
      "source": source,
      "description": description,
      "durationText": duration,
    },
  );

  Duration? _parseDuration(String s) {
    // "23:20" / "1:05:10" gibi
    final parts = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    }
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    return null;
  }
}
