import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

const double mediumFontSize = 18;
const double defaultReaderArabicFontSize = 18;
const String defaultReaderArabicFont = fontKitab;
const double arabicFontHeihgt = 2;

const Color uiSeedColorDefualt = Color(0xFF673AB7);
const uiSeedColors = [
  uiSeedColorDefualt,
  Color(0xFF3A7BD4),
  Color(0xFF2A9D8E),
  Color(0xFF2ECC71),
  Color(0xFFE76F50),
];

class ReaderColors {
  final Color surface;
  final Color onSurface;

  const ReaderColors({required this.surface, required this.onSurface});
}

const readerColorsLight = ReaderColors(
  surface: Color(0xFFFFFAF3),
  onSurface: Color(0xFF222223),
);

const readerColorsDark = ReaderColors(
  surface: Color(0xFF121212),
  onSurface: Color(0xFFEAEAEA),
);

ThemeData buildTheme(
  BuildContext context,
  Brightness b,
  AppSettingsController an,
) {
  final cs = ColorScheme.fromSeed(seedColor: an.seedColor, brightness: b);

  var td = ThemeData.from(colorScheme: cs, useMaterial3: true);
  td = td.copyWith(appBarTheme: td.appBarTheme.copyWith(centerTitle: true));
  return td;
}

ThemeData buildDarkTheme(BuildContext context, AppSettingsController an) {
  final cs = ColorScheme.fromSeed(
    seedColor: an.seedColor,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    // scaffoldBackgroundColor: const Color(0xFF121212),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs, an.readerFontSize),
    // inputDecorationTheme: InputDecorationTheme(
    //   hintStyle: TextStyle(color: Color(0xFF777777)),
    // ),
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
    // titleTextStyle: TextStyle(fontSize: 20, color: cs.onSurface),
    // titleTextStyle: TextStyle(fontSize: 20),
  );
}
