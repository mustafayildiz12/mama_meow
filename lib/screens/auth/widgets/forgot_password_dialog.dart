import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';

/// Şifre sıfırlama için e-posta soran diyalog. Geçerli e-postayı (trim'li)
/// döndürür; vazgeçilirse null. Görünüm temadan gelir (beyaz, 24 radius).
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key, this.initialEmail});

  final String? initialEmail;

  static Future<String?> show(BuildContext context, {String? initialEmail}) {
    return showDialog<String>(
      context: context,
      builder: (_) => ForgotPasswordDialog(initialEmail: initialEmail),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your account's email and we'll send you a link to reset your password.",
              style: TextStyle(color: AppColors.charcoalSoft),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.charcoalSoft),
          child: const Text('Cancel'),
        ),
        // Birincil eylem: temadan berry hap buton.
        FilledButton(onPressed: _submit, child: const Text('Send reset link')),
      ],
    );
  }
}
