import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hadaa_app/models/alert_record.dart';
import 'package:hadaa_app/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists past panic alerts locally to SharedPreferences as a
/// JSON-encoded list AND mirrors them to the Supabase `alerts` table
/// when the device is online and the user is logged in.
class HistoryService extends ChangeNotifier {
  static const _key = 'alert_history';
  static const _maxRecords = 100;

  List<AlertRecord> records = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    records = jsonList
        .map((s) => AlertRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  /// Append a new alert record (called from BLE service on the alert
  /// falling edge), trimming to the maximum allowed history size, then
  /// fire-and-forget push it to Supabase. The local record is marked
  /// synced=true on a successful push so we don't double-insert.
  Future<void> add(AlertRecord record) async {
    records.insert(0, record);
    if (records.length > _maxRecords) {
      records = records.sublist(0, _maxRecords);
    }
    await _persist();
    notifyListeners();

    // Try to push to Supabase right away. If it fails (offline, not
    // logged in, etc.) the record stays unsynced and the next syncUnsynced
    // call will retry it.
    final ok = await SupabaseService.syncAlert(record);
    if (ok) {
      record.synced = true;
      await _persist();
      notifyListeners();
    }
  }

  /// Push every record that hasn't been mirrored to Supabase yet. Called
  /// at app startup and after a successful login so previously-offline
  /// alerts get caught up.
  Future<void> syncUnsynced() async {
    if (!SupabaseService.isLoggedIn) return;
    bool changed = false;
    for (final r in records) {
      if (r.synced) continue;
      final ok = await SupabaseService.syncAlert(r);
      if (ok) {
        r.synced = true;
        changed = true;
      }
    }
    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> clear() async {
    records = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      records.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}

/// Global instance — initialized in main() before runApp().
final HistoryService historyService = HistoryService();
