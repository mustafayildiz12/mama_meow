import 'package:mama_meow/constants/app_constants.dart';

class AlarmPermissionPrefs {
  static const _kAskedOnce = 'exact_alarm_asked_once';

  static Future<bool> get askedOnce async {
    return infoStorage.read(_kAskedOnce) ?? false;
  }

  static Future<void> markAskedOnce() async {
    await infoStorage.write(_kAskedOnce, true);
  }

  static Future<void> reset() async {
    await infoStorage.remove(_kAskedOnce);
  }
}
