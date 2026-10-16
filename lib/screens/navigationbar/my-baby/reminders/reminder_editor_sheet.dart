import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/models/reminders/reminder_item.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';

/// 1 = Mon … 7 = Sun
const Map<int, String> kWeekdayShortLabels = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

/// Hatırlatıcı ekleme/düzenleme sayfası; kaydedince [ReminderDraft] döner.
class ReminderEditorSheet extends StatefulWidget {
  const ReminderEditorSheet({super.key, required this.config, this.initial});

  final ReminderConfig config;
  final ReminderItem? initial;

  @override
  State<ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<ReminderEditorSheet> {
  late TimeOfDay _time;
  late Set<int> _days;
  late bool _enabled;

  ReminderConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    analyticService.screenView(_config.editorScreenName);
    final it = widget.initial;
    _time = it?.timeOfDay ?? TimeOfDay.now();
    _days = Set<int>.of(it?.weekdays ?? const <int>{});
    _enabled = it?.enabled ?? true;
  }

  Future<void> _pickTime() async {
    // Ortak 24 saat seçici (tema: beyaz zemin, berry vurgu).
    final picked = await pick24hTime(context, _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _save() {
    Navigator.pop(
      context,
      ReminderDraft(
        time: _time,
        weekdays: Set<int>.of(_days),
        enabled: _enabled,
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final accent = _config.accent;
    final textTheme = Theme.of(context).textTheme;

    // Beyaz sheet (32 px üst köşe) + sabit Cancel (tonal) / Save (berry).
    return ActivitySheetScaffold(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      attachScrollController: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initial == null
                        ? _config.newReminderTitle
                        : _config.editReminderTitle,
                    style: textTheme.headlineSmall,
                  ),
                ),
                Switch(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ],
        ),
      ),
      onSave: _days.isEmpty ? null : () async => _save(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Material(
            color: AppColors.cottonWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              side: const BorderSide(color: AppColors.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(_config.editorIcon, color: accent, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      '${_two(_time.hour)}:${_two(_time.minute)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepCharcoal,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.charcoalSoft,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Days
          Text('Days', style: textTheme.titleSmall?.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kWeekdayShortLabels.entries.map((d) {
              final sel = _days.contains(d.key);
              return FilterChip(
                label: Text(d.value),
                selected: sel,
                onSelected: (_) => setState(
                  () => sel ? _days.remove(d.key) : _days.add(d.key),
                ),
                showCheckmark: true,
                checkmarkColor: AppColors.cottonWhite,
                backgroundColor: AppColors.pinkTint,
                selectedColor: accent,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
                  color: sel ? AppColors.cottonWhite : AppColors.deepCharcoal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
