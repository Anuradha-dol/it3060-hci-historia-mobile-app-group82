import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showAppMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : null,
    ),
  );
}

InputDecoration fieldDecoration(String label, {IconData? icon}) {
  return InputDecoration(
    hintText: label,
    prefixIcon: icon == null ? null : Icon(icon),
  );
}

String? requiredText(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required';
  }
  return null;
}

List<String> splitCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
