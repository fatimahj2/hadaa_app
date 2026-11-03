import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-configurable preferences (separate from theme/language which live
/// in AppSettings). Persisted to SharedPreferences so values survive app
/// restarts.
class UserSettings extends ChangeNotifier {
  static const _kName        = 'pref_bracelet_name';
  static const _kMessage     = 'pref_alert_message';
  static const _kSensitivity = 'pref_sensitivity';

  static const defaultBraceletName  = 'Hadaa_Bracelet';
  static const defaultAlertMessage  =
      'تم رصد مؤشرات مرتفعة، ابدئي التهدئة الآن';
  static const double defaultSensitivity = 50.0;

  String  braceletName  = defaultBraceletName;
  String  alertMessage  = defaultAlertMessage;
  double  sensitivity   = defaultSensitivity; // 0..100, cosmetic for now

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    braceletName  = prefs.getString(_kName) ?? defaultBraceletName;
    alertMessage  = prefs.getString(_kMessage) ?? defaultAlertMessage;
    sensitivity   = prefs.getDouble(_kSensitivity) ?? defaultSensitivity;
    notifyListeners();
  }

  Future<void> setBraceletName(String name) async {
    braceletName = name.trim().isEmpty ? defaultBraceletName : name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, braceletName);
    notifyListeners();
  }

  Future<void> setAlertMessage(String message) async {
    alertMessage = message.trim().isEmpty ? defaultAlertMessage : message.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMessage, alertMessage);
    notifyListeners();
  }

  Future<void> setSensitivity(double value) async {
    sensitivity = value.clamp(0.0, 100.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSensitivity, sensitivity);
    notifyListeners();
  }
}

final UserSettings userSettings = UserSettings();
