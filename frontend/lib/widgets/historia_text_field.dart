import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HistoriaTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final IconData? icon;
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const HistoriaTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.icon,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label *' : label,
            style: AppTextStyles.label.copyWith(
              fontSize: 11,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: icon == null ? null : Icon(icon, size: 18),
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoriaPasswordSuffix extends StatelessWidget {
  final bool hidden;
  final VoidCallback onPressed;

  const HistoriaPasswordSuffix({
    super.key,
    required this.hidden,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(58, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
      child: Text(hidden ? 'SHOW' : 'HIDE'),
    );
  }
}
