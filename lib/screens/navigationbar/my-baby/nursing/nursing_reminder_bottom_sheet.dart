import 'package:flutter/material.dart';
import 'package:mama_meow/models/reminders/nursing_reminder_model.dart';
import 'package:mama_meow/service/analytic_service.dart';

class ReminderEditorSheet extends StatefulWidget {
  final NursingReminderItem? initial;

  const ReminderEditorSheet({super.key, this.initial});

  @override
  State<ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<ReminderEditorSheet> {
  late TimeOfDay _time;
  late Set<int> _days;
  late bool _enabled;

  static const days = [
    {'label': 'Mon', 'value': 1},
    {'label': 'Tue', 'value': 2},
    {'label': 'Wed', 'value': 3},
    {'label': 'Thu', 'value': 4},
    {'label': 'Fri', 'value': 5},
    {'label': 'Sat', 'value': 6},
    {'label': 'Sun', 'value': 7},
  ];

  @override
  void initState() {
    super.initState();
    analyticService.screenView('nursing_reminder_sheet');
    final it = widget.initial;
    _time = it?.timeOfDay ?? TimeOfDay.now();
    _days = Set<int>.from(it?.weekdays ?? {});
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
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, ctrl) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9AA2), Color(0xFFFFB3BA)],
            ),
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
                            ? 'New Nursing Reminder'
                            : 'Edit Nursing Reminder',
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
                        const Icon(Icons.access_time),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Günler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: days.map((d) {
                    final v = d['value'] as int;
                    final sel = _days.contains(v);
                    return FilterChip(
                      label: Text(d['label'] as String),
                      selected: sel,
                      onSelected: (_) =>
                          setState(() => sel ? _days.remove(v) : _days.add(v)),
                      showCheckmark: true,
                      selectedColor: Colors.teal.shade100,
                      side: BorderSide(
                        color: sel ? Colors.teal : Colors.black12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
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
                        onPressed: _days.isEmpty
                            ? null
                            : () {
                                Navigator.pop(context, {
                                  'time': _time,
                                  'days': _days,
                                  'enabled': _enabled,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
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

  String _two(int n) => n.toString().padLeft(2, '0');
}
