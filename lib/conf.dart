import 'dart:async';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/sugg/sugg.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _fontKey = 'ar_font_size';
  static const _seedColorKey = 'seedc';
  static const _lastRouteKey = 'route';
  static const _readerIsOpenLexiconDireclyKey = 'reader_db_pop';
  static const _showSearchSuggKey = 'searchSugg';
  static const _showResutlsDireclyKey = 'dirRes';
  static const _useMoreArabicKey = 'dictEn';

  static const Color _seedColorDef = uiSeedColorDefualt;
  Color _seedColor = _seedColorDef;

  static const double _fontSizeDef = defaultArabicFontSize;
  double _fontSize = _fontSizeDef;

  static const ThemeMode _themeDef = ThemeMode.system;
  ThemeMode _theme = _themeDef;

  static const bool _readerIsOpenLexiconDireclyDef = false;
  bool _readerIsOpenLexiconDirecly = _readerIsOpenLexiconDireclyDef;

  static final String _lastRouteDef = routesToBeSavedInPref.first;
  String _lastRoute = _lastRouteDef;

  static const bool _showSearchSuggDef = true;
  bool _showSearchSugg = _showSearchSuggDef;

  static const bool _showResutlsDireclyDef = true;
  bool _showResutlsDirecly = _showResutlsDireclyDef;

  // show dict names in the selection in english
  static const bool _useMoreArabicDef = false;
  bool _useMoreArabic = _useMoreArabicDef;

  // TextStyle _arabicts = TextStyle(
  //   fontFamily: fontKitab,
  //   fontSize: defaultArabicFontSize,
  //   height: arabicFontHeihgt,
  // );

  VoidCallback? _refetchLexResults;

  final wake = _WakelockController();

  /// Load saved theme & font size from memory
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _theme = ThemeMode.values.firstWhere(
      (e) => e.name == prefs.getString(_themeKey),
      orElse: () => _themeDef,
    );

    final seedColorInt = prefs.getInt(_seedColorKey);
    _seedColor = seedColorInt == null ? _seedColorDef : Color(seedColorInt);

    _fontSize = prefs.getDouble(_fontKey) ?? _fontSizeDef;

    _readerIsOpenLexiconDirecly =
        prefs.getBool(_readerIsOpenLexiconDireclyKey) ??
        _readerIsOpenLexiconDireclyDef;

    _lastRoute = prefs.getString(_lastRouteKey) ?? _lastRouteDef;

    _showSearchSugg = prefs.getBool(_showSearchSuggKey) ?? _showSearchSuggDef;

    _showResutlsDirecly =
        prefs.getBool(_showResutlsDireclyKey) ?? _showResutlsDireclyDef;

    _useMoreArabic = prefs.getBool(_useMoreArabicKey) ?? _useMoreArabic;

    await wake.load();
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await load();
    notify();
  }

  void notify() {
    notifyListeners();
  }

  Future<void> saveTheme(ThemeMode mode) async {
    if (mode == _theme) return;
    _theme = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _theme.name);
  }

  Future<void> saveReaderIsOpenLexiconDirecly(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _readerIsOpenLexiconDirecly = v;
    await prefs.setBool(_readerIsOpenLexiconDireclyKey, v);
  }

  bool get readerIsOpenLexiconDirecly {
    return _readerIsOpenLexiconDirecly;
  }

  Future<void> saveShowSearchSugg(bool v) async {
    if (v == _showSearchSugg) return;
    _showSearchSugg = v;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSearchSuggKey, v);

    if (v) await SearchSuggestions.init();
    tryRefetchLexResults();
  }

  bool get showSearchSugg {
    return _showSearchSugg;
  }

  Future<void> saveShowResutlsDirecly(bool v) async {
    if (v == _showResutlsDirecly) return;
    _showResutlsDirecly = v;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showResutlsDireclyKey, v);

    tryRefetchLexResults();
  }

  bool get showResutlsDirecly {
    return _showResutlsDirecly;
  }

  Future<void> saveUseMoreArabic(bool v) async {
    if (v == _useMoreArabic) return;
    _useMoreArabic = v;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useMoreArabicKey, v);
  }

  bool get useMoreArabic => _useMoreArabic;

  Future<void> saveRoute(String r) async {
    final prefs = await SharedPreferences.getInstance();
    if (routesToBeSavedInPref.contains(r)) {
      await prefs.setString(_lastRouteKey, r);
    }
  }

  String get lastRoute {
    if (routesToBeSavedInPref.contains(_lastRoute)) return _lastRoute;
    return routesToBeSavedInPref.first;
  }

  Future<void> setFontSize(double size) async {
    if (_fontSize == size) return;
    _fontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontKey, size);
  }

  Color get seedColor => _seedColor;

  Future<void> setSeedColor(Color c) async {
    if (c == _seedColor) return;
    _seedColor = c;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, c.toARGB32());
  }

  double get fontSize {
    return _fontSize;
  }

  ThemeMode get theme {
    return _theme;
  }

  TextStyle getArabicTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: fontKitab,
      fontSize: _fontSize,
      height: arabicFontHeihgt,
      fontFamilyFallback: [fontKitab],
    );
  }

  set setRefetchLexResultsFunc(VoidCallback f) {
    _refetchLexResults = f;
  }

  void rmRefetchLexResultsFunc() {
    _refetchLexResults = null;
  }

  void tryRefetchLexResults() {
    if (_refetchLexResults == null) return;
    _refetchLexResults!();
  }
}

const durationToScreenWake = 7;

class _WakelockController {
  static const _wakeLockKey = 'wakeLock';
  static bool _enabled = true;

  static const Duration _timeout = Duration(minutes: durationToScreenWake);
  static Timer? _timer;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tougle(enable: prefs.getBool(_wakeLockKey) ?? true);
  }

  bool get isEnabled {
    return _enabled;
  }

  void tougle({bool? enable}) async {
    _enabled = enable ?? !_enabled;

    final prefs = await SharedPreferences.getInstance();
    if (_enabled) {
      try {
        await WakelockPlus.enable();
      } catch (_) {
        _enabled = false;
      }
      _resetTimer();
      await prefs.setBool(_wakeLockKey, true);
    } else {
      await WakelockPlus.disable();
      _timer?.cancel();
      await prefs.setBool(_wakeLockKey, false);
    }
  }

  Future<void> onUserActivity(PointerEvent? _) async {
    if (_enabled) {
      await WakelockPlus.enable();
      _resetTimer();
    }
  }

  static void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      WakelockPlus.disable();
    });
  }
}
