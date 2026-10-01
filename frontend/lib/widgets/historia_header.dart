import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HistoriaHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> actions;
  final bool showTitleDivider;

  const HistoriaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.icon = Icons.eco_outlined,
    this.actions = const [],
    this.showTitleDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 86,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/historia_header_banner.png'),
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.50),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 18, 14),
              child: HistoriaBrandRow(actions: actions),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTextStyles.screenTitle),
                  ),
                  Icon(
                    icon,
                    color: AppColors.primary.withValues(alpha: 0.18),
                    size: 32,
                  ),
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: AppTextStyles.bodyMuted),
              ],
              if (showTitleDivider) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class HistoriaBrandRow extends StatelessWidget {
  final bool dark;
  final String subtitle;
  final List<Widget> actions;

  const HistoriaBrandRow({
    super.key,
    this.dark = false,
    this.subtitle = 'EXPLORE HISTORY / FIND YOUR GUIDE',
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : AppColors.primaryDark;
    final mutedColor = dark ? const Color(0xFFD5E9DF) : AppColors.textSecondary;

    return Row(
      children: [
        HistoriaLogoMark(dark: dark),
        const SizedBox(width: 11),
        Expanded(
          child: HistoriaBrandText(
            dark: dark,
            subtitle: subtitle,
            titleColor: textColor,
            subtitleColor: mutedColor,
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 8),
          Wrap(spacing: 4, children: actions),
        ],
      ],
    );
  }
}

class HistoriaBrandText extends StatelessWidget {
  final bool dark;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;

  const HistoriaBrandText({
    super.key,
    this.dark = false,
    this.subtitle = 'EXPLORE HISTORY / FIND YOUR GUIDE',
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HISTORIA',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.brand.copyWith(
            color: titleColor ?? (dark ? Colors.white : AppColors.primaryDark),
            fontSize: 19,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color:
                subtitleColor ??
                (dark ? const Color(0xFFD5E9DF) : AppColors.textSecondary),
            fontSize: 7.2,
          ),
        ),
      ],
    );
  }
}

class HistoriaLogoMark extends StatelessWidget {
  final bool dark;
  final double size;

  const HistoriaLogoMark({super.key, this.dark = false, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.17),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.14)
            : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.18) : AppColors.border,
        ),
      ),
      child: Image.asset(
        'assets/images/historia_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.eco_outlined,
          color: dark ? Colors.white : AppColors.primary,
          size: size * 0.52,
        ),
      ),
    );
  }
}
