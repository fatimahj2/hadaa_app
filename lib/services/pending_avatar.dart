import 'dart:io';
import 'package:hadaa_app/services/supabase_service.dart';
import 'package:path_provider/path_provider.dart';

/// Helpers for the "pending avatar" file: the image the user picked at
/// signup time, before they were authenticated and could upload it to
/// Supabase Storage. The file is stashed in the app documents folder
/// and consumed on the first successful login.
class PendingAvatar {
  static const _filename = 'pending_avatar.jpg';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_filename');
  }

  /// Save the picked image bytes locally so we can upload them after
  /// the user logs in for the first time.
  static Future<void> stash(File source) async {
    final dest = await _file();
    await source.copy(dest.path);
  }

  /// If a pending avatar exists on disk, upload it now (the user has
  /// just successfully logged in, so we have a session) and delete
  /// the local copy. Returns the resulting public URL or null.
  static Future<String?> uploadIfPending() async {
    if (!SupabaseService.isLoggedIn) return null;
    final file = await _file();
    if (!await file.exists()) return null;
    final url = await SupabaseService.uploadAvatar(file);
    if (url != null) {
      try {
        await file.delete();
      } catch (_) {
        // best-effort cleanup; not critical if it fails
      }
    }
    return url;
  }
}
