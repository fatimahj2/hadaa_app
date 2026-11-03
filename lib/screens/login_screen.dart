import 'package:flutter/material.dart';
import 'package:hadaa_app/screens/main_navigation_screen.dart';
import 'package:hadaa_app/screens/signup_screen.dart';
import 'package:hadaa_app/services/history_service.dart';
import 'package:hadaa_app/services/pending_avatar.dart';
import 'package:hadaa_app/services/supabase_service.dart';
import 'package:hadaa_app/utils/app_colors.dart';
import 'package:hadaa_app/utils/app_settings.dart';
import 'package:hadaa_app/utils/strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _snack(S.t('يرجى إدخال البريد وكلمة السر',
          'Please enter email and password'));
      return;
    }

    setState(() => _loading = true);
    final error = await SupabaseService.signIn(
      email: email,
      password: password,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _snack(error);
      return;
    }

    // Post-login housekeeping:
    //   1. If a profile picture was picked at signup time, upload it now
    //      (we couldn't earlier — the user wasn't authenticated yet).
    //   2. Push any locally-cached alerts that haven't been mirrored to
    //      Supabase yet.
    // Both are best-effort and non-blocking — we don't want to delay
    // the user's navigation if either fails.
    PendingAvatar.uploadIfPending();
    historyService.syncUnsynced();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with AnimatedBuilder so the language toggle (when exposed
    // here later) actually rebuilds the screen.
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bgOf(context),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardOf(context).withOpacity(0.94),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFDCCCF5), Color(0xFFB89BE7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                          Icons.watch_outlined,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        S.t('دخول', 'Login'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDarkOf(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _inputField(
                        controller: emailController,
                        hint: S.t('البريد الإلكتروني', 'Email'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _inputField(
                        controller: passwordController,
                        hint: S.t('كلمة السر', 'Password'),
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lavender,
                            padding: const EdgeInsets.symmetric(vertical: 18),
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
                                  S.t('دخول', 'Login'),
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpScreen()),
                                );
                              },
                        child: Text(
                          S.t('ليس لديك حساب؟ إنشاء حساب جديد',
                              'No account? Create one'),
                          style: TextStyle(
                            color: AppColors.lavenderDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
}
