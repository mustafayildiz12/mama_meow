import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/auth/login_screen.dart';
import 'package:mama_meow/screens/auth/register_screen.dart';
import 'package:mama_meow/screens/get-started/get_started.dart';
import 'package:mama_meow/screens/navigationbar/bottom_nav_bar.dart';
import 'package:mama_meow/screens/podcast/podcast_form_page.dart';
import 'package:mama_meow/screens/premium/premium_paywall.dart';

class AppPages {
  static List<GetPage<dynamic>>? pages = [
    GetPage(name: AppRoutes.getStartedPage, page: () => const GetStartedPage()),
    GetPage(name: AppRoutes.loginPage, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.registerPage, page: () => const RegisterPage()),

    GetPage(
      name: AppRoutes.navigationBarPage,
      page: () => const BottomNavBarScreen(),
    ),
    GetPage(
      name: AppRoutes.uploadPodcastPage,
      page: () => const PodcastFormPage(),
    ),
    GetPage(name: AppRoutes.premiumPaywall, page: () => const PremiumPaywall()),
  ];
}
