import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/login_screen.dart';
import 'package:hadaa_app/screens/main_navigation_screen.dart';
import 'package:hadaa_app/services/supabase_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      // If a session is already cached on disk, skip login and go
      // straight to the main app. Otherwise show the login screen.
      final route = SupabaseService.isLoggedIn
          ? MaterialPageRoute(
              builder: (_) => const MainNavigationScreen())
          : MaterialPageRoute(builder: (_) => const LoginScreen());
      Navigator.pushReplacement(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1A1322), Color(0xFF2A2236)]
                : const [Color(0xFFF7F2FB), Color(0xFFECE0F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.white).withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.watch_outlined,
                size: 58,
                color: AppColors.lavenderDark,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              S.t('سوار حِداء', 'Hadaa Bracelet'),
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w800,
                color: AppColors.textDarkOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.t('Hadaa Bracelet', 'سوار حِداء'),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: AppColors.textLightOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
