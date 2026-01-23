import 'dart:io';
import 'package:flutter/services.dart';

class ExactAlarmPermission {
  static const _ch = MethodChannel('exact_alarm_permission');

  static Future<bool> canSchedule() async {
    if (!Platform.isAndroid) return true;
    return (await _ch.invokeMethod<bool>('canScheduleExactAlarms')) ?? true;
  }

  static Future<void> request() async {
    if (!Platform.isAndroid) return;
    await _ch.invokeMethod('requestExactAlarmPermission');
  }
}
