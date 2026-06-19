import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/constants/app_pages.dart';

/// Bildirime dokunulduğunda payload'daki rotaya yönlendirir.
/// Payload, hedef go_router yolu (ör. AppRoutes.myBaby) olarak saklanır.
void _routeFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  try {
    router.go(payload);
  } catch (_) {
    // Router henüz hazır değilse sessizce geç.
  }
}

/// Arka planda gelen dokunuşlar için top-level handler (zorunlu imza).
@pragma('vm:entry-point')
void notificationBackgroundTap(NotificationResponse response) {
  // Arka plandan açılışta uygulama ön plana gelince ana handler yönlendirir.
}

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
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) =>
          _routeFromPayload(response.payload),
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundTap,
    );

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

    // Uygulama bir bildirime dokunularak soğuk başlatıldıysa, ilgili rotayı uygula.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _routeFromPayload(launchDetails!.notificationResponse?.payload);
    }
  }
}
