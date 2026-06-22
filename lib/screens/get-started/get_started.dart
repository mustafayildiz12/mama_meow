// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/get-started/modals/terms_and_policy_modal.dart';
import 'package:mama_meow/service/analytic_service.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  final PageController _pageController = PageController();
  int _page = 0;

  // Kayıttan önce değeri anlatan tanıtım slaytları.
  static const List<_ValueSlide> _slides = [
    _ValueSlide(
      emoji: '🍼',
      title: 'Track every moment',
      subtitle:
          'Log feeding, sleep, diapers, pumping & medicine in just a few taps.',
    ),
    _ValueSlide(
      emoji: '🤖',
      title: 'Ask Meow, anytime',
      subtitle:
          'Get instant, personalized parenting answers from your AI companion — 24/7.',
    ),
    _ValueSlide(
      emoji: '📊',
      title: 'Insights & learning',
      subtitle:
          'Beautiful weekly reports plus an expert parenting podcast library.',
    ),
  ];

  // Toplam sayfa: 1 hero + değer slaytları.
  int get _pageCount => _slides.length + 1;
  bool get _isLastPage => _page == _pageCount - 1;

  @override
  void initState() {
    analyticService.screenView('get_started_screen');
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startGetStarted() async {
    final bool? isTermsAccepted = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TermsAndPrivacyModal(),
    );

    if (isTermsAccepted == true) {
      await infoStorage.write("getStarted", true);
      if (mounted) context.go(AppRoutes.loginPage);
    }
  }

  void _onNext() {
    if (_isLastPage) {
      _startGetStarted();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Skip -> doğrudan kayıt akışına geç.
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isLastPage ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _isLastPage ? null : _startGetStarted,
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeroPage();
                    return _buildValuePage(_slides[index - 1]);
                  },
                ),
              ),

              // Sayfa noktaları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.pink500 : Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.pink400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      shadowColor: Colors.pinkAccent,
                      elevation: 8,
                    ),
                    onPressed: _onNext,
                    child: Text(
                      _isLastPage ? "Get Started 😸" : "Next",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Made with ❤️ for families",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFBCFE8), Color(0xFFF9A8D4)],
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  "assets/happy.png",
                  color: AppColors.pink500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Coo Care Baby Tracker',
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
        ],
      ),
    );
  }

  Widget _buildValuePage(_ValueSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFBCFE8), Color(0xFFF9A8D4)],
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            alignment: Alignment.center,
            child: Text(slide.emoji, style: const TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.pink500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
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

/// Onboarding değer slaytı verisi.
class _ValueSlide {
  final String emoji;
  final String title;
  final String subtitle;
  const _ValueSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}
