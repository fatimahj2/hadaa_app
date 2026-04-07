import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/alert_screen.dart';
import 'package:hadaa_app/screens/breathing_screen.dart';
import 'package:hadaa_app/screens/connect_bracelet_screen.dart';
import 'package:hadaa_app/screens/home_screen.dart';
import 'package:hadaa_app/screens/settings_screen.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  final BleBraceletService ble = BleBraceletService();

  @override
  void initState() {
    super.initState();
    ble.init();
    ble.addListener(_handleAlertNavigation);
  }

  void _handleAlertNavigation() {
    if (ble.alert && currentIndex != 1 && mounted) {
      setState(() => currentIndex = 1);
    }
  }

  @override
  void dispose() {
    ble.removeListener(_handleAlertNavigation);
    ble.disposeService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(ble: ble),
      AlertScreen(
        ble: ble,
        onGoBreathing: () => setState(() => currentIndex = 2),
      ),
      const BreathingScreen(),
      ConnectBraceletScreen(ble: ble),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lavenderLight,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'التنبيه',
          ),
          NavigationDestination(
            icon: Icon(Icons.air_outlined),
            selectedIcon: Icon(Icons.air),
            label: 'التهدئة',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth_outlined),
            selectedIcon: Icon(Icons.bluetooth),
            label: 'الاتصال',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}