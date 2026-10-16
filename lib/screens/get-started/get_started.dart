import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/get-started/modals/terms_and_policy_modal.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

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
      icon: Icons.child_care_rounded,
      title: 'Track every moment',
      subtitle:
          'Log feeding, sleep, diapers, pumping & medicine in just a few taps.',
    ),
    _ValueSlide(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Ask Meow, anytime',
      subtitle:
          'Get instant, personalized parenting answers from your AI companion — 24/7.',
    ),
    _ValueSlide(
      icon: Icons.insights_rounded,
      title: 'Insights & learning',
      subtitle:
          'Beautiful weekly reports plus an expert parenting podcast library.',
    ),
  ];

  // Toplam sayfa: 1 hero + değer slaytları.
  int get _pageCount => _slides.length + 1;
  bool get _isLastPage => _page == _pageCount - 1;

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.cosyIvory,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    analyticService.screenView('get_started_screen');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -20,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.cosyIvory,
        body: SafeArea(
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
                    child: const Text("Skip"),
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
                      color: active
                          ? AppColors.activeBerry
                          : AppColors.warmPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: PrimaryPillButton(
                  label: _isLastPage ? "Get Started" : "Next",
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _onNext,
                ),
              ),
              const SizedBox(height: 12),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Made with "),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: AppColors.activeBerry,
                        semanticLabel: 'love',
                      ),
                    ),
                    TextSpan(text: " for families"),
                  ],
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoalSoft,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
            child: const _SlideBadge(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Image(
                  image: AssetImage("assets/happy.png"),
                  color: AppColors.activeBerry,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Coo Care Baby Tracker',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              height: 38 / 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.deepCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your Cattiest Mom's AI Companion",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.charcoalSoft),
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
          _SlideBadge(
            child: Icon(slide.icon, size: 56, color: AppColors.activeBerry),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              height: 30 / 24,
              fontWeight: FontWeight.w800,
              color: AppColors.deepCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              color: AppColors.charcoalSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slayt görseli: şeftali halkalı pembe daire.
class _SlideBadge extends StatelessWidget {
  const _SlideBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.peachPastel, width: 4),
      ),
      child: child,
    );
  }
}

/// Onboarding değer slaytı verisi.
class _ValueSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ValueSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
