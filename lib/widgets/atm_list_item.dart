import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/atm.dart';
import '../services/atm_service.dart';
import 'bank_logo.dart';
import 'crowd_badge.dart';

class AtmListItem extends StatelessWidget {
  final int index;
  final AtmResult result;
  final VoidCallback onTap;
  const AtmListItem({super.key, required this.index, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            SizedBox(width: 18, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textGrey))),
            BankLogo(bank: result.atm.bank),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(result.atm.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(result.atm.alamat, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              // crowdLevel non-null hanya kalau result berasal dari AtmService.rankAtms() (Weighted Scoring).
              // Kalau dari nearestNeighbor() biasa (mis. peta utama), field ini null dan badge disembunyikan.
              if (result.crowdLevel != null) Padding(
                padding: const EdgeInsets.only(top: 4),
                child: CrowdBadge(level: result.crowdLevel)),
            ])),
            Text(AtmService.formatKm(result.jarakKm), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        )));
  }
}