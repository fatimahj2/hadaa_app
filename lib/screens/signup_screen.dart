import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadaa_app/services/pending_avatar.dart';
import 'package:hadaa_app/services/supabase_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';
import 'package:hadaa_app/utils/strings.dart';
import 'package:image_picker/image_picker.dart';

/// Full registration form. Collects every field the customer asked for
/// (except profile pic — that comes in Pass 2). On submit, calls
/// SupabaseService.signUp which forwards the data to a database trigger
/// that creates the profile row.
///
/// Email confirmation is on by default in Supabase, so after a successful
/// signup we show a "check your inbox" dialog and pop back to login.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _ageCtrl       = TextEditingController();
  final _weightCtrl    = TextEditingController();
  final _heightCtrl    = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  String _sex = 'Female';
  bool _loading = false;
  File? _pickedAvatar;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _pickedAvatar = File(picked.path));
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final error = await SupabaseService.signUp(
      email:     _emailCtrl.text.trim(),
      password:  _passwordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),
      age:       int.parse(_ageCtrl.text),
      sex:       _sex,
      weightKg:  double.parse(_weightCtrl.text),
      heightCm:  double.parse(_heightCtrl.text),
      phone:     _phoneCtrl.text.trim(),
    );
    if (!mounted) return;

    if (error != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Stash the picked avatar so it gets uploaded after the user
    // confirms their email and logs in for the first time.
    if (_pickedAvatar != null) {
      await PendingAvatar.stash(_pickedAvatar!);
    }
    if (!mounted) return;
    setState(() => _loading = false);

    // Show "check your email" then return to login
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardOf(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read,
                color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text(
              S.t('تحققي من بريدك الإلكتروني',
                  'Check your email'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDarkOf(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.t(
                'تم إرسال رابط تأكيد إلى بريدك. اضغطي عليه ثم سجّلي الدخول.',
                'A confirmation link was sent to your inbox. Click it, then log in.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textLightOf(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.t('حسناً', 'OK')),
          ),
        ],
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bgOf(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.lavenderDark),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            S.t('إنشاء حساب جديد', 'Create account'),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDarkOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _avatarPicker(),
                    const SizedBox(height: 20),
                    // Name row
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _firstNameCtrl,
                            hint: S.t('الاسم الأول', 'First name'),
                            icon: Icons.person_outline,
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            controller: _lastNameCtrl,
                            hint: S.t('اسم العائلة', 'Last name'),
                            icon: Icons.person_outline,
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _emailCtrl,
                      hint: S.t('البريد الإلكتروني', 'Email'),
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _email,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _phoneCtrl,
                      hint: S.t('رقم الهاتف', 'Phone'),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    // Age + sex row
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _ageCtrl,
                            hint: S.t('العمر', 'Age'),
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: _intInRange(5, 120),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _sexDropdown()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Weight + height row
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            controller: _weightCtrl,
                            hint: S.t('الوزن (كجم)', 'Weight (kg)'),
                            icon: Icons.monitor_weight_outlined,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: _doubleInRange(20, 300),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _textField(
                            controller: _heightCtrl,
                            hint: S.t('الطول (سم)', 'Height (cm)'),
                            icon: Icons.height,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: _doubleInRange(80, 250),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _passwordCtrl,
                      hint: S.t('كلمة السر (6 أحرف على الأقل)',
                          'Password (min 6 chars)'),
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? S.t('كلمة السر قصيرة جداً',
                              'Password too short')
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _signUp,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.lavender,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                S.t('إنشاء الحساب', 'Sign up'),
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- avatar picker ----

  Widget _avatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lavenderLight,
                border: Border.all(
                    color: AppColors.lavenderDark, width: 3),
                image: _pickedAvatar != null
                    ? DecorationImage(
                        image: FileImage(_pickedAvatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _pickedAvatar == null
                  ? const Icon(
                      Icons.person,
                      size: 64,
                      color: AppColors.lavenderDark,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lavenderDark,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- form helpers ----

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textAlign: TextAlign.right,
      style: TextStyle(color: AppColors.textDarkOf(context)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.lavenderDark),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textLightOf(context)),
        filled: true,
        fillColor: AppColors.creamOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _sexDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.creamOf(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sex,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down,
              color: AppColors.lavenderDark),
          style: TextStyle(color: AppColors.textDarkOf(context)),
          dropdownColor: AppColors.cardOf(context),
          items: [
            DropdownMenuItem(
              value: 'Female',
              child: Text(S.t('أنثى', 'Female')),
            ),
            DropdownMenuItem(
              value: 'Male',
              child: Text(S.t('ذكر', 'Male')),
            ),
          ],
          onChanged: (v) => setState(() => _sex = v ?? 'Female'),
        ),
      ),
    );
  }

  // ---- validators ----

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty)
          ? S.t('مطلوب', 'Required')
          : null;

  String? _email(String? v) {
    if (v == null || v.trim().isEmpty) return S.t('مطلوب', 'Required');
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : S.t('بريد غير صحيح', 'Invalid email');
  }

  String? Function(String?) _intInRange(int min, int max) => (v) {
        if (v == null || v.isEmpty) return S.t('مطلوب', 'Required');
        final n = int.tryParse(v);
        if (n == null || n < min || n > max) {
          return S.t('قيمة غير صحيحة', 'Invalid value');
        }
        return null;
      };

  String? Function(String?) _doubleInRange(double min, double max) => (v) {
        if (v == null || v.isEmpty) return S.t('مطلوب', 'Required');
        final n = double.tryParse(v);
        if (n == null || n < min || n > max) {
          return S.t('قيمة غير صحيحة', 'Invalid value');
        }
        return null;
      };
}
