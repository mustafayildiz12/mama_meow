import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';

/// 1=Mon … 7=Sun
class SolidReminderItem {
  final int reminderId;
  final TimeOfDay timeOfDay; // 24h
  final Set<int> weekdays; // 1..7
  final bool enabled;

  SolidReminderItem({
    required this.reminderId,
    required this.timeOfDay,
    required this.weekdays,
    required this.enabled,
  });

  SolidReminderItem copyWith({
    int? reminderId,
    TimeOfDay? timeOfDay,
    Set<int>? weekdays,
    bool? enabled,
  }) {
    return SolidReminderItem(
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
    'weekdays': weekdays.toList(),
    'enabled': enabled,
  };

  factory SolidReminderItem.fromJson(Map<String, dynamic> j) {
    return SolidReminderItem(
      reminderId: j['id'] as int,
      timeOfDay: TimeOfDay(hour: j['hour'] as int, minute: j['minute'] as int),
      weekdays: Set<int>.from((j['weekdays'] as List).map((e) => e as int)),
      enabled: j['enabled'] as bool,
    );
  }
}

class SolidRemindersStore {
  static const _key = 'solid_reminders_list_v1';
  static const _idKey = 'solid_reminders_next_id_v1';

  static Future<List<SolidReminderItem>> loadAll() async {
    final raw = infoStorage.read(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => SolidReminderItem.fromJson(e))
        .toList();
  }

  static Future<void> saveAll(List<SolidReminderItem> items) async {
    await infoStorage.write(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<int> nextId() async {
    final id = infoStorage.read(_idKey) ?? 1;
    await infoStorage.write(_idKey, id + 1);
    return id;
  }
}
