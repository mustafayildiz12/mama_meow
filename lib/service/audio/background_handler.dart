import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';

class PodcastAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<AudioInterruptionEvent>? intrSub;
  StreamSubscription<void>? noisySub;

  // Interruption sonrası resume edip etmeyeceğimizi tutalım
  bool _resumeAfterInterruption = false;

  // Duck yaptıysak geri almak için
  double? _volumeBeforeDuck;

  /// Queue = podcast listesi (MediaItem)
  final _queueSubject = BehaviorSubject<List<MediaItem>>.seeded(const []);

  /// Index stream (next/prev için)
  Stream<int?> get _indexStream => _player.currentIndexStream;

  PodcastAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;

    // ✅ Konfigürasyon: müzik/podcast gibi davran
    await session.configure(const AudioSessionConfiguration.music());

    // Playback state -> audio_service
    _player.playbackEventStream.map(_transformEvent).listen(playbackState.add);

    // current MediaItem -> audio_service
    _indexStream.listen((index) {
      final q = _queueSubject.value;
      if (index == null || index < 0 || index >= q.length) return;
      mediaItem.add(q[index]);
    });

    // Queue -> audio_service
    _queueSubject.listen(queue.add);

    // ============================
    // ✅ Interruption (call/siri/alarm) -> pause / resume
    // ============================
    intrSub?.cancel();
    intrSub = session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        // interruption başladı
        _resumeAfterInterruption = _player.playing;

        if (event.type == AudioInterruptionType.pause ||
            event.type == AudioInterruptionType.unknown) {
          if (_player.playing) {
            await _player.pause();
          }
        } else if (event.type == AudioInterruptionType.duck) {
          // Duck -> ses kıs (opsiyonel)
          // Eğer istemiyorsan komple kaldırabilirsin.
          if (_player.playing) {
            _volumeBeforeDuck ??= _player.volume;
            try {
              await _player.setVolume(0.3);
            } catch (_) {}
          }
        }
      } else {
        // interruption bitti
        // Duck yaptıysak sesi geri al
        if (_volumeBeforeDuck != null) {
          try {
            await _player.setVolume(_volumeBeforeDuck!);
          } catch (_) {}
          _volumeBeforeDuck = null;
        }

        // Eğer interruption yüzünden durmuşsak otomatik devam et
        if (_resumeAfterInterruption) {
          _resumeAfterInterruption = false;
          try {
            // hazır değilse play patlayabilir
            if (_player.processingState == ProcessingState.ready ||
                _player.processingState == ProcessingState.buffering) {
              await _player.play();
            }
          } catch (_) {}
        }
      }
    });

    // ============================
    // ✅ Headphone unplug / Bluetooth disconnect -> pause
    // ============================
    noisySub?.cancel();
    noisySub = session.becomingNoisyEventStream.listen((_) async {
      if (_player.playing) {
        await _player.pause();
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.rewind,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 2, 4],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  /// UI: Listeyi set et ve index’ten başlat
  Future<void> setQueueAndPlay(
    List<MediaItem> items,
    int startIndex, {
    bool autoPlay = true,
  }) async {
    _queueSubject.add(items);

    final source = ConcatenatingAudioSource(
      children: items.map((m) => AudioSource.uri(Uri.parse(m.id))).toList(),
    );

    await _player.setAudioSource(
      source,
      initialIndex: startIndex,
      preload: false, // ✅ performans
    );

    if (autoPlay) {
      await _player.play();
    }
  }

  // ---- Commands ----
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    // ✅ stream cleanup (istersen stop’ta değil dispose’ta da yeter)
    _resumeAfterInterruption = false;
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> fastForward() =>
      _player.seek(_player.position + const Duration(seconds: 10));

  @override
  Future<void> rewind() =>
      _player.seek(_player.position - const Duration(seconds: 10));

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (repeatMode == AudioServiceRepeatMode.one) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  /*
  // ✅ audio_service lifecycle
  @override
  Future<void> close() async {
    await intrSub?.cancel();
    await noisySub?.cancel();
    await _queueSubject.close();
    await _player.dispose();
    return super.close();
  }
   */
}
