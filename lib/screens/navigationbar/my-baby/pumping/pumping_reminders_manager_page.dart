import 'package:flutter/material.dart';
import 'package:mama_meow/models/reminders/pumping_reminder_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_reminder_schecule.dart';
import 'package:mama_meow/service/analytic_service.dart';


import 'pumping_reminder_editor_sheet.dart';

class PumpingRemindersManagerPage extends StatefulWidget {
  const PumpingRemindersManagerPage({super.key});

  @override
  State<PumpingRemindersManagerPage> createState() =>
      _PumpingRemindersManagerPageState();
}

class _PumpingRemindersManagerPageState
    extends State<PumpingRemindersManagerPage> {
  List<PumpingReminderItem> _items = [];

  @override
  void initState() {
     analyticService.screenView('pumping_reminder_manager');
    setTimeZone();
    _load();
     super.initState();
  }

  Future<void> setTimeZone() async {
    PumpingReminderNotificationService.instance.init();
  }

  Future<void> _load() async {
    final list = await PumpingRemindersStore.loadAll();
    setState(() => _items = list);
    await PumpingReminderNotificationService.instance.reapplyAll(_items);
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PumpingReminderEditorSheet(),
    );
    if (result == null) return;

    final id = await PumpingRemindersStore.nextId();
    final item = PumpingReminderItem(
      reminderId: id,
      timeOfDay: result['time'] as TimeOfDay,
      weekdays: Set<int>.from(result['days'] as Set<int>),
      enabled: result['enabled'] as bool,
    );

    final next = [..._items, item];
    await PumpingRemindersStore.saveAll(next);
    setState(() => _items = next);

    await PumpingReminderNotificationService.instance.scheduleItem(item);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder added')));
  }

  Future<void> _edit(PumpingReminderItem it) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PumpingReminderEditorSheet(initial: it),
    );
    if (result == null) return;

    final updated = it.copyWith(
      timeOfDay: result['time'] as TimeOfDay,
      weekdays: Set<int>.from(result['days'] as Set<int>),
      enabled: result['enabled'] as bool,
    );

    final next = _items
        .map((e) => e.reminderId == it.reminderId ? updated : e)
        .toList();
    await PumpingRemindersStore.saveAll(next);
    setState(() => _items = next);

    await PumpingReminderNotificationService.instance.cancelItem(it);
    await PumpingReminderNotificationService.instance.scheduleItem(updated);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder updated')));
  }

  Future<void> _toggle(PumpingReminderItem it, bool v) async {
    final updated = it.copyWith(enabled: v);
    final next = _items
        .map((e) => e.reminderId == it.reminderId ? updated : e)
        .toList();
    await PumpingRemindersStore.saveAll(next);
    setState(() => _items = next);

    if (v) {
      await PumpingReminderNotificationService.instance.scheduleItem(updated);
    } else {
      await PumpingReminderNotificationService.instance.cancelItem(it);
    }
  }

  Future<void> _delete(PumpingReminderItem it) async {
    final next = _items.where((e) => e.reminderId != it.reminderId).toList();
    await PumpingRemindersStore.saveAll(next);
    setState(() => _items = next);
    await PumpingReminderNotificationService.instance.cancelItem(it);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pumping Reminders')),
      body: _items.isEmpty
          ? const Center(child: Text('No reminders yet. Tap + to add.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final it = _items[i];
                return _ReminderCard(
                  item: it,
                  onToggle: (v) => _toggle(it, v),
                  onEdit: () => _edit(it),
                  onDelete: () => _delete(it),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final PumpingReminderItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _two(int n) => n.toString().padLeft(2, '0');
  static const labels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.health_and_safety)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_two(item.timeOfDay.hour)}:${_two(item.timeOfDay.minute)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.weekdays
                            .map(
                              (d) => Chip(
                                label: Text(labels[d]!),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(value: item.enabled, onChanged: onToggle),
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
