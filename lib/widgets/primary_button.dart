import 'package:flutter/material.dart';
import '../core/theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading, outline;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.outline = false});

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return SizedBox(width: double.infinity, height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ));
    }
    return SizedBox(width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ));
  }
}