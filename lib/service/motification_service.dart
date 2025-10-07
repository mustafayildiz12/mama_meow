import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'nursing_reminders';
  static const String channelName = 'Nursing Reminders';
  static const String channelDesc = 'Nursing-related scheduled reminders';

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);

    // Android kanal
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
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

  Future<void> requestPermissionsIfNeeded() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Her seçili gün için ayrı bir schedule yapacağız.
  Future<void> scheduleWeeklyAt(
    int id,
    int weekday, // 1=Mon ... 7=Sun (tz standardına göre)
    int hour,
    int minute, {
    required String title,
    required String body,
  }) async {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    final tz.TZDateTime fireDate = _nextInstanceOfWeekdayTime(
      weekday,
      hour,
      minute,
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      fireDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Monday=1 ... Sunday=7
    int addDays = (weekday - scheduled.weekday) % 7;
    if (addDays < 0) addDays += 7;
    if (addDays == 0 && scheduled.isBefore(now)) addDays = 7;
    return scheduled.add(Duration(days: addDays));
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids) {
      await cancel(id);
    }
  }
}
