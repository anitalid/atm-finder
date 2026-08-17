import 'package:flutter/material.dart';

class BankLogo extends StatelessWidget {
  final String bank;
  const BankLogo({super.key, required this.bank});

  static const Map<String, Color> _colors = {
    'BCA': Color(0xFF0060AF), 'BNI': Color(0xFFEE722E), 'BRI': Color(0xFF00529C),
    'Mandiri': Color(0xFF0A3F7B), 'BSI': Color(0xFF00A39E),
    'CIMB Niaga': Color(0xFFE1251B), 'Danamon': Color(0xFFF5A700),
  };

  @override
  Widget build(BuildContext context) {
    return Container(width: 40, height: 28,
      decoration: BoxDecoration(color: _colors[bank] ?? const Color(0xFF1D5ED9), borderRadius: BorderRadius.circular(6)),
      child: Center(child: Text(bank, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))));
  }
}