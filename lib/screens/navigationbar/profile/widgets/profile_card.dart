import 'package:flutter/material.dart';

/// Profil ekranındaki beyaz, yuvarlak köşeli kartların ortak kabuğu.
/// [onTap] verilirse kartın tamamı tıklanabilir olur.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  static final _radius = BorderRadius.circular(20);

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: _radius),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(borderRadius: _radius, onTap: onTap, child: content),
    );
  }
}
