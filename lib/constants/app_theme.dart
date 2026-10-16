import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

/// Warm Cotton & Berry teması (docs/design/warm-cotton-berry/DESIGN.md).
/// Bileşenler renklerini buradan alır; ekranlarda renk sabiti yazılmaz.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Nunito';

  static const double radiusCard = 24;
  static const double radiusInput = 16;
  static const double radiusSheet = 32;
  static const double buttonHeight = 56;

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.activeBerry,
    onPrimary: AppColors.cottonWhite,
    primaryContainer: AppColors.pinkTint,
    onPrimaryContainer: AppColors.deepCharcoal,
    secondary: AppColors.warmPink,
    onSecondary: AppColors.deepCharcoal,
    secondaryContainer: AppColors.pinkTint,
    onSecondaryContainer: AppColors.deepCharcoal,
    tertiary: AppColors.peachPastel,
    onTertiary: AppColors.deepCharcoal,
    tertiaryContainer: AppColors.peachTint,
    onTertiaryContainer: AppColors.deepCharcoal,
    error: AppColors.berryInk,
    onError: AppColors.cottonWhite,
    errorContainer: AppColors.pinkTint,
    onErrorContainer: AppColors.deepCharcoal,
    surface: AppColors.cottonWhite,
    onSurface: AppColors.deepCharcoal,
    onSurfaceVariant: AppColors.charcoalSoft,
    surfaceContainerLowest: AppColors.cottonWhite,
    surfaceContainerLow: AppColors.cottonWhite,
    surfaceContainer: AppColors.cosyIvory,
    surfaceContainerHigh: AppColors.pinkTint,
    surfaceContainerHighest: AppColors.pinkTint,
    outline: AppColors.outline,
    outlineVariant: AppColors.hairline,
    shadow: AppColors.deepCharcoal,
    scrim: AppColors.deepCharcoal,
    inverseSurface: AppColors.deepCharcoal,
    onInverseSurface: AppColors.cosyIvory,
    inversePrimary: AppColors.warmPink,
    surfaceTint: Colors.transparent,
  );

  static TextTheme _textTheme() {
    const c = AppColors.deepCharcoal;
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: c),
      displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: c),
      displaySmall: TextStyle(
        fontSize: 32,
        height: 38 / 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: c,
      ),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w800,
        color: c,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w800,
        color: c,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w700,
        color: c,
      ),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: c,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: c,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: AppColors.charcoalSoft,
      ),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
    );
  }

  static ThemeData light() {
    final textTheme = _textTheme();
    const pill = StadiumBorder();
    const buttonLabel = TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    const buttonSize = Size(64, 52);
    final inputRadius = BorderRadius.circular(radiusInput);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: _scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.cosyIvory,
      canvasColor: AppColors.cosyIvory,
      dividerColor: AppColors.hairline,
      iconTheme: const IconThemeData(color: AppColors.deepCharcoal),
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.cosyIvory,
        foregroundColor: AppColors.deepCharcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontFamily: fontFamily),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.activeBerry,
          foregroundColor: AppColors.cottonWhite,
          disabledBackgroundColor: AppColors.hairline,
          disabledForegroundColor: AppColors.charcoalSoft,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: pill,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: buttonLabel,
        ),
      ),
      // Renkler şemadan gelir: FilledButton berry, FilledButton.tonal pinkTint.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepCharcoal,
          side: const BorderSide(color: AppColors.outline, width: 1.5),
          shape: pill,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: buttonLabel,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.berryInk,
          textStyle: buttonLabel.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.cottonWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.charcoalSoft),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.charcoalSoft),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.berryInk,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.charcoalSoft,
        suffixIconColor: AppColors.charcoalSoft,
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.activeBerry, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.berryInk),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.berryInk, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.pinkTint,
        selectedColor: AppColors.activeBerry,
        disabledColor: AppColors.hairline,
        checkmarkColor: AppColors.cottonWhite,
        side: BorderSide.none,
        shape: pill,
        labelStyle: textTheme.labelMedium?.copyWith(fontFamily: fontFamily),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          fontFamily: fontFamily,
          color: AppColors.cottonWhite,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cottonWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cottonWhite,
        modalBackgroundColor: AppColors.cottonWhite,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cottonWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontFamily: fontFamily),
        contentTextStyle: textTheme.bodyMedium?.copyWith(fontFamily: fontFamily),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepCharcoal,
        actionTextColor: AppColors.warmPink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          fontFamily: fontFamily,
          color: AppColors.cottonWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.activeBerry,
        foregroundColor: AppColors.cottonWhite,
        elevation: 2,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.activeBerry,
        linearTrackColor: AppColors.pinkTint,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.cottonWhite
              : AppColors.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.activeBerry
              : AppColors.hairline,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.activeBerry
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.cottonWhite),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.activeBerry
              : AppColors.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.activeBerry,
        inactiveTrackColor: AppColors.pinkTint,
        thumbColor: AppColors.activeBerry,
        overlayColor: AppColors.activeBerry.withValues(alpha: 0.16),
        valueIndicatorColor: AppColors.deepCharcoal,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.charcoalSoft,
        textColor: AppColors.deepCharcoal,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontFamily: fontFamily),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(fontFamily: fontFamily),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.activeBerry
                : AppColors.pinkTint,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.cottonWhite
                : AppColors.deepCharcoal,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(buttonLabel.copyWith(fontSize: 14)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.berryInk,
        unselectedLabelColor: AppColors.charcoalSoft,
        indicatorColor: AppColors.activeBerry,
        dividerColor: AppColors.hairline,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.cottonWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.cottonWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.cottonWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.activeBerry,
        selectionColor: AppColors.warmPink.withValues(alpha: 0.4),
        selectionHandleColor: AppColors.activeBerry,
      ),
    );
  }
}
