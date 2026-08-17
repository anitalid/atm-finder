import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase otomatis membaca konfigurasi dari android/app/google-services.json
    // Tidak perlu load manual dari assets lagi
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('FIREBASE INIT ERROR: $e');
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal inisialisasi Firebase:\n$e\n\nPastikan file google-services.json ada di android/app/',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(const AtmFinderApp());
}

class AtmFinderApp extends StatelessWidget {
  const AtmFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATM Finder Yogyakarta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}