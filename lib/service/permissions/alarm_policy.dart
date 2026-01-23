import 'dart:async';

import 'package:mama_meow/service/permissions/alarm_prefs.dart';
import 'package:mama_meow/service/permissions/exact_alarm_permission.dart';

class AlarmPolicy {
  AlarmPolicy._();
  static final AlarmPolicy instance = AlarmPolicy._();

  bool _canExact = true;
  bool get canExact => _canExact;

  final _ctrl = StreamController<bool>.broadcast();
  Stream<bool> get stream => _ctrl.stream;

  Future<bool> refresh() async {
    final ok = await ExactAlarmPermission.canSchedule();
    if (ok != _canExact) {
      _canExact = ok;
      _ctrl.add(_canExact);
    }
    return _canExact;
  }

  Future<void> ensure() async {
    final ok = await refresh();
    if (ok) return;

    final alreadyAsked = await AlarmPermissionPrefs.askedOnce;
    if (alreadyAsked) return; // 🚫 tekrar ayara fırlatma

    await AlarmPermissionPrefs.markAskedOnce();
    await ExactAlarmPermission.request();
  }
}
