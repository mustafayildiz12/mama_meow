import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/firebase_options.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';

class AppInitService {
  static Future<void> initApp() async {
    await init();
    await initPurchase();
    await initRoute();
  }

  static initPurchase() async {
    final iap = InAppPurchaseService();
    await iap.initPlatformState(); // ÖNEMLİ: await
  }

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Gerekli servislerin başlatılması
    await Future.wait([GetStorage.init("local"), GetStorage.init("info")]);
  }

  static Future<void> initRoute() async {
    final User? user = authenticationService.getUser();

    if (user != null) {
      final bool isUserExist = await databaseService
          .getAdminBasicInfoFromRealTime(user.uid);

      if (isUserExist) {
        bool isUserPremium = InAppPurchaseService().checkUserHaveProduct();
        if (isUserPremium) {
          AppRoutes.initialRoute = AppRoutes.navigationBarPage;
        } else {
          AppRoutes.initialRoute = AppRoutes.navigationBarPage;
        }
      }
    } else {
      bool? getStarted = await infoStorage.read("getStarted");
      if (getStarted != null) {
        AppRoutes.initialRoute = AppRoutes.loginPage;
      } else {
        AppRoutes.initialRoute = AppRoutes.getStartedPage;
      }
    }
  }
}
