import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HistoriaInfoBox extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final bool placeholder;

  const HistoriaInfoBox({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.placeholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = placeholder ? AppColors.surfaceWarm : AppColors.primarySoft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 11),
          if (icon != null) ...[
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(message, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
