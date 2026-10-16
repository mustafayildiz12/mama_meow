import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/constants/args/display_podcast_args.dart';
import 'package:mama_meow/models/podcast_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/podcast_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
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

  // Not: filtre `label` ile yapılır (p.category.contains(label)); etiketler
  // veriyle eşleştiği için yazımları değiştirilmemeli.
  final categories = [
    {'id': 'all', 'label': 'All'},
    {'id': 'infantcare', 'label': 'Infant Care'},
    {'id': 'feeding', 'label': '0-6 Months'},
    {'id': 'growth', 'label': 'Toddler Care'},
    {'id': 'diaper', 'label': 'Common Ilnesses'},
    {'id': 'journal', 'label': 'Pregnancy'},
    {'id': 'Childbirth', 'label': 'Childbirth'},
    {'id': 'Healthaspects', 'label': 'Health Aspects'},
    {'id': 'childsleep', 'label': 'Child Sleep'},
    {'id': 'babycare', 'label': 'Baby Care'},
    {'id': 'motorskills', 'label': 'Motor Skills'},
    {'id': 'sleep', 'label': 'Sleep'},
    {'id': 'infanthealth', 'label': 'Infant Health'},
    {'id': 'childdevelopment', 'label': 'Child Development'},
  ];

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.cosyIvory,
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

    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: CustomLoader(
        inAsyncCall: isLoading,
        child: Scaffold(
          backgroundColor: AppColors.cosyIvory,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // başlık + arama
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Podcasts", style: textTheme.displaySmall),
                      const SizedBox(height: 4),
                      const Text(
                        "Short episodes from pediatric experts",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.charcoalSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                        onChanged: (val) => setState(() => searchTerm = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // kategori çipleri
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      final selected = selectedCategory == c['label'];
                      // Renkler chipTheme'den gelir (seçili berry, diğerleri pinkTint).
                      return ChoiceChip(
                        label: Text(c['label']!),
                        selected: selected,
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.cottonWhite
                              : AppColors.deepCharcoal,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) =>
                            setState(() => selectedCategory = c['label']!),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _loadFailed && podcasts.isEmpty
                      ? _LoadError(onRetry: getPageData)
                      : filtered.isEmpty
                      ? const _EmptyState()
                      : CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              // Liste tek beyaz kart içinde, satırlar arası ince çizgi.
                              sliver: DecoratedSliver(
                                decoration: BoxDecoration(
                                  color: AppColors.cottonWhite,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusCard,
                                  ),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                sliver: SliverPadding(
                                  padding: const EdgeInsets.all(8),
                                  sliver: SliverList.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, _) => const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Divider(),
                                    ),
                                    itemBuilder: (context, i) {
                                      final p = filtered[i];
                                      return _PodcastRow(
                                        podcast: p,
                                        index: i,
                                        onTap: () {
                                          context.pushNamed(
                                            'podcastDetail',
                                            extra: DisplayPodcastArgs(
                                              podcast: p,
                                              podcastList: filtered,
                                              currentIndex: i,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
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

/// Beyaz, tam yuvarlak arama alanı.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  static OutlineInputBorder _pill(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: "Search podcasts...",
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: _pill(AppColors.outline),
        enabledBorder: _pill(AppColors.outline),
        focusedBorder: _pill(AppColors.activeBerry, width: 2),
      ),
      onChanged: onChanged,
    );
  }
}

/// Liste satırı: kapak, başlık + meta, pembe yuvarlak oynat simgesi.
class _PodcastRow extends StatelessWidget {
  const _PodcastRow({
    required this.podcast,
    required this.index,
    required this.onTap,
  });

  final Podcast podcast;
  final int index;
  final VoidCallback onTap;

  static const double _coverSize = 56;

  @override
  Widget build(BuildContext context) {
    // Görsel yoksa / yüklenemezse dönüşümlü pembe-şeftali ikon kutusu.
    final fallback = IconSquircle(
      size: _coverSize,
      background: index.isEven ? AppColors.pinkTint : AppColors.peachTint,
      child: const Icon(
        Icons.headphones_rounded,
        color: AppColors.activeBerry,
        size: 26,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: podcast.icon.isEmpty
                    ? fallback
                    : CachedNetworkImage(
                        imageUrl: podcast.icon,
                        width: _coverSize,
                        height: _coverSize,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => fallback,
                        errorWidget: (context, url, error) => fallback,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 22 / 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepCharcoal,
                      ),
                    ),
                    if (podcast.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        podcast.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: AppColors.charcoalSoft,
                        ),
                      ),
                    ],
                    if (podcast.duration.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.berryInk,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            podcast.duration,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Görsel ipucu; dokunma satırın kendisine gider.
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.pinkTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.activeBerry,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtre/arama sonucu boşken.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/podcat.png", width: 88, height: 88),
            const SizedBox(height: 12),
            const Text(
              "No podcasts found",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoalSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/podcat.png", width: 88, height: 88),
            const SizedBox(height: 12),
            const Text(
              "Couldn't load podcasts. Please check your connection.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.charcoalSoft),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              child: PrimaryPillButton(label: "Try Again", onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}
