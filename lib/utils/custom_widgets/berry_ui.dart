import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';

/// Warm Cotton & Berry ortak arayüz parçaları (docs/design/warm-cotton-berry).

/// Uygulamadaki aktivite türleri ve görsel kimlikleri. Aktiviteler renkle
/// değil ikon + etiketle ayrışır; kart zeminleri pembe/şeftali dönüşümlüdür.
enum ActivityKind {
  nursing('Nursing'),
  solid('Solids'),
  sleep('Sleep'),
  diaper('Diaper'),
  pumping('Pumping'),
  medicine('Medicine'),
  journal('Journal');

  const ActivityKind(this.label);

  final String label;

  /// Kart zemini (sabit sırayla pembe / şeftali).
  Color get tileColor => switch (this) {
    ActivityKind.solid ||
    ActivityKind.diaper ||
    ActivityKind.medicine => AppColors.peachTint,
    _ => AppColors.pinkTint,
  };

  /// Material'de biberon ikonu olmadığı için nursing SVG kullanır.
  IconData? get icon => switch (this) {
    ActivityKind.nursing => null,
    ActivityKind.solid => Icons.rice_bowl_outlined,
    ActivityKind.sleep => Icons.bedtime_outlined,
    ActivityKind.diaper => Icons.baby_changing_station_outlined,
    ActivityKind.pumping => Icons.water_drop_outlined,
    ActivityKind.medicine => Icons.medication_outlined,
    ActivityKind.journal => Icons.menu_book_outlined,
  };
}

/// Aktivitenin çizgi ikonu.
class ActivityIcon extends StatelessWidget {
  const ActivityIcon({
    super.key,
    required this.kind,
    this.size = 24,
    this.color = AppColors.activeBerry,
  });

  final ActivityKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = kind.icon;
    if (icon != null) return Icon(icon, size: size, color: color);
    return SvgPicture.asset(
      'assets/bottle.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: kind.label,
    );
  }
}

/// Yuvarlatılmış kare ikon zemini.
class IconSquircle extends StatelessWidget {
  const IconSquircle({
    super.key,
    required this.child,
    this.background = AppColors.cottonWhite,
    this.size = 44,
    this.radius = 16,
  });

  final Widget child;
  final Color background;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Beyaz, ince pembe çizgili standart kart.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.cottonWhite,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusCard);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Çizgisiz, renkli zeminli kart (ipucu, premium, aktivite).
class TintCard extends StatelessWidget {
  const TintCard({
    super.key,
    required this.child,
    this.color = AppColors.peachTint,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Bölüm başlığı + isteğe bağlı sağdaki bağlantı ("See all →").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.headlineSmall)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

/// Berry dolgulu, parıltılı birincil hap buton.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = AppTheme.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Etiketin sağında gösterilir (ör. Icons.arrow_forward).
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final fg = enabled ? AppColors.cottonWhite : AppColors.charcoalSoft;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        shadows: enabled ? AppColors.berryGlow : null,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(64, height),
            textStyle: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.activeBerry,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 20, color: fg),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
