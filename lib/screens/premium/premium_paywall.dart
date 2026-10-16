import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_visuals.dart';
import 'package:mama_meow/screens/premium/widgets/feature_carousel.dart';
import 'package:mama_meow/screens/premium/widgets/legal_footer.dart';
import 'package:mama_meow/screens/premium/widgets/package_card.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Premium satın alma ekranı. Satın alma veya geri yükleme sonrası premium
/// aktifse `true` ile kapanır.
class PremiumPaywall extends StatefulWidget {
  const PremiumPaywall({super.key});

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.cosyIvory,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static const _loadErrorMessage =
      "Subscription plans couldn't be loaded. Please check your connection and try again.";

  static const List<PaywallFeature> _features = [
    PaywallFeature(
      icon: Icons.child_care_outlined,
      title: "Complete Baby Tracking",
      advantages: ["Feeding & sleep logs", "Diaper & medicine tracking"],
    ),
    PaywallFeature(
      icon: Icons.headphones_outlined,
      title: "Expert Podcast Library",
      advantages: ["Summarized parenting books", "Expert interview series"],
    ),
    PaywallFeature(
      icon: Icons.auto_awesome_outlined,
      title: "AI-Powered Assistant",
      advantages: ["24/7 smart Q&A support", "Personalized recommendations"],
    ),
  ];

  final InAppPurchaseService _iap = InAppPurchaseService();

  PremiumType _selectedType = PremiumType.yearly;
  bool _loading = true;
  String? _error;
  bool _purchasing = false;
  bool _restoring = false;

  Package? _monthlyPackage;
  Package? _yearlyPackage;

  bool get _busy => _purchasing || _restoring;

  Package? get _selectedPackage =>
      _selectedType == PremiumType.monthly ? _monthlyPackage : _yearlyPackage;

  @override
  void initState() {
    super.initState();
    analyticService.screenView('paywall_screen');
    analyticService.paywallShown(source: 'feature_gate');
    _loadOfferings();
  }

  @override
  Widget build(BuildContext context) {
    final infoReady = !_loading && _error == null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.cosyIvory,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: _buildTopBar(),
              ),
              Expanded(child: _buildBody()),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: PaywallLegalFooter(
                  onAboutSubscriptions: infoReady
                      ? _showSubscriptionInfo
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Geri yükleme her durumda (yükleme hatasında da) erişilebilir.
        TextButton(
          onPressed: _busy ? null : _restore,
          child: _restoring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Restore'),
        ),
        CircleCloseButton(onPressed: _purchasing ? null : () => _close()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final textTheme = Theme.of(context).textTheme;

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.charcoalSoft,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryPillButton(label: "Try Again", onPressed: _loadOfferings),
            ],
          ),
        ),
      );
    }

    final cta = _ctaText();
    final priceNote = cta.priceNote;
    const captionStyle = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      color: AppColors.charcoalSoft,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: MascotCircle(size: MascotCircle.sizeFor(context))),
          const SizedBox(height: 16),
          const Center(child: _AudienceBadge()),
          const SizedBox(height: 12),
          Text(
            "Unlock Premium Features",
            textAlign: TextAlign.center,
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          Text(
            "Calmer days, smarter nights.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.charcoalSoft),
          ),
          const SizedBox(height: 24),
          const PaywallFeatureList(features: _features),

          // Rozet kartın üst kenarından taştığı için ek boşluk.
          const SizedBox(height: 36),
          _buildPlans(),

          const SizedBox(height: 24),
          Semantics(
            hint: priceNote,
            child: PrimaryPillButton(
              label: cta.label,
              icon: Icons.arrow_forward,
              loading: _purchasing,
              onPressed: (_selectedPackage == null || _busy)
                  ? null
                  : _purchaseSelected,
            ),
          ),

          const SizedBox(height: 14),
          if (priceNote != null) ...[
            Text(
              priceNote,
              textAlign: TextAlign.center,
              style: captionStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.deepCharcoal,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            _renewalNotice,
            textAlign: TextAlign.center,
            style: captionStyle,
          ),
        ],
      ),
    );
  }

  /// Paket kartları: sığarsa yan yana (eşit yükseklik), dar ekranda veya
  /// büyük yazı ölçeğinde alt alta.
  Widget _buildPlans() {
    final yearly = _yearlyPackage;
    final monthly = _monthlyPackage;
    final cards = <Widget>[
      if (yearly != null) _packageCard(yearly, PremiumType.yearly),
      if (monthly != null) _packageCard(monthly, PremiumType.monthly),
    ];
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            cards.length == 2 &&
            constraints.maxWidth >= 320 &&
            textScale <= 1.3;
        if (sideBySide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 24),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  void _showSubscriptionInfo() {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _InfoDialog(monthly: _monthlyPackage, yearly: _yearlyPackage),
    );
  }

  Widget _packageCard(Package package, PremiumType type) {
    return PaywallPackageCard(
      type: type,
      package: package,
      trialDays: _iap.getTrialDays(package),
      selected: _selectedType == type,
      onSelected: _busy ? null : (t) => setState(() => _selectedType = t),
    );
  }

  /// Platforma göre abonelik iptal bilgisi.
  static String get _renewalNotice {
    final where = PlatformInfo.isIOS
        ? "your App Store account settings"
        : PlatformInfo.isAndroid
        ? "Google Play > Payments & subscriptions"
        : "your app store account settings";
    return "Auto-renewing subscription. Cancel anytime in $where. "
        "To avoid charges, cancel before the trial ends.";
  }

  /// Paywall'ı kapatır; altında sayfa yoksa (derin bağlantı) uygulamaya döner.
  void _close([bool? result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.goNamed('myBaby');
    }
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final offering = await _iap.loadOfferings();

      // Paketleri tipine göre ayır
      Package? monthly;
      Package? yearly;
      for (final package in offering?.availablePackages ?? const <Package>[]) {
        switch (_iap.getPackageType(package)) {
          case 'monthly':
            monthly = package;
          case 'yearly':
            yearly = package;
        }
      }

      if (!mounted) return;
      setState(() {
        _monthlyPackage = monthly;
        _yearlyPackage = yearly;
        if (monthly == null && yearly == null) {
          _error = _loadErrorMessage;
        } else {
          // Varsayılan: yıllık (yoksa aylık)
          _selectedType = yearly != null
              ? PremiumType.yearly
              : PremiumType.monthly;
        }
      });
    } catch (e) {
      debugPrint('loadOfferings failed: $e');
      if (mounted) setState(() => _error = _loadErrorMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchaseSelected() async {
    final package = _selectedPackage;
    if (_busy) return;
    if (package == null) {
      customSnackBar.error("No product selected");
      return;
    }

    setState(() => _purchasing = true);
    var isSuccess = false;
    try {
      isSuccess = await _iap.purchasePackage(package);
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
    if (isSuccess && mounted) _close(true);
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _restoring = true);
    var isPremium = false;
    try {
      // Sonuç snackbar'ını servis gösterir.
      isPremium = await _iap.restorePurchases();
    } catch (e) {
      debugPrint('restorePurchases failed: $e');
      customSnackBar.error("Restore failed. Please try again.");
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
    if (isPremium && mounted) _close(true);
  }

  /// Satın alma düğmesinin metni. Deneme varsa `Then <fiyat> / <dönem>`
  /// kısmı tek satırlık hap düğmede kesilmesin diye düğmenin hemen altında
  /// [priceNote] olarak gösterilir.
  ({String label, String? priceNote}) _ctaText() {
    final p = _selectedPackage;
    if (p == null) return (label: "Subscribe", priceNote: null);
    final price = p.storeProduct.priceString;
    final freq = _selectedType == PremiumType.monthly ? "month" : "year";
    final trialDays = _iap.getTrialDays(p);

    if (trialDays != null && trialDays != "0") {
      return (
        label: "Start $trialDays-day free trial",
        priceNote: "Then $price / $freq",
      );
    }
    return (label: "Subscribe for $price / $freq", priceNote: null);
  }
}

/// "For tired parents" beyaz hap rozeti (berry kalp ikonlu).
class _AudienceBadge extends StatelessWidget {
  const _AudienceBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: ShapeDecoration(
        color: AppColors.cottonWhite,
        shape: StadiumBorder(side: BorderSide(color: AppColors.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 16, color: AppColors.activeBerry),
            SizedBox(width: 6),
            Text(
              "For tired parents",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.deepCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  final Package? monthly;
  final Package? yearly;
  const _InfoDialog({this.monthly, this.yearly});

  @override
  Widget build(BuildContext context) {
    String lineFor(Package? p, String name) {
      if (p == null) return "";
      final price = p.storeProduct.priceString;
      final freq = (name == "Monthly") ? "month" : "year";
      final trialDays = InAppPurchaseService().getTrialDays(p);
      final trial = (trialDays != null && trialDays != "0")
          ? " • Includes a $trialDays-day free trial."
          : "";
      return "• $name plan: $price per $freq$trial";
    }

    final manageWhere = PlatformInfo.isIOS
        ? "in your App Store account settings"
        : PlatformInfo.isAndroid
        ? "in the Google Play Subscription Center"
        : "in your app store account settings";

    return AlertDialog(
      title: const Text("About Subscription"),
      content: SingleChildScrollView(
        child: Text(
          [
            "Subscriptions automatically renew unless canceled at least 24 hours before the current period ends.",
            lineFor(monthly, "Monthly"),
            lineFor(yearly, "Yearly"),
            "You can manage or cancel your subscription anytime $manageWhere.",
          ].where((e) => e.isNotEmpty).join("\n\n"),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
