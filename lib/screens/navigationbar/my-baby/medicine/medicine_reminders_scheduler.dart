import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/models/reminders/medicine_reminder_model.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:timezone/timezone.dart' as tz;

class MedicineReminderNotificationService {
  MedicineReminderNotificationService._();
  static final MedicineReminderNotificationService instance =
      MedicineReminderNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const channelId = 'medicine_reminders';
  static const channelName = 'Medicine Reminders';
  static const channelDesc = 'Medication intake scheduled reminders';

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);

    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> askPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Unique namespace (diğer modüllerle çakışmaz)
  static const int base = 13000;
  static int scheduleId(int reminderId, int weekday) =>
      base + reminderId * 10 + weekday;

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    // Bugün hedef saat
    final todayAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Hedef güne kaç gün kaldı? (0..6)
    var daysUntil = (weekday - now.weekday + 7) % 7;

    // Eğer hedef gün bugün ve saat geçmişse -> 7 gün sonrası
    if (daysUntil == 0 && !todayAt.isAfter(now)) {
      daysUntil = 7;
    }

    return todayAt.add(Duration(days: daysUntil));
  }

  Future<void> scheduleItem(MedicineReminderItem item) async {
    if (!item.enabled || item.weekdays.isEmpty) return;

    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    for (final d in item.weekdays) {
      await _plugin.zonedSchedule(
        scheduleId(item.reminderId, d),
        'MamaMeow – Medicine Reminder',
        'Time ${_two(item.timeOfDay.hour)}:${_two(item.timeOfDay.minute)}',
        _nextWeekly(d, item.timeOfDay.hour, item.timeOfDay.minute),
        details,
        androidScheduleMode: AlarmPolicy.instance.canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelItem(MedicineReminderItem item) async {
    for (final d in {1, 2, 3, 4, 5, 6, 7}) {
      await _plugin.cancel(scheduleId(item.reminderId, d));
    }
  }

  Future<void> reapplyAll(List<MedicineReminderItem> items) async {
    for (final it in items) {
      await cancelItem(it);
    }
    for (final it in items.where((e) => e.enabled && e.weekdays.isNotEmpty)) {
      await scheduleItem(it);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
