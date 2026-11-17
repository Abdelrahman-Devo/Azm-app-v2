import 'package:material_ui/material_ui.dart';

/// Azm brand palette: deep navy + elegant green, with calm helper colors.
class AzmColors {
  const AzmColors._();

  static const navy = Color(0xFF0F2D52);
  static const navyDeep = Color(0xFF0A1727);
  static const navyCard = Color(0xFF11243C);
  static const green = Color(0xFF1FA463);
  static const greenBright = Color(0xFF4AD08A);
  static const gold = Color(0xFFF4A024);
  static const lightBackground = Color(0xFFF3F6F9);
}

const String azmFontFamily = 'Tajawal';

ThemeData buildAzmTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final base = ColorScheme.fromSeed(
    seedColor: AzmColors.green,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: dark ? AzmColors.greenBright : AzmColors.navy,
    onPrimary: dark ? AzmColors.navyDeep : Colors.white,
    secondary: dark ? AzmColors.greenBright : AzmColors.green,
    onSecondary: dark ? AzmColors.navyDeep : Colors.white,
    surface: dark ? AzmColors.navyCard : Colors.white,
    onSurface: dark ? const Color(0xFFE8EEF5) : const Color(0xFF14202E),
    onSurfaceVariant: dark ? const Color(0xFF9FB1C5) : const Color(0xFF5A6B7D),
    surfaceContainerHighest: dark
        ? const Color(0xFF1B3252)
        : const Color(0xFFE8EEF4),
    outlineVariant: dark ? const Color(0xFF223B5C) : const Color(0xFFDCE4EC),
  );

  final background = dark ? AzmColors.navyDeep : AzmColors.lightBackground;
  const radius = 20.0;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: azmFontFamily,
    scaffoldBackgroundColor: background,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: azmFontFamily,
        fontWeight: FontWeight.w800,
        fontSize: 20,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: scheme.secondary.withValues(alpha: dark ? 0.22 : 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: azmFontFamily,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.secondary
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.secondary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(
        alpha: dark ? 0.6 : 0.7,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.secondary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? AzmColors.greenBright : AzmColors.green,
        foregroundColor: dark ? AzmColors.navyDeep : Colors.white,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: azmFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(64, 52),
        side: BorderSide(color: scheme.outlineVariant, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: azmFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.secondary,
        textStyle: const TextStyle(
          fontFamily: azmFontFamily,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? AzmColors.greenBright : AzmColors.green,
      foregroundColor: dark ? AzmColors.navyDeep : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      textStyle: TextStyle(
        fontFamily: azmFontFamily,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF223B5C) : AzmColors.navy,
      contentTextStyle: const TextStyle(
        fontFamily: azmFontFamily,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.secondary.withValues(alpha: 0.2),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: TextStyle(
        fontFamily: azmFontFamily,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? (dark ? AzmColors.navyDeep : Colors.white)
            : scheme.onSurfaceVariant,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? scheme.secondary
            : scheme.surfaceContainerHighest,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.secondary,
      thumbColor: scheme.secondary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
    ),
  );
}
