import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/custom_solid_model.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/models/dummy/dummy_solid_list.dart';
import 'package:mama_meow/models/solid_food.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/add_custom_solid.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_reminder_manager_page.dart';
import 'package:mama_meow/service/activities/add_custom_solid_service.dart';
import 'package:mama_meow/service/activities/solid_service.dart';

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
  /// Arama
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = "";

  /// Zaman ve reaksiyon (global)
  TimeOfDay _time = TimeOfDay.now();
  Reaction? _reaction;

  /// Custom list
  List<CustomSolidModel> customSolids = [];

  /// Seçilen ürünler + miktar
  final Map<_PickedItem, int> _picked = {}; // item -> amount

  String get _eatTimeStr {
    final dt = DateTime(0, 1, 1, _time.hour, _time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  @override
  void initState() {
    super.initState();
    getPageData();
  }

  Future<void> getPageData() async {
    final items = await addCustomSolidService.getCustomSolids();
    setState(() => customSolids = items);
  }

  // Reaction listesi
  final reactions = const [
    Reaction.loveIt,
    Reaction.meh,
    Reaction.hatedIt,
    Reaction.allergicOrSensitivity,
  ];

  String reactionToText(Reaction r) {
    switch (r) {
      case Reaction.loveIt:
        return "love it";
      case Reaction.meh:
        return "meh";
      case Reaction.hatedIt:
        return "hated it";
      case Reaction.allergicOrSensitivity:
        return "allergic or sensitivity";
    }
  }

  IconData _iconForStartOfSleep(Reaction r) {
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

  void _toggleRecent(SolidFood f) {
    final key = _PickedItem(name: f.name, isCustom: false, thumb: f.asset);
    setState(() {
      if (_picked.containsKey(key)) {
        _picked.remove(key);
      } else {
        _picked[key] = 1;
      }
    });
  }

  void _toggleCustom(CustomSolidModel c) {
    final key = _PickedItem(name: c.name, isCustom: true, thumb: c.solidLink);
    setState(() {
      if (_picked.containsKey(key)) {
        _picked.remove(key);
      } else {
        _picked[key] = 1;
      }
    });
  }

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
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_picked.isEmpty) return;

    // Her seçilen ürün için ayrı SolidModel kaydediyoruz
    for (final entry in _picked.entries) {
      final item = entry.key;
      final amount = entry.value;

      final model = SolidModel(
        solidName: item.name,
        solidAmount: amount.toString(),
        createdAt: DateTime.now().toIso8601String(),
        eatTime: _eatTimeStr,
        reactions: _reaction,
      );

      await solidService.addSolid(model);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Platform.isAndroid
            ? SafeArea(
                top: false,
                child: sheetBody(theme, context, scrollController),
              )
            : sheetBody(theme, context, scrollController);
      },
    );
  }

  Container sheetBody(
    ThemeData theme,
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA8E6CF), Color(0xFF88D8C0)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
      ),
      child: Column(
        children: [
          // Handle
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
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

          // (4) Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
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
                          color: Colors.black12.withValues(alpha:.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SolidRemindersManagerPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.alarm_add), // or Icons.alarm_add
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // (1) Recent (çoklu seçim)
                  _SectionTitle("Recent Foods"),
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
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (_) => const AddCustomSolidBottomSheet(),
                          );
                          await getPageData();
                        },
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
                    Column(
                      children: _picked.entries.map((e) {
                        final k = e.key;
                        final qty = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: ListTile(
                            leading: _ThumbIcon(item: k),
                            title: Text(k.name),
                            subtitle: Text(k.isCustom ? "Custom" : "Recent"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _dec(k),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  "$qty",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  onPressed: () => _inc(k),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _picked.remove(k));
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Time
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Time",
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(_eatTimeStr),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reactions chips (opsiyonel, global)
                  _ChipPickerSection<Reaction>(
                    title: "Reaction",
                    labelBuilder: (v) => reactionToText(v!),
                    items: reactions,
                    value: _reaction,
                    onChanged: (v) => setState(() => _reaction = v),
                    iconBuilder: (v) => _iconForStartOfSleep(v!),
                  ),
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.grey.shade200,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _picked.isNotEmpty ? _save : null,
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                : theme.dividerColor.withValues(alpha:0.6),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha:selected ? 0.12 : 0.06),
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

class _ChipPickerSection<T> extends StatelessWidget {
  final String title; // örn: "Reaction"
  final List<T> items; // seçenekler
  final T? value; // seçili değer (tek)
  final ValueChanged<T?> onChanged;
  final IconData Function(T?)? iconBuilder;
  final String Function(T?) labelBuilder;

  const _ChipPickerSection({
    required this.title,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
    this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _ChipTile(
                    label: labelBuilder(it),
                    selected: it == value,
                    icon: iconBuilder != null ? iconBuilder!(it) : null,
                    onTap: () => onChanged(it),
                  ),
                ),
            ],
          ),
        ),
      ],
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
                : theme.dividerColor.withValues(alpha:0.6),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha:selected ? 0.12 : 0.06),
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

class _ChipTile extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _ChipTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.kOrange : AppColors.kLightOrange;
    final border = selected ? AppColors.kDeepOrange : Colors.black12;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? AppColors.kDeepOrange : Colors.black54,
                  ),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
