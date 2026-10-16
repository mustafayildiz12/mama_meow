import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

/// Profil ekranındaki beyaz, 24 radius, ince pembe çizgili kartların ortak
/// kabuğu (Warm Cotton & Berry [AppCard]). [onTap] verilirse kartın tamamı
/// tıklanabilir olur.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(padding: padding, onTap: onTap, child: child);
  }
}

/// Profil kartlarındaki ayar satırı: 40 px pembe daire içinde berry ikon,
/// başlık (+ isteğe bağlı alt başlık) ve sağda ok.
class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            ProfileIconCircle(icon: icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 24 / 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepCharcoal,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.charcoalSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppColors.charcoalSoft,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pembe zeminli yuvarlak ikon tutucu (ayar satırları, hakkında, hesap).
class ProfileIconCircle extends StatelessWidget {
  const ProfileIconCircle({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
    this.background = AppColors.pinkTint,
    this.color = AppColors.activeBerry,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
