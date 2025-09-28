import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/premium/premium_bottom_sheet.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

class TrialOfferingPage extends StatefulWidget {
  const TrialOfferingPage({super.key});

  @override
  State<TrialOfferingPage> createState() => _TrialOfferingPageState();
}

class _TrialOfferingPageState extends State<TrialOfferingPage> {
 

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

  bool isTrial = false;

  void checkIsTrial() async {
    int? trialCount = infoStorage.read("trialCount");
    if (trialCount == null) {
      setState(() {
        isTrial = true;
      });
    } else if (trialCount < 4) {
      setState(() {
        isTrial = true;
      });
    }
  }

  Future<void> _startTrial() async {
    try {
      await infoStorage.write("trialCount", 1);
      await Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.navigationBarPage,
        (_) => false,
      );
    } catch (e) {
      customSnackBar.error("Failed to start free trial");
    }
  }

  void _showSubscriptionOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PremiumBottomSheetPlayMonti(
        showTrialFirst: true, // Trial'ı öne çıkar
      ),
    );
  }

  @override
  void initState() {
    checkIsTrial();
    ;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.kLightOrange,
      body: SafeArea(child: _buildMainContent(theme, screenHeight)),
    );
  }

  Widget _buildMainContent(ThemeData theme, double screenHeight) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 12),
            Text(
              "Explore Premium Features",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Discover all premium features and take your experience to the next level.",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 24),
            // Features
            _buildFeaturesSection(),

            SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (isTrial) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: _startTrial,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.play_circle),
                  const SizedBox(width: 8),
                  Text(
                    "Free Trial",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Subscribe Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _showSubscriptionOptions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.star),
                const SizedBox(width: 8),
                Text(
                  "View Plans",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
         const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      feature.icon,
                      size: 24,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ],
              ),
              if (index < features.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  const _Feature({required this.icon, required this.title});
}
