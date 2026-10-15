import 'package:flutter/material.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';
import 'package:mama_meow/service/reminders/reminder_store.dart';

/// Nursing hatırlatıcılarının özet durumu (ör. ikon rengi için).
class NursingReminderSettings {
  final TimeOfDay timeOfDay; // 24h
  final Set<int> weekdays; // 1=Mon ... 7=Sun
  final bool enabled;

  NursingReminderSettings({
    required this.timeOfDay,
    required this.weekdays,
    required this.enabled,
  });

  factory NursingReminderSettings.disabled() => NursingReminderSettings(
    timeOfDay: const TimeOfDay(hour: 12, minute: 0),
    weekdays: {},
    enabled: false,
  );
}

/// Eski API. Artık ayrı bir kayıt tutmaz; nursing [ReminderStore]'dan
/// türetilir: en az bir etkin hatırlatıcı varsa `enabled == true`.
/// Yeni kod için: `ReminderStore.of(ReminderCategory.nursing).hasActive()`.
class ReminderPrefs {
  static Future<NursingReminderSettings> load() async {
    final active = (await ReminderStore.of(
      ReminderCategory.nursing,
    ).loadAll()).where((e) => e.isActive).toList();
    if (active.isEmpty) return NursingReminderSettings.disabled();
    return NursingReminderSettings(
      timeOfDay: active.first.timeOfDay,
      weekdays: {for (final e in active) ...e.weekdays},
      enabled: true,
    );
  }
}
