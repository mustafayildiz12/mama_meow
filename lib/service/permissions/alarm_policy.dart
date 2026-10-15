import 'dart:async';

import 'package:mama_meow/service/permissions/alarm_prefs.dart';
import 'package:mama_meow/service/permissions/exact_alarm_permission.dart';
import 'package:mama_meow/service/reminders/reminder_scheduler.dart';

/// Android exact-alarm izninin önbelleklenmiş durumu.
class AlarmPolicy {
  AlarmPolicy._();
  static final AlarmPolicy instance = AlarmPolicy._();

  bool? _canExact;

  /// Henüz okunmadıysa true: exact kurulamazsa zamanlama zaten inexact'e düşer.
  bool get canExact => _canExact ?? true;

  /// İzni platformdan okur. Durum değiştiyse (uygulama kapalıyken değişmiş
  /// olsa bile) tüm hatırlatıcıları yeni moda göre yeniden kurar.
  Future<bool> refresh({bool reapplyOnChange = true}) async {
    final ok = await ExactAlarmPermission.canSchedule();
    if (ok == null) return canExact;

    final previous = _canExact ?? AlarmPermissionPrefs.lastCanExact;
    _canExact = ok;
    if (previous != ok) {
      await AlarmPermissionPrefs.setLastCanExact(ok);
      if (previous != null && reapplyOnChange) {
        unawaited(ReminderScheduler.instance.reapplyAllCategories());
      }
    }
    return ok;
  }

  /// İzin yoksa (yalnızca bir kez) sistem ayarına yönlendirir. Kullanıcı geri
  /// döndüğünde tamamlanır; izin verildiyse [refresh] hatırlatıcıları yeniden
  /// kurar.
  Future<void> ensure() async {
    if (await refresh()) return;

    final alreadyAsked = await AlarmPermissionPrefs.askedOnce;
    if (alreadyAsked) return; // tekrar ayara fırlatma

    await AlarmPermissionPrefs.markAskedOnce();
    await ExactAlarmPermission.request();
    await refresh();
  }
}
