import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

enum PremiumType { monthly, yearly }

/// Tek bir abonelik paketi kartı: beyaz, 24 radius. Seçiliyken 2 px berry
/// çerçeve ve berry onay dairesi; değilken hairline çerçeve ve boş daire.
/// Kartın tamamı dokunulabilir; seçim [onSelected] ile bildirilir.
/// Yan yana dizildiğinde eşit yükseklik için dikey kısıtı olduğu gibi alır.
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
    final chipText = isYearly ? "Most popular" : null;
    final select = onSelected;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      side: selected
          ? const BorderSide(color: AppColors.activeBerry, width: 2)
          : const BorderSide(color: AppColors.hairline),
    );

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Stack(
        clipBehavior: Clip.none,
        // Row(stretch) içinde kart tam yüksekliği alır, Column içinde
        // içeriği kadar uzar.
        fit: StackFit.passthrough,
        children: [
          Material(
            color: AppColors.cottonWhite,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: select == null ? null : () => select(type),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 22 / 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepCharcoal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CheckCircle(selected: selected),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Fiyat: uzun para birimlerinde taşmasın diye küçülür.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        package.storeProduct.priceString,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 32,
                          height: 38 / 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.deepCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      perText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.berryInk,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Açıklama (deneme / yenileme bilgisi)
                    Text(
                      subtitle.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (chipText != null)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(child: _PopularChip(text: chipText)),
            ),
        ],
      ),
    );
  }
}

/// Seçim göstergesi: seçiliyse berry dolgulu onay, değilse boş daire.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.activeBerry : AppColors.cottonWhite,
        border: Border.all(
          color: selected ? AppColors.activeBerry : AppColors.outline,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: AppColors.cottonWhite)
          : null,
    );
  }
}

/// Kartın üst kenarına oturan berry hap rozet.
class _PopularChip extends StatelessWidget {
  const _PopularChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppColors.activeBerry,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.cottonWhite,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
