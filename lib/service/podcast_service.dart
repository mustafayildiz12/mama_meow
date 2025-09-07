import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/podcast_model.dart';

class PodcastService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Yardımcılar ---

  String _extOf(File f) {
    final name = f.path.split('/').last;
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String _guessContentType(String ext) {
    switch (ext) {
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _uploadFile({
    required File file,
    required String storagePath, // örn: podcasts/{id}/audio.mp3
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(contentType: contentType);
      final snapshot = await ref.putFile(file, metadata);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
    }
  }

  // --- Eski metodun genelleştirilmiş hali (audio için) ---
  Future<String> addPodcastToStorage(File file, String podcastId) async {
    final ext = _extOf(file).isEmpty ? 'm4a' : _extOf(file);
    final path = 'podcasts/$podcastId/audio.$ext';
    final ct = _guessContentType(ext);
    return _uploadFile(file: file, storagePath: path, contentType: ct);
  }

  // Realtime Database'e podcast metadata ekler
  Future<void> addPodcastToRealtime(Podcast podcast) async {
    await _realtimeDatabase
        .ref('podcasts')
        .child(podcast.id)
        .set(podcast.toJson());
  }

  /// Tek tek dosya alıp URL'leri dönen, modeli güncelleyen yardımcı.
  /// Null olan dosyalar yüklenmez, mevcut değerler korunur.
  Future<Podcast> uploadAssetsAndReturnUpdated({
    required Podcast base,
    File? audio,
    File? icon,
  }) async {
    String audioUrl = base.audioUrl;

    String iconUrl = base.icon;

    // Audio
    if (audio != null) {
      final ext = _extOf(audio).isEmpty ? 'm4a' : _extOf(audio);
      final ct = _guessContentType(ext);
      final path = 'podcasts/${base.id}/audio.$ext';
      audioUrl = await _uploadFile(
        file: audio,
        storagePath: path,
        contentType: ct,
      );
    }

    // Icon
    if (icon != null) {
      final ext = _extOf(icon).isEmpty ? 'png' : _extOf(icon);
      final ct = _guessContentType(ext);
      final path = 'podcasts/${base.id}/icon.$ext';
      iconUrl = await _uploadFile(
        file: icon,
        storagePath: path,
        contentType: ct,
      );
    }

    // Podcast modelini güncelleyip döndür
    final updated = Podcast(
      id: base.id,
      title: base.title,
      subtitle: base.subtitle,
      duration: base.duration,
      category: base.category,
      description: base.description,
      audioUrl: audioUrl,
      icon: iconUrl,
    );
    return updated;
  }

  /// (Opsiyon) Tek adımda: dosyaları yükle + DB'ye yaz
  Future<void> savePodcastWithFiles({
    required Podcast base,
    File? audio,
    File? thumbnail,
    File? coverArt,
    File? icon,
  }) async {
    final updated = await uploadAssetsAndReturnUpdated(
      base: base,
      audio: audio,
      icon: icon,
    );
    await addPodcastToRealtime(updated);
  }

  /// (Senin mevcut akışınla uyumlu) Sadece audio verip kaydetmek istersen:
  Future<void> savePodcast(File file, Podcast podcast) async {
    final audioUrl = await addPodcastToStorage(file, podcast.id);
    final updatedPodcast = Podcast(
      id: podcast.id,
      title: podcast.title,
      subtitle: podcast.subtitle,
      duration: podcast.duration,
      category: podcast.category,

      description: podcast.description,
      audioUrl: audioUrl,
      icon: podcast.icon,
    );
    await addPodcastToRealtime(updatedPodcast);
  }

  Future<List<Podcast>> getPodcastList() async {
    final List<Podcast> favorites = [];

    final DatabaseReference ref = _realtimeDatabase.ref('podcasts');

    final DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      final raw = snapshot.value;

      if (raw is Map) {
        // Sadece value’lar (yani activity map’leri) ile ilgileniyoruz
        for (final value in raw.values) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            final model = Podcast.fromJson(map);

            favorites.add(model);
          }
        }
      } // 2) Kaynak veri LIST ise (örn: [null, {...}, null, {...}])
      else if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final model = Podcast.fromJson(map);

            favorites.add(model);
          }
        }
      }
    }

    return favorites;
  }
}

final PodcastService podcastService = PodcastService();
