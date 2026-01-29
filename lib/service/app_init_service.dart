import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
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

    tz.initializeTimeZones();

    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();

      // ✅ IANA id: "Europe/Istanbul"
      tz.setLocalLocation(tz.getLocation(info.identifier));

      print("🌍 Timezone identifier: ${info.identifier}");
      print(
        "🌍 Timezone localized: ${info.localizedName?.name} (${info.localizedName?.locale})",
      );
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      print("⚠️ Timezone fallback to UTC: $e");
    }

    // Notifications
    await NotificationService.instance.init();
  }

  static Future<void> requestAndroidNotificationPermission() async {
    if (!Platform.isAndroid) return;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // ✅ Sadece Android 13+ (API 33) runtime permission ister
    if (sdkInt < 33) return;

    try {
      final fln = FlutterLocalNotificationsPlugin();
      await fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      // burada crash olmasın, logla geç
      // debugPrint("Notif permission request failed: $e");
    }
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
