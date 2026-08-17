import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({super.key, required this.label, this.hint, this.icon,
    this.obscureText = false, this.controller, this.keyboardType, this.validator});

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.controller, keyboardType: widget.keyboardType,
        validator: widget.validator, obscureText: _obscure,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 18, color: AppColors.textGrey),
          suffixIcon: widget.obscureText
              ? IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textGrey),
                  onPressed: () => setState(() => _obscure = !_obscure))
              : null,
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }
}