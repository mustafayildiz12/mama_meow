import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mama_meow/utils/date_range.dart';

/// Aktivite raporlarının renk paleti. Her rapor sayfası kendi paletini
/// [ReportPaletteScope] ile verir; kartlar renkleri buradan okur.
class ReportPalette {
  const ReportPalette({
    required this.tint,
    required this.segmentFill,
    this.badge,
    this.segmentBackground = Colors.white,
    this.segmentActiveForeground = Colors.white,
  });

  /// [ReportSectionCard] degradesinin başlangıç rengi.
  final Color tint;

  /// Kart başlığındaki emoji rozetinin zemini (null → [tint]).
  final Color? badge;

  /// Daily/Weekly/Monthly seçicisinde aktif buton zemini.
  final Color segmentFill;
  final Color segmentBackground;
  final Color segmentActiveForeground;

  static const fallback = ReportPalette(
    tint: Color(0xFFE2E8F0),
    segmentFill: Color(0xFF94A3B8),
  );

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

/// Raporlarda kullanılan 4 kademeli renk skalası.
Color tierColor(
  num value, {
  required num high,
  required num mid,
  required num low,
}) {
  if (value >= high) return const Color(0xFF2ECC71);
  if (value >= mid) return const Color(0xFFFF7F50);
  if (value >= low) {
    // Biraz daha parlak sarı
    final hsl = HSLColor.fromColor(const Color(0xFFF1C40F));
    return hsl.withLightness((hsl.lightness * 1.10).clamp(0, 1)).toColor();
  }
  return const Color(0xFF3498DB);
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

/// Daily / Weekly / Monthly cam efektli seçici.
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
    final inactiveFg = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: palette.segmentBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
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
                      inactiveFg: inactiveFg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ]
            : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add),
                        label: Text(actionLabel!),
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

/// Paletin rengiyle degrade zeminli rapor kartı.
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

  /// Sağ üstteki emoji rozeti (null → rozet yok).
  final String? leading;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = ReportPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.tint, Colors.white.withValues(alpha: 0.9)],
          stops: const [0.2, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (leading != null)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.badge ?? palette.tint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(leading!, style: const TextStyle(fontSize: 24)),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
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
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
            if (i > 0) SizedBox(width: gap),
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
    final titleMedium = Theme.of(context).textTheme.titleMedium;
    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            title,
            style: titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: valueMaxLines,
            style: titleMedium?.copyWith(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
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
                    backgroundColor: trackColor ?? color.withValues(alpha: 0.1),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(tips[i].$1, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(tips[i].$2)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
