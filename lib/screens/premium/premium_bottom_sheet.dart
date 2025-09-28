import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum PremiumType { monthly, yearly }

class PremiumBottomSheetPlayMonti extends StatefulWidget {
  final bool showTrialFirst;
  final String? offeringIdentifier; // Belirli bir offering kullanmak için

  const PremiumBottomSheetPlayMonti({
    super.key,
    this.showTrialFirst = false,
    this.offeringIdentifier,
  });

  @override
  State<PremiumBottomSheetPlayMonti> createState() =>
      _PremiumBottomSheetPlayMontiState();
}

class _PremiumBottomSheetPlayMontiState
    extends State<PremiumBottomSheetPlayMonti> {
  PremiumType selectedType = PremiumType.monthly;

  final List<_Feature> features = [
    _Feature(
      icon: CupertinoIcons.timer,
      title: "Unlimited baby tracking (feed, sleep, diapers, growth)",
    ),
    _Feature(
      icon: CupertinoIcons.chart_bar_fill,
      title: "Trends & insights (day • week • month)",
    ),
    _Feature(
      icon: CupertinoIcons.chat_bubble_2_fill,
      title: "Ask MamaMeow — unlimited AI answers",
    ),
    _Feature(icon: CupertinoIcons.headphones, title: "Full podcast library"),
    _Feature(
      icon: CupertinoIcons.bell_fill,
      title: "Smart reminders & gentle nudges you can customize",
    ),

    _Feature(
      icon: CupertinoIcons.cloud_upload_fill,
      title: "Data export (CSV/PDF) & secure cloud backup",
    ),
    _Feature(
      icon: CupertinoIcons.lock_shield_fill,
      title: "Private & secure — you control your data",
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
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      minChildSize: 0.5,
      initialChildSize: 0.9,
      maxChildSize: 0.92,
      builder: (c, s) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.pink100,
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
                          Text(
                            "Unlock Premium Features",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Discover all premium features and take your experience to the next level.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Features – PageView
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 90,
                                        width: 90,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF7FF),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          f.icon,
                                          size: 44,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          f.title,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (pageIndex + 1) / features.length,
                              backgroundColor: const Color(0xFFE0F2FE),
                              color: const Color(0xFF3B82F6),
                              minHeight: 6,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // MONTHLY
                          if (_monthlyPackage != null) ...[
                            _buildPackageCard(
                              _monthlyPackage!,
                              PremiumType.monthly,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // YEARLY
                          if (_yearlyPackage != null) ...[
                            _buildPackageCard(
                              _yearlyPackage!,
                              PremiumType.yearly,
                            ),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 16),
                          // CTA
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasTrialSelected()
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _purchaseSelected,
                              child: Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
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

    switch (type) {
      case PremiumType.monthly:
        title = "Monthly Plan";
        subtitle = "Includes a 7 day free trial. Auto-renews unless canceled.";

        break;
      case PremiumType.yearly:
        title = "Yearly Plan";
        subtitle = "Includes a 14 day free trial. Auto-renews unless canceled.";
        // Yıllık plan genelde en popüler
        chipText = "Popular"; // "En Popüler" vb.
        break;
    }

    final gradient = selected
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFEFF7FF), Color(0xFFE6F7EE)],
          )
        : null;

    return InkWell(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        height: 128,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? null : Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: selected
              ? Border.all(color: const Color(0xFF93C5FD), width: 1)
              : null,
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: selected,
                  onChanged: (_) => setState(() => selectedType = type),
                  fillColor: WidgetStatePropertyAll(Colors.green.shade500),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),

            // Price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Fiyat
                Text(
                  package.storeProduct.priceString,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),

                // Trial pill
                if (hasFreeTrial)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF16A34A)),
                    ),
                    child: Text(
                      "7-Day Free Trial",
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),

                const Spacer(),

                // Badge
                if (chipText != null && chipText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chipText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
          selectedType = monthly != null
              ? PremiumType.monthly
              : PremiumType.yearly;
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.navigationBarPage,
        (_) => false,
      );
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
  final IconData icon;
  final String title;
  const _Feature({required this.icon, required this.title});
}
