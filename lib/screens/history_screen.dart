import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _fmt(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    String t(int n) => n.toString().padLeft(2, '0');
    return '${t(d.day)}/${t(d.month)}/${d.year} • ${t(d.hour)}:${t(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final svc = HistoryService();
    return Scaffold(appBar: AppBar(title: const Text('Riwayat Pencarian'), actions: [
      IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.textGrey), onPressed: () async {
        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          title: const Text('Bersihkan Riwayat'), content: const Text('Hapus semua riwayat pencarian?'),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus'))]));
        if (ok == true) await svc.clearHistory();
      }),
    ]),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: svc.watchHistory(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = List.of(snap.data!.docs)..sort((a, b) =>
          ((b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
              .compareTo((a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
        if (docs.isEmpty) return const Center(child: Text('Belum ada riwayat', style: TextStyle(color: AppColors.textGrey)));
        return ListView.separated(padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data();
            return Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d['teks'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('${d['bank'] ?? ''} • ${_fmt(d['createdAt'] as Timestamp?)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                ])),
              ]));
          });
      }));
  }
}