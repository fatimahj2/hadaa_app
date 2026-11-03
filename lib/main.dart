import 'package:flutter/material.dart';
import 'package:hadaa_app/config.dart';
import 'package:hadaa_app/screens/splash_screen.dart';
import 'package:hadaa_app/services/history_service.dart';
import 'package:hadaa_app/services/user_settings.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';
import 'package:hadaa_app/utils/notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await initializeNotifications();
  // Load all persisted preferences before the first frame so the splash
  // already renders in the user's previously chosen theme + language.
  await appSettings.load();
  await userSettings.load();
  await historyService.load();
  // Best-effort: push any locally-cached alerts that haven't been
  // mirrored to Supabase yet (e.g. fired while offline). Non-blocking.
  historyService.syncUnsynced();
  runApp(const HadaaApp());
}

class HadaaApp extends StatelessWidget {
  const HadaaApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lavender,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      fontFamily: 'Arial',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching appSettings here is what makes theme changes propagate
    // (via Theme.of inheritance). Language changes are handled separately
    // by AnimatedBuilder wrappers inside individual screens.
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hadaa Bracelet',
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: appSettings.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
