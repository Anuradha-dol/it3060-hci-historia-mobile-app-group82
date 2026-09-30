import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle brand = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryDark,
    letterSpacing: 0,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryDark,
    height: 1.08,
    letterSpacing: 0,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryDark,
    height: 1.18,
    letterSpacing: 0,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryDark,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    color: AppColors.textSecondary,
    letterSpacing: 0,
  );
}
