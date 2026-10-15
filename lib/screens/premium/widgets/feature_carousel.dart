import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

class PaywallFeature {
  final String icon;
  final String title;
  final List<String> advantages;

  const PaywallFeature({
    required this.icon,
    required this.title,
    required this.advantages,
  });
}

/// Premium özelliklerini kaydırmalı kartlarla gösterir; altında ilerleme
/// çubuğu vardır. Yükseklik yazı ölçeğine göre büyür.
class PaywallFeatureCarousel extends StatefulWidget {
  const PaywallFeatureCarousel({super.key, required this.features});

  final List<PaywallFeature> features;

  @override
  State<PaywallFeatureCarousel> createState() => _PaywallFeatureCarouselState();
}

class _PaywallFeatureCarouselState extends State<PaywallFeatureCarousel> {
  static const double _baseHeight = 192;

  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final features = widget.features;
    // Büyük yazı boyutlarında kesilmemesi için yüksekliği ölçekle.
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final height = _baseHeight * math.max(1.0, textScale);

    return Column(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: PageView.builder(
            itemCount: features.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (_, i) => _FeaturePage(feature: features[i]),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: features.isEmpty ? 0 : (_pageIndex + 1) / features.length,
              backgroundColor: Colors.pink.shade100,
              color: AppColors.pink500,
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.feature});

  final PaywallFeature feature;

  @override
  Widget build(BuildContext context) {
    // Yine de sığmazsa içerik kaydırılabilir olsun.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.pink400,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(feature.icon, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              feature.title,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          for (final advantage in feature.advantages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("✅"),
                  const SizedBox(width: 8),
                  Flexible(child: Text(advantage)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
