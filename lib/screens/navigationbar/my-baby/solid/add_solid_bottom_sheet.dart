import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/models/dummy/dummy_solid_list.dart';
import 'package:mama_meow/models/solid_food.dart';
import 'package:mama_meow/service/activities/solid_service.dart';

class AddSolidBottomSheet extends StatefulWidget {
  const AddSolidBottomSheet();

  @override
  State<AddSolidBottomSheet> createState() => _AddSolidBottomSheetState();
}

class _AddSolidBottomSheetState extends State<AddSolidBottomSheet> {
  String? _selectedSolid;
  int _amount = 1;
  TimeOfDay _time = TimeOfDay.now();
  Reaction? _reaction;

  String get _eatTimeStr {
    final dt = DateTime(0, 1, 1, _time.hour, _time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  void _pickTime() async {
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
    if (_selectedSolid == null || _amount <= 0) return;

    final model = SolidModel(
      solidName: _selectedSolid!,
      solidAmount: _amount.toString(),
      createdAt: DateTime.now().toIso8601String(),
      eatTime: _eatTimeStr,
      reactions: _reaction,
    );

    await solidService.addSolid(model);

    Navigator.pop(context, true);
    //  Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.kLightOrange,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      FoodChipPickerSection(
                        title: "Add Solid",
                        items: kSolidFoods,
                        value: _selectedSolid, // String? (ör. "Banana")
                        onChanged: (value) =>
                            setState(() => _selectedSolid = value),
                      ),
                      const SizedBox(height: 12),

                      // Miktar +/-
                      Row(
                        children: [
                          const Text(
                            "Amount:",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _amount > 0
                                ? () => setState(() => _amount -= 1)
                                : null,
                          ),
                          Text(
                            "$_amount",
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _amount += 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Saat seçimi
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

                      // Reactions chips (opsiyonel)
                      _ChipPickerSection<Reaction>(
                        title: "Reaction",
                        labelBuilder: (v) => reactionToText(v!),
                        items: items,
                        value: _reaction,
                        onChanged: (v) => setState(() => _reaction = v),
                        iconBuilder: (v) => _iconForStartOfSleep(v!),
                      ),
                    ],
                  ),
                ),
              ),

              // Kaydet butonu
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
                        onPressed: (_selectedSolid != null && _amount > 0)
                            ? _save
                            : null,
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  // Reaction listesi
  final items = <Reaction>[
    Reaction.loveIt,
    Reaction.meh,
    Reaction.hatedIt,
    Reaction.allergicOrSensitivity,
  ];

  // Reaction → Icon eşleştirmesi
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
}

class _ChipPickerSection<T> extends StatelessWidget {
  final String title; // örn: "Start of sleep"
  final List<T> items; // seçenekler
  final T? value; // seçili değer
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        // Sağa kaydırılabilir sıra
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

class FoodChipPickerSection extends StatelessWidget {
  final String title; // örn: "Add Solid"
  final List<SolidFood> items; // kSolidFoods
  final String? value; // seçili food adı
  final ValueChanged<String?> onChanged;

  const FoodChipPickerSection({
    super.key,
    required this.title,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle
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

        // Sağa kaydırılabilir sıra (chip kart hissini bozmadan)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in items)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _FoodChipTile(
                    label: f.name,
                    asset: f.asset,
                    selected: f.name == value,
                    onTap: () => onChanged(f.name),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip kart tasarımını korur; sadece üstte SVG, altta label gösterir.
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
        width: 110, // kare kare görünüm için sabit bir genişlik iyi oluyor
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.primaryColorLight
                : theme.dividerColor.withOpacity(0.6),
            width: selected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(selected ? 0.12 : 0.06),
              blurRadius: selected ? 12 : 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SVG görseli
            SizedBox(
              width: 48,
              height: 48,
              child: SvgPicture.asset(asset, width: 48, height: 48, fit: BoxFit.contain)),
            const SizedBox(height: 8),
            // İsim
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
