import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController(), _email = TextEditingController(),
        _hp = TextEditingController(), _password = TextEditingController();
  bool _loading = false;

  Future<void> _daftar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // 1. Buat akun di Firebase
      await AuthService().register(
          nama: _nama.text,
          email: _email.text,
          nomorHp: _hp.text,
          password: _password.text);

      // 2. Logout agar tidak auto-login (sesuai alur yang diminta)
      await AuthService().logout();

      // 3. Kembali ke Login dengan pesan sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Akun berhasil dibuat! Silakan login.'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthService.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Daftar untuk melanjutkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline,
                  controller: _nama,
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                AppTextField(
                  label: 'Email',
                  hint: 'Masukkan email',
                  icon: Icons.mail_outline,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                AppTextField(
                  label: 'Nomor HP',
                  hint: 'Masukkan nomor HP',
                  icon: Icons.phone_android,
                  controller: _hp,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || !v.startsWith('08'))
                      ? 'Gunakan format 08xx'
                      : null,
                ),
                AppTextField(
                  label: 'Password',
                  hint: 'Buat password',
                  icon: Icons.lock_outline,
                  controller: _password,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimal 6 karakter'
                      : null,
                ),
                const SizedBox(height: 6),
                PrimaryButton(
                    label: 'Daftar', loading: _loading, onPressed: _daftar),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Sudah punya akun? ',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Masuk di sini',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}