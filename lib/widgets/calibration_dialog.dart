import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/strings.dart';

/// Modal dialog shown while the bracelet re-learns the GSR baseline.
///
/// Displays clear instructions, a progress indicator, and counts up the
/// elapsed seconds. Auto-closes when bleService.calibrating flips to false
/// (the bracelet sends `CALIB:0` once the 60-second window completes), or
/// after a 70-second hard timeout as a fallback.
///
/// Used both from the Settings screen ("Start calibration" button) and
/// from MainNavigationScreen on the user's first successful pairing.
class CalibrationDialog extends StatefulWidget {
  const CalibrationDialog({super.key});

  @override
  State<CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<CalibrationDialog> {
  Timer? _ticker;
  Timer? _timeoutTimer;
  int _elapsed = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    bleService.addListener(_checkDone);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
    _timeoutTimer = Timer(const Duration(seconds: 70), () {
      if (!mounted) return;
      _markDone();
    });
  }

  void _checkDone() {
    // bleService.calibrating starts true once the bracelet starts learning,
    // then flips to false when the baseline locks. We wait for that flip,
    // but only after a few seconds to make sure we caught the rising edge.
    if (mounted && !bleService.calibrating && _elapsed > 5) {
      _markDone();
    }
  }

  void _markDone() {
    if (_done) return;
    _done = true;
    setState(() {});
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _timeoutTimer?.cancel();
    bleService.removeListener(_checkDone);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_elapsed / 60).clamp(0.0, 1.0);

    return AlertDialog(
      backgroundColor: AppColors.cardOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_done) ...[
            const Icon(Icons.check_circle,
                color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              S.t('اكتملت المعايرة!', 'Calibration complete!'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDarkOf(context),
              ),
            ),
          ] else ...[
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    color: AppColors.lavender,
                    backgroundColor: AppColors.lavenderLight,
                  ),
                  Text(
                    '${(60 - _elapsed).clamp(0, 60)}s',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDarkOf(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.t('جاري المعايرة...', 'Calibrating...'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDarkOf(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.t(
                'ضعي السوار على المعصم واجلسي بهدوء وتنفسي طبيعياً.\nلا تتحركي حتى تكتمل المعايرة.',
                'Wear the bracelet on your wrist, sit quietly, and breathe normally.\nDo not move until calibration completes.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textLightOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
