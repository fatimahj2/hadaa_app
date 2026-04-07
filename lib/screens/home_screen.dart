import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class HomeScreen extends StatelessWidget {
  final BleBraceletService ble;
  const HomeScreen({super.key, required this.ble});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'سوار حَداء',
      actions: const [
        Icon(Icons.notifications_none, color: AppColors.lavenderDark),
        SizedBox(width: 8),
      ],
      child: AnimatedBuilder(
        animation: ble,
        builder: (context, _) {
          final statusText = ble.alert
              ? 'تنبيه'
              : ble.connected
                  ? 'مستقر'
                  : 'غير متصل';

          final statusColor = ble.alert
              ? AppColors.warning
              : ble.connected
                  ? AppColors.success
                  : AppColors.textLight;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _connectionBanner(ble),
              const SizedBox(height: 16),
              _statusCard(statusText, statusColor),
              const SizedBox(height: 14),
              _valueCard(
                icon: Icons.favorite,
                title: 'نبض القلب',
                value: ble.bpm == null
                    ? '-- bpm'
                    : '${ble.bpm!.toStringAsFixed(0)} bpm',
              ),
              const SizedBox(height: 12),
              _valueCard(
                icon: Icons.water_drop_outlined,
                title: 'التوصيلية الجلدية',
                value: ble.gsr == null ? '--' : ble.gsr!.toStringAsFixed(0),
              ),
              const SizedBox(height: 12),
              _valueCard(
                icon: Icons.directions_run,
                title: 'الحركة',
                value: ble.motion == null ? '--' : ble.motion!.toStringAsFixed(1),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _connectionBanner(BleBraceletService ble) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            ble.connected ? 'متصل بالسوار' : 'غير متصل',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            ble.connected ? Icons.check_circle : Icons.cancel_outlined,
            color: ble.connected ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String statusText, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          const Text(
            'الحالة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFF7F0E5), Color(0xFFDCCAF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.lavenderDark),
        ],
      ),
    );
  }
}