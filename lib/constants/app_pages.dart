import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/args/display_podcast_args.dart';
import 'package:mama_meow/screens/navigationbar/bottom_nav_bar.dart';
import 'package:mama_meow/screens/navigationbar/learn/display_podcast.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_reminder_manager_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/diaper_report_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_reminders_manager_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_report_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/nursing_report_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/reminder_manager_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_reminders_manager_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/sleep_reminder_manager_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/sleep_report_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_reminder_manager_page.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/solid_report_page.dart';


import 'package:mama_meow/constants/app_routes.dart';

// Screens
import 'package:mama_meow/screens/get-started/get_started.dart';
import 'package:mama_meow/screens/auth/login_screen.dart';
import 'package:mama_meow/screens/auth/register_screen.dart';
import 'package:mama_meow/screens/premium/premium_paywall.dart';
import 'package:mama_meow/screens/auth/admin_update_page.dart';

// Tab screens
import 'package:mama_meow/screens/navigationbar/home/home_screen.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/my_baby_screen.dart';
import 'package:mama_meow/screens/navigationbar/learn/learn_screen.dart';
import 'package:mama_meow/screens/navigationbar/profile/profile_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.myBaby,
  // Redirect logic removed to allow guest access
  
  routes: [
    /// AUTH ÖNCESİ (public)
    GoRoute(
      path: AppRoutes.getStartedPage,
      name: 'getStarted',
      builder: (context, state) => const GetStartedPage(),
    ),
    GoRoute(
      path: AppRoutes.loginPage,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerPage,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),

    /// AUTH SONRASI: BottomNav (StatefulShellRoute)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 0) My Baby (Moved to first position)
        

        // 1) Ask Meow
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.askMeow,
              name: 'askMeow',
              builder: (context, state) => const AskMeowView(),
              routes: [
                // Detay sayfa pattern (şimdilik örnek)
                // GoRoute(
                //   path: 'detail/:id',
                //   name: 'askMeowDetail',
                //   builder: (context, state) {
                //     final id = state.pathParameters['id']!;
                //     return AskMeowDetailPage(id: id);
                //   },
                // ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myBaby,
              name: 'myBaby',
              builder: (context, state) => const MyBabyScreen(),
              routes: [
                GoRoute(
                  path: AppRoutes.nursingReport,
                  name: 'nursingReport',
                  builder: (context, state) => const NursingReportPage(),
                ),
                GoRoute(
                  path: AppRoutes.solidReport,
                  name: 'solidReport',
                  builder: (context, state) => const SolidReportPage(),
                ),
                GoRoute(
                  path: AppRoutes.sleepReport,
                  name: 'sleepReport',
                  builder: (context, state) => const SleepReportPage(),
                ),
                GoRoute(
                  path: AppRoutes.diaperReport,
                  name: 'diaperReport',
                  builder: (context, state) => const DiaperReportPage(),
                ),
                GoRoute(
                  path: AppRoutes.pumpingReport,
                  name: 'pumpingReport',
                  builder: (context, state) => const PumpingReportPage(),
                ),
                GoRoute(
                  path: AppRoutes.medicineReport,
                  name: 'medicineReport',
                  builder: (context, state) => const MedicineReportPage(),
                ),

                GoRoute(
                  path: AppRoutes.diaperReminders,
                  name: 'diaperReminders',
                  builder: (context, state) =>
                      const DiaperRemindersManagerPage(),
                ),
                GoRoute(
                  path: AppRoutes.medicineReminders,
                  name: 'medicineReminders',
                  builder: (context, state) =>
                      const MedicineRemindersManagerPage(),
                ),
                GoRoute(
                  path: AppRoutes.nursingReminders,
                  name: 'nursingReminders',
                  builder: (context, state) =>
                      const NursingRemindersManagerPage(),
                ),
                GoRoute(
                  path: AppRoutes.pumpingReminders,
                  name: 'pumpingReminders',
                  builder: (context, state) =>
                      const PumpingRemindersManagerPage(),
                ),
                GoRoute(
                  path: AppRoutes.sleepReminders,
                  name: 'sleepReminders',
                  builder: (context, state) =>
                      const SleepRemindersManagerPage(),
                ),
                GoRoute(
                  path: AppRoutes.solidReminders,
                  name: 'solidReminders',
                  builder: (context, state) =>
                      const SolidRemindersManagerPage(),
                ),
              ],
            ),
          ],
        ),

        // 2) Learn
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.learn,
              name: 'learn',
              builder: (context, state) => const LearnPage(),
              routes: [
                GoRoute(
                  path: 'podcast',
                  name: 'podcastDetail',
                  builder: (context, state) {
                    final args = state.extra! as DisplayPodcastArgs;
                    return DisplayPodcastPage(
                      podcast: args.podcast,
                      podcastList: args.podcastList,
                      currentIndex: args.currentIndex,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // 3) Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                // Detay sayfa pattern
              ],
            ),
          ],
        ),
      ],
    ),

    /// Shell dışı sayfalar (auth sonrası genelde modal/standalone)
    GoRoute(
      path: AppRoutes.premiumPaywall,
      name: 'premiumPaywall',
      builder: (context, state) => const PremiumPaywall(),
    ),
    GoRoute(
      path: AppRoutes.adminUpdate,
      name: 'adminUpdate',
      builder: (context, state) => const AdminUpdatePage(),
    ),
  ],
);
