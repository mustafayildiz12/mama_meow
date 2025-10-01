import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';

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

  Map<String, dynamic> toJson() => {
    'hour': timeOfDay.hour,
    'minute': timeOfDay.minute,
    'weekdays': weekdays.toList(),
    'enabled': enabled,
  };

  factory NursingReminderSettings.fromJson(Map<String, dynamic> json) {
    return NursingReminderSettings(
      timeOfDay: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      weekdays: Set<int>.from((json['weekdays'] as List).map((e) => e as int)),
      enabled: json['enabled'] as bool,
    );
  }
}

class ReminderPrefs {
  static const String _key = 'nursing_reminder_settings';

  static Future<NursingReminderSettings> load() async {
    final raw = localStorage.read(_key);
    if (raw == null) return NursingReminderSettings.disabled();
    try {
      return NursingReminderSettings.fromJson(jsonDecode(raw));
    } catch (_) {
      return NursingReminderSettings.disabled();
    }
  }

  static Future<void> save(NursingReminderSettings s) async {
   
    await localStorage.write(_key, jsonEncode(s.toJson()));
  }
}
