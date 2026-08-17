import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web tidak didukung.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      default: throw UnsupportedError('Platform tidak didukung.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1b2C3d4E5f6G7h8I9j0KlMnOpQrStUvWx',                        // ← dari "current_key"
    appId: '1:332655328794:android:9c4251707ef7d6e66a9ba3',    // ← sudah benar (App ID di screenshot)
    messagingSenderId: '332655328794',                         // ← sudah benar (project_number)
    projectId: 'atm-finder',                                   // ← sudah benar (project_id)
    storageBucket: 'atm-finder.appspot.com',                   // ← dari "storage_bucket"
  );
}