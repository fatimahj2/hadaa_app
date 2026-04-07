import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/splash_screen.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  runApp(const HadaaApp());
}

class HadaaApp extends StatelessWidget {
  const HadaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hadaa Bracelet',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Arial',
      ),
      home: const SplashScreen(),
    );
  }
}
