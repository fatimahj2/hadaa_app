import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/login_screen.dart';
import 'package:hadaa_app/services/ble_service.dart';
import 'package:hadaa_app/services/supabase_service.dart';
import 'package:hadaa_app/services/user_settings.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:hadaa_app/widgets/app_shell.dart';
import 'package:hadaa_app/widgets/calibration_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _msgCtrl;
  late double _sensitivity;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: userSettings.braceletName);
    _msgCtrl = TextEditingController(text: userSettings.alertMessage);
    _sensitivity = userSettings.sensitivity;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Capture the messenger reference before popping — once we pop, our
    // context becomes invalid for ScaffoldMessenger.of() lookups.
    final messenger = ScaffoldMessenger.of(context);
    await userSettings.setBraceletName(_nameCtrl.text);
    await userSettings.setAlertMessage(_msgCtrl.text);
    await userSettings.setSensitivity(_sensitivity);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(S.t('تم الحفظ', 'Saved'))),
    );
  }

  Future<void> _calibrate() async {
    // Bracelet must be connected and the firmware must support the command
    // characteristic for this to work. Tell the user clearly if not.
    if (!bleService.connected || bleService.commandCharacteristic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.t(
            'يجب الاتصال بالسوار أولاً',
            'Please connect the bracelet first',
          )),
        ),
      );
      return;
    }

    final ok = await bleService.sendCommand('CMD:CALIBRATE');
    if (!ok || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.t(
              'تعذّر إرسال أمر المعايرة',
              'Failed to send calibration command',
            )),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CalibrationDialog(),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.t('تسجيل الخروج', 'Log out')),
        content: Text(S.t(
          'هل تريدين تسجيل الخروج من حسابك؟',
          'Do you want to log out of your account?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.t('إلغاء', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.t('تسجيل الخروج', 'Log out'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await SupabaseService.signOut();
    if (!mounted) return;
    // Pop everything and go back to login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgOf(context),
      body: SafeArea(
        // Watching appSettings here makes the screen rebuild on language
        // change, so all the S.t() calls inside re-evaluate.
        child: AnimatedBuilder(
          animation: appSettings,
          builder: (context, _) {
            return AppShell(
              title: S.t('الإعدادات', 'Settings'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _accountSection(),
                  const SizedBox(height: 14),
                  _section(
                    title: S.t('اسم السوار', 'Bracelet name'),
                    child: TextField(
                      controller: _nameCtrl,
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(color: AppColors.textDarkOf(context)),
                      decoration: _inputDecoration(
                          context, 'Hadaa_Bracelet'),
                    ),
                    hint: S.t(
                      'يجب أن يطابق اسم البلوتوث المُعلن من السوار',
                      'Must match the BLE name advertised by the bracelet',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title:
                        S.t('رسالة التنبيه المخصصة', 'Custom alert message'),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(color: AppColors.textDarkOf(context)),
                      decoration: _inputDecoration(
                        context,
                        S.t('رسالة التنبيه...', 'Alert message...'),
                      ),
                    ),
                    hint: S.t(
                      'هذه الرسالة تظهر في إشعار التنبيه',
                      'This message appears in the alert notification',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title:
                        '${S.t('حساسية التنبيه', 'Alert sensitivity')}: ${_sensitivity.toStringAsFixed(0)}%',
                    child: Slider(
                      value: _sensitivity,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.lavender,
                      label: '${_sensitivity.toStringAsFixed(0)}%',
                      onChanged: (v) => setState(() => _sensitivity = v),
                    ),
                    hint: S.t(
                      'حالياً يتم حفظ القيمة محلياً فقط',
                      'For now this value is stored locally only',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    title: S.t('معايرة GSR', 'GSR calibration'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _calibrate,
                          icon: const Icon(Icons.tune,
                              color: AppColors.lavenderDark),
                          label: Text(
                            S.t('بدء المعايرة', 'Start calibration'),
                            style: const TextStyle(
                              color: AppColors.lavenderDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                                color: AppColors.lavenderDark, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    hint: S.t(
                      'يعيد تعلّم المستوى الأساسي للتوصيلية الجلدية خلال 60 ثانية. يجب الاتصال بالسوار أولاً.',
                      'Re-learns the skin conductance baseline over 60 seconds. The bracelet must be connected first.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      S.t('حفظ الإعدادات', 'Save settings'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textLightOf(context)),
      filled: true,
      fillColor: AppColors.creamOf(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Account section: shows the logged-in user's email and a logout button.
  Widget _accountSection() {
    final email = SupabaseService.currentUser?.email ?? '—';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.t('الحساب', 'Account'),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email_outlined,
                  color: AppColors.lavenderDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  email,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textDarkOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: Text(
              S.t('تسجيل الخروج', 'Log out'),
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.danger, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDarkOf(context),
            ),
          ),
          const SizedBox(height: 12),
          child,
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLightOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

