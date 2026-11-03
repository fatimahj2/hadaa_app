import 'dart:io';
import 'package:hadaa_app/models/alert_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase client. Centralizes auth + profile
/// queries + storage uploads + alert syncing so the rest of the app
/// doesn't have to know how the backend is structured.
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ----- session helpers -----

  static Session? get currentSession => client.auth.currentSession;
  static User?    get currentUser    => client.auth.currentUser;
  static bool     get isLoggedIn     => currentUser != null;

  // ----- auth -----

  static Future<String?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int    age,
    required String sex,
    required double weightKg,
    required double heightCm,
    required String phone,
  }) async {
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name':  lastName,
          'age':        age.toString(),
          'sex':        sex,
          'weight_kg':  weightKg.toString(),
          'height_cm':  heightCm.toString(),
          'phone':      phone,
        },
      );
      if (res.user == null) return 'Sign-up failed (no user returned)';
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> signOut() => client.auth.signOut();

  // ----- profile -----

  static Future<Map<String, dynamic>?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return res;
    } catch (_) {
      return null;
    }
  }

  // ----- avatar -----

  /// Upload a profile picture file to the avatars storage bucket and
  /// patch the profiles row with the public URL. Returns the public URL
  /// on success or null on failure.
  ///
  /// Path convention: <user_id>/avatar.jpg — matches the storage RLS
  /// policy which checks (storage.foldername(name))[1] = auth.uid().
  static Future<String?> uploadAvatar(File imageFile) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final path = '${user.id}/avatar.jpg';
      await client.storage.from('avatars').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      final url = client.storage.from('avatars').getPublicUrl(path);
      // Cache-busting query param so the new image shows immediately
      // (otherwise the CDN may serve a stale copy from a previous upload).
      final urlWithBuster =
          '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      await client
          .from('profiles')
          .update({'avatar_url': urlWithBuster}).eq('id', user.id);
      return urlWithBuster;
    } catch (_) {
      return null;
    }
  }

  // ----- alerts -----

  /// Push a single alert record to the Supabase `alerts` table.
  /// Returns true on success, false on any failure (offline, RLS
  /// rejection, etc.) so the caller can leave the local record marked
  /// as unsynced and retry later.
  static Future<bool> syncAlert(AlertRecord record) async {
    final user = currentUser;
    if (user == null) return false;
    try {
      await client.from('alerts').insert({
        'id':               record.id,
        'user_id':          user.id,
        'start_time':       record.startTime.toIso8601String(),
        'end_time':         record.endTime.toIso8601String(),
        'peak_bpm':         record.peakBpm,
        'peak_gsr':         record.peakGsr,
        'duration_seconds': record.durationSeconds,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
