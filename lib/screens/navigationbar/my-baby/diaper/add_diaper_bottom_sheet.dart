import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/models/dummy/dummy_solid_list.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_reminder_manager_page.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/analytic_service.dart';

class AddDiaperBottomSheet extends StatefulWidget {
  const AddDiaperBottomSheet({super.key});

  @override
  State<AddDiaperBottomSheet> createState() => _AddDiaperBottomSheetState();
}

class _AddDiaperBottomSheetState extends State<AddDiaperBottomSheet> {
  String? _selectedDiaper;

  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    analyticService.screenView('add_diaper_sheet');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Platform.isAndroid
            ? SafeArea(top: false, child: sheetBody(context))
            : sheetBody(context);
      },
    );
  }

  Container sheetBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade200, Colors.tealAccent.shade200],
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const DiaperRemindersManagerPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.alarm_add,
                        ), // veya Icons.alarm_add
                      ),
                    ],
                  ),

                  _ChipPickerSection<String?>(
                    labelBuilder: (v) => v!,
                    items: kDummyDiapers,
                    title: "Add Diaper",
                    value: _selectedDiaper,
                    onChanged: (value) =>
                        setState(() => _selectedDiaper = value),
                  ),
                  const SizedBox(height: 24),

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
                          Text(_diaperTimeStr),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18),
                        ],
                      ),
                    ),
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
                    onPressed: (_selectedDiaper != null) ? _save : null,
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

  String get _diaperTimeStr {
    final dt = DateTime(0, 1, 1, _time.hour, _time.minute);
    return DateFormat('HH:mm').format(dt);
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
    if (_selectedDiaper == null) return;

    final model = DiaperModel(
      diaperName: _selectedDiaper!,
      createdAt: DateTime.now().toIso8601String(),
      diaperTime: _diaperTimeStr,
    );

    await diaperService.addDiaper(model);

    Navigator.pop(context, true);
    //  Navigator.of(context).pop(model);
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
