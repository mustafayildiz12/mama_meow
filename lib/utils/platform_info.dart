import 'package:flutter/foundation.dart';

/// Platform kontrolleri için tek nokta.
///
/// `dart:io` `Platform.isX` web hedefinde `UnsupportedError` fırlatır ve
/// `get` paketinin `GetPlatform`'u projede doğrudan bağımlılık değildir;
/// ikisinin yerine bunu kullanın.
abstract final class PlatformInfo {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
