import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/podcast_model.dart';

class DisplayPodcastPage extends StatefulWidget {
  final Podcast podcast;
  const DisplayPodcastPage({super.key, required this.podcast});

  @override
  State<DisplayPodcastPage> createState() => _DisplayPodcastPageState();
}

class _DisplayPodcastPageState extends State<DisplayPodcastPage> {
  late AudioPlayer _player;
  bool isPlaying = false;
  bool isLooping = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();

    // oynatma durumu
    _player.playingStream.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    // tamamlandığında davranış: loop açıksa zaten başa sarar
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        if (!isLooping) {
          // loop kapalıysa isteğe bağlı: bir kez daha başlat
          _player.seek(Duration.zero);
          _player.play();
        }
        // loop açıksa LoopMode.one bunu zaten yapar
      }
    });

    // (opsiyonel) mevcut loop mode'u dinle
    _player.loopModeStream.listen((mode) {
      if (!mounted) return;
      setState(() => isLooping = (mode == LoopMode.one));
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.podcast;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title),
        centerTitle: true,
        backgroundColor: AppColors.purple500,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: p.coverArt,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              p.description,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // --- Slider ve süreler StreamBuilder ile ---
            StreamBuilder<Duration?>(
              stream: _player.durationStream,
              builder: (context, durationSnap) {
                final total = durationSnap.data ?? Duration.zero;
                final max = total.inMilliseconds > 0
                    ? total.inMilliseconds.toDouble()
                    : 0.0;

                return StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  initialData: Duration.zero,
                  builder: (context, positionSnap) {
                    final pos = positionSnap.data ?? Duration.zero;
                    double value = pos.inMilliseconds.toDouble();

                    // Guard: NaN/∞/max aşımı vb.
                    if (value.isNaN || value.isInfinite) value = 0.0;
                    if (max > 0.0 && value > max) value = max;
                    if (max == 0.0) value = 0.0;

                    return Column(
                      children: [
                        Slider(
                          min: 0.0,
                          max: max,
                          value: value,
                          onChanged: (v) {
                            // Drag esnasında anında seek
                            _player.seek(Duration(milliseconds: v.toInt()));
                          },
                          activeColor: Colors.purple,
                        ),
                        Text(
                          "${_fmt(pos)} / ${_fmt(total)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 64,
                color: Colors.purple,
              ),
              onPressed: togglePlay,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    // Saat varsa hh:mm:ss, yoksa mm:ss
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }

  Future<void> _initAudio() async {
    try {
      await _player.setUrl(widget.podcast.audioUrl);
      // İstersen burada duration’a erişebilirsin:
      // final dur = _player.duration; // null olabilir
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ses yüklenemedi: $e')));
    }
  }

  void togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
    // isPlaying güncellemesini playingStream zaten yapıyor
  }
}
