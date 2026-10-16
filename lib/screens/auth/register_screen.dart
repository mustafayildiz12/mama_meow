import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';
import 'package:mama_meow/screens/auth/widgets/auth_visuals.dart';
import 'package:mama_meow/screens/get-started/modals/baby_info_modal.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

/// Kayıt ekranı. Giriş ekranından `push` ile açıldıysa başarılı kayıtta
/// `true` ile kapanır; aksi halde Ask Meow sekmesine gider.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.cosyIvory,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    analyticService.screenView('register_screen');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: CustomLoader(
        inAsyncCall: _isLoading,
        child: Scaffold(
          backgroundColor: AppColors.cosyIvory,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: MascotCircle(
                              size: MascotCircle.sizeFor(context),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Join Coo Care Baby Tracker!",
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Create your account to start tracking your baby's journey",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.charcoalSoft,
                            ),
                          ),
                          const SizedBox(height: 28),

                          const AuthFieldLabel("Your Name"),
                          const SizedBox(height: 8),
                          AuthTextField(
                            controller: _nameController,
                            hintText: "Enter your name",
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            validator: AuthValidators.name,
                          ),
                          const SizedBox(height: 16),

                          const AuthFieldLabel("Email Address"),
                          const SizedBox(height: 8),
                          AuthTextField(
                            controller: _emailController,
                            hintText: "Enter your email",
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: AuthValidators.email,
                          ),
                          const SizedBox(height: 16),

                          const AuthFieldLabel("Password"),
                          const SizedBox(height: 8),
                          AuthTextField(
                            controller: _passwordController,
                            hintText: "Enter your password",
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: AuthValidators.newPassword,
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "Password must be at least ${AuthValidators.minPasswordLength} characters long",
                              style: textTheme.bodySmall,
                            ),
                          ),

                          const SizedBox(height: 28),
                          // Yükleme göstergesi CustomLoader'da.
                          PrimaryPillButton(
                            label: "Create Account",
                            onPressed: _isLoading ? null : _handleRegister,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading ? null : _openLogin,
                              child: Text.rich(
                                TextSpan(
                                  text: "Already have an account? ",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.charcoalSoft,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "Sign In",
                                      style: TextStyle(
                                        color: AppColors.berryInk,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.berryInk,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
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

  /// Girişe dön: giriş ekranından açıldıysa geri, değilse giriş sayfasına.
  void _openLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('login');
    }
  }

  void _finishRegister() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.goNamed('askMeow');
    }
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    bool isSuccess = false;
    try {
      isSuccess = await authenticationService.registerAndSaveUser(
        email: email,
        password: password,
        name: name,
        context: context,
      );
    } catch (e) {
      debugPrint('register failed: $e');
      customSnackBar.warning("Unable to register. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!isSuccess || !mounted) return;

    await BabyInfoModal.showAndSave(context);
    if (mounted) _finishRegister();
  }
}
