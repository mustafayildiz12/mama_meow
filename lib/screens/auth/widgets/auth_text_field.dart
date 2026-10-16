import 'package:flutter/material.dart';
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

/// Uygulamanın standart metin alanı. Görünüm temadan gelir (beyaz zemin,
/// 16 radius, outline çerçeve, odakta 2 px berry, charcoalSoft ikonlar).
/// [isPassword] verilirse görünürlük düğmesi (tooltip'li) alanın kendisi
/// tarafından yönetilir.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
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

  /// Alanın solundaki çizgi ikon (ör. Icons.mail_outline).
  final IconData? prefixIcon;
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

  /// Varsayılan iç boşluk: 16 + 24 (satır) + 16 = 56 px yükseklik.
  static const EdgeInsetsGeometry _defaultPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  /// Aynı görünümü dropdown gibi diğer form alanlarında kullanmak için.
  /// Çerçeve ve renkler temanın `inputDecorationTheme`'inden gelir.
  static InputDecoration decoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: '',
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
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
    final prefixIcon = widget.prefixIcon;
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
        contentPadding: widget.contentPadding ?? AuthTextField._defaultPadding,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: _obscured ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
