import 'package:mama_meow/constants/app_constants.dart';

class AlarmPermissionPrefs {
  static const _kAskedOnce = 'exact_alarm_asked_once';
  static const _kLastCanExact = 'exact_alarm_last_can_exact';

  static Future<bool> get askedOnce async {
    return infoStorage.read(_kAskedOnce) ?? false;
  }

  static Future<void> markAskedOnce() async {
    await infoStorage.write(_kAskedOnce, true);
  }

  /// Son bilinen exact-alarm izni (uygulama kapalıyken değişti mi diye).
  static bool? get lastCanExact {
    final v = infoStorage.read(_kLastCanExact);
    return v is bool ? v : null;
  }

  static Future<void> setLastCanExact(bool value) async {
    await infoStorage.write(_kLastCanExact, value);
  }
}
