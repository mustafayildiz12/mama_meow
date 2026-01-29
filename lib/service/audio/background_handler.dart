import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';

class PodcastAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  /// Queue = podcast listesi (MediaItem)
  final _queueSubject = BehaviorSubject<List<MediaItem>>.seeded(const []);

  /// Index stream (next/prev için)
  Stream<int?> get _indexStream => _player.currentIndexStream;

  PodcastAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Audio session (interruption / ducking)
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

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

      preload: false,
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
}
