import 'package:flutter/material.dart';
import '../models/crowd_report.dart';

/// Badge kecil untuk menampilkan tingkat keramaian ATM.
/// Dipakai di DetailScreen dan (nanti) di daftar hasil pencarian.
class CrowdBadge extends StatelessWidget {
  final CrowdLevel? level;
  const CrowdBadge({super.key, required this.level});

  static Color colorFor(CrowdLevel level) => switch (level) {
    CrowdLevel.sepi => const Color(0xFF2FA84F),
    CrowdLevel.sedang => const Color(0xFFE0A800),
    CrowdLevel.ramai => const Color(0xFFE8730C),
    CrowdLevel.sangatRamai => const Color(0xFFD9342B),
  };

  @override
  Widget build(BuildContext context) {
    final l = level;
    final color = l == null ? const Color(0xFF8A94A6) : colorFor(l);
    final label = l?.label ?? 'Belum ada laporan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
