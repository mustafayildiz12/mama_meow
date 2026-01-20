import 'package:mama_meow/models/reminders/nursing_reminder_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NursingReminderNotificationService {
  NursingReminderNotificationService._();
  static final NursingReminderNotificationService instance = NursingReminderNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const channelId = 'nursing_reminders';
  static const channelName = 'Nursing Reminders';
  static const channelDesc = 'Nursing-related scheduled reminders';

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
    );
    final init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);

    const channel = AndroidNotificationChannel(
      channelId, channelName, description: channelDesc, importance: Importance.high, playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> askPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static const int base = 8000; // namespace
  static int scheduleId(int reminderId, int weekday) => base + reminderId * 10 + weekday;

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var sched = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    int addDays = (weekday - sched.weekday) % 7;
    if (addDays < 0) addDays += 7;
    if (addDays == 0 && sched.isBefore(now)) addDays = 7;
    return sched.add(Duration(days: addDays));
  }

  Future<void> scheduleItem(NursingReminderItem item) async {
    if (!item.enabled || item.weekdays.isEmpty) return;
    final android = AndroidNotificationDetails(
      channelId, channelName, channelDescription: channelDesc,
      importance: Importance.high, priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);
    for (final d in item.weekdays) {
      await _plugin.zonedSchedule(
        scheduleId(item.reminderId, d),
        'Time for a cozy cuddle & feed! 🤱🐾 MamaMeow’s got your back',
        '👶 Time ${_two(item.timeOfDay.hour)}:${_two(item.timeOfDay.minute)}',
        _nextWeekly(d, item.timeOfDay.hour, item.timeOfDay.minute),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelItem(NursingReminderItem item) async {
    for (final d in {1,2,3,4,5,6,7}) {
      await _plugin.cancel(scheduleId(item.reminderId, d));
    }
  }

  Future<void> reapplyAll(List<NursingReminderItem> items) async {
    // Önce hepsinin slotlarını temizle
    for (final it in items) { await cancelItem(it); }
    // Sonra sadece enabled olanları kur
    for (final it in items.where((e) => e.enabled && e.weekdays.isNotEmpty)) {
      await scheduleItem(it);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
