import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/history_screen.dart';
import 'package:hadaa_app/screens/settings_screen.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';

/// Common page chrome:
///   - Header row: action icons on the left, battery badge + title on the right
///   - On root screens: theme + language + history + settings icons
///   - On pushed routes (canPop): a single back arrow instead
///   - Scrollable body below
class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: Row(
            children: [
              if (canPop)
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.lavenderDark),
                  onPressed: () => Navigator.pop(context),
                )
              else ...[
                IconButton(
                  tooltip: appSettings.isDark ? 'Light mode' : 'Dark mode',
                  icon: Icon(
                    appSettings.isDark ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.lavenderDark,
                  ),
                  onPressed: appSettings.toggleTheme,
                ),
                IconButton(
                  tooltip: 'Toggle language',
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.lavenderDark, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appSettings.isArabic ? 'EN' : 'AR',
                      style: const TextStyle(
                        color: AppColors.lavenderDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  onPressed: appSettings.toggleLanguage,
                ),
                IconButton(
                  tooltip: 'History',
                  icon: const Icon(Icons.history,
                      color: AppColors.lavenderDark),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.lavenderDark),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
              ...?actions,
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const _BatteryBadge(),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDarkOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Small live-updating battery badge that subscribes to bleService directly
/// so the AppShell parent doesn't have to rebuild the whole header on every
/// BLE notification.
class _BatteryBadge extends StatelessWidget {
  const _BatteryBadge();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bleService,
      builder: (context, _) {
        final bat = bleService.battery;
        IconData icon;
        Color color;
        if (bat == null) {
          icon = Icons.battery_unknown;
          color = AppColors.textLightOf(context);
        } else if (bat <= 10) {
          icon = Icons.battery_alert;
          color = AppColors.danger;
        } else if (bat <= 20) {
          icon = Icons.battery_2_bar;
          color = AppColors.warning;
        } else if (bat <= 50) {
          icon = Icons.battery_4_bar;
          color = AppColors.lavenderDark;
        } else if (bat <= 80) {
          icon = Icons.battery_5_bar;
          color = AppColors.lavenderDark;
        } else {
          icon = Icons.battery_full;
          color = AppColors.success;
        }

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                bat == null ? '--' : '$bat%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
