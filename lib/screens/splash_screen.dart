import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ===== ILUSTRASI: langit + Tugu + pin ATM =====
        Expanded(
          flex: 11,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.location_on_rounded,
                      size: 150, color: AppColors.primary),
                  Container(
                    width: 60, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('ATM',
                        style: TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
        // ===== JUDUL =====
        Expanded(
          flex: 7,
          child: Container(
            width: double.infinity,
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(children: [
              const SizedBox(height: 24),
              const Text('ATM Finder',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 2),
              const Text('Yogyakarta',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const SizedBox(height: 14),
              const Text('Temukan ATM terdekat\ndengan mudah dan cepat',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ]),
          ),
        ),
      ]),
    );
  }
}