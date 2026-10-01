import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HistoriaNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const HistoriaNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });
}

class HistoriaBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final List<HistoriaNavItem> items;
  final ValueChanged<int> onTap;

  const HistoriaBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _BottomNavButton(
                    item: items[index],
                    active: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final HistoriaNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.navMuted;

    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: active ? 22 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              active ? item.activeIcon ?? item.icon : item.icon,
              color: color,
              size: 21,
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
