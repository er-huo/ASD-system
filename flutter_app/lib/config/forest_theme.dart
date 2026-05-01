import 'package:flutter/material.dart';

class ForestPalette {
  static const Color bark = Color(0xFF6B4F3A);
  static const Color moss = Color(0xFF5F7D4E);
  static const Color fern = Color(0xFF7FA36A);
  static const Color sage = Color(0xFFDCE7D1);
  static const Color mist = Color(0xFFF6F1E8);
  static const Color sunrise = Color(0xFFF2C98A);
  static const Color berry = Color(0xFFB56B6B);
  static const Color cream = Color(0xFFFFFBF6);
}

final ColorScheme forestColorScheme = ColorScheme.fromSeed(
  seedColor: ForestPalette.moss,
  brightness: Brightness.light,
).copyWith(
  primary: ForestPalette.moss,
  onPrimary: Colors.white,
  secondary: ForestPalette.sunrise,
  onSecondary: ForestPalette.bark,
  tertiary: ForestPalette.fern,
  surface: ForestPalette.cream,
  onSurface: ForestPalette.bark,
  error: ForestPalette.berry,
  outline: ForestPalette.fern.withValues(alpha: 0.45),
  shadow: Colors.black.withValues(alpha: 0.12),
);

final ThemeData forestTheme = ThemeData(
  useMaterial3: true,
  colorScheme: forestColorScheme,
  scaffoldBackgroundColor: ForestPalette.mist,
  appBarTheme: const AppBarTheme(
    backgroundColor: ForestPalette.cream,
    foregroundColor: ForestPalette.bark,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: ForestPalette.cream,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: ForestPalette.sage),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: ForestPalette.sage,
    selectedColor: ForestPalette.sunrise,
    disabledColor: ForestPalette.sage.withValues(alpha: 0.6),
    labelStyle: const TextStyle(
      color: ForestPalette.bark,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    side: BorderSide.none,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      color: ForestPalette.bark,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    titleMedium: TextStyle(
      color: ForestPalette.bark,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      color: ForestPalette.bark,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      color: ForestPalette.bark,
      height: 1.4,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: ForestPalette.bark,
    contentTextStyle: const TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);
