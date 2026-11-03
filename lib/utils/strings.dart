import 'package:hadaa_app/utils/app_settings.dart';

/// Tiny inline-translation helper. Each call site passes both the Arabic and
/// English version of the string, and we pick the right one based on the
/// current language setting. No localization framework needed for this scale.
///
/// Usage:
///   Text(S.t('دخول', 'Login'))
class S {
  static String t(String ar, String en) {
    return appSettings.isArabic ? ar : en;
  }
}
