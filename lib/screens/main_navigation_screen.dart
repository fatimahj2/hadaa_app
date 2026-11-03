import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/alert_screen.dart';
import 'package:hadaa_app/screens/breathing_screen.dart';
import 'package:hadaa_app/screens/connect_bracelet_screen.dart';
import 'package:hadaa_app/screens/home_screen.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/calibration_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  // Rising-edge tracking for two auto-navigation cases:
  //   - alert false→true   → jump to alert tab
  //   - connected false→true → jump to home tab (one-time, on first pair)
  // Without rising-edge logic the listener would re-fire on every BLE
  // notification and yank the user away from whatever screen they tapped.
  bool _wasAlerting = false;
  bool _wasConnected = false;
  bool _hasAutoNavigatedHome = false;

  @override
  void initState() {
    super.initState();
    // First-launch UX: if the bracelet isn't connected yet, send the user
    // straight to the Connect tab so they pair first. Once connected they
    // get auto-forwarded to Home (see _handleStateChange below).
    currentIndex = bleService.connected ? 0 : 3;
    _wasConnected = bleService.connected;
    _hasAutoNavigatedHome = bleService.connected;

    bleService.init();
    bleService.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    if (!mounted) return;

    // 1) Rising-edge alert → jump to alert tab
    final isAlerting = bleService.alert;
    if (isAlerting && !_wasAlerting && currentIndex != 1) {
      setState(() => currentIndex = 1);
    }
    _wasAlerting = isAlerting;

    // 2) First successful connection after login → jump from Connect tab
    // to Home tab AND immediately kick off a mandatory GSR calibration so
    // the user starts with a fresh per-session baseline. Only happens once
    // per session so the user can navigate freely afterward without being
    // yanked back.
    final isConnected = bleService.connected;
    if (isConnected && !_wasConnected && !_hasAutoNavigatedHome) {
      _hasAutoNavigatedHome = true;
      setState(() => currentIndex = 0);
      _kickoffCalibration();
    }
    _wasConnected = isConnected;
  }

  // Sends CMD:CALIBRATE and shows the calibration dialog. The tricky bit:
  // when the BLE connection callback fires (connected=true), the service
  // discovery hasn't completed yet, so commandCharacteristic is still
  // null. We poll for it for up to ~3 seconds before giving up.
  Future<void> _kickoffCalibration() async {
    // Wait for the post-frame so the home tab is fully rendered before
    // the dialog floats over it.
    await Future.delayed(const Duration(milliseconds: 100));

    // Poll for the command characteristic to be discovered. flutter_blue_plus
    // typically finishes service discovery within a second of connecting,
    // but can be slower on first connection.
    for (int i = 0; i < 15; i++) {
      if (!mounted) return;
      if (bleService.commandCharacteristic != null) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    final ok = await bleService.sendCommand('CMD:CALIBRATE');
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t(
            'تعذّر بدء المعايرة — تحقّقي من اتصال السوار',
            'Could not start calibration — check the bracelet connection',
          )),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CalibrationDialog(),
    );
  }

  @override
  void dispose() {
    bleService.removeListener(_handleStateChange);
    bleService.disposeService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watching appSettings here makes the bottom-nav labels AND every page
    // content rebuild when the user toggles language. The pages list is
    // recreated inside this builder, so each page widget is a new instance
    // and Flutter rebuilds it through the element-update mechanism.
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        // Note: do NOT use `const` constructors here. Const widgets are
        // cached as the same instance and Flutter's element-update logic
        // skips rebuilding identical instances — meaning S.t() inside
        // these screens would never re-evaluate when the language toggles.
        final pages = [
          HomeScreen(),
          AlertScreen(
            onGoBreathing: () => setState(() => currentIndex = 2),
          ),
          BreathingScreen(),
          ConnectBraceletScreen(),
        ];

        return Scaffold(
          backgroundColor: AppColors.bgOf(context),
          body: SafeArea(child: pages[currentIndex]),
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.cardOf(context),
            indicatorColor: AppColors.lavenderLight,
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                setState(() => currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: S.t('الرئيسية', 'Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.notifications_none),
                selectedIcon: const Icon(Icons.notifications),
                label: S.t('التنبيه', 'Alert'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.air_outlined),
                selectedIcon: const Icon(Icons.air),
                label: S.t('التهدئة', 'Calm'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.bluetooth_outlined),
                selectedIcon: const Icon(Icons.bluetooth),
                label: S.t('الاتصال', 'Connect'),
              ),
            ],
          ),
        );
      },
    );
  }
}
