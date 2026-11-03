import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  // Animation state
  double scale = 1.0;
  bool inhaling = true;
  bool running = false; // start paused — user taps Start to begin
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      running = true;
      inhaling = true;
      scale = 1.25;
    });
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        inhaling = !inhaling;
        scale = inhaling ? 1.25 : 1.0;
      });
    });
  }

  void _stop() {
    timer?.cancel();
    timer = null;
    setState(() {
      running = false;
      scale = 1.0;
      inhaling = true;
    });
  }

  void _toggle() => running ? _stop() : _start();

  @override
  Widget build(BuildContext context) {
    final phaseLabel = !running
        ? S.t('متوقف', 'Paused')
        : (inhaling
            ? S.t('شهيق...', 'Inhale...')
            : S.t('زفير...', 'Exhale...'));

    return AppShell(
      title: S.t('التهدئة', 'Calm'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFF6EFFB), Color(0xFFEAE0F8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            AnimatedScale(
              scale: scale,
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7EFDF), Color(0xFFD8C2F2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              phaseLabel,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              S.t('خذي نفسًا عميقًا بهدوء...', 'Take a deep breath slowly...'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: _toggle,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lavender,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  running
                      ? S.t('إيقاف', 'Stop')
                      : S.t('بدء', 'Start'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
