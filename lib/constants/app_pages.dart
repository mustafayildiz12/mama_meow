import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/args/display_podcast_args.dart';
import 'package:mama_meow/screens/navigationbar/bottom_nav_bar.dart';
import 'package:mama_meow/screens/navigationbar/learn/display_podcast.dart';

import 'package:mama_meow/service/authentication_service.dart';
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
  initialLocation: AppRoutes.initialRoute,
  redirect: (context, state) {
    final user = authenticationService.getUser();
    final loggedIn = user != null;

    final loc = state.matchedLocation;

    final isAuthFree =
        loc == AppRoutes.initialRoute ||
        loc == AppRoutes.loginPage ||
        loc == AppRoutes.registerPage;

    // Giriş yoksa ve auth-free değilse -> getStarted
    if (!loggedIn && !isAuthFree) {
      return AppRoutes.getStartedPage;
    }

    // Giriş varsa ve auth-free sayfalardaysa -> default tab
    if (loggedIn && isAuthFree) {
      return AppRoutes.askMeow;
    }

    return null;
  },

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
        // 0) Ask Meow
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

        // 1) My Baby
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.myBaby,
              name: 'myBaby',
              builder: (context, state) => const MyBabyScreen(),
              routes: [
                // Detay sayfa pattern
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
