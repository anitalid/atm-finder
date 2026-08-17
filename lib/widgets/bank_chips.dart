import 'package:flutter/material.dart';
import '../core/theme.dart';

class BankChips extends StatelessWidget {
  final List<String> banks;
  final String selected;
  final ValueChanged<String> onSelect;
  const BankChips({super.key, required this.banks, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: banks.length,
        itemBuilder: (_, i) {
          final b = banks[i], act = b == selected;
          return GestureDetector(
            onTap: () => onSelect(b),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: act ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: act ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(b, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: act ? Colors.white : AppColors.textGrey)),
            ),
          );
        },
      ));
  }
}