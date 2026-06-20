import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:timezone/timezone.dart' as tz;

/// Uygulama-güdümlü geri kazanım (re-engagement) bildirimleri.
///
/// Kullanıcının kendi kurduğu hatırlatıcılardan farklı olarak, bu servis
/// uygulamanın kendisinin tetiklediği "geri dön" dürtülerini yönetir:
/// - Hareketsizlik (3/7 gün açmadıysa)
/// - Haftalık özet dürtüsü
///
/// Her uygulama açılışında [scheduleAll] çağrılır; böylece "açılış" = etkileşim
/// sayılır ve hareketsizlik sayacı sıfırlanır.
class ReEngagementService {
  ReEngagementService._();
  static final ReEngagementService instance = ReEngagementService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const channelId = 'reengagement';
  static const channelName = 'Reminders & Tips';
  static const channelDesc =
      'Gentle nudges to keep tracking and check your reports';

  // Diğer scheduler base'leriyle (8000, 10000 ...) çakışmayan ayrı namespace.
  static const int _idInactivity3 = 90001;
  static const int _idInactivity7 = 90002;
  static const int _idWeekly = 90003;

  Future<void> init() async {
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

  NotificationDetails get _details {
    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  AndroidScheduleMode get _mode => AlarmPolicy.instance.canExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Açılışta çağır: hareketsizlik sayacını sıfırla + haftalık özeti garanti et.
  ///
  /// Bildirim kurulumu kritik değildir: herhangi bir adım başarısız olursa
  /// (örn. exact alarm izni yok) sessizce yutulur ki uygulama açılışı (splash)
  /// asla bloke olmasın.
  Future<void> scheduleAll() async {
    // Gerçek exact-alarm iznini öğren ki _mode doğru modu seçsin.
    await AlarmPolicy.instance.refresh();
    await bumpInactivityReminders();
    await scheduleWeeklySummary();
  }

  /// Hareketsizlik dürtülerini bugünden ileriye yeniden kurar (önce iptal eder).
  /// Kullanıcı 3 (veya 7) gün boyunca uygulamayı açmazsa tetiklenir.
  Future<void> bumpInactivityReminders() async {
    await _plugin.cancel(_idInactivity3);
    await _plugin.cancel(_idInactivity7);

    final now = tz.TZDateTime.now(tz.local);

    await _safeSchedule(
      _idInactivity3,
      'We miss you & your little one 🐾',
      "Log today's feeds, sleep & diapers in seconds — and ask Mia anything.",
      _atHourAfterDays(now, days: 3, hour: 11),
    );

    await _safeSchedule(
      _idInactivity7,
      "Your baby's tracker is waiting 😺",
      'A quick tap keeps your logs and weekly reports up to date.',
      _atHourAfterDays(now, days: 7, hour: 11),
    );
  }

  /// Haftalık özet dürtüsü (Pazar 19:00, her hafta tekrar).
  Future<void> scheduleWeeklySummary() async {
    await _safeSchedule(
      _idWeekly,
      'Your weekly baby summary is ready 📊',
      "See this week's sleep, feeding & diaper trends.",
      _nextWeekly(DateTime.sunday, 19, 0),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// [zonedSchedule]'ı güvenli şekilde sarar:
  /// - exact alarm izni yoksa otomatik olarak inexact moda düşer,
  /// - başka herhangi bir hata da yutulur (bildirim opsiyoneldir, açılışı
  ///   engellememeli).
  Future<void> _safeSchedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when, {
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: AppRoutes.myBaby,
      );
    }

    try {
      await schedule(_mode);
    } on PlatformException catch (e) {
      // Exact alarm izni anlık olarak reddedilmişse inexact ile yeniden dene.
      if (e.code == 'exact_alarms_not_permitted') {
        try {
          await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
        } catch (_) {
          // yine olmadıysa sessizce geç
        }
      }
    } catch (_) {
      // bildirim kurulamadı; açılışı bloke etme
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancel(_idInactivity3);
    await _plugin.cancel(_idInactivity7);
    await _plugin.cancel(_idWeekly);
  }

  tz.TZDateTime _atHourAfterDays(
    tz.TZDateTime from, {
    required int days,
    required int hour,
  }) {
    final target = from.add(Duration(days: days));
    return tz.TZDateTime(tz.local, target.year, target.month, target.day, hour);
  }

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final todayAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    var daysUntil = (weekday - now.weekday + 7) % 7;
    if (daysUntil == 0 && !todayAt.isAfter(now)) {
      daysUntil = 7;
    }
    return todayAt.add(Duration(days: daysUntil));
  }
}

final ReEngagementService reEngagementService = ReEngagementService.instance;
