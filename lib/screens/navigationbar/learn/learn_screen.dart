import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/screens/navigationbar/learn/display_podcast.dart';
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
        floatingActionButton: FloatingActionButton(
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
          child: Icon(Icons.add),
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
                                        DisplayPodcastPage(podcast: p),
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
                                      child: CachedNetworkImage(
                                        imageUrl: p.icon,
                                        height: 120,
                                        width: 80,
                                        fit: BoxFit.fitHeight,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
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
