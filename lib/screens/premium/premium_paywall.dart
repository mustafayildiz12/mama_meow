import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum PremiumType { monthly, yearly }

class PremiumPaywall extends StatefulWidget {
  final bool showTrialFirst;
  final String? offeringIdentifier; // Belirli bir offering kullanmak için

  const PremiumPaywall({
    super.key,
    this.showTrialFirst = false,
    this.offeringIdentifier,
  });

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  PremiumType selectedType = PremiumType.monthly;

  final List<_Feature> features = [
    _Feature(
      icon: "👩‍🍼",
      title: "Complete Baby Tracking",
      subtitle:
          "Track every precious moment and milestone in your baby's development",
      advantages: ["Feeding & Sleep Logs", "Diaper & Medicine Tracking"],
    ),
    _Feature(
      icon: "🎧",
      title: "Expert Podcast Library",
      subtitle:
          "Learn from the best parenting exams with curated audio content",
      advantages: ["Summarized Parenting Books", "Expert Interview Series"],
    ),
    _Feature(
      icon: "🚀",
      title: "AI-Powered Asistant",
      subtitle:
          "Get instant answers to all your parenting questions with smart AI technology",
      advantages: ["24/7 Smart Q&A Support", "Personalized Recommendations"],
    ),
  ];

  int pageIndex = 0;

  // Dinamik offering state'i
  final InAppPurchaseService _iap = InAppPurchaseService();
  bool _loading = true;
  String? _error;

  Package? _monthlyPackage;
  Package? _yearlyPackage;

  // StoreProduct? _monthlyProduct;
  //  StoreProduct? _yearlyProduct;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _restore,
                      child: Text(
                        'Refresh',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          CupertinoIcons.clear,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),

                if (_loading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _loadOfferings,
                    child: Text("Try Again"),
                  ),
                ] else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Center(
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

                          // Features – PageView
                          Center(
                            child: Container(
                              height: 192,

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: PageView.builder(
                                itemCount: features.length,
                                onPageChanged: (i) =>
                                    setState(() => pageIndex = i),
                                itemBuilder: (_, i) {
                                  final f = features[i];
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 56,
                                          width: 56,
                                          decoration: BoxDecoration(
                                            color: AppColors.pink400,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            f.icon,
                                            style: TextStyle(fontSize: 32),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Center(
                                          child: Text(
                                            f.title,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: f.advantages.map((e) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Row(
                                                children: [
                                                  Text("✅"),
                                                  SizedBox(width: 8),
                                                  Text(e),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (pageIndex + 1) / features.length,
                                backgroundColor: Colors.pink.shade100,
                                color: AppColors.pink500,
                                minHeight: 6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // YEARLY
                          if (_yearlyPackage != null) ...[
                            _buildPackageCard(
                              _yearlyPackage!,
                              PremiumType.yearly,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // MONTHLY
                          if (_monthlyPackage != null) ...[
                            _buildPackageCard(
                              _monthlyPackage!,
                              PremiumType.monthly,
                            ),
                            const SizedBox(height: 16),
                          ],

                          const SizedBox(height: 16),
                          // CTA
                          InkWell(
                            onTap: _purchaseSelected,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.pink500, Colors.pink],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Restore + Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _restore,
                                child: Text(
                                  "Restore",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.circle, size: 5),
                              TextButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => const _InfoDialog(),
                                ),
                                child: Text(
                                  "About Subscriptions",
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Footer links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        String url = "";
                        if (GetPlatform.isIOS) {
                          url =
                              "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
                        } else if (GetPlatform.isAndroid) {
                          url =
                              "https://play.google.com/intl/ALL_tr/about/play-terms/";
                        }
                        await launchUrl(Uri.parse(url));
                      },
                      child: Text(
                        "Terms",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.circle, size: 6),
                    TextButton(
                      onPressed: () async {
                        final uri = Uri.parse(
                          "https://kuyumcu-fd31a.firebaseapp.com/#/mamaMeowPolicy",
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Text(
                        "Privacy",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasTrialSelected() {
    final package = _selectedPackage;
    if (package != null) {
      final trialDays = _iap.getTrialDays(package);
      return trialDays != null && trialDays != "0";
    }
    return false;
  }

  Widget _buildPackageCard(Package package, PremiumType type) {
    final selected = selectedType == type;
    final trialDays = _iap.getTrialDays(package);
    final hasFreeTrial = trialDays != null && trialDays != "0";

    String title;
    String subtitle;
    String? chipText;
    String perText;

    switch (type) {
      case PremiumType.monthly:
        title = "Monthly Plan";
        subtitle = "Includes a 7 day free trial. Auto-renews unless canceled.";
        perText = "Billed monthly";

        break;
      case PremiumType.yearly:
        title = "Annual Plan";
        subtitle = "Includes a 14 day free trial. Auto-renews unless canceled.";
        // Yıllık plan genelde en popüler
        chipText = "MOST POPULAR"; // "En Popüler" vb.
        perText = "Billed once per year";
        break;
    }

    return InkWell(
      onTap: () => setState(() => selectedType = type),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 128,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.shade100,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.pink, width: selected ? 2 : 0.2),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title + Radio
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    Text(
                      perText,
                      style: TextStyle(
                        color: Color(0xFF7d828f),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),

                    Text(
                      package.storeProduct.priceString,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFec4899),
                      ),
                    ),

                    Radio<bool>(
                      value: true,
                      groupValue: selected,
                      onChanged: (_) => setState(() => selectedType = type),
                      fillColor: WidgetStatePropertyAll(Colors.pink.shade500),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                // Subtitle
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (chipText != null && chipText.isNotEmpty)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 120,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFf46a12).withValues(alpha: 0.1),
                        const Color(
                          0xFFf46a12,
                        ).withValues(alpha: 0.9), // Canlı turuncu
                        const Color(0xFFf46a12), // Turuncuyu baskın yap
                      ],
                      stops: const [
                        0.0, // %0 noktasında beyaz başlasın
                        0.15, // %15’te beyaz-turuncu geçiş
                        1.0, // geri kalan tamamen turuncu
                      ],
                    ),

                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    chipText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadOfferings() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      List<Package> packages;

      // Belirli bir offering istendiyse onu yükle, yoksa current'ı al
      if (widget.offeringIdentifier != null) {
        packages = await _iap.loadSpecificOffering(widget.offeringIdentifier!);
      } else {
        packages = await _iap.loadOfferings();
      }

      // Paketleri tipine göre ayır
      Package? monthly;
      Package? yearly;

      for (final package in packages) {
        final type = _iap.getPackageType(package);
        switch (type) {
          case 'monthly':
            monthly = package;
            break;
          case 'yearly':
            yearly = package;
            break;
        }
      }

      setState(() {
        _monthlyPackage = monthly;
        _yearlyPackage = yearly;

        // Default seçim: trial öne çıkarılacaksa ve trial varsa onu seç
        if (widget.showTrialFirst) {
          // Hangi pakette daha uzun trial varsa onu seç
          final monthlyTrial = monthly != null
              ? _iap.getTrialDays(monthly)
              : null;
          final yearlyTrial = yearly != null ? _iap.getTrialDays(yearly) : null;

          if (monthlyTrial != null && yearlyTrial != null) {
            final monthlyDays = int.tryParse(monthlyTrial) ?? 0;
            final yearlyDays = int.tryParse(yearlyTrial) ?? 0;
            selectedType = yearlyDays > monthlyDays
                ? PremiumType.yearly
                : PremiumType.monthly;
          } else if (monthlyTrial != null) {
            selectedType = PremiumType.monthly;
          } else if (yearlyTrial != null) {
            selectedType = PremiumType.yearly;
          } else {
            selectedType = monthly != null
                ? PremiumType.monthly
                : PremiumType.yearly;
          }
        } else {
          selectedType = yearly != null
              ? PremiumType.yearly
              : PremiumType.monthly;
        }
      });
    } on PlatformException catch (e) {
      setState(() {
        _error = e.message ?? e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Package? get _selectedPackage =>
      selectedType == PremiumType.monthly ? _monthlyPackage : _yearlyPackage;

  Future<void> _purchaseSelected() async {
    final package = _selectedPackage;
    if (package == null) {
      customSnackBar.error("No product selected");
      return;
    }

    bool isSuccess = await _iap.purchasePackage(package);
    if (isSuccess) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _restore() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      customSnackBar.error("Restore failed");
    }
  }

  String _getButtonText() {
    final package = _selectedPackage;
    if (package != null) {
      final trialDays = _iap.getTrialDays(package);
      if (trialDays != null && trialDays != "0") {
        return "Start $trialDays days for free";
      }
    }
    return "Subscribe";
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("About Subscription"),
      content: SingleChildScrollView(
        child: Text(
          'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. '
          'A 7-day free trial is included. After the trial, the plan renews at the price shown (Monthly: 4.99\$, Yearly: 49.99\$). '
          'Manage or cancel your subscription in your account settings.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    );
  }
}

class _Feature {
  final String icon;
  final String title;
  final String subtitle;
  final List<String> advantages;
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.advantages,
  });
}
