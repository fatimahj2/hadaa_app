import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:hadaa_app/models/alert_record.dart';
import 'package:hadaa_app/services/history_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/app_shell.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Default date range: last 30 days through today.
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  // Two-digit padding helper used by both date and time formatting.
  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatDate(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)}';

  String _formatTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  String _formatDateTime(DateTime t) => '${_formatDate(t)} ${_formatTime(t)}';

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  // Records that fall inside the currently selected date range.
  List<AlertRecord> get _filtered {
    final start = DateTime(_range.start.year, _range.start.month,
        _range.start.day);
    // Include the entire end day (up to 23:59:59).
    final end = DateTime(
        _range.end.year, _range.end.month, _range.end.day, 23, 59, 59);
    return historyService.records.where((r) {
      return !r.startTime.isBefore(start) && !r.startTime.isAfter(end);
    }).toList();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.lavenderDark,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _range = picked);
    }
  }

  Future<void> _exportCsv() async {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t(
            'لا توجد سجلات ضمن النطاق المحدد',
            'No records in the selected range',
          )),
        ),
      );
      return;
    }

    // Build the CSV rows. Header first, then one row per filtered record.
    final rows = <List<dynamic>>[
      ['Date', 'Start time', 'End time', 'Duration (s)', 'Peak BPM', 'Peak GSR'],
    ];
    for (final r in filtered) {
      rows.add([
        _formatDate(r.startTime),
        _formatTime(r.startTime),
        _formatTime(r.endTime),
        r.durationSeconds,
        r.peakBpm.toStringAsFixed(0),
        r.peakGsr.toStringAsFixed(0),
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);

    // Write to a temp file and hand it to the system share sheet so the
    // user can save it to Downloads, Drive, send via WhatsApp, etc.
    final dir = await getTemporaryDirectory();
    final filename =
        'hadaa_history_${_formatDate(_range.start)}_${_formatDate(_range.end)}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: S.t('سجل تنبيهات حِداء', 'Hadaa alert history'),
      text: S.t(
        'سجل التنبيهات من ${_formatDate(_range.start)} إلى ${_formatDate(_range.end)}',
        'Alert history from ${_formatDate(_range.start)} to ${_formatDate(_range.end)}',
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t('مسح السجل؟', 'Clear history?')),
        content: Text(S.t(
            'سيتم حذف جميع السجلات نهائياً.', 'All records will be deleted.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t('إلغاء', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.t('مسح', 'Clear'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await historyService.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: appSettings,
          builder: (context, _) {
            return AppShell(
              title: S.t('سجل التنبيهات', 'Alert history'),
              actions: [
                IconButton(
                  tooltip: S.t('مسح السجل', 'Clear history'),
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.lavenderDark),
                  onPressed: _confirmClear,
                ),
              ],
              child: AnimatedBuilder(
                animation: historyService,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _rangeAndExportBar(context),
                      const SizedBox(height: 14),
                      _resultsList(context),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Top bar: shows the current date range, lets the user pick a new
  // one, and offers a download button to export the filtered records.
  Widget _rangeAndExportBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _pickRange,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.date_range,
                      color: AppColors.lavenderDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.t('النطاق الزمني', 'Date range'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLightOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDate(_range.start)}  →  ${_formatDate(_range.end)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDarkOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_calendar_outlined,
                      color: AppColors.lavenderDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_rounded),
              label: Text(
                S.t('تنزيل CSV', 'Download CSV'),
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lavender,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsList(BuildContext context) {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            S.t(
              'لا توجد تنبيهات في هذا النطاق',
              'No alerts in this date range',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLightOf(context),
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    return Column(
      children: filtered.map((r) => _recordCard(context, r)).toList(),
    );
  }

  Widget _recordCard(BuildContext context, AlertRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(r.durationSeconds),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: [
                  if (!r.synced)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: AppColors.textLightOf(context),
                      ),
                    ),
                  Text(
                    _formatDateTime(r.startTime),
                    style: TextStyle(
                      color: AppColors.textDarkOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(context, S.t('ذروة النبض', 'Peak BPM'),
                  r.peakBpm.toStringAsFixed(0), Icons.favorite),
              _stat(context, S.t('ذروة GSR', 'Peak GSR'),
                  r.peakGsr.toStringAsFixed(0), Icons.water_drop_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.lavenderDark, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
