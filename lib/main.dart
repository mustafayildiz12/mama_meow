import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mama_meow/constants/app_pages.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/app_init_service.dart';

Future<void> main() async {
 
  await AppInitService.initApp();
  runMyApp();
}

void runMyApp() {
  return runApp(
    GetMaterialApp(
      title: 'Mama Meow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppRoutes.initialRoute,
      getPages: AppPages.pages,
    ),
  );
}
