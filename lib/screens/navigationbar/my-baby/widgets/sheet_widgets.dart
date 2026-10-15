import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/utils/platform_info.dart';

/// Aktivite ekleme sheet'ini standart ayarlarla açar.
Future<T?> showActivitySheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
      backgroundColor: Colors.red,
    ),
  );
}

/// Sheet zemin dekorasyonu (degrade + üst köşeler yuvarlak).
BoxDecoration sheetDecoration(
  List<Color> colors, {
  double radius = 16,
  bool shadow = true,
}) {
  return BoxDecoration(
    gradient: LinearGradient(colors: colors),
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    boxShadow: shadow
        ? const [BoxShadow(blurRadius: 16, color: Colors.black12)]
        : null,
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

/// Ekleme sheet'lerinin ortak iskeleti: kaydırılabilir içerik + Back/Save
/// butonları. Kaydetme sürerken Save pasif olur (çift kayıt engeli).
class ActivitySheetScaffold extends StatelessWidget {
  const ActivitySheetScaffold({
    super.key,
    required this.gradient,
    required this.child,
    required this.onSave,
    this.radius = 16,
    this.header,
    this.padding = const EdgeInsets.all(16),
    this.attachScrollController = false,
    this.backLabel = 'Back',
    this.saveColor,
    this.initialChildSize = 0.85,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.96,
  });

  final List<Color> gradient;
  final double radius;

  /// Kaydırma alanının üstünde sabit kalan kısım.
  final Widget? header;
  final Widget child;
  final EdgeInsets padding;

  /// true → içerik sheet'in sürükleme kontrolcüsüne bağlanır.
  final bool attachScrollController;
  final String backLabel;

  /// null → Save pasif (form geçersiz).
  final Future<void> Function()? onSave;

  /// null → OutlinedButton, aksi halde bu renkte ElevatedButton.
  final Color? saveColor;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    return ActivitySheetFrame(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      decoration: sheetDecoration(gradient, radius: radius),
      builder: (context, controller) => Column(
        children: [
          ?header,
          Expanded(
            child: SingleChildScrollView(
              controller: attachScrollController ? controller : null,
              padding: padding,
              child: child,
            ),
          ),
          SheetActionBar(
            backLabel: backLabel,
            onSave: onSave,
            saveColor: saveColor,
          ),
        ],
      ),
    );
  }
}

class SheetActionBar extends StatefulWidget {
  const SheetActionBar({
    super.key,
    required this.onSave,
    this.backLabel = 'Back',
    this.saveColor,
  });

  final Future<void> Function()? onSave;
  final String backLabel;
  final Color? saveColor;

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
    final canSave = widget.onSave != null && !_saving;
    final color = widget.saveColor;

    Widget label(Color? fg) => _saving
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Text('Save', style: fg == null ? null : TextStyle(color: fg));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.grey.shade200),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(widget.backLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: color == null
                ? OutlinedButton(
                    onPressed: canSave ? _handleSave : null,
                    child: label(null),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.onSave != null
                          ? color
                          : Colors.grey,
                    ),
                    onPressed: canSave ? _handleSave : null,
                    child: label(Colors.white),
                  ),
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Text(value),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Seçim kartlarının görünümü.
class ChipTileStyle {
  const ChipTileStyle({
    required this.width,
    required this.height,
    required this.background,
    required this.selectedBackground,
    required this.selectedBorder,
    required this.selectedIcon,
    this.padding = 10,
    this.selectedBorderWidth = 1.5,
    this.iconGap = 8,
    this.labelMaxLines = 3,
    this.labelFontSize = 11,
    this.labelHeight = 1.15,
    this.shadow = true,
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

  /// Turuncu kare kartlar (diaper, solid tepkileri).
  static const orange = ChipTileStyle(
    width: 96,
    height: 96,
    background: AppColors.kLightOrange,
    selectedBackground: AppColors.kOrange,
    selectedBorder: AppColors.kDeepOrange,
    selectedIcon: AppColors.kDeepOrange,
  );

  /// Büyük turuncu kartlar (pumping taraf seçimi).
  static const orangeLarge = ChipTileStyle(
    width: 120,
    height: 120,
    background: AppColors.kLightOrange,
    selectedBackground: AppColors.kOrange,
    selectedBorder: AppColors.kDeepOrange,
    selectedIcon: AppColors.kDeepOrange,
  );

  /// Sleep seçenekleri (2 satır etiket).
  static const orangeCompact = ChipTileStyle(
    width: 96,
    height: 96,
    background: AppColors.kLightOrange,
    selectedBackground: AppColors.kOrange,
    selectedBorder: AppColors.kDeepOrange,
    selectedIcon: AppColors.kDeepOrange,
    iconGap: 6,
    labelMaxLines: 2,
  );

  /// Küçük turuncu kartlar (ilaç adları).
  static const orangeSmall = ChipTileStyle(
    width: 100,
    height: 80,
    padding: 8,
    background: AppColors.kLightOrange,
    selectedBackground: AppColors.kOrange,
    selectedBorder: AppColors.kDeepOrange,
    selectedBorderWidth: 2,
    selectedIcon: AppColors.kDeepOrange,
    iconGap: 4,
    labelMaxLines: 2,
    labelFontSize: 10,
    labelHeight: null,
    shadow: false,
    itemGap: 8,
  );

  /// Nursing kartları.
  static final teal = ChipTileStyle(
    width: 100,
    height: 80,
    padding: 8,
    background: Colors.white,
    selectedBackground: Colors.teal.shade100,
    selectedBorder: Colors.teal,
    selectedBorderWidth: 2,
    selectedIcon: Colors.teal,
    iconGap: 4,
    labelMaxLines: 2,
    labelFontSize: 10,
    labelHeight: null,
    shadow: false,
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
    this.style = ChipTileStyle.orange,
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
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: s.width,
          height: s.height,
          padding: EdgeInsets.all(s.padding),
          decoration: BoxDecoration(
            color: selected ? s.selectedBackground : s.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? s.selectedBorder : Colors.black12,
              width: selected ? s.selectedBorderWidth : 1,
            ),
            boxShadow: s.shadow
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 24,
                  color: selected ? s.selectedIcon : Colors.black54,
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
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
