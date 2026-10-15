import 'package:flutter/material.dart';
import 'package:mama_meow/models/reminders/reminder_item.dart';
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, ctrl) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _config.gradient),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16)],
          ),
          child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time
                InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Icon(_config.editorIcon),
                        const SizedBox(width: 12),
                        Text(
                          '${_two(_time.hour)}:${_two(_time.minute)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Days
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                      selectedColor: accent.shade100,
                      side: BorderSide(color: sel ? accent : Colors.black12),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _days.isEmpty ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
