import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
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
    final theme = Theme.of(context);

    return CustomLoader(
      inAsyncCall: isLoading,
      child: ActivitySheetScaffold(
        initialChildSize: 0.85,
        gradient: const [Color(0xFFA8E6CF), Color(0xFF88D8C0)],
        attachScrollController: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        onSave: _picked.isNotEmpty ? _save : null,
        header: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Arama + hatırlatıcı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: "Search solids...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black12.withValues(alpha: .2),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => openReminders(context, 'solidReminders'),
                    icon: const Icon(Icons.alarm_add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (1) Recent (çoklu seçim)
            const _SectionTitle("Recent Foods"),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _filteredRecent)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
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
            const SizedBox(height: 12),

            // (2) Custom (kullanıcının ekledikleri) (çoklu seçim)
            Row(
              children: [
                const _SectionTitle("Custom Foods"),
                IconButton(
                  onPressed: _addCustomFood,
                  icon: const Icon(Icons.add_box, color: Colors.white),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in _filteredCustom)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CustomCard(
                        item: item,
                        selected: _isSelectedCustom(item),
                        onTap: () => _toggleCustom(item),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // (3) Seçilenler & miktarlar
            if (_picked.isNotEmpty) ...[
              const _SectionTitle("Selected"),
              const SizedBox(height: 8),
              for (final e in _picked.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
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
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          "${e.value}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          onPressed: () => _inc(e.key),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _picked.remove(e.key)),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            TimeField(value: formatHHmm(_time), onTap: _pickTime),
            const SizedBox(height: 12),

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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
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
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: item.thumb ?? "",
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (c, u, e) => const Icon(Icons.error),
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
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.primaryColorLight
                : theme.dividerColor.withValues(alpha: 0.6),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: selected ? 0.12 : 0.06,
              ),
              blurRadius: selected ? 12 : 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// (Aynı kaldı) – Recent için chip kart
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
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.primaryColorLight
                : theme.dividerColor.withValues(alpha: 0.6),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: selected ? 0.12 : 0.06,
              ),
              blurRadius: selected ? 12 : 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: SvgPicture.asset(
                asset,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
