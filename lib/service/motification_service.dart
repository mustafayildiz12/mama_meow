import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/constants/app_pages.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/service/re_engagement_service.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';
import 'package:mama_meow/service/reminders/reminder_scheduler.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:timezone/timezone.dart' as tz;

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

/// Yerel bildirimlerin tek giriş noktası.
///
/// `FlutterLocalNotificationsPlugin` bir singleton'dır; `initialize` yalnızca
/// burada (tap callback'i ile) bir kez çağrılır ve tüm Android kanalları
/// burada oluşturulur. Zamanlayıcılar (hatırlatıcılar, re-engagement) sadece
/// [safeZonedSchedule] / [cancel] kullanır.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initFuture;

  /// Web'de zamanlanmış bildirim yok; plugin'in web tarafı Flutter'ın
  /// service worker'ını değiştirdiği için hiç başlatılmaz.
  bool get isSupported => !PlatformInfo.isWeb;

  /// Tekrar çağrılması güvenlidir; ilk çağrı plugin'i başlatır.
  Future<void> init() async {
    if (!isSupported) return;
    final pending = _initFuture ??= _init();
    try {
      await pending;
    } catch (_) {
      if (identical(_initFuture, pending)) _initFuture = null;
      rethrow;
    }
  }

  Future<void> _init() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) =>
          _routeFromPayload(response.payload),
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundTap,
    );

    await _createAndroidChannels();

    // Uygulama bir bildirime dokunularak soğuk başlatıldıysa, ilgili rotayı uygula.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _routeFromPayload(launchDetails!.notificationResponse?.payload);
    }

    // Eski bildirim ID şemasından tek seferlik geçiş (açılışı bloke etmez).
    unawaited(Future(ReminderScheduler.instance.migrateLegacyIfNeeded));
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final channels = [
      for (final c in ReminderCategory.values)
        AndroidNotificationChannel(
          c.config.channelId,
          c.config.channelName,
          description: c.config.channelDescription,
          importance: Importance.high,
          playSound: true,
        ),
      ReEngagementService.channel,
    ];
    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  /// [FlutterLocalNotificationsPlugin.zonedSchedule]'ı güvenli şekilde sarar:
  /// - exact alarm izni yoksa (`exact_alarms_not_permitted`) inexact moda düşer,
  /// - diğer hatalar yutulur (bildirim opsiyoneldir, akışı bozmamalı).
  ///
  /// Kurulabildiyse true döner.
  Future<bool> safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    if (!isSupported) return false;

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );

    final exact = AlarmPolicy.instance.canExact;
    try {
      await init();
      await schedule(
        exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } on PlatformException catch (e) {
      if (exact && e.code == 'exact_alarms_not_permitted') {
        try {
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
          return true;
        } catch (e2) {
          debugPrint('Notification $id could not be scheduled: $e2');
        }
      } else {
        debugPrint('Notification $id could not be scheduled: $e');
      }
    } catch (e) {
      debugPrint('Notification $id could not be scheduled: $e');
    }
    return false;
  }

  Future<void> cancel(int id) async {
    if (!isSupported) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Notification $id could not be cancelled: $e');
    }
  }

  /// Bekleyen (zamanlanmış) bildirimlerin ID'leri; hata olursa boş.
  Future<List<int>> pendingIds() async {
    if (!isSupported) return const [];
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return [for (final p in pending) p.id];
    } catch (e) {
      debugPrint('Pending notifications could not be read: $e');
      return const [];
    }
  }
}
