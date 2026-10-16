import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';
import 'package:mama_meow/utils/platform_info.dart';

/// Aktivite ekleme sheet'ini standart ayarlarla açar.
Future<T?> showActivitySheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusSheet),
      ),
    ),
    builder: builder,
  );
}

/// Her zaman 24 saat biçiminde saat seçici.
Future<TimeOfDay?> pick24hTime(BuildContext context, TimeOfDay initial) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

/// "HH:mm"
String formatHHmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Alarm iznini kontrol edip hatırlatıcı sayfasını açar.
Future<void> openReminders(BuildContext context, String routeName) async {
  await AlarmPolicy.instance.ensure();
  if (!context.mounted) return;
  await context.pushNamed(routeName);
}

/// Kayıt başarısız olduğunda gösterilen ortak mesaj.
void showSaveError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Couldn't save. Please try again."),
      backgroundColor: AppColors.berryInk,
    ),
  );
}

/// Sheet zemini: beyaz, üst köşeler 32 px, yumuşak gölge.
BoxDecoration sheetDecoration({bool shadow = true}) {
  return BoxDecoration(
    color: AppColors.cottonWhite,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(AppTheme.radiusSheet),
    ),
    boxShadow: shadow ? AppColors.floatShadow : null,
  );
}

/// DraggableScrollableSheet + (Android'de) alt SafeArea + dekorasyon.
class ActivitySheetFrame extends StatelessWidget {
  const ActivitySheetFrame({
    super.key,
    required this.decoration,
    required this.builder,
    this.initialChildSize = 0.85,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.96,
  });

  final Decoration decoration;
  final Widget Function(BuildContext context, ScrollController controller)
  builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, controller) {
        final body = Container(
          decoration: decoration,
          child: builder(context, controller),
        );
        return PlatformInfo.isAndroid
            ? SafeArea(top: false, child: body)
            : body;
      },
    );
  }
}

/// Sheet'in standart başlığı: tutamaç, aktivite ikonu, başlık, alt başlık,
/// kapatma butonu.
class ActivitySheetHeader extends StatelessWidget {
  const ActivitySheetHeader({
    super.key,
    required this.title,
    this.kind,
    this.subtitle,
    this.actions = const [],
    this.showClose = true,
  });

  final String title;
  final ActivityKind? kind;
  final String? subtitle;

  /// Kapatma butonunun solundaki ek ikon butonları (ör. hatırlatıcı).
  final List<Widget> actions;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final kind = this.kind;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (kind != null) ...[
                IconSquircle(
                  background: kind.tileColor,
                  size: 48,
                  child: ActivityIcon(kind: kind),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.headlineMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.charcoalSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              for (final action in actions) ...[
                action,
                const SizedBox(width: 8),
              ],
              if (showClose)
                IconButton(
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.pinkTint,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.deepCharcoal),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ekleme sheet'lerinin ortak iskeleti: kaydırılabilir içerik + Cancel/Save
/// butonları. Kaydetme sürerken Save pasif olur (çift kayıt engeli).
class ActivitySheetScaffold extends StatelessWidget {
  const ActivitySheetScaffold({
    super.key,
    required this.child,
    required this.onSave,
    this.kind,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.header,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
    this.attachScrollController = false,
    this.backLabel = 'Cancel',
    this.initialChildSize = 0.85,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.96,
  });

  /// Başlıktaki aktivite ikonu.
  final ActivityKind? kind;

  /// null değilse standart [ActivitySheetHeader] gösterilir.
  final String? title;
  final String? subtitle;

  /// Başlıktaki ek ikon butonları (ör. hatırlatıcı).
  final List<Widget> actions;

  /// Kaydırma alanının üstünde sabit kalan ek kısım.
  final Widget? header;
  final Widget child;
  final EdgeInsets padding;

  /// true → içerik sheet'in sürükleme kontrolcüsüne bağlanır.
  final bool attachScrollController;
  final String backLabel;

  /// null → Save pasif (form geçersiz).
  final Future<void> Function()? onSave;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    return ActivitySheetFrame(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      decoration: sheetDecoration(),
      builder: (context, controller) => Column(
        children: [
          if (title != null)
            ActivitySheetHeader(
              title: title!,
              kind: kind,
              subtitle: subtitle,
              actions: actions,
            ),
          ?header,
          Expanded(
            child: SingleChildScrollView(
              controller: attachScrollController ? controller : null,
              padding: padding,
              child: child,
            ),
          ),
          SheetActionBar(backLabel: backLabel, onSave: onSave),
        ],
      ),
    );
  }
}

class SheetActionBar extends StatefulWidget {
  const SheetActionBar({
    super.key,
    required this.onSave,
    this.backLabel = 'Cancel',
  });

  final Future<void> Function()? onSave;
  final String backLabel;

  @override
  State<SheetActionBar> createState() => _SheetActionBarState();
}

class _SheetActionBarState extends State<SheetActionBar> {
  bool _saving = false;

  Future<void> _handleSave() async {
    final onSave = widget.onSave;
    if (_saving || onSave == null) return;
    setState(() => _saving = true);
    try {
      await onSave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cottonWhite,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(widget.backLabel),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryPillButton(
                label: 'Save',
                height: 52,
                loading: _saving,
                onPressed: widget.onSave == null ? null : _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sheet içinde beyaz başlıklı kart.
class SheetSectionCard extends StatelessWidget {
  const SheetSectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cottonWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 15,
              color: AppColors.deepCharcoal,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// "Time" alanı (dokununca saat seçici açılır).
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.value,
    required this.onTap,
    this.label = 'Time',
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 20,
              color: AppColors.activeBerry,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.charcoalSoft,
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçim kartlarının görünümü (pembe zemin; seçiliyken beyaz + berry çerçeve).
class ChipTileStyle {
  const ChipTileStyle({
    required this.width,
    required this.height,
    this.background = AppColors.pinkTint,
    this.selectedBackground = AppColors.cottonWhite,
    this.selectedBorder = AppColors.activeBerry,
    this.selectedIcon = AppColors.activeBerry,
    this.padding = 10,
    this.selectedBorderWidth = 2,
    this.iconGap = 8,
    this.labelMaxLines = 3,
    this.labelFontSize = 12,
    this.labelHeight = 1.15,
    this.shadow = false,
    this.itemGap = 10,
  });

  final double width;
  final double height;
  final double padding;
  final Color background;
  final Color selectedBackground;
  final Color selectedBorder;
  final double selectedBorderWidth;
  final Color selectedIcon;
  final double iconGap;
  final int labelMaxLines;
  final double labelFontSize;
  final double? labelHeight;
  final bool shadow;
  final double itemGap;

  /// Kare kartlar (diaper, solid tepkileri).
  static const standard = ChipTileStyle(width: 96, height: 96);

  /// Sleep seçenekleri (2 satır etiket).
  static const compact = ChipTileStyle(
    width: 96,
    height: 96,
    iconGap: 6,
    labelMaxLines: 2,
  );

  /// Küçük kartlar (ilaç adları).
  static const small = ChipTileStyle(
    width: 100,
    height: 80,
    padding: 8,
    iconGap: 4,
    labelMaxLines: 2,
    labelFontSize: 11,
    labelHeight: null,
    itemGap: 8,
  );
}

/// Başlık + yatay kaydırılabilir tek seçimli kart listesi.
class ChipPickerSection<T> extends StatelessWidget {
  const ChipPickerSection({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.title,
    this.labelBuilder,
    this.iconBuilder,
    this.style = ChipTileStyle.standard,
  });

  final String? title;
  final List<T> items;
  final T? value;
  final ValueChanged<T> onChanged;

  /// null → `toString()`.
  final String Function(T item)? labelBuilder;
  final IconData Function(T item)? iconBuilder;
  final ChipTileStyle style;

  @override
  Widget build(BuildContext context) {
    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final it in items)
            Padding(
              padding: EdgeInsets.only(right: style.itemGap),
              child: _ChipTile(
                label: labelBuilder?.call(it) ?? '$it',
                icon: iconBuilder?.call(it),
                selected: it == value,
                style: style,
                onTap: () => onChanged(it),
              ),
            ),
        ],
      ),
    );
    if (title == null) return row;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 15,
              color: AppColors.deepCharcoal,
            ),
          ),
        ),
        row,
      ],
    );
  }
}

class _ChipTile extends StatelessWidget {
  const _ChipTile({
    required this.label,
    required this.selected,
    required this.style,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final ChipTileStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: s.width,
              height: s.height,
              padding: EdgeInsets.all(s.padding),
              decoration: BoxDecoration(
                color: selected ? s.selectedBackground : s.background,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? s.selectedBorder : Colors.transparent,
                  width: s.selectedBorderWidth,
                ),
                boxShadow: s.shadow && selected ? AppColors.berryGlow : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 24,
                      color: selected ? s.selectedIcon : AppColors.charcoalSoft,
                    ),
                    SizedBox(height: s.iconGap),
                  ],
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: s.labelMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: s.labelFontSize,
                      height: s.labelHeight,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.deepCharcoal,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(top: 6, right: 6, child: _CheckBadge()),
          ],
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.activeBerry,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: size * 0.68, color: AppColors.cottonWhite),
    );
  }
}

/// Sheet bölüm başlığı (15/w700, koyu kömür).
class SheetSectionLabel extends StatelessWidget {
  const SheetSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 15,
          color: AppColors.deepCharcoal,
        ),
      ),
    );
  }
}

/// Pembe hap zemin üzerinde berry seçili dilimli seçim (Nursing/Bottle, oz/ml).
/// Her dokunuşta [onChanged] çağrılır (eski açılır listeyle aynı davranış).
class SheetPillToggle extends StatelessWidget {
  const SheetPillToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _PillSegment(
                label: option,
                selected: option == value,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.activeBerry : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected
                      ? AppColors.cottonWhite
                      : AppColors.deepCharcoal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Büyük taraf kartı: seçiliyken beyaz + 2 px berry çerçeve + onay rozeti,
/// değilken pembe zemin.
class SideChoiceCard extends StatelessWidget {
  const SideChoiceCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusCard);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? AppColors.cottonWhite : AppColors.pinkTint,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? AppColors.activeBerry : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: selected
                        ? AppColors.activeBerry
                        : AppColors.charcoalSoft,
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 12,
                right: 12,
                child: _CheckBadge(size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
