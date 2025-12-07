import 'package:flutter/material.dart';
import 'package:mama_meow/models/reminders/solid_reminder_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_reminder_editor_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_reminder_schecular.dart';
import 'package:mama_meow/service/analytic_service.dart';

class SolidRemindersManagerPage extends StatefulWidget {
  const SolidRemindersManagerPage({super.key});

  @override
  State<SolidRemindersManagerPage> createState() =>
      _SolidRemindersManagerPageState();
}

class _SolidRemindersManagerPageState extends State<SolidRemindersManagerPage> {
  List<SolidReminderItem> _items = [];

  @override
  void initState() {
    super.initState();
    analyticService.screenView('solid_reminder_manager');
    setTimeZone();
    _load();
  }

  Future<void> setTimeZone() async {
    SolidReminderNotificationService.instance.init();
  }

  Future<void> _load() async {
    final list = await SolidRemindersStore.loadAll();
    setState(() => _items = list);
    await SolidReminderNotificationService.instance.reapplyAll(_items);
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SolidReminderEditorSheet(),
    );
    if (result == null) return;

    final id = await SolidRemindersStore.nextId();
    final item = SolidReminderItem(
      reminderId: id,
      timeOfDay: result['time'] as TimeOfDay,
      weekdays: Set<int>.from(result['days'] as Set<int>),
      enabled: result['enabled'] as bool,
    );

    final next = [..._items, item];
    await SolidRemindersStore.saveAll(next);
    setState(() => _items = next);

    await SolidReminderNotificationService.instance.scheduleItem(item);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder added')));
  }

  Future<void> _edit(SolidReminderItem it) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SolidReminderEditorSheet(initial: it),
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
    await SolidRemindersStore.saveAll(next);
    setState(() => _items = next);

    await SolidReminderNotificationService.instance.cancelItem(it);
    await SolidReminderNotificationService.instance.scheduleItem(updated);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder updated')));
  }

  Future<void> _toggle(SolidReminderItem it, bool v) async {
    final updated = it.copyWith(enabled: v);
    final next = _items
        .map((e) => e.reminderId == it.reminderId ? updated : e)
        .toList();
    await SolidRemindersStore.saveAll(next);
    setState(() => _items = next);

    if (v) {
      await SolidReminderNotificationService.instance.scheduleItem(updated);
    } else {
      await SolidReminderNotificationService.instance.cancelItem(it);
    }
  }

  Future<void> _delete(SolidReminderItem it) async {
    final next = _items.where((e) => e.reminderId != it.reminderId).toList();
    await SolidRemindersStore.saveAll(next);
    setState(() => _items = next);
    await SolidReminderNotificationService.instance.cancelItem(it);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solid Reminders')),
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
  final SolidReminderItem item;
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
                const CircleAvatar(child: Icon(Icons.restaurant)),
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
