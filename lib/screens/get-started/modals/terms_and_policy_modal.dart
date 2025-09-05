import 'package:flutter/material.dart';

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
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
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
                        'Welcome to MamaMeow! 😸',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEC4899),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Before we start, please review our policies',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Terms of Use
                const Text(
                  '📋 Terms of Use',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC4899),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF1F5),
                    border: Border(
                      left: BorderSide(color: Color(0xFFF472B6), width: 4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MamaMeow: Your Cattiest Mom\'s AI Companion',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'By downloading or using MamaMeow, you agree to these Terms of Use. This app is designed for parents or legal guardians aged 18 or older.',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Use for personal, non-commercial purposes only',
                        ),
                        Text('• Provide accurate information about your baby'),
                        Text(
                          '• AI responses are for guidance, not medical advice',
                        ),
                        Text(
                          '• We may update features and terms at our discretion',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Privacy Policy
                const Text(
                  '🔒 Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC4899),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF1F5),
                    border: Border(
                      left: BorderSide(color: Color(0xFFF472B6), width: 4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MamaMeow: Your Cattiest Mom\'s AI Companion',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'We collect baby\'s name, birth date, activity logs, journal entries, and device permissions (camera, microphone, notifications) with your consent.',
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Data used for personalized insights and reminders',
                        ),
                        Text('• Stored securely with encryption'),
                        Text('• Never sold to third parties'),
                        Text(
                          '• You can access, correct, or delete your data anytime',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Checkboxes
                Row(
                  children: [
                    Checkbox(
                      value: agreedToTerms,
                      activeColor: Color(0xFFEC4899),
                      onChanged: (val) => setState(() => agreedToTerms = val!),
                    ),
                    const Expanded(child: Text('I agree to the Terms of Use')),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: agreedToPrivacy,
                      activeColor: Color(0xFFEC4899),
                      onChanged: (val) =>
                          setState(() => agreedToPrivacy = val!),
                    ),
                    const Expanded(
                      child: Text('I agree to the Privacy Policy'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF472B6),
                          disabledBackgroundColor: const Color(
                            0xFFF472B6,
                          ).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
