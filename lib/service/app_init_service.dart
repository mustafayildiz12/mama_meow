import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/firebase_options.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/service/motification_service.dart';
import 'package:mama_meow/service/re_engagement_service.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppInitService {
  /// `runApp`'tan önce çalışması gerekenler. Native splash bunları beklediği
  /// için kısa tutulur; ağ beklemesi olan adımlar zaman aşımına bağlıdır.
  static Future<void> initApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initCrashlytics();
    // RTDB'ye herhangi bir erişimden önce çağrılmalı; aksi halde eklenti
    // ayarı sessizce yok sayar.
    _initDatabasePersistence();

    await Future.wait([GetStorage.init("local"), GetStorage.init("info")]);
    deviceInfo = await globalFunctions.getDeviceVersionFunction();
    await _initTimeZone();

    await InAppPurchaseService().initPlatformState();
    await _restoreSession();
    _initSystemUIOverlayStyle();
  }

  /// İlk kare çizildikten sonra çalışabilecek işler (izin istemleri,
  /// bildirim zamanlamaları, analitik).
  static Future<void> initAfterFirstFrame() async {
    try {
      await _initNotifications();
    } catch (e, st) {
      debugPrint("Notification init failed: $e");
      _recordNonFatal(e, st, 'notification init');
    }
    await analyticService.appOpen();
  }

  static void _initCrashlytics() {
    if (kIsWeb) return; // Crashlytics web'i desteklemiyor.
    final crashlytics = FirebaseCrashlytics.instance;
    crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.presentError(details);
      crashlytics.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static void _initDatabasePersistence() {
    if (kIsWeb) return;
    final db = FirebaseDatabase.instance;
    db.setPersistenceEnabled(true);
    db.setPersistenceCacheSizeBytes(50 * 1024 * 1024);
  }

  /// Oturum açıksa kullanıcı profilini, RevenueCat oturumunu ve `appInfo`
  /// yapılandırmasını yükler.
  static Future<void> _restoreSession() async {
    final user = authenticationService.getUser();
    if (user == null) return;
    try {
      await databaseService
          .getAdminBasicInfoFromRealTime(user.uid)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint("Session restore timed out; continuing offline.");
    }
  }

  static Future<void> _initTimeZone() async {
    tz.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e, st) {
      // Yanlış saat diliminde hatırlatıcılar yanlış saatte çalar; görünür olsun.
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      debugPrint("Timezone fallback to UTC: $e");
      _recordNonFatal(e, st, 'timezone fallback');
    }
  }

  static Future<void> _initNotifications() async {
    await _requestAndroidNotificationPermission();
    await NotificationService.instance.init();

    // Geri kazanım dürtüleri: her açılışta hareketsizlik sayacını sıfırla ve
    // haftalık özeti garanti et. Hata açılışı etkilemesin.
    try {
      await reEngagementService.init();
      await reEngagementService.scheduleAll();
    } catch (e) {
      debugPrint("Re-engagement scheduling failed (non-fatal): $e");
    }
  }

  /// Android 13+ (API 33) bildirim izni ister. Eklenti daha eski
  /// sürümlerde izin verilmiş kabul eder.
  static Future<void> _requestAndroidNotificationPermission() async {
    if (!PlatformInfo.isAndroid) return;
    try {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint("Notification permission request failed: $e");
    }
  }

  static void _initSystemUIOverlayStyle() {
    // İçerik status/nav barın arkasına uzansın (navigasyon çubuğu gizlenmez).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  static void _recordNonFatal(Object e, StackTrace st, String reason) {
    if (kIsWeb) return;
    FirebaseCrashlytics.instance.recordError(e, st, reason: reason);
  }
}
