import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class AlertScreen extends StatefulWidget {
  final VoidCallback onGoBreathing;

  const AlertScreen({
    super.key,
    required this.onGoBreathing,
  });

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: S.t('التنبيه', 'Alert'),
      child: AnimatedBuilder(
        animation: bleService,
        builder: (context, _) {
          final active = bleService.alert;
          final elapsed = (active && bleService.alertStartedAt != null)
              ? DateTime.now().difference(bleService.alertStartedAt!)
              : Duration.zero;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: active
                          ? const [Color(0xFFF7EAF0), Color(0xFFE9DDF8)]
                          : const [Color(0xFFF7EEF8), Color(0xFFEDE4F8)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      active
                          ? Icons.warning_amber_rounded
                          : Icons.favorite_border,
                      size: 80,
                      color: active
                          ? AppColors.warning
                          : AppColors.lavenderDark,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  active
                      ? S.t('مؤشرات مرتفعة، يُنصح بالتهدئة',
                          'Elevated indicators — please calm down')
                      : S.t('لا يوجد تنبيه حاليًا', 'No active alert'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDarkOf(context),
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          _formatElapsed(elapsed),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _liveStat(
                        context,
                        Icons.favorite,
                        S.t('نبض القلب', 'BPM'),
                        bleService.bpm == null
                            ? '--'
                            : bleService.bpm!.toStringAsFixed(0),
                      ),
                      _liveStat(
                        context,
                        Icons.water_drop_outlined,
                        'GSR',
                        bleService.gsr == null
                            ? '--'
                            : bleService.gsr!.toStringAsFixed(0),
                      ),
                      _liveStat(
                        context,
                        Icons.directions_run,
                        S.t('الحركة', 'Motion'),
                        bleService.motion == null
                            ? '--'
                            : bleService.motion!.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    S.t(
                      'الحالة الحالية مستقرة. سيظهر التنبيه هنا عند وجود خطر.',
                      'Current state is stable. Alerts will appear here when needed.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: AppColors.textLightOf(context),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onGoBreathing,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      S.t('ابدئي التهدئة', 'Start calming'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _liveStat(
      BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.lavenderDark, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDarkOf(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLightOf(context),
          ),
        ),
      ],
    );
  }
}
