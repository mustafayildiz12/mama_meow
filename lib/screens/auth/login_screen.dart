import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';
import 'package:mama_meow/screens/auth/widgets/forgot_password_dialog.dart';
import 'package:mama_meow/screens/get-started/modals/baby_info_modal.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/app_update_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/platform_info.dart';

/// Giriş ekranı. Başka bir sayfanın üstüne `push` ile açıldıysa başarılı
/// girişte `true` ile kapanır (çağıran akış kaldığı yerden devam eder);
/// aksi halde Ask Meow sekmesine gider.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    analyticService.screenView('login_screen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateService().checkAndShowUpdateIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: CustomLoader(
        inAsyncCall: _isLoading,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                            child: SingleChildScrollView(
                              child: AutofillGroup(child: _buildForm()),
                            ),
                          ),
                          // Dekoratif noktalar
                          const Positioned(
                            top: -10,
                            left: -10,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.pink200,
                            ),
                          ),
                          const Positioned(
                            bottom: -10,
                            right: -10,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.purple200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: _close,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.pink200, AppColors.pink300],
                ),
              ),
              child: const Center(
                child: Icon(Icons.pets, size: 40, color: AppColors.pink500),
              ),
            ),
            const Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Sign in to continue your parenting journey 🐾",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          "Email Address",
          style: TextStyle(fontWeight: FontWeight.w500),
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

        const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        AuthTextField(
          controller: _passwordController,
          hintText: "Enter your password",
          isPassword: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: AuthValidators.password,
          onFieldSubmitted: (_) => _handleLogin(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: const Text(
              "Forgot password?",
              style: TextStyle(
                color: AppColors.pink500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pink400,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Sign In",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),

        if (PlatformInfo.isIOS) ...[
          _SocialButton(
            icon: const Icon(Icons.apple, size: 30),
            label: "Login with Apple",
            onPressed: _isLoading
                ? null
                : () => _handleSocialSignIn(
                    authenticationService.signInWithApple,
                  ),
          ),
          const SizedBox(height: 12),
        ],
        _SocialButton(
          icon: Image.asset("assets/google.png", height: 24),
          label: "Login with Google",
          onPressed: _isLoading
              ? null
              : () =>
                    _handleSocialSignIn(authenticationService.signInWithGoogle),
        ),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _openRegister,
            child: const Text(
              "Don't have an account? Sign Up",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.pink500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Ekranı kapatır: üstüne açıldığı sayfaya döner, yoksa misafir olarak
  /// uygulamaya devam eder.
  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('myBaby');
    }
  }

  /// Başarılı giriş sonrası yönlendirme.
  void _finishSignIn() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.goNamed('askMeow');
    }
  }

  Future<void> _openRegister() async {
    final registered = await context.pushNamed<bool>('register');
    if (registered == true && mounted) _finishSignIn();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);
    int result = 0;
    try {
      result = await authenticationService.login(
        context,
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('login failed: $e');
      customSnackBar.warning("Could not log in");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;

    if (result == 1) {
      _finishSignIn();
    } else if (result == 2) {
      customSnackBar.warning("This account is deleted permanently");
      await authenticationService.logoutFromFirebase();
    }
  }

  /// Google ve Apple girişi için ortak akış.
  Future<void> _handleSocialSignIn(Future<int> Function() signIn) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    int result = SocialSignInResult.failed;
    try {
      result = await signIn();
    } catch (e) {
      debugPrint('social sign-in failed: $e');
      customSnackBar.warning("Failed to login");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (!mounted) return;

    switch (result) {
      case SocialSignInResult.existingUser:
        _finishSignIn();
      case SocialSignInResult.newUser:
        await BabyInfoModal.showAndSave(context);
        if (mounted) _finishSignIn();
      default:
        // failed: mesajı servis gösterdi; cancelled: kullanıcı vazgeçti.
        break;
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = await ForgotPasswordDialog.show(
      context,
      initialEmail: _emailController.text.trim(),
    );
    if (email == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await authenticationService.forgotPassword(email: email);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: OutlinedButton.icon(
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
