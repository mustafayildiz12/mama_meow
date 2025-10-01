import 'package:flutter/material.dart';
import 'package:mama_meow/models/reminders/diaper_reminder_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_reminder_editor.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_reminder_schecule.dart';


class DiaperRemindersManagerPage extends StatefulWidget {
  const DiaperRemindersManagerPage({super.key});

  @override
  State<DiaperRemindersManagerPage> createState() =>
      _DiaperRemindersManagerPageState();
}

class _DiaperRemindersManagerPageState
    extends State<DiaperRemindersManagerPage> {
  List<DiaperReminderItem> _items = [];

  @override
  void initState() {
    super.initState();

    setTimeZone();
    _load();
  }

  Future<void> setTimeZone() async {
    DiaperReminderNotificationService.instance.init();
  }

  Future<void> _load() async {
    final list = await DiaperRemindersStore.loadAll();
    setState(() => _items = list);
    await DiaperReminderNotificationService.instance.reapplyAll(_items);
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiaperReminderEditorSheet(),
    );
    if (result == null) return;

    final id = await DiaperRemindersStore.nextId();
    final item = DiaperReminderItem(
      reminderId: id,
      timeOfDay: result['time'] as TimeOfDay,
      weekdays: Set<int>.from(result['days'] as Set<int>),
      enabled: result['enabled'] as bool,
    );

    final next = [..._items, item];
    await DiaperRemindersStore.saveAll(next);
    setState(() => _items = next);

    await DiaperReminderNotificationService.instance.scheduleItem(item);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder added')));
  }

  Future<void> _edit(DiaperReminderItem it) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiaperReminderEditorSheet(initial: it),
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
    await DiaperRemindersStore.saveAll(next);
    setState(() => _items = next);

    await DiaperReminderNotificationService.instance.cancelItem(it);
    await DiaperReminderNotificationService.instance.scheduleItem(updated);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder updated')));
  }

  Future<void> _toggle(DiaperReminderItem it, bool v) async {
    final updated = it.copyWith(enabled: v);
    final next = _items
        .map((e) => e.reminderId == it.reminderId ? updated : e)
        .toList();
    await DiaperRemindersStore.saveAll(next);
    setState(() => _items = next);

    if (v) {
      await DiaperReminderNotificationService.instance.scheduleItem(updated);
    } else {
      await DiaperReminderNotificationService.instance.cancelItem(it);
    }
  }

  Future<void> _delete(DiaperReminderItem it) async {
    final next = _items.where((e) => e.reminderId != it.reminderId).toList();
    await DiaperRemindersStore.saveAll(next);
    setState(() => _items = next);
    await DiaperReminderNotificationService.instance.cancelItem(it);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diaper Reminders')),
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
  final DiaperReminderItem item;
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
                const CircleAvatar(child: Icon(Icons.baby_changing_station)),
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
