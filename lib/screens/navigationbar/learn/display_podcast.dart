import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/main.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/extensions/post_media_item_extension.dart';
import 'package:mama_meow/utils/url_utils.dart';

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

  /// Kuyruk bu sayfa için kuruldu mu (premium akışı tamamlandı mı).
  bool _started = false;

  /// Giriş/paywall akışı sürerken tekrar tetiklenmesin.
  bool _gateActive = false;

  // speed UI
  double playbackSpeed = 1.0;
  final List<double> speedOptions = [1.0, 1.25, 1.5, 2.0];

  // streams
  Stream<MediaItem?> get _mediaItemStream => audioHandler.mediaItem;

  StreamSubscription<PlaybackState>? _prepSub;
  Timer? _prepTimeout;

  // Stream'ler bir kez oluşturulur; her build'de yeniden abone olunmaz.
  late final Stream<double> _speedStream = audioHandler.playbackState
      .map((s) => s.speed)
      .distinct();
  late final Stream<Duration?> _durationStream = audioHandler.mediaItem
      .map((m) => m?.duration)
      .distinct();
  late final Stream<Duration> _positionStream = AudioService.position
      .map((d) => Duration(milliseconds: (d.inMilliseconds ~/ 200) * 200))
      .distinct();

  bool get _controlsEnabled =>
      _started && !_isPreparing && _prepareError == null;

  bool _isBusy(PlaybackState s) =>
      s.processingState == AudioProcessingState.loading ||
      s.processingState == AudioProcessingState.buffering;

  bool _dragging = false;
  double? _dragValueMs;

  bool _isReady(PlaybackState s) =>
      s.processingState == AudioProcessingState.ready;

  bool _canControl(PlaybackState s) {
    final busy = _isBusy(s);
    if (busy) return false;
    if (!_isReady(s)) return false;
    return _started && _prepareError == null;
  }

  @override
  void initState() {
    super.initState();
    analyticService.screenView('display_podcast_screen');
    // Giriş/paywall'a yönlendirme build sırasında yapılmasın diye ilk
    // kareden sonra başlat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initFlow();
    });
  }

  @override
  void dispose() {
    _prepSub?.cancel();
    _prepTimeout?.cancel();
    super.dispose();
  }

  /// Misafir → giriş, premium değil → paywall, sonra oynatmaya başla.
  /// Kullanıcı vazgeçerse sayfa pasif kontrollerle kalır; oynat düğmesi
  /// akışı yeniden başlatır.
  Future<void> _initFlow() async {
    if (_gateActive) return;
    _gateActive = true;
    try {
      if (authenticationService.getUser() == null) {
        final signedIn = await context.pushNamed<bool>('login');
        if (!mounted || signedIn != true) return;
      }

      await _checkUserPremiumSafe();
      if (!mounted) return;

      if (!isUserPremium) {
        final purchased = await context.pushNamed<bool>('premiumPaywall');
        if (!mounted || purchased != true) return;
        await _checkUserPremiumSafe();
        if (!mounted || !isUserPremium) return;
      }

      await _prepareAndStart();
    } finally {
      _gateActive = false;
    }
  }

  Future<void> _checkUserPremiumSafe() async {
    try {
      final user = authenticationService.getUser();
      if (user == null) {
        if (mounted) setState(() => isUserPremium = false);
        return;
      }
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

  static const _loadErrorMessage =
      "Couldn't load this episode. Please check your connection and try again.";

  Future<void> _prepareAndStart() async {
    setState(() {
      _isPreparing = true;
      _prepareError = null;
    });

    // Önce varsa eski dinleyiciyi kapat
    await _prepSub?.cancel();
    _prepTimeout?.cancel();

    // 🎧 Audio hazır mı diye dinle
    _prepSub = audioHandler.playbackState.listen((state) {
      if (state.processingState == AudioProcessingState.ready) {
        if (mounted) setState(() => _isPreparing = false);
        _prepSub?.cancel();
        _prepSub = null;
      }
    });

    final items = widget.podcastList.map((e) => e.toMediaItem()).toList();
    try {
      // Kuyruğu kur (yükleme oynatmayla başlar).
      await audioHandler.setQueueAndPlay(
        items,
        widget.currentIndex,
        autoPlay: false,
      );
    } catch (e) {
      debugPrint('setQueueAndPlay failed: $e');
      _onPrepareFailed();
      return;
    }
    _started = true;

    // play() oynatma durana kadar tamamlanmaz; beklemeden başlat.
    unawaited(
      audioHandler.play().catchError((Object e) {
        debugPrint('play failed: $e');
        _onPrepareFailed();
      }),
    );

    // Güvenlik zaman aşımı (ağ bozulursa): hâlâ boştaysa hata göster.
    _prepTimeout = Timer(const Duration(seconds: 6), () {
      _prepSub?.cancel();
      _prepSub = null;
      if (!mounted || !_isPreparing) return;
      final ps = audioHandler.playbackState.value.processingState;
      setState(() {
        _isPreparing = false;
        if (ps == AudioProcessingState.idle) _prepareError = _loadErrorMessage;
      });
    });
  }

  void _onPrepareFailed() {
    _prepSub?.cancel();
    _prepSub = null;
    _prepTimeout?.cancel();
    if (!mounted) return;
    setState(() {
      _isPreparing = false;
      _prepareError = _loadErrorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final coverSize = math.min(screen.height * 0.32, screen.width - 80);
    final textTheme = Theme.of(context).textTheme;

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
          backgroundColor: AppColors.cosyIvory,
          appBar: AppBar(
            leadingWidth: 72,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _CircleBackButton(
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          bottomNavigationBar: SafeArea(
            child: StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              initialData: audioHandler.playbackState.value,
              builder: (_, snap) {
                final state = snap.data ?? audioHandler.playbackState.value;
                final busy = _isBusy(state);

                final controlsEnabled = _canControl(state);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (busy) ...[
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Loading...",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (_prepareError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _prepareError!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.berryInk,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _retry,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PlainControl(
                            icon: Icons.skip_previous_rounded,
                            onPressed: controlsEnabled ? _playPrevious : null,
                          ),
                          _SoftControl(
                            icon: Icons.replay_10_rounded,
                            onPressed: controlsEnabled ? _skipBackward : null,
                          ),
                          _PlayPauseButton(
                            playing: state.playing,
                            active: controlsEnabled,
                            onPressed: () {
                              togglePlay(controlsEnabled);
                            },
                          ),
                          _SoftControl(
                            icon: Icons.forward_10_rounded,
                            onPressed: controlsEnabled ? _skipForward : null,
                          ),
                          _PlainControl(
                            icon: Icons.skip_next_rounded,
                            onPressed: controlsEnabled ? _playNext : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        "These podcasts are for informational purposes only...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: AppColors.charcoalSoft,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _cover(iconUrl, coverSize)),

                const SizedBox(height: 24),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),

                if (creator.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mic_none_rounded,
                        size: 16,
                        color: AppColors.charcoalSoft,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          creator,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoalSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

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

                const SizedBox(height: 12),

                // --- Speed ---
                StreamBuilder<double>(
                  stream: _speedStream,
                  initialData: audioHandler.playbackState.value.speed,
                  builder: (_, spSnap) {
                    final speed = (spSnap.data ?? 1.0);
                    playbackSpeed = speed;

                    final fg = _controlsEnabled
                        ? AppColors.deepCharcoal
                        : AppColors.charcoalSoft;

                    return Center(
                      child: Container(
                        padding: const EdgeInsets.only(left: 14, right: 8),
                        decoration: const ShapeDecoration(
                          color: AppColors.pinkTint,
                          shape: StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed_rounded, size: 18, color: fg),
                            const SizedBox(width: 6),
                            DropdownButton<double>(
                              value: playbackSpeed,
                              items: speedOptions.map((s) {
                                return DropdownMenuItem<double>(
                                  value: s,
                                  child: Text(
                                    "${s}x",
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
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
                              underline: const SizedBox.shrink(),
                              dropdownColor: AppColors.cottonWhite,
                              borderRadius: BorderRadius.circular(16),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              iconEnabledColor: AppColors.deepCharcoal,
                              iconDisabledColor: AppColors.charcoalSoft,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                if (description.isNotEmpty) ...[
                  AppCard(child: Text(description, style: textTheme.bodyLarge)),
                  const SizedBox(height: 12),
                ],

                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Source: ",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepCharcoal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _buildSource(source)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Büyük, 24 px yuvarlatılmış kapak; görsel yoksa pembe kulaklık kutusu.
  Widget _cover(String iconUrl, double size) {
    final fallback = IconSquircle(
      size: size,
      radius: AppTheme.radiusCard,
      background: AppColors.pinkTint,
      child: Icon(
        Icons.headphones_rounded,
        size: size * 0.3,
        color: AppColors.activeBerry,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: iconUrl.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: iconUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) => IconSquircle(
                size: size,
                radius: AppTheme.radiusCard,
                background: AppColors.pinkTint,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }

  Widget _buildSource(String source) {
    if (!UrlUtils.isWebUrl(source)) {
      return Text(
        source,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.charcoalSoft),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () async {
          final opened = await UrlUtils.openExternal(source);
          if (!opened) customSnackBar.warning("Couldn't open this link");
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          source,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: AppColors.berryInk,
          ),
        ),
      ),
    );
  }

  Widget _progressBar({required bool enabled}) {
    return StreamBuilder<Duration?>(
      stream: _durationStream,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();

        return StreamBuilder<Duration>(
          stream: _positionStream,
          initialData: Duration.zero,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;

            final liveMs = pos.inMilliseconds.toDouble().clamp(
              0,
              maxMs <= 0 ? 0 : maxMs,
            );

            final shownMs = _dragging ? (_dragValueMs ?? liveMs) : liveMs;

            return Column(
              children: [
                // Renkler temadan (berry / pinkTint); pasifken açık pembe.
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    disabledActiveTrackColor: AppColors.warmPink,
                    disabledInactiveTrackColor: AppColors.pinkTint,
                    disabledThumbColor: AppColors.warmPink,
                  ),
                  child: Slider(
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
                  ),
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoalSoft,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  // ---- Controls (handler) ----
  Future<void> _playNext() => audioHandler.skipToNext();
  Future<void> _playPrevious() => audioHandler.skipToPrevious();
  Future<void> _skipForward() => audioHandler.fastForward();
  Future<void> _skipBackward() => audioHandler.rewind();
  Future<void> _changePlaybackSpeed(double speed) =>
      audioHandler.setSpeed(speed);

  /// Hata sonrası yeniden dene.
  void _retry() => isUserPremium ? _prepareAndStart() : _initFlow();

  Future<void> togglePlay(bool controlsEnabled) async {
    // Henüz başlatılmadıysa (misafir / premium değil / vazgeçti) akışı
    // baştan çalıştır: giriş → paywall → oynat.
    if (authenticationService.getUser() == null ||
        !isUserPremium ||
        !_started) {
      await _initFlow();
      return;
    }

    if (controlsEnabled) {
      final playing = audioHandler.playbackState.value.playing;
      if (playing) {
        await audioHandler.pause();
      } else {
        await audioHandler.play();
      }
    }
  }
}

/// Beyaz, ince çizgili yuvarlak geri butonu.
class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.cottonWhite,
        foregroundColor: AppColors.deepCharcoal,
        side: const BorderSide(color: AppColors.hairline),
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
    );
  }
}

/// Pasif kontroller için soluk ikon rengi.
Color get _disabledControlColor =>
    AppColors.charcoalSoft.withValues(alpha: 0.4);

/// Zeminsiz kömür rengi kontrol (önceki / sonraki).
class _PlainControl extends StatelessWidget {
  const _PlainControl({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 32,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.deepCharcoal,
        disabledForegroundColor: _disabledControlColor,
        fixedSize: const Size(48, 48),
      ),
      icon: Icon(icon),
    );
  }
}

/// Pembe yuvarlak zeminli kontrol (10 sn geri / ileri).
class _SoftControl extends StatelessWidget {
  const _SoftControl({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 26,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.pinkTint,
        foregroundColor: AppColors.deepCharcoal,
        disabledBackgroundColor: AppColors.pinkTint.withValues(alpha: 0.6),
        disabledForegroundColor: _disabledControlColor,
        fixedSize: const Size(52, 52),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon),
    );
  }
}

/// 72 px berry oynat / duraklat dairesi. Her zaman dokunulabilir: oynatma
/// hazır değilse giriş → paywall → oynat akışını başlatır.
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.active,
    required this.onPressed,
  });

  final bool playing;

  /// Kontroller hazır mı; değilse daha açık pembe ve parıltısız.
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: active ? AppColors.berryGlow : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        iconSize: 40,
        style: IconButton.styleFrom(
          backgroundColor: active ? AppColors.activeBerry : AppColors.warmPink,
          foregroundColor: AppColors.cottonWhite,
          fixedSize: const Size(72, 72),
          shape: const CircleBorder(),
        ),
        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      ),
    );
  }
}
