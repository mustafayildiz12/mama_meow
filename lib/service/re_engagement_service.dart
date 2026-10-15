import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/motification_service.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/service/reminders/schedule_time.dart';
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

  static const channelId = 'reengagement';
  static const channelName = 'Reminders & Tips';
  static const channelDesc =
      'Gentle nudges to keep tracking and check your reports';

  /// Kanal [NotificationService.init] içinde oluşturulur.
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDesc,
    importance: Importance.high,
    playSound: true,
  );

  // Hatırlatıcı ID şemasının (ReminderConfig, 100_000_000+) dışında sabit ID'ler.
  static const int _idInactivity3 = 90001;
  static const int _idInactivity7 = 90002;
  static const int _idWeekly = 90003;

  NotificationService get _notifications => NotificationService.instance;

  /// Plugin ve kanallar [NotificationService.init] ile kurulur (tekrar
  /// çağrılması güvenli); geriye dönük uyumluluk için korunur.
  Future<void> init() => _notifications.init();

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Açılışta çağır: hareketsizlik sayacını sıfırla + haftalık özeti garanti et.
  ///
  /// Bildirim kurulumu kritik değildir: herhangi bir adım başarısız olursa
  /// (örn. exact alarm izni yok) sessizce yutulur ki uygulama açılışı (splash)
  /// asla bloke olmasın.
  Future<void> scheduleAll() async {
    // Gerçek exact-alarm iznini öğren ki doğru mod seçilsin.
    await AlarmPolicy.instance.refresh();
    await bumpInactivityReminders();
    await scheduleWeeklySummary();
  }

  /// Hareketsizlik dürtülerini bugünden ileriye yeniden kurar (önce iptal eder).
  /// Kullanıcı 3 (veya 7) gün boyunca uygulamayı açmazsa tetiklenir.
  Future<void> bumpInactivityReminders() async {
    await _notifications.cancel(_idInactivity3);
    await _notifications.cancel(_idInactivity7);

    final now = tz.TZDateTime.now(tz.local);

    await _schedule(
      _idInactivity3,
      'We miss you & your little one 🐾',
      "Log today's feeds, sleep & diapers in seconds — and ask Mia anything.",
      atHourAfterDays(now, days: 3, hour: 11),
    );

    await _schedule(
      _idInactivity7,
      "Your baby's tracker is waiting 😺",
      'A quick tap keeps your logs and weekly reports up to date.',
      atHourAfterDays(now, days: 7, hour: 11),
    );
  }

  /// Haftalık özet dürtüsü (Pazar 19:00, her hafta tekrar).
  Future<void> scheduleWeeklySummary() async {
    await _schedule(
      _idWeekly,
      'Your weekly baby summary is ready 📊',
      "See this week's sleep, feeding & diaper trends.",
      nextInstanceOf(weekday: DateTime.sunday, hour: 19, minute: 0),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when, {
    DateTimeComponents? matchDateTimeComponents,
  }) {
    return _notifications.safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      details: _details,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: AppRoutes.myBaby,
    );
  }
}

final ReEngagementService reEngagementService = ReEngagementService.instance;
