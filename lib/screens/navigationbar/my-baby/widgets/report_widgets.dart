import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Aktivite raporlarının renk paleti. Tüm raporlar [ReportPalette.berry]
/// kullanır; kartlar renkleri [ReportPaletteScope] üzerinden okur.
class ReportPalette {
  const ReportPalette({
    required this.tint,
    required this.segmentFill,
    this.badge,
    this.segmentBackground = AppColors.pinkTint,
    this.segmentActiveForeground = AppColors.berryInk,
  });

  /// [ReportSectionCard] degradesinin başlangıç rengi.
  final Color tint;

  /// Kart başlığındaki emoji rozetinin zemini (null → [tint]).
  final Color? badge;

  /// Daily/Weekly/Monthly seçicisinde aktif buton zemini.
  final Color segmentFill;
  final Color segmentBackground;
  final Color segmentActiveForeground;

  /// Warm Cotton & Berry rapor paleti.
  static const berry = ReportPalette(
    tint: AppColors.pinkTint,
    badge: AppColors.peachTint,
    segmentFill: AppColors.cottonWhite,
  );

  static const fallback = berry;

  static ReportPalette of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ReportPaletteScope>()
          ?.palette ??
      fallback;
}

class ReportPaletteScope extends InheritedWidget {
  const ReportPaletteScope({
    super.key,
    required this.palette,
    required super.child,
  });

  final ReportPalette palette;

  @override
  bool updateShouldNotify(ReportPaletteScope oldWidget) =>
      palette != oldWidget.palette;
}

/// Grafik veri noktası (kategori → değer).
class ChartEntry {
  const ChartEntry(this.label, this.value);
  final String label;
  final num value;
}

/// Haritayı değere göre azalan sıralı grafik listesine çevirir.
List<ChartEntry> sortedEntries(Map<String, num> map) =>
    map.entries.map((e) => ChartEntry(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

/// Haritayı ekleme sırasını koruyarak grafik listesine çevirir ("00".."23").
List<ChartEntry> orderedEntries(Map<String, num> map) =>
    map.entries.map((e) => ChartEntry(e.key, e.value)).toList();

/// Raporlarda kullanılan 4 kademeli renk skalası (berry → pink → peach → çizgi).
Color tierColor(
  num value, {
  required num high,
  required num mid,
  required num low,
}) {
  if (value >= high) return AppColors.activeBerry;
  if (value >= mid) return AppColors.warmPink;
  if (value >= low) return AppColors.peachPastel;
  return AppColors.outline;
}

/// Dakikayı "1h 5m" biçiminde yazar.
String formatMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (minutes == 0) return "0m";
  if (h == 0) return "${m}m";
  if (m == 0) return "${h}h";
  return "${h}h ${m}m";
}

/// Daily / Weekly / Monthly seçici: pembe hap zemin üzerinde beyaz kayan seçim.
class RangeSegmented extends StatelessWidget {
  const RangeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChanged;

  static const _labels = {
    ReportPeriod.today: 'Daily',
    ReportPeriod.week: 'Weekly',
    ReportPeriod.month: 'Monthly',
  };

  @override
  Widget build(BuildContext context) {
    final palette = ReportPalette.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: palette.segmentBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final p in ReportPeriod.values) ...[
            if (p != ReportPeriod.values.first) const SizedBox(width: 4),
            Expanded(
              child: _SegmentButton(
                label: _labels[p]!,
                selected: value == p,
                onTap: () => onChanged(p),
                activeFill: palette.segmentFill,
                activeFg: palette.segmentActiveForeground,
                inactiveFg: AppColors.deepCharcoal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeFill,
    required this.activeFg,
    required this.inactiveFg,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeFill;
  final Color activeFg;
  final Color? inactiveFg;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? activeFill : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected ? AppColors.floatShadow : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected ? activeFg : inactiveFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Boş / hata durumu mesajı. Kaydırılabilir olduğu için üstteki
/// RefreshIndicator ile "çekerek yenile" çalışır.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Rapor yüklenemediğinde gösterilen standart mesaj.
  const CenteredMessage.loadError({super.key})
    : emoji = '⚠️',
      title = 'Something went wrong',
      subtitle = "We couldn't load this report. Pull to refresh and try again.",
      actionLabel = null,
      onAction = null;

  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.charcoalSoft,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: PrimaryPillButton(
                          label: actionLabel!,
                          icon: Icons.add,
                          height: 52,
                          onPressed: onAction,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Beyaz, ince çizgili rapor kartı.
class ReportSectionCard extends StatelessWidget {
  const ReportSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final String? subtitle;

  /// Eski emoji rozeti; tasarım gereği gösterilmez.
  final String? leading;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cottonWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.charcoalSoft,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Özet kartı: başlık + yan yana [StatTile]'lar.
class ReportHeaderCard extends StatelessWidget {
  const ReportHeaderCard({
    super.key,
    required this.title,
    required this.stats,
    this.subtitle,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 16),
    this.gap = 8,
    this.tileHeight = 86,
    this.valueFontSize = 14,
    this.valueMaxLines,
  });

  final String title;
  final String? subtitle;
  final String? leading;
  final EdgeInsets padding;

  /// (başlık, değer) çiftleri.
  final List<(String, String)> stats;
  final double gap;
  final double tileHeight;
  final double? valueFontSize;
  final int? valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return ReportSectionCard(
      padding: padding,
      title: title,
      subtitle: subtitle,
      leading: leading,
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: tileHeight * 0.6,
                margin: EdgeInsets.symmetric(horizontal: gap / 2),
                color: AppColors.hairline,
              ),
            Expanded(
              child: StatTile(
                title: stats[i].$1,
                value: stats[i].$2,
                height: tileHeight,
                valueFontSize: valueFontSize,
                valueMaxLines: valueMaxLines,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.title,
    required this.value,
    this.height = 86,
    this.valueFontSize = 14,
    this.valueMaxLines,
  });

  final String title;
  final String value;
  final double height;
  final double? valueFontSize;
  final int? valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Değer büyük ve tek satır; sığmazsa küçülür.
    final valueSize = (valueFontSize ?? 14) < 20 ? 24.0 : valueFontSize!;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.charcoalSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: valueMaxLines ?? 1,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: valueSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiket + ilerleme çubuğu + değer satırı ("en uzun uyku", "en çok yenen" ...).
class RatioBarTile extends StatelessWidget {
  const RatioBarTile({
    super.key,
    required this.label,
    required this.valueText,
    required this.ratio,
    required this.color,
    this.trackColor,
    this.leading,
  });

  final String label;
  final String valueText;
  final double ratio;
  final Color color;

  /// Çubuk arka planı (null → [color] %10).
  final Color? trackColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cottonWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.isFinite ? ratio.clamp(0, 1) : 0,
                    minHeight: 8,
                    backgroundColor: trackColor ?? AppColors.pinkTint,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valueText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sabit ipuçları kartı (emoji rozeti + metin satırları).
class ReportTipsCard extends StatelessWidget {
  const ReportTipsCard({
    super.key,
    required this.title,
    required this.leading,
    required this.badgeColor,
    required this.tips,
  });

  final String title;
  final String leading;

  /// Eski parametre; rozetler her zaman şeftalidir.
  final Color badgeColor;

  /// (emoji, metin) çiftleri.
  final List<(String, String)> tips;

  @override
  Widget build(BuildContext context) {
    return ReportSectionCard(
      title: title,
      leading: leading,
      child: Column(
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                IconSquircle(
                  background: AppColors.peachTint,
                  size: 36,
                  radius: 12,
                  child: Text(tips[i].$1, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(tips[i].$2)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
