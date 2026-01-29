import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_globals.dart';
import 'package:mama_meow/constants/app_localization.dart';
import 'package:mama_meow/constants/app_pages.dart';
import 'package:mama_meow/service/app_init_service.dart';

Future<void> main() async {
  await AppInitService.initApp();

  if (!kIsWeb) {
    final db = FirebaseDatabase.instance;
    db.setPersistenceEnabled(true);
    db.setPersistenceCacheSizeBytes(50 * 1024 * 1024);
  }

  runMyApp();
}

void runMyApp() {
  return runApp(
    MaterialApp.router(
      title: 'MamaMeow',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Nunito",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      locale: AppLocalization.locale, // Varsayılan dil
      supportedLocales: AppLocalization.supportedLocales,
      localizationsDelegates: AppLocalization.localizationsDelegates,
      routerConfig: router,
    ),
  );
}
