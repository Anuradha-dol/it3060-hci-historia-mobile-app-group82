import 'package:flutter/material.dart';

class AsyncButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const AsyncButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  child: child,
                ),
              ),
      ),
    );
  }
}
