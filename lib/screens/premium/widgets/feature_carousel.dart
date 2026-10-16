import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

class PaywallFeature {
  /// Berry çizgi ikon (ör. Icons.headphones_outlined).
  final IconData icon;
  final String title;
  final List<String> advantages;

  const PaywallFeature({
    required this.icon,
    required this.title,
    required this.advantages,
  });
}

/// Premium özelliklerini tek beyaz kart içinde listeler (eski kaydırmalı
/// carousel'in yerini aldı). Her satır: pinkTint squircle içinde berry ikon,
/// başlık ve tek satırda birleşen avantajlar; satırlar arası içeriden
/// başlayan hairline ayraç.
class PaywallFeatureList extends StatelessWidget {
  const PaywallFeatureList({super.key, required this.features});

  final List<PaywallFeature> features;

  static const double _iconSize = 44;
  static const double _iconGap = 14;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const Divider(indent: _iconSize + _iconGap),
            _FeatureRow(feature: features[i]),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final PaywallFeature feature;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          IconSquircle(
            size: PaywallFeatureList._iconSize,
            background: AppColors.pinkTint,
            child: Icon(feature.icon, size: 22, color: AppColors.activeBerry),
          ),
          const SizedBox(width: PaywallFeatureList._iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.advantages.join(' · '),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
