import 'package:ara_dict/conf.dart';
import 'package:flutter/material.dart';

const double mediumFontSize = 18;
const double defaultArabicFontSize = 18;
const double arabicFontHeihgt = 1.8;

const uiSeedColors = [
  Colors.deepPurple,
  Color(0xFFE76F50),
  Color(0xFF3A7BD4),
  Color(0xFF2A9D8E),
  Color(0xFF2ECC71),
];

ThemeData buildLightTheme(BuildContext context, AppSettingsController an) {
  final cs = ColorScheme.fromSeed(seedColor: an.seedColor).copyWith(
    brightness: Brightness.light,
    surface: const Color(0xFFFFFAF3),
    onSurface: const Color(0xFF222223),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor: const Color(0xFFFFFAF3),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs, an.fontSize),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
    ),
  );
}

ThemeData buildDarkTheme(BuildContext context, AppSettingsController an) {
  final cs =
      ColorScheme.fromSeed(
        seedColor: an.seedColor,
        brightness: Brightness.dark,
      ).copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFEAEAEA),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: const Color(0xFF121212),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs, an.fontSize),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Color(0xFF777777)),
    ),
  );
}

DrawerThemeData _buildDrawerTheme(ColorScheme cs) {
  return DrawerThemeData(
    backgroundColor: cs.surface, // your paper color
    scrimColor: cs.onSurface.withAlpha(30), // overlay when drawer opens
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
    ),
  );
}

AppBarTheme _buildAppBarTheme(ColorScheme cs, double mediumFontSizeArg) {
  return AppBarTheme(
    // backgroundColor: cs.primary,
    // foregroundColor: cs.onPrimary,
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 20, color: cs.onSurface),
    // titleTextStyle: TextStyle(fontSize: 20),
  );
}
