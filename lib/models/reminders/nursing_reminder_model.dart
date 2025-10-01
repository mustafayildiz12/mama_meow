import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';

/// 1=Mon ... 7=Sun
class NursingReminderItem {
  final int reminderId;           // unique per reminder
  final TimeOfDay timeOfDay;      // 24h
  final Set<int> weekdays;        // 1..7
  final bool enabled;

  NursingReminderItem({
    required this.reminderId,
    required this.timeOfDay,
    required this.weekdays,
    required this.enabled,
  });

  NursingReminderItem copyWith({
    int? reminderId,
    TimeOfDay? timeOfDay,
    Set<int>? weekdays,
    bool? enabled,
  }) {
    return NursingReminderItem(
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

  factory NursingReminderItem.fromJson(Map<String, dynamic> j) {
    return NursingReminderItem(
      reminderId: j['id'] as int,
      timeOfDay: TimeOfDay(hour: j['hour'] as int, minute: j['minute'] as int),
      weekdays: Set<int>.from((j['weekdays'] as List).map((e) => e as int)),
      enabled: j['enabled'] as bool,
    );
  }
}

class NursingRemindersStore {
  static const _key = 'nursing_reminders_list_v1';
  static const _idKey = 'nursing_reminders_next_id_v1';

  /// Tümünü yükle
  static Future<List<NursingReminderItem>> loadAll() async {
   
    final raw = localStorage.read(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => NursingReminderItem.fromJson(e))
        .toList();
    return list;
  }

  /// Tümünü kaydet
  static Future<void> saveAll(List<NursingReminderItem> items) async {
    
    await localStorage.write(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// Yeni id üret
  static Future<int> nextId() async {
 
    final id = localStorage.read(_idKey) ?? 1;
    await localStorage.write(_idKey, id + 1);
    return id;
  }
}
