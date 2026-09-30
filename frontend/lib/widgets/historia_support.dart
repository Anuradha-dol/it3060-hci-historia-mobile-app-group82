import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HistoriaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  const HistoriaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}

class HistoriaIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const HistoriaIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class HistoriaSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HistoriaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.sectionTitle),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppTextStyles.bodyMuted),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class HistoriaScreenPadding extends StatelessWidget {
  final Widget child;

  const HistoriaScreenPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: child,
    );
  }
}

class HistoriaProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? subtitle;

  const HistoriaProfileSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return HistoriaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.bodyMuted),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class HistoriaListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const HistoriaListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.bodyMuted),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ] else if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class HistoriaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const HistoriaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return HistoriaCard(
      color: AppColors.surfaceWarm,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class HistoriaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const HistoriaStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return HistoriaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.title.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

class HistoriaStatusPalette {
  final Color foreground;
  final Color background;
  final Color border;
  final IconData icon;

  const HistoriaStatusPalette({
    required this.foreground,
    required this.background,
    required this.border,
    required this.icon,
  });
}

HistoriaStatusPalette historiaStatusPalette(String status) {
  switch (status.toUpperCase()) {
    case 'VERIFIED':
    case 'APPROVED':
      return const HistoriaStatusPalette(
        foreground: AppColors.success,
        background: AppColors.successBg,
        border: Color(0xFFB9D8C2),
        icon: Icons.check_circle_outline,
      );
    case 'NEEDS_WORK':
      return const HistoriaStatusPalette(
        foreground: AppColors.warning,
        background: AppColors.warningBg,
        border: Color(0xFFE7C982),
        icon: Icons.priority_high_rounded,
      );
    case 'REJECTED':
      return const HistoriaStatusPalette(
        foreground: AppColors.danger,
        background: AppColors.dangerBg,
        border: Color(0xFFE2B5AB),
        icon: Icons.cancel_outlined,
      );
    case 'PENDING':
      return const HistoriaStatusPalette(
        foreground: AppColors.info,
        background: AppColors.infoBg,
        border: Color(0xFFBED7DD),
        icon: Icons.more_horiz,
      );
    default:
      return const HistoriaStatusPalette(
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
        border: AppColors.border,
        icon: Icons.info_outline,
      );
  }
}

class HistoriaStatusChip extends StatelessWidget {
  final String status;

  const HistoriaStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = historiaStatusPalette(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: 14, color: palette.foreground),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: palette.foreground,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class HistoriaStatusCard extends StatelessWidget {
  final String status;
  final String title;
  final String message;
  final List<Widget> actions;

  const HistoriaStatusCard({
    super.key,
    required this.status,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final palette = historiaStatusPalette(status);

    return HistoriaCard(
      color: palette.background,
      borderColor: palette.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(palette.icon, color: palette.foreground, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: palette.foreground,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: AppTextStyles.body.copyWith(
                        color: palette.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}
