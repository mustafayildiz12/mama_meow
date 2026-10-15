import 'package:flutter/material.dart';

/// Kullanıcının kurduğu tekrar eden hatırlatıcı (tüm kategoriler için ortak).
///
/// JSON şekli kalıcı veridir (GetStorage "info"), değiştirmeyin:
/// `{id, hour, minute, weekdays: [1..7], enabled}` — 1 = Mon … 7 = Sun.
class ReminderItem {
  final int reminderId;
  final TimeOfDay timeOfDay; // 24h
  final Set<int> weekdays; // 1..7
  final bool enabled;

  const ReminderItem({
    required this.reminderId,
    required this.timeOfDay,
    required this.weekdays,
    required this.enabled,
  });

  static const Set<int> allWeekdays = {1, 2, 3, 4, 5, 6, 7};

  /// Haftanın her günü seçili → tek günlük bildirim yeterli.
  bool get isDaily => weekdays.containsAll(allWeekdays);

  bool get isActive => enabled && weekdays.isNotEmpty;

  /// Mon..Sun sıralı.
  List<int> get sortedWeekdays => weekdays.toList()..sort();

  ReminderItem copyWith({
    int? reminderId,
    TimeOfDay? timeOfDay,
    Set<int>? weekdays,
    bool? enabled,
  }) {
    return ReminderItem(
      reminderId: reminderId ?? this.reminderId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weekdays: weekdays ?? this.weekdays,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': reminderId,
    'hour': timeOfDay.hour,
    'minute': timeOfDay.minute,
    'weekdays': sortedWeekdays,
    'enabled': enabled,
  };

  /// Bozuk kayıtlarda null döner (çağıran atlar).
  static ReminderItem? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final hour = raw['hour'];
    final minute = raw['minute'];
    final days = raw['weekdays'];
    final enabled = raw['enabled'];
    if (id is! int || hour is! int || minute is! int) return null;
    if (days is! List || enabled is! bool) return null;
    if (id < 0 || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return ReminderItem(
      reminderId: id,
      timeOfDay: TimeOfDay(hour: hour, minute: minute),
      weekdays: days.whereType<int>().where(allWeekdays.contains).toSet(),
      enabled: enabled,
    );
  }
}

/// Editör sayfasının döndürdüğü tipli taslak.
class ReminderDraft {
  final TimeOfDay time;
  final Set<int> weekdays;
  final bool enabled;

  const ReminderDraft({
    required this.time,
    required this.weekdays,
    required this.enabled,
  });
}
