// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/main.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/audio/background_handler.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/extensions/post_media_item_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class DisplayPodcastPage extends StatefulWidget {
  final Podcast podcast;
  final List<Podcast> podcastList;
  final int currentIndex;

  const DisplayPodcastPage({
    super.key,
    required this.podcast,
    required this.podcastList,
    required this.currentIndex,
  });

  @override
  State<DisplayPodcastPage> createState() => _DisplayPodcastPageState();
}

class _DisplayPodcastPageState extends State<DisplayPodcastPage> {
  bool isUserPremium = false;

  // hazırlık state’i
  bool _isPreparing = true;
  String? _prepareError;

  // speed UI
  double playbackSpeed = 1.0;
  final List<double> speedOptions = [1.0, 1.25, 1.5, 2.0];

  // streams
  Stream<MediaItem?> get _mediaItemStream => audioHandler.mediaItem;

  StreamSubscription<PlaybackState>? _prepSub;

  Stream<double> get _speedStream =>
      audioHandler.playbackState.map((s) => s.speed).distinct();

  bool get _controlsEnabled => !_isPreparing && _prepareError == null;

  bool _isBusy(PlaybackState s) =>
      s.processingState == AudioProcessingState.loading ||
      s.processingState == AudioProcessingState.buffering;

  bool _dragging = false;
  double? _dragValueMs;

  final bool _seeking = false;
  double? _seekPreviewMs;
  Timer? _seekDebounce;

  bool _isReady(PlaybackState s) =>
      s.processingState == AudioProcessingState.ready;

  bool _canControl(PlaybackState s) {
    final busy = _isBusy(s);
    if (busy) return false;
    if (!_isReady(s)) return false;
    if (!isUserPremium) return false; // ✅ premium gate
    return _prepareError == null;
  }

  @override
  void initState() {
    super.initState();
    analyticService.screenView('display_podcast_screen');
    _initFlow();
  }

  @override
  void dispose() {
    _prepSub?.cancel();
    _seekDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initFlow() async {
    // 1) premium kontrol
    await _checkUserPremiumSafe();

    if (isUserPremium) {
      await _prepareAndStart();
    } else {
      await context.pushNamed("premiumPaywall").then((v) async {
        if (v == true) {
          await _checkUserPremiumSafe();
          if (isUserPremium) {
            await _prepareAndStart();
          }
        }
      });
    }
  }

  Future<void> _checkUserPremiumSafe() async {
    try {
      final iap = InAppPurchaseService();
      final isP = await iap.isPremium();
      if (!mounted) return;
      setState(() => isUserPremium = isP);
    } catch (_) {
      // premium check fail olsa bile ekran çalışsın
      if (!mounted) return;
      setState(() => isUserPremium = false);
    }
  }

  Future<void> _prepareAndStart() async {
    setState(() {
      _isPreparing = true;
      _prepareError = null;
    });

    // Önce varsa eski dinleyiciyi kapat
    _prepSub?.cancel();

    // 🎧 Audio hazır mı / çalıyor mu diye dinle
    _prepSub = audioHandler.playbackState.listen((state) {
      final ps = state.processingState;

      final isReady = ps == AudioProcessingState.ready;

      if (isReady) {
        if (mounted) setState(() => _isPreparing = false);

        _prepSub?.cancel();
        _prepSub = null;
      }
    });

    // ignore: unnecessary_cast
    final handler = audioHandler as PodcastAudioHandler;
    final items = widget.podcastList.map((e) => e.toMediaItem()).toList();

    // ❌ await YOK → UI bloklanmaz
    handler.setQueueAndPlay(
      items,
      widget.currentIndex,
      autoPlay: isUserPremium,
    );

    // safety timeout (network bozulursa)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isPreparing) {
        setState(() => _isPreparing = false);
      }
      _prepSub?.cancel();
      _prepSub = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return StreamBuilder<MediaItem?>(
      stream: _mediaItemStream,
      builder: (context, mediaSnap) {
        final item = mediaSnap.data;

        // fallback: ilk açılışta mediaItem daha gelmemiş olabilir
        final title = item?.title ?? widget.podcast.title;
        final extras = (item?.extras ?? const <String, dynamic>{});

        final description =
            (extras["description"] as String?) ?? widget.podcast.description;
        final source = (extras["source"] as String?) ?? widget.podcast.source;
        final creator =
            (extras["creator"] as String?) ?? widget.podcast.creator;
        final iconUrl = (extras["icon"] as String?) ?? widget.podcast.icon;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            title: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.pink500,
          ),

          bottomNavigationBar: SafeArea(
            child: StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              initialData: audioHandler.playbackState.value,
              builder: (_, snap) {
                final state = snap.data ?? audioHandler.playbackState.value;
                final busy = _isBusy(state);

                final controlsEnabled = _canControl(state);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (busy) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Loading...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous,
                            size: 36,
                            color: controlsEnabled
                                ? Colors.pink.shade500
                                : Colors.grey.shade400,
                          ),
                          onPressed: controlsEnabled ? _playPrevious : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.replay_10,
                            size: 32,
                            color: controlsEnabled
                                ? Colors.pink.shade500
                                : Colors.grey.shade400,
                          ),
                          onPressed: controlsEnabled ? _skipBackward : null,
                        ),
                        IconButton(
                          icon: Icon(
                            state.playing
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            size: 64,
                            color: controlsEnabled
                                ? Colors.pink.shade500
                                : Colors.grey.shade400,
                          ),
                          onPressed: controlsEnabled ? togglePlay : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.forward_10,
                            size: 32,
                            color: controlsEnabled
                                ? Colors.pink.shade500
                                : Colors.grey.shade400,
                          ),
                          onPressed: controlsEnabled ? _skipForward : null,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            size: 36,
                            color: controlsEnabled
                                ? Colors.pink.shade500
                                : Colors.grey.shade400,
                          ),
                          onPressed: controlsEnabled ? _playNext : null,
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "These podcasts are for informational purposes only...",
                        style: TextStyle(fontSize: 9, height: 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: iconUrl,
                    height: height * 0.3,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // --- Slider + Time ---
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  initialData: audioHandler.playbackState.value,
                  builder: (_, snap) {
                    final state = snap.data ?? audioHandler.playbackState.value;
                    final busy = _isBusy(state);

                    // slider sadece ready iken açık olsun (senin istediğin)
                    final enabled =
                        !busy &&
                        state.processingState == AudioProcessingState.ready;

                    return _progressBar(enabled: enabled);
                  },
                ),

                const SizedBox(height: 8),

                // --- Speed ---
                StreamBuilder<double>(
                  stream: _speedStream,
                  initialData: audioHandler.playbackState.value.speed,
                  builder: (_, spSnap) {
                    final speed = (spSnap.data ?? 1.0);
                    playbackSpeed = speed;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.speed, color: Colors.grey),
                        const SizedBox(width: 8),
                        DropdownButton<double>(
                          value: playbackSpeed,
                          items: speedOptions.map((s) {
                            return DropdownMenuItem<double>(
                              value: s,
                              child: Text(
                                "${s}x",
                                style: TextStyle(
                                  color: _controlsEnabled
                                      ? Colors.pink.shade500
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _controlsEnabled
                              ? (newSpeed) {
                                  if (newSpeed != null) {
                                    _changePlaybackSpeed(newSpeed);
                                  }
                                }
                              : null,
                          underline: Container(),
                          dropdownColor: Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: _controlsEnabled
                                ? Colors.pink.shade500
                                : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text(
                      "Creator: ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Expanded(child: Text(creator)),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Text(
                      "Source: ",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: _buildSource(source)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSource(String source) {
    final isUrl = source.contains("http");
    if (!isUrl) {
      return Text(source, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return TextButton(
      onPressed: () async {
        await launchUrl(
          Uri.parse(source),
          mode: LaunchMode.externalApplication,
        );
      },
      child: Text(
        source,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(decoration: TextDecoration.underline),
      ),
    );
  }

  Widget _progressBar({required bool enabled}) {
    final duration$ = audioHandler.mediaItem.map((m) => m?.duration).distinct();

    return StreamBuilder<Duration?>(
      stream: duration$,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();

        return StreamBuilder<Duration>(
          stream: AudioService.position
              .map(
                (d) => Duration(milliseconds: (d.inMilliseconds ~/ 200) * 200),
              )
              .distinct(),
          initialData: Duration.zero,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;

            final liveMs = pos.inMilliseconds.toDouble().clamp(
              0,
              maxMs <= 0 ? 0 : maxMs,
            );

            final shownMs = _dragging
                ? (_dragValueMs ?? liveMs)
                : (_seeking ? (_seekPreviewMs ?? liveMs) : liveMs);

            return Column(
              children: [
                Slider(
                  min: 0,
                  max: (maxMs <= 0 ? 1 : maxMs),
                  value: shownMs.toDouble(),
                  onChangeStart: (!enabled || maxMs <= 0)
                      ? null
                      : (v) => setState(() {
                          _dragging = true;
                          _dragValueMs = v;
                        }),
                  onChanged: (!enabled || maxMs <= 0)
                      ? null
                      : (v) {
                          // Drag sırasında sadece local değer güncelle
                          // setState burada yine var ama ağır iş yok, jitter azalır.
                          // İstersen bunu ValueNotifier’a da çevirebiliriz.
                          setState(() => _dragValueMs = v);
                        },
                  onChangeEnd: (!enabled || maxMs <= 0)
                      ? null
                      : (v) async {
                          final target = Duration(milliseconds: v.toInt());
                          await audioHandler.seek(_clamp(target, duration));
                          if (!mounted) return;
                          setState(() {
                            _dragging = false;
                            _dragValueMs = null;
                          });
                        },
                  activeColor: Colors.pink.shade500,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _timeText(Duration(milliseconds: shownMs.toInt())),
                      _timeText(duration),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Duration _clamp(Duration v, Duration max) {
    if (v < Duration.zero) return Duration.zero;
    if (v > max) return max;
    return v;
  }

  Widget _timeText(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      h > 0 ? "$h:$m:$s" : "$m:$s",
      style: const TextStyle(color: Colors.grey),
    );
  }

  // ---- Controls (handler) ----
  Future<void> _playNext() => audioHandler.skipToNext();
  Future<void> _playPrevious() => audioHandler.skipToPrevious();
  Future<void> _skipForward() => audioHandler.fastForward();
  Future<void> _skipBackward() => audioHandler.rewind();
  Future<void> _changePlaybackSpeed(double speed) =>
      audioHandler.setSpeed(speed);

  Future<void> togglePlay() async {
    if (!isUserPremium) {
      await context.pushNamed("premiumPaywall").then((v) async {
        if (v == true) {
          await _checkUserPremiumSafe();
          if (isUserPremium) {
            await audioHandler.play();
          }
        }
      });
      return;
    }

    final playing = audioHandler.playbackState.value.playing;
    if (playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }
}
