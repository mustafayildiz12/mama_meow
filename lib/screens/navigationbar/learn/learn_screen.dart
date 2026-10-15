import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/args/display_podcast_args.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
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
  String selectedCategory = 'All';

  bool isLoading = false;
  bool _loadFailed = false;

  List<Podcast> podcasts = [];

  final categories = [
    {'id': 'all', 'label': 'All', 'icon': '🎧'},
    {'id': 'infantcare', 'label': 'Infant Care', 'icon': '💤'},
    {'id': 'feeding', 'label': '0-6 Months', 'icon': '🍼'},
    {'id': 'growth', 'label': 'Toddler Care', 'icon': '📏'},
    {'id': 'diaper', 'label': 'Common Ilnesses', 'icon': '👶'},
    {'id': 'journal', 'label': 'Pregnancy', 'icon': '📔'},
    {'id': 'Childbirth', 'label': 'Childbirth', 'icon': '📔'},
    {'id': 'Healthaspects', 'label': 'Health Aspects', 'icon': '📔'},
    {'id': 'childsleep', 'label': 'Child Sleep', 'icon': '📔'},
    {'id': 'babycare', 'label': 'Baby Care', 'icon': '📔'},
    {'id': 'motorskills', 'label': 'Motor Skills', 'icon': '📔'},
    {'id': 'sleep', 'label': 'Sleep', 'icon': '📔'},
    {'id': 'infanthealth', 'label': 'Infant Health', 'icon': '📔'},
    {'id': 'childdevelopment', 'label': 'Child Development', 'icon': '📔'},
  ];

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFF5F3FF),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    analyticService.screenView('learn_screen');
    getPageData();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = podcasts.where((p) {
      final matchesSearch =
          p.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
          p.subtitle.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' || p.category.contains(selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: CustomLoader(
        inAsyncCall: isLoading,
        child: Scaffold(
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
                  Image.asset("assets/podcat.png", width: 96, height: 96),
                  const SizedBox(height: 8),
                  const Text(
                    "Podcasts",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "No time to read! Just listen, meow 🐾",
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
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
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
                              final selected = selectedCategory == c['label'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c['label']!),
                                  selected: selected,
                                  onSelected: (_) => setState(
                                    () => selectedCategory = c['label']!,
                                  ),
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
                    child: _loadFailed && podcasts.isEmpty
                        ? _LoadError(onRetry: getPageData)
                        : filtered.isEmpty
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
                                onTap: () async {
                                  context.pushNamed(
                                    'podcastDetail',
                                    extra: DisplayPodcastArgs(
                                      podcast: p,
                                      podcastList: filtered,
                                      currentIndex: i,
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
      ),
    );
  }

  Future<void> getPageData() async {
    setState(() {
      isLoading = true;
      _loadFailed = false;
    });
    try {
      final podcastList = await podcastService.getPodcastList();
      if (!mounted) return;
      setState(() => podcasts = podcastList);
    } catch (e) {
      debugPrint('getPodcastList failed: $e');
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Couldn't load podcasts. Please check your connection.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}
