import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

enum PremiumType { monthly, yearly }

/// Tek bir abonelik paketi kartı. Bir `RadioGroup<PremiumType>` altında
/// kullanılmalıdır (seçim radyosu gruba bağlanır).
class PaywallPackageCard extends StatelessWidget {
  const PaywallPackageCard({
    super.key,
    required this.type,
    required this.package,
    required this.trialDays,
    required this.selected,
    required this.onSelected,
  });

  final PremiumType type;
  final Package package;

  /// Ücretsiz deneme günü; yoksa null.
  final String? trialDays;
  final bool selected;
  final ValueChanged<PremiumType>? onSelected;

  bool get _hasFreeTrial => trialDays != null && trialDays != "0";

  String get _planLabel {
    final price = package.storeProduct.priceString;
    final freq = type == PremiumType.monthly ? "month" : "year";
    return _hasFreeTrial
        ? " • After the $trialDays-day free trial, it renews at $price per $freq."
        : " • Automatically renews at $price per $freq.";
  }

  @override
  Widget build(BuildContext context) {
    final isYearly = type == PremiumType.yearly;
    final title = isYearly ? "Annual Plan" : "Monthly Plan";
    final perText = isYearly ? "Billed once per year" : "Billed monthly";
    final subtitle = _hasFreeTrial
        ? "Includes a $trialDays-day free trial.$_planLabel"
        : _planLabel;
    // Yıllık plan genelde en popüler
    final chipText = isYearly ? "MOST POPULAR" : null;
    final select = onSelected;

    return Semantics(
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: select == null ? null : () => select(type),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 128),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade100,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.pink,
                  width: selected ? 2 : 0.2,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Fiyat satırı
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          perText,
                          style: const TextStyle(
                            color: Color(0xFF7d828f),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        package.storeProduct.priceString,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.pink500,
                        ),
                      ),
                      Radio<PremiumType>(
                        value: type,
                        fillColor: WidgetStatePropertyAll(Colors.pink.shade500),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Açıklama
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.info,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (chipText != null)
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _PopularChip(text: chipText),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopularChip extends StatelessWidget {
  const _PopularChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFf46a12);
    return Container(
      constraints: const BoxConstraints(minWidth: 136, minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            orange.withValues(alpha: 0.1),
            orange.withValues(alpha: 0.9), // Canlı turuncu
            orange, // Turuncuyu baskın yap
          ],
          stops: const [0.0, 0.15, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      // Faktörler 1: içerik kadar yer kaplar, min boyutta ortalanır.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
