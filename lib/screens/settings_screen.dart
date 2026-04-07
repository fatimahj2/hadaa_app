import 'package:flutter/material.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'الإعدادات',
      child: Column(
        children: [
          _tile(Icons.notifications_outlined, 'الإشعارات'),
          const SizedBox(height: 12),
          _tile(Icons.bluetooth_searching, 'إعادة الاتصال بالسوار'),
          const SizedBox(height: 12),
          _tile(Icons.person_outline, 'تغيير الاسم'),
          const SizedBox(height: 12),
          _tile(Icons.info_outline, 'حول التطبيق'),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: AppColors.textLight,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.lavenderDark),
        ],
      ),
    );
  }
}