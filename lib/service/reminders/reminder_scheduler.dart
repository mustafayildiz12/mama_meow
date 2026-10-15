import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/models/reminders/reminder_item.dart';
import 'package:mama_meow/service/motification_service.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';
import 'package:mama_meow/service/reminders/reminder_store.dart';
import 'package:mama_meow/service/reminders/schedule_time.dart';

/// Tüm kategorilerin hatırlatıcı bildirimlerini kurar / iptal eder.
///
/// Plugin'i başlatmaz (bkz. [NotificationService.init]). İşlemler sırayla
/// çalışır; böylece sayfa açılışındaki reapply ile ekleme/düzenleme yarışmaz.
/// Hiçbir public metot hata fırlatmaz (bildirim opsiyoneldir).
class ReminderScheduler {
  ReminderScheduler._();
  static final ReminderScheduler instance = ReminderScheduler._();

  static const String _kMigratedKey = 'reminders_notification_ids_v2';

  Future<void> _queue = Future<void>.value();

  Future<void> _serial(String label, Future<void> Function() op) {
    final result = _queue.then((_) => op()).catchError((Object e) {
      debugPrint('ReminderScheduler.$label failed: $e');
    });
    _queue = result;
    return result;
  }

  /// [item]'ın önceki tüm bildirimlerini (yeni + eski şema) iptal eder; item
  /// etkinse yeniden kurar. Düzenleme sonrası da bunu çağırın.
  Future<void> scheduleItem(ReminderCategory category, ReminderItem item) =>
      _serial('scheduleItem', () async {
        await AlarmPolicy.instance.refresh();
        await _cancel(category.config, item);
        await _schedule(category.config, item);
      });

  Future<void> cancelItem(ReminderCategory category, ReminderItem item) =>
      _serial('cancelItem', () => _cancel(category.config, item));

  /// Kategorinin tüm bildirimlerini [items]'a göre baştan kurar.
  Future<void> reapply(ReminderCategory category, List<ReminderItem> items) =>
      _serial('reapply', () async {
        await AlarmPolicy.instance.refresh();
        await _reapply(category.config, items);
      });

  /// Tüm kategorileri kayıtlı listelerinden yeniden kurar (ör. exact-alarm
  /// izni değiştiğinde).
  Future<void> reapplyAllCategories() =>
      _serial('reapplyAllCategories', _reapplyAll);

  /// Eski ID şemasındaki OS kayıtlarını iptal edip tüm hatırlatıcıları yeni
  /// şemayla kurar; cihaz başına bir kez çalışır.
  Future<void> migrateLegacyIfNeeded() => _serial('migrate', () async {
    if (!NotificationService.instance.isSupported) return;
    if (infoStorage.read(_kMigratedKey) == true) return;
    await _reapplyAll();
    await infoStorage.write(_kMigratedKey, true);
  });

  /// Tüm kategorilerin bildirimlerini iptal eder ve listeleri siler.
  Future<void> cancelAndClearAll() => _serial('cancelAndClearAll', () async {
    for (final category in ReminderCategory.values) {
      final store = ReminderStore.of(category);
      for (final item in await store.loadAll()) {
        await _cancel(category.config, item);
      }
      await store.clear();
    }
    // Listede olmayan (bozuk kayıt vb.) artıkları da temizle.
    for (final id in await NotificationService.instance.pendingIds()) {
      if (ReminderConfig.isReminderNotificationId(id)) {
        await NotificationService.instance.cancel(id);
      }
    }
  });

  Future<void> _reapplyAll() async {
    await AlarmPolicy.instance.refresh(reapplyOnChange: false);
    for (final category in ReminderCategory.values) {
      final items = await ReminderStore.of(category).loadAll();
      await _reapply(category.config, items);
    }
  }

  Future<void> _reapply(ReminderConfig config, List<ReminderItem> items) async {
    // Önce hepsinin slotlarını temizle (iOS'ta 64 bekleyen bildirim limiti),
    // sonra sadece etkin olanları kur.
    for (final it in items) {
      await _cancel(config, it);
    }
    for (final it in items) {
      await _schedule(config, it);
    }
  }

  Future<void> _schedule(ReminderConfig config, ReminderItem item) async {
    if (!item.isActive) return;
    if (item.reminderId > ReminderConfig.maxReminderId) {
      debugPrint('Reminder id ${item.reminderId} out of range, skipped');
      return;
    }
    final details = _details(config);
    final hour = item.timeOfDay.hour;
    final minute = item.timeOfDay.minute;
    final body = config.notificationBody(item.timeOfDay);

    if (item.isDaily) {
      await NotificationService.instance.safeZonedSchedule(
        id: config.notificationId(item.reminderId, 0),
        title: config.notificationTitle,
        body: body,
        scheduledDate: nextInstanceOf(hour: hour, minute: minute),
        details: details,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: AppRoutes.myBaby,
      );
      return;
    }

    for (final day in item.sortedWeekdays) {
      await NotificationService.instance.safeZonedSchedule(
        id: config.notificationId(item.reminderId, day),
        title: config.notificationTitle,
        body: body,
        scheduledDate: nextInstanceOf(hour: hour, minute: minute, weekday: day),
        details: details,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: AppRoutes.myBaby,
      );
    }
  }

  Future<void> _cancel(ReminderConfig config, ReminderItem item) async {
    final notifications = NotificationService.instance;
    if (item.reminderId <= ReminderConfig.maxReminderId) {
      for (var slot = 0; slot <= 7; slot++) {
        await notifications.cancel(
          config.notificationId(item.reminderId, slot),
        );
      }
    }
    for (var day = 1; day <= 7; day++) {
      await notifications.cancel(
        config.legacyNotificationId(item.reminderId, day),
      );
    }
  }

  NotificationDetails _details(ReminderConfig config) => NotificationDetails(
    android: AndroidNotificationDetails(
      config.channelId,
      config.channelName,
      channelDescription: config.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: const DarwinNotificationDetails(),
  );
}

final ReminderScheduler reminderScheduler = ReminderScheduler.instance;
