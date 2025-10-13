// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/get-started/modals/terms_and_policy_modal.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -20,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.pink100,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background with animated circles (simplified)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.pink100, // pink-100
                  AppColors.purple50, // purple-50
                  AppColors.blue100,
                ],
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cat face placeholder (replace with custom painting/image)
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.pink200, AppColors.pink300],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: const Center(
                      child: Text('😺', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MamaMeow',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [AppColors.pink500, AppColors.purple500],
                      ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Your Cattiest Mom's AI Companion 🐾",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: AppColors.pink400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    shadowColor: Colors.pinkAccent,
                    elevation: 8,
                  ),
                  onPressed: () async {
                    bool isTermsAccepted = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const TermsAndPrivacyModal(),
                    );

                    if (isTermsAccepted) {
                      await infoStorage.write("getStarted", true);
                      await Navigator.pushNamed(context, AppRoutes.loginPage);
                    }
                  },
                  child: const Text(
                    "Get Started 😸",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Version 1.0 - Made with ❤️ for families",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void launchUrl(String url) {
    // You can use url_launcher or another package
    debugPrint('Launching: \$url');
  }
}
