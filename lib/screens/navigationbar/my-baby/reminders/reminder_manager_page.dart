import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/reminders/reminder_item.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/reminders/reminder_editor_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';
import 'package:mama_meow/service/reminders/reminder_scheduler.dart';
import 'package:mama_meow/service/reminders/reminder_store.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

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
    // Diğer sheet'lerle aynı açılış (şeffaf zemin, scrim, 32 px köşe).
    return showActivitySheet<ReminderDraft>(
      context,
      (_) => ReminderEditorSheet(config: _config, initial: initial),
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
      backgroundColor: AppColors.cosyIvory,
      appBar: AppBar(title: Text(_config.screenTitle)),
      body: _items.isEmpty
          ? _EmptyReminders(config: _config)
          : ListView.separated(
              // Alttaki boşluk son kartın FAB altında kalmaması için.
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final it = _items[i];
                return _ReminderCard(
                  item: it,
                  icon: _config.cardIcon,
                  iconBackground: _config.gradient.first,
                  accent: _config.accent,
                  onToggle: (v) => _toggle(it, v),
                  onEdit: () => _edit(it),
                  onDelete: () => _delete(it),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.activeBerry,
        foregroundColor: AppColors.cottonWhite,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Liste boşken: kategori ikonu + yumuşak kömür renkli ipucu.
class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders({required this.config});

  final ReminderConfig config;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconSquircle(
              background: config.gradient.first,
              size: 64,
              radius: 20,
              child: Icon(config.cardIcon, color: config.accent, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders yet. Tap + to add.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.charcoalSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beyaz, ince çizgili hatırlatıcı kartı.
class _ReminderCard extends StatelessWidget {
  final ReminderItem item;
  final IconData icon;
  final Color iconBackground;
  final Color accent;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.item,
    required this.icon,
    required this.iconBackground,
    required this.accent,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconSquircle(
                background: iconBackground,
                size: 48,
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_two(item.timeOfDay.hour)}:${_two(item.timeOfDay.minute)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        // Kapalı hatırlatıcı soluk görünür.
                        color: item.enabled
                            ? AppColors.deepCharcoal
                            : AppColors.charcoalSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.sortedWeekdays
                          .map((d) => _DayChip(label: kWeekdayShortLabels[d]!))
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
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.charcoalSoft,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.charcoalSoft,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seçili gün rozeti: pembe tint zemin, berry ink metin.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.berryInk,
        ),
      ),
    );
  }
}
