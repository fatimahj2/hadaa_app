import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class ConnectBraceletScreen extends StatelessWidget {
  final BleBraceletService ble;
  const ConnectBraceletScreen({super.key, required this.ble});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'الاتصال بالسوار',
      actions: const [
        Icon(Icons.settings_outlined, color: AppColors.lavenderDark),
        SizedBox(width: 8),
      ],
      child: AnimatedBuilder(
        animation: ble,
        builder: (context, _) {
          return Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFDCCAF5), Color(0xFFB89BE7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bluetooth,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: ble.scanning ? null : ble.startScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lavender,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(ble.scanning ? 'جاري البحث...' : 'بحث عن السوار'),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    if (ble.devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'لا توجد أجهزة بعد',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ),
                    ...ble.devices.map((d) {
                      final isSelected =
                          ble.connectedDeviceId == d.remoteId.str;
                      final name = d.platformName.isNotEmpty
                          ? d.platformName
                          : 'جهاز بدون اسم';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success)
                            : const Icon(Icons.bluetooth_searching,
                                color: AppColors.textLight),
                        title: Text(
                          name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          d.remoteId.str,
                          textAlign: TextAlign.right,
                        ),
                        trailing: isSelected
                            ? TextButton(
                                onPressed: ble.disconnect,
                                child: const Text('فصل'),
                              )
                            : TextButton(
                                onPressed: () => ble.connectToDevice(d),
                                child: const Text('اتصال'),
                              ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
