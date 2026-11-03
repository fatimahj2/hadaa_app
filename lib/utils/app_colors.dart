import 'package:flutter/material.dart';

/// Color palette for the Hadaa app.
///
/// Constants are the LIGHT mode colors. The `*Of(context)` helpers return
/// the appropriate value based on the current theme brightness, so widgets
/// can do `color: AppColors.cardOf(context)` and get the right thing in
/// either mode without knowing about themes themselves.
class AppColors {
  // ---------- light-mode constants ----------
  static const bg = Color(0xFFF5F0FA);
  static const card = Colors.white;
  static const lavender = Color(0xFFB89BE7);
  static const lavenderDark = Color(0xFF7C62B7);
  static const lavenderLight = Color(0xFFEDE4F8);
  static const beige = Color(0xFFF7F1E8);
  static const cream = Color(0xFFFFFCF9);
  static const textDark = Color(0xFF5B4A77);
  static const textLight = Color(0xFF9A8CB4);
  static const success = Color(0xFF5DAE8B);
  static const warning = Color(0xFFE2A567);
  static const danger = Color(0xFFD97D98);

  // ---------- dark-mode equivalents ----------
  // Hand-tuned to keep the lavender vibe but darker. The accent colors
  // (lavender, success, warning, danger) stay the same in both modes.
  static const bgDark = Color(0xFF1A1322);
  static const cardDark = Color(0xFF2A2236);
  static const creamDark = Color(0xFF362C46);
  static const textDarkOnDark = Color(0xFFEDE4F8);
  static const textLightOnDark = Color(0xFFB5A8CC);

  // ---------- adaptive helpers ----------
  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bgOf(BuildContext c) => _isDark(c) ? bgDark : bg;
  static Color cardOf(BuildContext c) => _isDark(c) ? cardDark : card;
  static Color creamOf(BuildContext c) => _isDark(c) ? creamDark : cream;
  static Color textDarkOf(BuildContext c) =>
      _isDark(c) ? textDarkOnDark : textDark;
  static Color textLightOf(BuildContext c) =>
      _isDark(c) ? textLightOnDark : textLight;
}
