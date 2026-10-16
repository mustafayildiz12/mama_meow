import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

/// Giriş, kayıt ve paywall ekranlarının ortak görsel parçaları
/// (Warm Cotton & Berry).

/// Şeftali zeminli yuvarlak maskot (uygulama logosundaki uyuyan kedi).
class MascotCircle extends StatelessWidget {
  const MascotCircle({
    super.key,
    this.size = 192,
    this.background = AppColors.peachTint,
  });

  final double size;
  final Color background;

  /// Kısa ekranlarda (ör. iPhone SE) maskot küçülür; böylece giriş formu ve
  /// birincil buton kaydırmadan görünür kalır. Uzun ekranlarda 192 px.
  static double sizeFor(BuildContext context) =>
      (MediaQuery.sizeOf(context).height - 560).clamp(96.0, 192.0);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: background,
        // Logo görselinin kenarları şeffaf; daireyi doldurması için büyütülür.
        child: Transform.scale(
          scale: 1.25,
          child: Image.asset(
            'assets/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// 44 px pinkTint daire içinde kapatma düğmesi.
class CircleCloseButton extends StatelessWidget {
  const CircleCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Close',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.pinkTint,
        foregroundColor: AppColors.deepCharcoal,
        disabledBackgroundColor: AppColors.pinkTint,
        disabledForegroundColor: AppColors.charcoalSoft,
        minimumSize: const Size.square(44),
        fixedSize: const Size.square(44),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
      icon: const Icon(Icons.close, size: 22),
    );
  }
}

/// Form alanının üstündeki etiket (14/w700, deep charcoal).
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
