import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/premium/widgets/feature_carousel.dart';
import 'package:mama_meow/screens/premium/widgets/legal_footer.dart';
import 'package:mama_meow/screens/premium/widgets/package_card.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
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
    statusBarColor: Color(0xFFfbe7f3),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static const _loadErrorMessage =
      "Subscription plans couldn't be loaded. Please check your connection and try again.";

  static const List<PaywallFeature> _features = [
    PaywallFeature(
      icon: "👩‍🍼",
      title: "Complete Baby Tracking",
      advantages: ["Feeding & Sleep Logs", "Diaper & Medicine Tracking"],
    ),
    PaywallFeature(
      icon: "🎧",
      title: "Expert Podcast Library",
      advantages: ["Summarized Parenting Books", "Expert Interview Series"],
    ),
    PaywallFeature(
      icon: "🚀",
      title: "AI-Powered Assistant",
      advantages: ["24/7 Smart Q&A Support", "Personalized Recommendations"],
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [Color(0xFFfdf5fd), Color(0xFFfbe7f3)],
                stops: [0.1, 0.4],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black12)],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildBody()),
                  const PaywallLegalFooter(),
                ],
              ),
            ),
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
              : const Text(
                  'Restore',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
        ),
        CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            tooltip: 'Close',
            icon: const Icon(CupertinoIcons.clear, color: Colors.black87),
            onPressed: _purchasing ? null : () => _close(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _loadOfferings,
              child: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    final yearly = _yearlyPackage;
    final monthly = _monthlyPackage;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Center(
            child: Text(
              "Unlock Premium Features",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Color(0xFFf15a5f),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const PaywallFeatureCarousel(features: _features),
          const SizedBox(height: 24),

          RadioGroup<PremiumType>(
            groupValue: _selectedType,
            onChanged: (type) {
              if (type != null && !_busy) setState(() => _selectedType = type);
            },
            child: Column(
              children: [
                if (yearly != null) ...[
                  _packageCard(yearly, PremiumType.yearly),
                  const SizedBox(height: 16),
                ],
                if (monthly != null) ...[
                  _packageCard(monthly, PremiumType.monthly),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SubscribeButton(
            label: _buttonText(),
            loading: _purchasing,
            onPressed: (_selectedPackage == null || _busy)
                ? null
                : _purchaseSelected,
          ),

          const SizedBox(height: 18),
          Text(
            _renewalNotice,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              height: 1.3,
            ),
          ),

          Center(
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _InfoDialog(monthly: monthly, yearly: yearly),
              ),
              child: const Text(
                "About Subscriptions",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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

  String _buttonText() {
    final p = _selectedPackage;
    if (p == null) return "Subscribe";
    final price = p.storeProduct.priceString;
    final freq = _selectedType == PremiumType.monthly ? "month" : "year";
    final trialDays = _iap.getTrialDays(p);

    if (trialDays != null && trialDays != "0") {
      return "Start $trialDays-day free trial • Then $price / $freq";
    }
    return "Subscribe for $price / $freq";
  }
}

/// Gradyanlı ana satın alma düğmesi; işlem sürerken spinner gösterir.
class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled || loading ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.pink500, Colors.pink],
              ),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 52,
                  minWidth: double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
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
