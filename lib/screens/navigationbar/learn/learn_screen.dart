import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Podcast {
  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final String category;
  final String thumbnail;
  final String coverArt;
  final String description;
  final String audioUrl;
  final String icon;

  Podcast({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.category,
    required this.thumbnail,
    required this.coverArt,
    required this.description,
    required this.audioUrl,
    required this.icon,
  });
}

// örnek data
final podcasts = [
  Podcast(
    id: '1',
    title: "Understanding Your Baby's Sleep Patterns",
    subtitle: "Learn about normal sleep cycles and healthy habits.",
    duration: "8 min",
    category: "sleep",
    thumbnail:
        "https://images.pexels.com/photos/1257110/pexels-photo-1257110.jpeg?auto=compress&cs=tinysrgb&w=400&h=225",
    coverArt:
        "https://images.pexels.com/photos/1257110/pexels-photo-1257110.jpeg?auto=compress&cs=tinysrgb&w=600",
    description:
        "Discover the secrets to better baby sleep with expert guidance on sleep cycles, bedtime routines, and common sleep challenges.",
    audioUrl: "https://www.soundjay.com/misc/sounds/bell-ringing-05.wav",
    icon: "💤",
  ),
  Podcast(
    id: '2',
    title: "Decoding Baby's Cries",
    subtitle: "Different types of cries and how to respond effectively.",
    duration: "6 min",
    category: "growth",
    thumbnail:
        "https://images.pexels.com/photos/1648375/pexels-photo-1648375.jpeg?auto=compress&cs=tinysrgb&w=400&h=225",
    coverArt:
        "https://images.pexels.com/photos/1648375/pexels-photo-1648375.jpeg?auto=compress&cs=tinysrgb&w=600",
    description:
        "Learn to understand what your baby is trying to tell you through different types of cries.",
    audioUrl: "https://www.soundjay.com/misc/sounds/bell-ringing-05.wav",
    icon: "👶",
  ),
];

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String searchTerm = '';
  String selectedCategory = 'all';

  final categories = [
    {'id': 'all', 'label': 'All', 'icon': '🎧'},
    {'id': 'sleep', 'label': 'Sleep', 'icon': '💤'},
    {'id': 'feeding', 'label': 'Feeding', 'icon': '🍼'},
    {'id': 'growth', 'label': 'Growth', 'icon': '📏'},
    {'id': 'diaper', 'label': 'Diaper', 'icon': '👶'},
    {'id': 'journal', 'label': 'Journal', 'icon': '📔'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = podcasts.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesCategory =
          selectedCategory == 'all' || p.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
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
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
                                color: selected ? Colors.white : Colors.purple,
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
                                  builder: (_) => PodcastDetailPage(podcast: p),
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
                                      color: Colors.black12, blurRadius: 4),
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
                                        Text(p.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(p.subtitle,
                                            maxLines: 2,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.duration,
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
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
        title: const Text("Now Playing"),
        backgroundColor: Colors.purple,
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
            Text(p.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(p.description,
                style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Slider(
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
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
              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 64, color: Colors.purple),
              onPressed: togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}
