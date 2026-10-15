import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/utils/platform_info.dart';

/// Android 12+ exact alarm izni (flutter_local_notifications üzerinden).
abstract final class ExactAlarmPermission {
  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      PlatformInfo.isAndroid
      ? FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
      : null;

  /// Android dışında her zaman true; izin okunamazsa null.
  static Future<bool?> canSchedule() async {
    final android = _android;
    if (android == null) return true;
    try {
      return await android.canScheduleExactNotifications() ?? true;
    } catch (e) {
      debugPrint('canScheduleExactNotifications failed: $e');
      return null;
    }
  }

  /// Sistem ayar ekranını açar; kullanıcı geri döndüğünde güncel izin
  /// durumuyla tamamlanır.
  static Future<bool> request() async {
    final android = _android;
    if (android == null) return true;
    try {
      return await android.requestExactAlarmsPermission() ?? false;
    } catch (e) {
      debugPrint('requestExactAlarmsPermission failed: $e');
      return false;
    }
  }
}
