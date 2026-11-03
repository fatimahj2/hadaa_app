import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class ConnectBraceletScreen extends StatelessWidget {
  const ConnectBraceletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: S.t('الاتصال بالسوار', 'Connect bracelet'),
      actions: const [
        Icon(Icons.bluetooth, color: AppColors.lavenderDark),
        SizedBox(width: 8),
      ],
      child: AnimatedBuilder(
        animation: bleService,
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
                  onPressed:
                      bleService.scanning ? null : bleService.startScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lavender,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(bleService.scanning
                      ? S.t('جاري البحث...', 'Scanning...')
                      : S.t('بحث عن السوار', 'Search for bracelet')),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    if (bleService.devices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          S.t('لا توجد أجهزة بعد', 'No devices yet'),
                          style: TextStyle(
                              color: AppColors.textLightOf(context)),
                        ),
                      ),
                    ...bleService.devices.map((d) {
                      final isSelected =
                          bleService.connectedDeviceId == d.remoteId.str;
                      final name = d.platformName.isNotEmpty
                          ? d.platformName
                          : S.t('جهاز بدون اسم', 'Unnamed device');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success)
                            : Icon(Icons.bluetooth_searching,
                                color: AppColors.textLightOf(context)),
                        title: Text(
                          name,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: AppColors.textDarkOf(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          d.remoteId.str,
                          textAlign: TextAlign.right,
                        ),
                        trailing: isSelected
                            ? TextButton(
                                onPressed: bleService.disconnect,
                                child: Text(S.t('فصل', 'Disconnect')),
                              )
                            : TextButton(
                                onPressed: () => bleService.connectToDevice(d),
                                child: Text(S.t('اتصال', 'Connect')),
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
