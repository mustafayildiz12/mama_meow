import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';
import 'package:mama_meow/screens/auth/widgets/auth_visuals.dart';
import 'package:mama_meow/screens/auth/widgets/forgot_password_dialog.dart';
import 'package:mama_meow/screens/get-started/modals/baby_info_modal.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/app_update_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
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
    statusBarColor: AppColors.cosyIvory,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  /// Başka bir sayfanın üstüne açıldıysa true. Çıkış / hesap silme sonrası
  /// giriş ekranı kök sayfadır: kapatma butonu gösterilmez, kullanıcı
  /// uygulamaya ancak giriş yaparak döner. İlk build'de sabitlenir ki kapanış
  /// animasyonunda buton kaybolup içerik kaymasın.
  late final bool _canClose = context.canPop();

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
          backgroundColor: AppColors.cosyIvory,
          body: SafeArea(
            child: Column(
              children: [
                if (_canClose)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircleCloseButton(onPressed: () => context.pop()),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      _canClose ? 8 : 24,
                      20,
                      24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(child: _buildForm()),
                        ),
                      ),
                    ),
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
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: MascotCircle(size: MascotCircle.sizeFor(context))),
        const SizedBox(height: 20),
        Text(
          "Welcome Back!",
          textAlign: TextAlign.center,
          style: textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to continue your parenting journey",
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.charcoalSoft),
        ),
        const SizedBox(height: 28),

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
          autofillHints: const [AutofillHints.password],
          validator: AuthValidators.password,
          onFieldSubmitted: (_) => _handleLogin(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: const Text("Forgot password?"),
          ),
        ),
        const SizedBox(height: 8),

        // Yükleme göstergesi CustomLoader'da; etiket her zaman görünür kalır.
        PrimaryPillButton(
          label: "Sign In",
          onPressed: _isLoading ? null : _handleLogin,
        ),
        const SizedBox(height: 24),

        const _DividerLabel("or continue with"),
        const SizedBox(height: 16),
        Row(
          children: [
            if (PlatformInfo.isIOS) ...[
              Expanded(
                child: _SocialButton(
                  icon: const Icon(Icons.apple, size: 24),
                  label: "Apple",
                  semanticsLabel: "Login with Apple",
                  onPressed: _isLoading
                      ? null
                      : () => _handleSocialSignIn(
                          authenticationService.signInWithApple,
                        ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _SocialButton(
                icon: Image.asset("assets/google.png", height: 20),
                label: "Google",
                semanticsLabel: "Login with Google",
                onPressed: _isLoading
                    ? null
                    : () => _handleSocialSignIn(
                        authenticationService.signInWithGoogle,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _openRegister,
            child: Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.charcoalSoft,
                ),
                children: const [
                  TextSpan(
                    text: "Sign Up",
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
    );
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

/// "or continue with" ayracı: iki yanda hairline çizgi.
class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Beyaz, çerçeveli hap sosyal giriş düğmesi (Apple / Google).
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: icon,
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        semanticsLabel: semanticsLabel,
      ),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.cottonWhite,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
