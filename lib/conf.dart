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
  static const _lastRouteKey = 'route';
  static const _readerIsOpenLexiconDireclyKey = 'reader_db_pop';
  static const _readerRightAlignedKey = 'readerRightAlign';
  static const _showSearchSuggKey = 'searchSugg';

  double _fontSize = defaultArabicFontSize;
  ThemeMode _theme = ThemeMode.system;
  bool _readerIsOpenLexiconDirecly = false;
  bool _readerRightAligned = false;
  String _lastRoute = routesToBeSavedInPref.first;
  bool _showSearchSugg = true;

  final wake = _WakelockController();

  /// Load saved theme & font size from memory
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _theme = ThemeMode.values.firstWhere(
      (e) => e.name == prefs.getString(_themeKey),
      orElse: () => ThemeMode.system,
    );

    _fontSize = prefs.getDouble(_fontKey) ?? _fontSize;

    _readerIsOpenLexiconDirecly =
        prefs.getBool(_readerIsOpenLexiconDireclyKey) ??
        _readerIsOpenLexiconDirecly;

    _readerRightAligned =
        prefs.getBool(_readerRightAlignedKey) ?? _readerRightAligned;

    _lastRoute = prefs.getString(_lastRouteKey) ?? _lastRoute;

    _showSearchSugg = prefs.getBool(_showSearchSuggKey) ?? _showSearchSugg;

    await wake.load();
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

  Future<void> saveReaderRightAligned(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _readerRightAligned = v;
    await prefs.setBool(_readerRightAlignedKey, v);
  }

  bool get readerRightAligned {
    return _readerRightAligned;
  }

  Future<void> saveShowSearchSugg(bool v) async {
    if (v == _showSearchSugg) return;
    _showSearchSugg = v;

    if (v) SearchSuggestions.init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSearchSuggKey, v);
  }

  bool get showSearchSugg {
    return _showSearchSugg;
  }

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
    final prefs = await SharedPreferences.getInstance();
    notifyListeners();
    await prefs.setDouble(_fontKey, size);
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
      height: 1.8,
    );
  }
}

class _WakelockController {
  static const _wakeLockKey = 'wakeLock_enabled';
  static bool _enabled = true;

  static const Duration _timeout = Duration(minutes: 7);
  static Timer? _timer;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tougle(enable: prefs.getBool(_wakeLockKey) ?? true);
  }

  bool isEnabled() {
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
