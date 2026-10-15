import 'package:flutter/material.dart';
import 'package:mama_meow/models/reminders/reminder_item.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/reminders/reminder_editor_sheet.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';
import 'package:mama_meow/service/reminders/reminder_scheduler.dart';
import 'package:mama_meow/service/reminders/reminder_store.dart';

/// Bir kategorinin hatırlatıcılarını listeleyen / yöneten ortak sayfa.
class ReminderManagerPage extends StatefulWidget {
  const ReminderManagerPage({super.key, required this.config});

  final ReminderConfig config;

  @override
  State<ReminderManagerPage> createState() => _ReminderManagerPageState();
}

class _ReminderManagerPageState extends State<ReminderManagerPage> {
  List<ReminderItem> _items = const [];

  ReminderConfig get _config => widget.config;
  ReminderCategory get _category => _config.category;
  ReminderStore get _store => ReminderStore(_config);

  @override
  void initState() {
    super.initState();
    analyticService.screenView(_config.managerScreenName);
    _load();
  }

  Future<void> _load() async {
    final list = await _store.loadAll();
    _setItems(list);
    await reminderScheduler.reapply(_category, list);
  }

  void _setItems(List<ReminderItem> items) {
    if (!mounted) return;
    setState(() => _items = items);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<ReminderDraft?> _openEditor([ReminderItem? initial]) {
    return showModalBottomSheet<ReminderDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderEditorSheet(config: _config, initial: initial),
    );
  }

  List<ReminderItem> _replaced(ReminderItem updated) => _items
      .map((e) => e.reminderId == updated.reminderId ? updated : e)
      .toList();

  Future<void> _add() async {
    final draft = await _openEditor();
    if (draft == null) return;

    final item = ReminderItem(
      reminderId: await _store.nextId(),
      timeOfDay: draft.time,
      weekdays: draft.weekdays,
      enabled: draft.enabled,
    );
    final next = [..._items, item];
    await _store.saveAll(next);
    _setItems(next);

    await reminderScheduler.scheduleItem(_category, item);
    _showSnack('Reminder added');
  }

  Future<void> _edit(ReminderItem it) async {
    final draft = await _openEditor(it);
    if (draft == null) return;

    final updated = it.copyWith(
      timeOfDay: draft.time,
      weekdays: draft.weekdays,
      enabled: draft.enabled,
    );
    final next = _replaced(updated);
    await _store.saveAll(next);
    _setItems(next);

    // Eski slotları iptal eder, etkinse yeni halini kurar.
    await reminderScheduler.scheduleItem(_category, updated);
    _showSnack('Reminder updated');
  }

  Future<void> _toggle(ReminderItem it, bool enabled) async {
    final updated = it.copyWith(enabled: enabled);
    final next = _replaced(updated);
    await _store.saveAll(next);
    _setItems(next);

    if (enabled) {
      await reminderScheduler.scheduleItem(_category, updated);
    } else {
      await reminderScheduler.cancelItem(_category, it);
    }
  }

  Future<void> _delete(ReminderItem it) async {
    final next = _items.where((e) => e.reminderId != it.reminderId).toList();
    await _store.saveAll(next);
    _setItems(next);
    await reminderScheduler.cancelItem(_category, it);
    _showSnack('Reminder deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_config.screenTitle)),
      body: _items.isEmpty
          ? const Center(child: Text('No reminders yet. Tap + to add.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final it = _items[i];
                return _ReminderCard(
                  item: it,
                  icon: _config.cardIcon,
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
  final ReminderItem item;
  final IconData icon;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.item,
    required this.icon,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

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
                CircleAvatar(child: Icon(icon)),
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
                        children: item.sortedWeekdays
                            .map(
                              (d) => Chip(
                                label: Text(kWeekdayShortLabels[d]!),
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
