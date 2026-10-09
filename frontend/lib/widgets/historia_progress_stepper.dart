import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HistoriaProgressStepper extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const HistoriaProgressStepper({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: _StepNode(
                label: labels[index],
                index: index,
                currentStep: currentStep,
                first: index == 0,
                last: index == labels.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final int index;
  final int currentStep;
  final bool first;
  final bool last;

  const _StepNode({
    required this.label,
    required this.index,
    required this.currentStep,
    required this.first,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final completed = currentStep > index;
    final active = currentStep == index;
    final circleColor = completed || active
        ? AppColors.primary
        : AppColors.primarySoft;
    final textColor = completed || active
        ? AppColors.primaryDark
        : AppColors.textMuted;

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: first
                      ? Colors.transparent
                      : currentStep >= index
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 23 : 20,
                height: active ? 23 : 20,
                decoration: BoxDecoration(
                  color: circleColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: completed || active
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: completed
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: last
                      ? Colors.transparent
                      : currentStep > index
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
