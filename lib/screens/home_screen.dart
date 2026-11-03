import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tick once a second so the "data status" indicator can flip from
  // "receiving" → "not receiving" even when no new BLE notifications
  // are arriving (otherwise nothing would re-render).
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // True if a BLE notification arrived in the last ~3 seconds.
  bool get _isReceiving {
    final last = bleService.lastDataAt;
    if (!bleService.connected || last == null) return false;
    return DateTime.now().difference(last).inSeconds <= 3;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: S.t('سوار حِداء', 'Hadaa Bracelet'),
      actions: const [
        Icon(Icons.favorite_outline, color: AppColors.lavenderDark),
        SizedBox(width: 8),
      ],
      child: AnimatedBuilder(
        animation: bleService,
        builder: (context, _) {
          final statusText = bleService.alert
              ? S.t('تنبيه', 'Alert')
              : bleService.connected
                  ? S.t('مستقر', 'Stable')
                  : S.t('غير متصل', 'Offline');
          final statusColor = bleService.alert
              ? AppColors.warning
              : bleService.connected
                  ? AppColors.success
                  : AppColors.textLightOf(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _connectionBanner(context),
              const SizedBox(height: 16),
              _statusCard(context, statusText, statusColor),
              const SizedBox(height: 14),
              _bpmChartCard(context, bleService.bpmHistory),
              const SizedBox(height: 12),
              _valueCard(
                context: context,
                icon: Icons.favorite,
                title: S.t('نبض القلب', 'Heart rate'),
                value: bleService.bpm == null
                    ? '-- bpm'
                    : '${bleService.bpm!.toStringAsFixed(0)} bpm',
              ),
              const SizedBox(height: 12),
              _gsrCard(context),
              const SizedBox(height: 12),
              _valueCard(
                context: context,
                icon: Icons.directions_run,
                title: S.t('الحركة', 'Motion'),
                value: bleService.motion == null
                    ? '--'
                    : bleService.motion!.toStringAsFixed(1),
              ),
              const SizedBox(height: 12),
              _batteryCard(context, bleService.battery),
              const SizedBox(height: 12),
              _dataStatusCard(context),
            ],
          );
        },
      ),
    );
  }

  // GSR card with a "relaxed" / "stressed" label appended to the value.
  // Threshold is the same 1.10× baseline ratio used by the firmware's
  // de-escalation logic — anything above counts as elevated.
  Widget _gsrCard(BuildContext context) {
    if (bleService.gsr == null) {
      return _valueCard(
        context: context,
        icon: Icons.water_drop_outlined,
        title: S.t('التوصيلية الجلدية', 'Skin conductance'),
        value: '--',
      );
    }

    final gsr = bleService.gsr!;
    final base = bleService.gsrBaseline;
    String value = gsr.toStringAsFixed(0);
    Color? labelColor;

    if (base != null && base > 0) {
      final stressed = gsr >= base * 1.10;
      final label = stressed
          ? S.t('متوتر', 'Stressed')
          : S.t('مسترخي', 'Relaxed');
      labelColor = stressed ? AppColors.warning : AppColors.success;
      value = '${gsr.toStringAsFixed(0)}  •  $label';
    }

    return _valueCard(
      context: context,
      icon: Icons.water_drop_outlined,
      title: S.t('التوصيلية الجلدية', 'Skin conductance'),
      value: value,
      valueColor: labelColor,
    );
  }

  // Replaces the old "Last data received" card. Small indicator showing
  // whether the bracelet is actively streaming or stale, color-coded.
  Widget _dataStatusCard(BuildContext context) {
    final receiving = _isReceiving;
    final color = receiving ? AppColors.success : AppColors.danger;
    final icon = receiving ? Icons.sensors : Icons.sensors_off;
    final value = receiving
        ? S.t('يستقبل', 'Receiving')
        : S.t('لا يستقبل', 'Not receiving');

    return _valueCard(
      context: context,
      icon: icon,
      iconColor: color,
      title: S.t('حالة البيانات', 'Data status'),
      value: value,
      valueColor: color,
    );
  }

  Widget _bpmChartCard(BuildContext context, List<double> history) {
    // Filter out the 0 readings (no finger on sensor) — they would draw a
    // huge spike to the floor of the chart and visually overflow the card.
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      final v = history[i];
      if (v > 0) spots.add(FlSpot(i.toDouble(), v));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t('اتجاه نبض القلب', 'Heart rate trend'),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkOf(context),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ClipRect(
              child: spots.isEmpty
                  ? Center(
                      child: Text(
                        S.t('لا توجد بيانات بعد', 'No data yet'),
                        style: TextStyle(
                            color: AppColors.textLightOf(context)),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        clipData: const FlClipData.all(),
                        minY: 40,
                        maxY: 160,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppColors.lavender,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.lavender.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            bleService.connected
                ? S.t('متصل بالسوار', 'Connected to bracelet')
                : S.t('غير متصل', 'Not connected'),
            style: TextStyle(
              color: AppColors.textDarkOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            bleService.connected ? Icons.check_circle : Icons.cancel_outlined,
            color: bleService.connected ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _statusCard(
      BuildContext context, String statusText, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Text(
            S.t('الحالة', 'Status'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textLightOf(context),
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

  Widget _batteryCard(BuildContext context, int? bat) {
    IconData icon;
    Color iconColor;
    String valueText;

    if (bat == null) {
      icon = Icons.battery_unknown;
      iconColor = AppColors.textLightOf(context);
      valueText = '--';
    } else {
      valueText = '$bat%';
      if (bat <= 10) {
        icon = Icons.battery_alert;
        iconColor = AppColors.danger;
      } else if (bat <= 20) {
        icon = Icons.battery_2_bar;
        iconColor = AppColors.warning;
      } else if (bat <= 50) {
        icon = Icons.battery_4_bar;
        iconColor = AppColors.lavenderDark;
      } else if (bat <= 80) {
        icon = Icons.battery_5_bar;
        iconColor = AppColors.lavenderDark;
      } else {
        icon = Icons.battery_full;
        iconColor = AppColors.success;
      }
    }

    return _valueCard(
      context: context,
      icon: icon,
      iconColor: iconColor,
      title: S.t('بطارية السوار', 'Bracelet battery'),
      value: valueText,
    );
  }

  Widget _valueCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textDarkOf(context),
                fontSize: 18,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textLightOf(context),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: iconColor ?? AppColors.lavenderDark),
        ],
      ),
    );
  }
}
