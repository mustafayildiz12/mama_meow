import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

/// Hesap ayarları: e-posta / şifre güncelleme ve hesabı silme.
///
/// Şifre hiçbir yerde saklanmaz veya önceden doldurulmaz; değişiklik yalnızca
/// Firebase Auth üzerinden yapılır.
class UpdateEmailPasswordInfoModal extends StatefulWidget {
  const UpdateEmailPasswordInfoModal({super.key});

  @override
  State<UpdateEmailPasswordInfoModal> createState() =>
      _UpdateEmailPasswordInfoModalState();
}

class _UpdateEmailPasswordInfoModalState
    extends State<UpdateEmailPasswordInfoModal> {
  static const _recentLoginMessage =
      "For your security, please sign out, sign in again and then retry.";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final User? _user = authenticationService.getUser();

  /// 'password', 'google.com', 'apple.com'; oturum yoksa null.
  final String? _provider = authenticationService.findUserProvider();

  bool _busy = false;

  bool get _isEmailVerified => _user?.emailVerified ?? false;

  @override
  void initState() {
    super.initState();
    _emailController.text = currentMeowUser?.userEmail ?? _user?.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// [action] çalışırken diğer düğmeleri kilitler.
  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateEmail() async {
    final user = _user;
    if (user == null) return;
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    final newEmail = _emailController.text.trim();
    if (newEmail.toLowerCase() == (user.email ?? '').toLowerCase()) {
      customSnackBar.warning("This is already your email address");
      return;
    }

    await _runBusy(() async {
      try {
        await user.verifyBeforeUpdateEmail(newEmail);
        customSnackBar.success(
          "We sent a verification link to your new email. Your email will be updated once you verify it.",
        );
      } on FirebaseAuthException catch (e) {
        customSnackBar.warning(
          e.code == 'requires-recent-login'
              ? _recentLoginMessage
              : "Couldn't update your email. Please try again.",
        );
      } catch (e) {
        debugPrint('verifyBeforeUpdateEmail failed: $e');
        customSnackBar.warning("Couldn't update your email. Please try again.");
      }
    });
  }

  Future<void> _sendVerification() async {
    final user = _user;
    if (user == null) return;
    await _runBusy(() async {
      try {
        await user.sendEmailVerification();
        customSnackBar.success("Verification link sent to your email");
      } catch (e) {
        debugPrint('sendEmailVerification failed: $e');
        customSnackBar.warning(
          "Couldn't send the verification email. Please try again.",
        );
      }
    });
  }

  Future<void> _updatePassword() async {
    final user = _user;
    if (user == null) return;
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    await _runBusy(() async {
      try {
        await user.updatePassword(_passwordController.text);
        _passwordController.clear();
        customSnackBar.success("Your password has been updated");
        if (mounted) Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        customSnackBar.warning(switch (e.code) {
          'requires-recent-login' => _recentLoginMessage,
          'weak-password' =>
            "Password must be at least ${AuthValidators.minPasswordLength} characters",
          _ => "Couldn't update your password. Please try again.",
        });
      } catch (e) {
        debugPrint('updatePassword failed: $e');
        customSnackBar.warning(
          "Couldn't update your password. Please try again.",
        );
      }
    });
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text("Delete Account?"),
        content: const Text(
          "Are you sure you want to delete your account? All your data will be deleted along with your account. Do you still want to proceed?",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    bool deleted = false;
    await _runBusy(() async {
      try {
        deleted = await databaseService.deleteAccount();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          customSnackBar.warning(
            "For your security, please sign out, sign in again and then delete your account.",
          );
        } else {
          customSnackBar.error(
            "Account not deleted right now. Please try again later.",
          );
        }
      } catch (e) {
        debugPrint('deleteAccount failed: $e');
        customSnackBar.error(
          "Account not deleted right now. Please try again later.",
        );
      }
    });
    if (deleted && mounted) context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.pink500,
    );
    const fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final signedIn = _user != null && _provider != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 750, maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '👶💕 Update your information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // İşlem sürerken ince bir gösterge
              SizedBox(
                height: 4,
                child: _busy ? const LinearProgressIndicator() : null,
              ),
              const SizedBox(height: 8),

              if (!signedIn)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Please sign in to manage your account.",
                    textAlign: TextAlign.center,
                  ),
                ),

              if (signedIn && _provider == "password") ...[
                const Text("Email", style: labelStyle),
                const SizedBox(height: 8),
                Form(
                  key: _emailFormKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _emailController,
                          hintText: "Enter your email...",
                          keyboardType: TextInputType.emailAddress,
                          readOnly: !_isEmailVerified,
                          autofillHints: const [AutofillHints.email],
                          validator: AuthValidators.email,
                          contentPadding: fieldPadding,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : (_isEmailVerified
                                  ? _updateEmail
                                  : _sendVerification),
                        child: Text(_isEmailVerified ? "Update" : "Verify"),
                      ),
                    ],
                  ),
                ),
                if (!_isEmailVerified)
                  const Text(
                    'Verify your email to be able to change it.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                const SizedBox(height: 24),

                const Text("New Password", style: labelStyle),
                const SizedBox(height: 8),
                Form(
                  key: _passwordFormKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AuthTextField(
                          controller: _passwordController,
                          hintText: "Enter a new password",
                          isPassword: true,
                          maxLength: 24,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: AuthValidators.newPassword,
                          contentPadding: fieldPadding,
                          onFieldSubmitted: (_) => _updatePassword(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          onPressed: _busy ? null : _updatePassword,
                          child: const Text("Update"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (signedIn) ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : _confirmAndDeleteAccount,
                  icon: const Icon(CupertinoIcons.delete),
                  label: const Text("Delete Account"),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
