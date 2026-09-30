import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'historia_support.dart';

class HistoriaRoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  const HistoriaRoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.actionLabel,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return HistoriaCard(
      onTap: onTap,
      color: AppColors.primarySoft,
      borderColor: AppColors.borderStrong,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 19)),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTextStyles.bodyMuted),
                if (actionLabel != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    actionLabel!.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                Icons.arrow_forward,
                size: 20,
                color: onTap == null ? AppColors.textMuted : AppColors.primary,
              ),
        ],
      ),
    );
  }
}
