import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/firebase_options.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/service/motification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppInitService {
  static Future<void> initApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await init();
    await initPurchase();
    await initRoute();
    await initNotification();
    _initSetSystemUIOverlayStyle();
  }

  static Future<void> initNotification() async {
    await requestAndroidNotificationPermission();

    // 1) TZ veritabanını yükle
    tz.initializeTimeZones(); // 2025b IANA veritabanı dâhil. :contentReference[oaicite:2]{index=2}

    // 2) Cihazın timezone adını al (örn. "Europe/Istanbul")
    String timeZoneName = "UTC";
    try {
      var xx = await FlutterTimezone.getLocalTimezone();
      timeZoneName = xx.identifier;
    } catch (_) {
      timeZoneName = 'UTC'; // güvenli geri dönüş
    }
    print("Timezone: $timeZoneName");

    // 3) Yerel lokasyonu ayarla
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Notifications
    await NotificationService.instance.init();
  }

  static Future<void> requestAndroidNotificationPermission() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static void _initSetSystemUIOverlayStyle() {
    // İçerik status/nav barın arkasına uzansın:
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  static initPurchase() async {
    final iap = InAppPurchaseService();
    await iap.initPlatformState(); // ÖNEMLİ: await
  }

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Gerekli servislerin başlatılması
    await Future.wait([GetStorage.init("local"), GetStorage.init("info")]);

    applicationVersion = await globalFunctions.getApplicationVersionNumber();
    deviceInfo = await globalFunctions.getDeviceVersionFunction();
  }

  static Future<void> initRoute() async {
    final User? user = authenticationService.getUser();

    if (user != null) {
      final bool isUserExist = await databaseService
          .getAdminBasicInfoFromRealTime(user.uid);

      if (isUserExist) {
        InAppPurchaseService iap = InAppPurchaseService();
        bool isUserPremium = iap.checkUserHaveProduct() || await iap.isTrial();
        if (isUserPremium) {
          AppRoutes.initialRoute = AppRoutes.navigationBarPage;
        } else {
          AppRoutes.initialRoute = AppRoutes.navigationBarPage;
        }
      }
    } else {
      bool? getStarted = infoStorage.read("getStarted");
      if (getStarted != null) {
        AppRoutes.initialRoute = AppRoutes.loginPage;
      } else {
        AppRoutes.initialRoute = AppRoutes.getStartedPage;
      }
    }
  }

  void checkIsTrial() {
    int? trialCount = infoStorage.read("trialCount");
    if (trialCount == null) {
      isTrial = true;
    } else if (trialCount < 4) {
      isTrial = true;
    }
  }
}
