import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class AlertScreen extends StatelessWidget {
  final BleBraceletService ble;
  final VoidCallback onGoBreathing;

  const AlertScreen({
    super.key,
    required this.ble,
    required this.onGoBreathing,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'التنبيه',
      child: AnimatedBuilder(
        animation: ble,
        builder: (context, _) {
          final active = ble.alert;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  height: 190,
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
                      size: 84,
                      color: active
                          ? AppColors.warning
                          : AppColors.lavenderDark,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  active ? 'مؤشرات مرتفعة، يُنصح بالتهدئة' : 'لا يوجد تنبيه حاليًا',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  active
                      ? 'تم رصد ارتفاع في المؤشرات الحيوية، يرجى البدء بالتهدئة الآن.'
                      : 'الحالة الحالية مستقرة. سيظهر التنبيه هنا عند وجود خطر.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onGoBreathing,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'ابدئي التهدئة',
                      style: TextStyle(fontSize: 18),
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
}