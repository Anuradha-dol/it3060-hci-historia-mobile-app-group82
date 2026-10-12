import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A row of five stars used for rating input or read-only display.
///
/// Pass [onChanged] to make the stars tappable; omit it for a read-only
/// display (e.g. showing an existing rating).
class HistoriaStarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  const HistoriaStarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < value;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? AppColors.primary : AppColors.borderStrong,
        );

        if (onChanged == null) {
          return icon;
        }

        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onChanged!(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: icon,
          ),
        );
      }),
    );
  }
}
