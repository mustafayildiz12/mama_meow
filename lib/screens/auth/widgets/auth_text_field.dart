import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/service/global_functions.dart';

/// Giriş/kayıt ve hesap modallarındaki form alanları için ortak doğrulayıcılar.
abstract final class AuthValidators {
  static const int minPasswordLength = 6;

  static String? email(String? value) => globalFunctions.emailValidator(value);

  /// Giriş: yalnızca boş olmamalı (eski hesaplarda uzunluk kuralı farklı
  /// olabilir).
  static String? password(String? value) =>
      (value ?? '').isEmpty ? 'Please enter your password' : null;

  /// Yeni şifre (kayıt / şifre değiştirme): Firebase en az 6 karakter ister.
  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  static String? name(String? value) =>
      (value ?? '').trim().isEmpty ? 'Please enter your name' : null;
}

/// Uygulamanın pembe çerçeveli metin alanı. [isPassword] verilirse
/// görünürlük düğmesi (tooltip'li) alanın kendisi tarafından yönetilir.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.isPassword = false,
    this.validator,
    this.onFieldSubmitted,
    this.maxLength,
    this.readOnly = false,
    this.enabled,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLength;
  final bool readOnly;
  final bool? enabled;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;

  /// Aynı görünümü dropdown gibi diğer form alanlarında kullanmak için.
  static InputDecoration decoration({
    String? hintText,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: '',
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pink200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pink400, width: 2),
      ),
    );
  }

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.isPassword;
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: isPassword && _obscured,
      autocorrect: !isPassword,
      enableSuggestions: !isPassword,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLength: widget.maxLength,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      textCapitalization: widget.textCapitalization,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: AuthTextField.decoration(
        hintText: widget.hintText,
        contentPadding: widget.contentPadding,
        suffixIcon: isPassword
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscured ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
