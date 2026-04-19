import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Labelled progress bar — used in goals and dashboard
class LabelledProgressBar extends StatelessWidget {
  final String label;
  final String trailing;
  final double progress;       // 0.0–1.0
  final Color color;
  final double height;

  const LabelledProgressBar({
    super.key,
    required this.label,
    required this.trailing,
    required this.progress,
    required this.color,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body),
              Text(trailing,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: height,
            ),
          ),
        ],
      ),
    );
  }
}

// Circular progress ring — used on timer screen
class ProgressRing extends StatelessWidget {
  final double progress;   // 0.0–1.0
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 160,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}