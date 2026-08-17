import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';  // ← TAMBAHAN BARU
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found': return 'Email tidak terdaftar.';
        case 'wrong-password': return 'Password salah.';
        case 'invalid-credential': return 'Email atau password salah.';
        case 'email-already-in-use': return 'Email sudah terdaftar.';
        case 'weak-password': return 'Password terlalu lemah (min. 6 karakter).';
        case 'invalid-phone-number': return 'Nomor HP tidak valid.';
        case 'invalid-verification-code': return 'Kode OTP salah.';
        case 'too-many-requests': return 'Terlalu banyak percobaan, coba lagi nanti.';
        default: return e.message ?? 'Terjadi kesalahan.';
      }
    }
    if (e is PlatformException) {
      return e.message ?? 'Terjadi kesalahan: ${e.code}';
    }
    return e.toString();
  }

  Future<User> login(String email, String password) async {
    final c = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    return c.user!;
  }

  Future<User> register({
    required String nama,
    required String email,
    required String nomorHp,
    required String password,
  }) async {
    final c = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = c.user!;
    await user.updateDisplayName(nama);
    await _db.collection('users').doc(user.uid).set({
      'nama': nama,
      'email': email.trim(),
      'nomorHp': nomorHp,
      'provider': 'password',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return user;
  }

  String? _verificationId;

  static String toE164(String hp) {
    var h = hp.replaceAll(RegExp(r'[\s-]'), '');
    if (h.startsWith('0')) h = '62${h.substring(1)}';
    if (!h.startsWith('+')) h = '+$h';
    return h;
  }

  Future<void> sendOtp(
    String nomorHp, {
    required void Function() onCodeSent,
    required void Function(String) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: toE164(nomorHp),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (c) => _link(c),
      verificationFailed: (e) => onFailed(errorMessage(e)),
      codeSent: (vid, _) {
        _verificationId = vid;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp(String code) async {
    if (_verificationId == null) throw Exception('OTP belum dikirim.');
    try {
      await _link(PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: code));
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked' &&
          e.code != 'credential-already-in-use') {
        rethrow;
      }
    }
  }

  Future<void> _link(PhoneAuthCredential c) async {
    final u = _auth.currentUser;
    if (u == null) {
      await _auth.signInWithCredential(c);
      return;
    }
    try {
      await u.linkWithCredential(c);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked' &&
          e.code != 'credential-already-in-use') {
        rethrow;
      }
    }
  }

  Future<User> loginWithGoogle() async {
    try {
      final acc = await _google.signIn();
      if (acc == null) throw Exception('Login Google dibatalkan.');
      final auth = await acc.authentication;
      final c = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(
              accessToken: auth.accessToken, idToken: auth.idToken));
      await _ensureProfile(c.user!, 'google');
      return c.user!;
    } catch (e) {
      throw Exception('Login Google gagal: ${errorMessage(e)}');
    }
  }

  Future<User> loginWithFacebook() async {
    try {
      final r = await FacebookAuth.instance.login();
      if (r.status != LoginStatus.success) {
        throw Exception('Login Facebook dibatalkan.');
      }
      final c = await _auth.signInWithCredential(
          FacebookAuthProvider.credential(r.accessToken!.tokenString));
      await _ensureProfile(c.user!, 'facebook');
      return c.user!;
    } catch (e) {
      throw Exception('Login Facebook gagal: ${errorMessage(e)}');
    }
  }

  Future<void> _ensureProfile(User u, String provider) =>
      _db.collection('users').doc(u.uid).set({
        'nama': u.displayName ?? u.email ?? 'Pengguna',
        'email': u.email ?? '',
        'nomorHp': u.phoneNumber ?? '',
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}

    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}

    await _auth.signOut();
  }
}