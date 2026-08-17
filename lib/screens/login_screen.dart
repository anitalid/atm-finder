import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _masuk() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(_email.text, _password.text);
      if (mounted) Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      _snack(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text('Selamat Datang!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text('Masuk untuk melanjutkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                const SizedBox(height: 18),

                // ===== ILUSTRASI TUGU ESTETIK =====
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEAF3FC), Color(0xFFD8E6FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/login_ilustration.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                AppTextField(label: 'Email', hint: 'Masukkan email',
                    icon: Icons.mail_outline, controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                AppTextField(label: 'Password', hint: 'Masukkan password',
                    icon: Icons.lock_outline, controller: _password, obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Masuk', loading: _loading, onPressed: _masuk),
                const SizedBox(height: 22),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Belum punya akun? ',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Daftar di sini',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: AppColors.primary))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}