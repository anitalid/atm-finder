import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(appBar: AppBar(title: const Text('Profil Saya')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (ctx, snap) {
          final d = (snap.data?.data() ?? {}) as Map<String, dynamic>; // FIXED: Casting Map
          final nama = (d['nama'] as String?) ?? user?.displayName ?? 'Pengguna';
          return Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              CircleAvatar(radius: 30, backgroundColor: AppColors.primaryLight,
                child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text((d['nomorHp'] as String?) ?? user?.phoneNumber ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                Text((d['email'] as String?) ?? user?.email ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ])),
            ]));
        }),
      const SizedBox(height: 16),
      _StatsSection(uid: user?.uid),
      const SizedBox(height: 16),
      _menu(context, Icons.person_outline_rounded, 'Edit Profil', () =>
        _showEditProfileSheet(context, user)),
      _menu(context, Icons.lock_outline_rounded, 'Ubah Password', () =>
        _showChangePasswordSheet(context, user)),
      _menu(context, Icons.history_rounded, 'Riwayat Pencarian', () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
      _menu(context, Icons.help_outline_rounded, 'Bantuan', () =>
        _dialog(context, 'Bantuan', 'Hubungi kami: bantuan@atmfinder.id\nGunakan menu Riwayat untuk melihat pencarian sebelumnya.')),
      _menu(context, Icons.info_outline_rounded, 'Tentang Aplikasi', () =>
        _dialog(context, 'Tentang Aplikasi', 'ATM Finder Yogyakarta v1.0\nMetode Nearest Neighbor berbasis GIS dengan Firebase.')),
      const SizedBox(height: 24),
      SizedBox(height: 48, child: OutlinedButton(
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: const Text('Keluar'), content: const Text('Yakin ingin keluar dari akun?'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar'))]));
          if (ok == true && context.mounted) {
            await AuthService().logout();
            if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }
        },
        child: const Text('Keluar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)))),
    ]));
  }

  Widget _menu(BuildContext context, IconData icon, String title, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.textGrey),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textGrey),
          ])))));

  void _dialog(BuildContext context, String title, String content) =>
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text(title), content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))]));

  // Ambil data user dulu dari Firestore sebelum buka form, biar field-nya
  // ke-prefill sama data yang sekarang, bukan kosong.
  Future<void> _showEditProfileSheet(BuildContext context, User? user) async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final d = (doc.data() ?? {}) as Map<String, dynamic>;
    final namaCtrl = TextEditingController(text: (d['nama'] as String?) ?? user.displayName ?? '');
    final hpCtrl = TextEditingController(text: (d['nomorHp'] as String?) ?? user.phoneNumber ?? '');
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: 20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Edit Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 16),
          TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: hpCtrl, keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Nomor HP', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 46, child: FilledButton(
            onPressed: () async {
              final nama = namaCtrl.text.trim();
              final hp = hpCtrl.text.trim();
              if (nama.isEmpty) return;
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                {'nama': nama, 'nomorHp': hp}, SetOptions(merge: true), // merge biar field lain gak ketimpa
              );
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui')));
              }
            },
            child: const Text('Simpan'),
          )),
        ]),
      ),
    );
  }

  // Ganti password langsung di app. Wajib reauthenticate pakai password
  // lama dulu — Firebase mewajibkan ini sebelum updatePassword() kalau
  // sesi login user udah agak lama, kalau enggak bakal kena error
  // 'requires-recent-login'. Cuma jalan buat akun provider 'password'.
  Future<void> _showChangePasswordSheet(BuildContext context, User? user) async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final provider = (doc.data()?['provider'] as String?) ?? 'password';

    if (provider != 'password' || user.email == null) {
      _dialog(context, 'Tidak Tersedia',
          'Akun kamu login pakai ${provider == 'google' ? 'Google' : provider == 'facebook' ? 'Facebook' : 'nomor HP'}, jadi tidak ada password yang bisa diubah dari sini.');
      return;
    }
    if (!context.mounted) return;

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: 20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ubah Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 16),
            TextField(controller: currentCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Saat Ini', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru', border: OutlineInputBorder())),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 46, child: FilledButton(
              onPressed: submitting ? null : () async {
                final newPass = newCtrl.text;
                if (newPass.length < 6) {
                  setState(() => errorText = 'Password baru minimal 6 karakter');
                  return;
                }
                if (newPass != confirmCtrl.text) {
                  setState(() => errorText = 'Konfirmasi password tidak cocok');
                  return;
                }
                setState(() { submitting = true; errorText = null; });
                try {
                  final cred = EmailAuthProvider.credential(email: user.email!, password: currentCtrl.text);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPass);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
                  }
                } on FirebaseAuthException catch (e) {
                  setState(() {
                    submitting = false;
                    errorText = e.code == 'wrong-password' || e.code == 'invalid-credential'
                        ? 'Password saat ini salah'
                        : AuthService.errorMessage(e);
                  });
                }
              },
              child: submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            )),
          ]),
        ),
      ),
    );
  }
}

/// Kartu statistik ringkas: total pencarian & total laporan keramaian
/// yang pernah dikirim user. Ambil dari koleksi 'riwayat' dan 'crowd_reports',
/// difilter berdasarkan userId, lalu dihitung pakai count() aggregation query
/// (lebih murah daripada fetch semua dokumen cuma buat dihitung).
class _StatsSection extends StatelessWidget {
  final String? uid;
  const _StatsSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    final riwayatQuery = FirebaseFirestore.instance
        .collection('riwayat')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    final laporanQuery = FirebaseFirestore.instance
        .collection('crowd_reports')
        .where('userId', isEqualTo: uid)
        .count()
        .get();

    return FutureBuilder<List<AggregateQuerySnapshot>>(
      future: Future.wait([riwayatQuery, laporanQuery]),
      builder: (ctx, snap) {
        final totalPencarian = snap.data?[0].count ?? 0;
        final totalLaporan = snap.data?[1].count ?? 0;
        final loading = snap.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Expanded(child: _statItem(
              icon: Icons.search_rounded,
              label: 'Pencarian',
              value: loading ? '-' : '$totalPencarian',
            )),
            Container(width: 1, height: 40, color: AppColors.border),
            Expanded(child: _statItem(
              icon: Icons.campaign_outlined,
              label: 'Laporan Dikirim',
              value: loading ? '-' : '$totalLaporan',
            )),
          ]),
        );
      },
    );
  }

  Widget _statItem({required IconData icon, required String label, required String value}) =>
      Column(children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      ]);
}