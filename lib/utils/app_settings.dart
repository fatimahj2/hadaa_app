import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences (theme + language). A single global instance is
/// shared across the whole app and persisted to SharedPreferences so the
/// user's choice survives app restarts.
class AppSettings extends ChangeNotifier {
  static const _kIsDark = 'pref_is_dark';
  static const _kIsArabic = 'pref_is_arabic';

  bool _isDark = false;
  bool _isArabic = true;

  bool get isDark => _isDark;
  bool get isArabic => _isArabic;

  /// Read previously saved values from disk. Call once at app startup
  /// (before runApp so the first frame already shows the right theme).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_kIsDark) ?? false;
    _isArabic = prefs.getBool(_kIsArabic) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, _isDark);
  }

  Future<void> toggleLanguage() async {
    _isArabic = !_isArabic;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsArabic, _isArabic);
  }
}

final AppSettings appSettings = AppSettings();
