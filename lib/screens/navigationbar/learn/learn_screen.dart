import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/podcast_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';

// örnek data

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String searchTerm = '';
  String selectedCategory = 'all';

  bool isLoading = false;

  List<Podcast> podcasts = [];

  final categories = [
    {'id': 'all', 'label': 'All', 'icon': '🎧'},
    {'id': 'sleep', 'label': 'Sleep', 'icon': '💤'},
    {'id': 'feeding', 'label': 'Feeding', 'icon': '🍼'},
    {'id': 'growth', 'label': 'Growth', 'icon': '📏'},
    {'id': 'diaper', 'label': 'Diaper', 'icon': '👶'},
    {'id': 'journal', 'label': 'Journal', 'icon': '📔'},
  ];

  @override
  void initState() {
    getPageData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = podcasts.where((p) {
      final matchesSearch =
          p.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesCategory =
          selectedCategory == 'all' || p.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return CustomLoader(
      inAsyncCall: isLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F3FF),
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.uploadPodcastPage,
                ).then((v) async {
                  if (v != null) {
                    await getPageData();
                  }
                });
              },
              icon: Icon(Icons.add),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F3FF), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              children: [
                const Icon(Icons.podcasts, size: 48, color: Color(0xFF9333EA)),
                const SizedBox(height: 8),
                const Text(
                  "Podcasts",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Expert parenting guidance in audio format",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                // search + filter
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "Search podcasts...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => searchTerm = val),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categories.map((c) {
                            final selected = selectedCategory == c['id'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c['label']!),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => selectedCategory = c['id']!),
                                selectedColor: Colors.purple.shade400,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.purple,
                                ),
                                backgroundColor: Colors.purple.shade100,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No podcasts found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PodcastDetailPage(podcast: p),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        p.thumbnail,
                                        width: 80,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            p.subtitle,
                                            maxLines: 2,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      p.duration,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getPageData() async {
    setState(() {
      isLoading = true;
    });
    List<Podcast> podcastList = await podcastService.getPodcastList();

    setState(() {
      podcasts = podcastList;
      isLoading = false;
    });
  }
}

// podcast detay sayfası
class PodcastDetailPage extends StatefulWidget {
  final Podcast podcast;
  const PodcastDetailPage({super.key, required this.podcast});

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage> {
  late AudioPlayer _player;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setUrl(widget.podcast.audioUrl);
    _player.durationStream.listen((d) {
      if (d != null) setState(() => duration = d);
    });
    _player.positionStream.listen((p) {
      setState(() => position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void togglePlay() {
    if (isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
    setState(() => isPlaying = !isPlaying);
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
              child: Image.network(p.coverArt, height: 250, fit: BoxFit.cover),
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
            Slider(
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble().clamp(
                0,
                duration.inSeconds.toDouble(),
              ),
              onChanged: (val) {
                _player.seek(Duration(seconds: val.toInt()));
              },
              activeColor: Colors.purple,
            ),
            Text(
              "${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} "
              "/ ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.grey),
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
}
