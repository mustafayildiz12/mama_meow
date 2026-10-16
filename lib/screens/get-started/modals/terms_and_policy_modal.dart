import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

class TermsAndPrivacyModal extends StatefulWidget {
  const TermsAndPrivacyModal({super.key});

  @override
  State<TermsAndPrivacyModal> createState() => _TermsAndPrivacyModalState();
}

class _TermsAndPrivacyModalState extends State<TermsAndPrivacyModal> {
  bool agreedToTerms = false;
  bool agreedToPrivacy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scrim,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cottonWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Welcome to Coo Care Baby Tracker!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          height: 26 / 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepCharcoal,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Before we start, please review our policies',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Terms of Use
                const _PolicyHeader(
                  icon: Icons.description_outlined,
                  title: 'Terms of Use',
                ),
                const SizedBox(height: 8),
                const _PolicyBox(
                  children: [
                    Text(
                      'Coo Care Baby Tracker: Your Cattiest Mom\'s AI Companion',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'By downloading or using Coo Care Baby Tracker, you agree to these Terms of Use. This app is designed for parents or legal guardians aged 18 or older.',
                    ),
                    SizedBox(height: 8),
                    Text('• Use for personal, non-commercial purposes only'),
                    Text('• Provide accurate information about your baby'),
                    Text('• AI responses are for guidance, not medical advice'),
                    Text(
                      '• We may update features and terms at our discretion',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Privacy Policy
                const _PolicyHeader(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy Policy',
                ),
                const SizedBox(height: 8),
                const _PolicyBox(
                  children: [
                    Text(
                      'Coo Care Baby Tracker: Your Cattiest Mom\'s AI Companion',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We collect baby\'s name, birth date, activity logs, journal entries, and device permissions (camera, microphone, notifications) with your consent.',
                    ),
                    SizedBox(height: 8),
                    Text('• Data used for personalized insights and reminders'),
                    Text('• Stored securely with encryption'),
                    Text('• Never sold to third parties'),
                    Text(
                      '• You can access, correct, or delete your data anytime',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Onay kutuları (renkler checkboxTheme'den)
                Row(
                  children: [
                    Checkbox(
                      value: agreedToTerms,
                      onChanged: (val) => setState(() => agreedToTerms = val!),
                    ),
                    const Expanded(child: Text('I agree to the Terms of Use')),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: agreedToPrivacy,
                      onChanged: (val) =>
                          setState(() => agreedToPrivacy = val!),
                    ),
                    const Expanded(
                      child: Text('I agree to the Privacy Policy'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (agreedToTerms && agreedToPrivacy)
                            ? () {
                                Navigator.pop(context, true);
                              }
                            : null,
                        child: const Text('Continue'),
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
}

/// Politika bölüm başlığı: berry çizgi ikon + başlık.
class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.activeBerry),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.deepCharcoal,
          ),
        ),
      ],
    );
  }
}

/// Kaydırılabilir, ivory zeminli politika metni kutusu.
class _PolicyBox extends StatelessWidget {
  const _PolicyBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cosyIvory,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: const BoxConstraints(maxHeight: 150),
      child: SingleChildScrollView(
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            fontSize: 13,
            height: 18 / 13,
            color: AppColors.deepCharcoal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
