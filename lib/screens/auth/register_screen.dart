import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';
import 'package:mama_meow/screens/get-started/modals/baby_info_modal.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
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
    statusBarColor: Colors.white,
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
    const labelStyle = TextStyle(fontWeight: FontWeight.w500);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: CustomLoader(
        inAsyncCall: _isLoading,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: AutofillGroup(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.pink200,
                                      AppColors.pink300,
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: AppColors.pink500,
                                  ),
                                ),
                              ),
                              const Text(
                                "Join Coo Care Baby Tracker!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Create your account to start tracking your baby's journey 💕",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),

                              const _FieldLabel("Your Name", style: labelStyle),
                              const SizedBox(height: 8),
                              AuthTextField(
                                controller: _nameController,
                                hintText: "Enter your name",
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.name],
                                validator: AuthValidators.name,
                              ),
                              const SizedBox(height: 16),

                              const _FieldLabel(
                                "Email Address",
                                style: labelStyle,
                              ),
                              const SizedBox(height: 8),
                              AuthTextField(
                                controller: _emailController,
                                hintText: "Enter your email",
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: AuthValidators.email,
                              ),
                              const SizedBox(height: 16),

                              const _FieldLabel("Password", style: labelStyle),
                              const SizedBox(height: 8),
                              AuthTextField(
                                controller: _passwordController,
                                hintText: "Enter your password",
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: AuthValidators.newPassword,
                                onFieldSubmitted: (_) => _handleRegister(),
                              ),
                              const SizedBox(height: 4),
                              const _FieldLabel(
                                "Password must be at least ${AuthValidators.minPasswordLength} characters long",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.pink400,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isLoading ? null : _openLogin,
                                child: const Text(
                                  "Already have an account? Sign In",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.pink500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dekoratif noktalar
                      const Positioned(
                        top: -10,
                        left: -10,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.pink200,
                          foregroundColor: Colors.transparent,
                        ),
                      ),
                      const Positioned(
                        bottom: -10,
                        right: -10,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.purple200,
                          foregroundColor: Colors.transparent,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: style),
    );
  }
}
