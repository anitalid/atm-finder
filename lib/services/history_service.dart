import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> addHistory(String teks, String bank) async {
    final uid = _uid;
    if (uid == null || teks.trim().isEmpty) return;

    // Guard anti-duplikat: cek entri terakhir user ini. Kalau teks & bank
    // sama persis dan baru disimpan < 5 detik lalu, skip. Dibungkus try-catch
    // supaya kalau query ini gagal (mis. index Firestore belum ke-create),
    // riwayat tetap kesimpen seperti biasa, bukan gagal total.
    try {
      final last = await _db.collection('riwayat')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (last.docs.isNotEmpty) {
        final d = last.docs.first.data();
        final lastTeks = d['teks'] as String?;
        final lastBank = d['bank'] as String?;
        final lastTs = (d['createdAt'] as Timestamp?)?.toDate();
        final isSame = lastTeks == teks && lastBank == bank;
        final isRecent = lastTs != null && DateTime.now().difference(lastTs) < const Duration(seconds: 5);
        if (isSame && isRecent) return;
      }
    } catch (e) {
      // Gagal cek duplikat (mis. index belum ada) — lanjut simpan seperti biasa.
    }

    await _db.collection('riwayat').add({
      'userId': uid, 'teks': teks, 'bank': bank, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchHistory() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('riwayat').where('userId', isEqualTo: uid).snapshots();
  }

  Future<void> clearHistory() async {
    final uid = _uid;
    if (uid == null) return;
    final snap = await _db.collection('riwayat').where('userId', isEqualTo: uid).get();
    final b = _db.batch();
    for (final d in snap.docs) b.delete(d.reference); // FIXED: d.reference
    await b.commit();
  }
}