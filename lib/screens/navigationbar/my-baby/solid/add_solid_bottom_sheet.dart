import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/models/activities/custom_solid_model.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/models/dummy/dummy_solid_list.dart';
import 'package:mama_meow/models/solid_food.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/add_custom_solid.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/add_custom_solid_service.dart';
import 'package:mama_meow/service/activities/solid_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';

class AddSolidBottomSheet extends StatefulWidget {
  const AddSolidBottomSheet({super.key});

  @override
  State<AddSolidBottomSheet> createState() => _AddSolidBottomSheetState();
}

/// Seçimlerin anahtarı: recent mi custom mı ve adı
class _PickedItem {
  final String name;
  final bool isCustom; // true: Custom Foods, false: Recent Foods
  final String? thumb; // UI’de göstermek için (svg asset ya da network)

  const _PickedItem({required this.name, required this.isCustom, this.thumb});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PickedItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(name, isCustom);
}

class _AddSolidBottomSheetState extends State<AddSolidBottomSheet> {
  static const _reactions = Reaction.values;

  /// Arama
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  /// Zaman ve reaksiyon (tüm seçimlere ortak)
  TimeOfDay _time = TimeOfDay.now();
  Reaction? _reaction;

  /// Kullanıcının eklediği yiyecekler
  List<CustomSolidModel> customSolids = [];

  /// Seçilen ürünler + miktar
  final Map<_PickedItem, int> _picked = {}; // item -> amount

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    analyticService.screenView('add_solid_sheet');
    _loadCustomSolids();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSolids() async {
    try {
      final items = await addCustomSolidService.getCustomSolids();
      if (mounted) setState(() => customSolids = items);
    } catch (e) {
      debugPrint('getCustomSolids failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// "Add New Food" yalnızca giriş yapmış kullanıcıya açılır.
  Future<void> _addCustomFood() async {
    if (authenticationService.getUser() == null) {
      context.pushNamed('login');
      return;
    }
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const AddCustomSolidBottomSheet(),
    );
    if (added == true && mounted) {
      setState(() => isLoading = true);
      await _loadCustomSolids();
    }
  }

  IconData _iconForReaction(Reaction r) {
    switch (r) {
      case Reaction.loveIt:
        return Icons.favorite;
      case Reaction.meh:
        return Icons.thumbs_up_down;
      case Reaction.hatedIt:
        return Icons.sentiment_very_dissatisfied;
      case Reaction.allergicOrSensitivity:
        return Icons.warning_amber;
    }
  }

  void _toggle(_PickedItem key) {
    setState(() {
      if (_picked.containsKey(key)) {
        _picked.remove(key);
      } else {
        _picked[key] = 1;
      }
    });
  }

  void _toggleRecent(SolidFood f) =>
      _toggle(_PickedItem(name: f.name, isCustom: false, thumb: f.asset));

  void _toggleCustom(CustomSolidModel c) =>
      _toggle(_PickedItem(name: c.name, isCustom: true, thumb: c.solidLink));

  void _inc(_PickedItem k) =>
      setState(() => _picked[k] = (_picked[k] ?? 1) + 1);
  void _dec(_PickedItem k) => setState(() {
    final v = (_picked[k] ?? 1) - 1;
    if (v <= 0) {
      _picked.remove(k);
    } else {
      _picked[k] = v;
    }
  });

  bool _isSelectedRecent(SolidFood f) =>
      _picked.keys.any((k) => !k.isCustom && k.name == f.name);

  bool _isSelectedCustom(CustomSolidModel c) =>
      _picked.keys.any((k) => k.isCustom && k.name == c.name);

  List<SolidFood> get _filteredRecent {
    if (_query.trim().isEmpty) return kSolidFoods;
    final q = _query.toLowerCase();
    return kSolidFoods
        .where((e) => e.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  List<CustomSolidModel> get _filteredCustom {
    if (_query.trim().isEmpty) return customSolids;
    final q = _query.toLowerCase();
    return customSolids
        .where((e) => e.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _pickTime() async {
    final picked = await pick24hTime(context, _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_picked.isEmpty) return;
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }

    try {
      // Her seçilen ürün için ayrı SolidModel kaydediyoruz. Kaydedilenler
      // listeden düşülür; hata sonrası tekrar denemede çift kayıt olmaz.
      for (final entry in [..._picked.entries]) {
        final model = SolidModel(
          solidName: entry.key.name,
          solidAmount: entry.value.toString(),
          createdAt: DateTime.now().toIso8601String(),
          eatTime: formatHHmm(_time),
          reactions: _reaction,
        );
        await solidService.addSolid(model);
        if (mounted) setState(() => _picked.remove(entry.key));
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('addSolid failed: $e');
      if (!mounted) return;
      showSaveError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomLoader(
      inAsyncCall: isLoading,
      child: ActivitySheetScaffold(
        kind: ActivityKind.solid,
        title: 'Add Solids',
        initialChildSize: 0.85,
        attachScrollController: true,
        onSave: _picked.isNotEmpty ? _save : null,
        // Arama + hatırlatıcı (standart başlığın altında sabit kalır)
        header: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: "Search solids...",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Reminders',
                onPressed: () => openReminders(context, 'solidReminders'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.pinkTint,
                ),
                icon: const Icon(
                  Icons.alarm_add,
                  color: AppColors.deepCharcoal,
                ),
              ),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (1) Recent (çoklu seçim)
            const _SectionTitle("Recent foods"),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in _filteredRecent)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _FoodChipTile(
                        label: f.name,
                        asset: f.asset,
                        selected: _isSelectedRecent(f),
                        onTap: () => _toggleRecent(f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // (2) Custom (kullanıcının ekledikleri) (çoklu seçim)
            Row(
              children: [
                const _SectionTitle("Custom foods"),
                const SizedBox(width: 4),
                // Küçük, yuvarlak berry "+" (yeni yiyecek ekle)
                IconButton(
                  tooltip: 'Add New Food',
                  onPressed: _addCustomFood,
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.activeBerry,
                    foregroundColor: AppColors.cottonWhite,
                    fixedSize: const Size(32, 32),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in _filteredCustom)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _CustomCard(
                        item: item,
                        selected: _isSelectedCustom(item),
                        onTap: () => _toggleCustom(item),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // (3) Seçilenler & miktarlar
            if (_picked.isNotEmpty) ...[
              const _SectionTitle("Selected"),
              const SizedBox(height: 10),
              for (final e in _picked.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cottonWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: ListTile(
                    leading: _ThumbIcon(item: e.key),
                    title: Text(e.key.name),
                    subtitle: Text(e.key.isCustom ? "Custom" : "Recent"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _dec(e.key),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.activeBerry,
                          ),
                        ),
                        Text(
                          "${e.value}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepCharcoal,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _inc(e.key),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.activeBerry,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _picked.remove(e.key)),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            TimeField(value: formatHHmm(_time), onTap: _pickTime),
            const SizedBox(height: 24),

            // Tepki (opsiyonel, tüm seçimlere ortak)
            ChipPickerSection<Reaction>(
              title: "Reaction",
              items: _reactions,
              value: _reaction,
              labelBuilder: reactionToText,
              iconBuilder: _iconForReaction,
              onChanged: (v) => setState(() => _reaction = v),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet bölüm başlığı (15/w700, koyu kömür).
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 15,
        color: AppColors.deepCharcoal,
      ),
    );
  }
}

class _ThumbIcon extends StatelessWidget {
  final _PickedItem item;
  const _ThumbIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    // Recent -> SVG asset, Custom -> Network image
    if (item.isCustom) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: item.thumb ?? "",
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (c, u, e) =>
              const Icon(Icons.error_outline, color: AppColors.charcoalSoft),
          placeholder: (c, u) => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: 40,
        height: 40,
        child: SvgPicture.asset(item.thumb ?? "", fit: BoxFit.contain),
      );
    }
  }
}

class _CustomCard extends StatelessWidget {
  final CustomSolidModel item;
  final bool selected;
  final VoidCallback onTap;
  const _CustomCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FoodTileFrame(
      label: item.name,
      selected: selected,
      onTap: onTap,
      image: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: item.solidLink,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error_outline, color: AppColors.charcoalSoft),
        ),
      ),
    );
  }
}

/// Recent için yiyecek kartı (SVG görsel).
class _FoodChipTile extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _FoodChipTile({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FoodTileFrame(
      label: label,
      selected: selected,
      onTap: onTap,
      image: SizedBox(
        width: 32,
        height: 32,
        child: SvgPicture.asset(
          asset,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Yiyecek kartı çerçevesi (ChipTileStyle görünümü): seçiliyken beyaz +
/// 2 px berry çerçeve + onay rozeti, değilken pembe zemin.
class _FoodTileFrame extends StatelessWidget {
  final String label;
  final Widget image;
  final bool selected;
  final VoidCallback onTap;

  const _FoodTileFrame({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 100,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.cottonWhite : AppColors.pinkTint,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? AppColors.activeBerry : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  image,
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.deepCharcoal,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.activeBerry,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: AppColors.cottonWhite,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
