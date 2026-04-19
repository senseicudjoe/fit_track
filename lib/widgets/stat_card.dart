import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Reusable stat card used on dashboard and progress screens
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? sub;
  final Color accent;
  final double? progress;    // 0.0–1.0, shows progress bar if not null
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.sub,
    required this.accent,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label
            Text(label, style: AppTextStyles.caption),

            // Value row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppTextStyles.statValue),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(unit!, style: AppTextStyles.caption),
                ],
              ],
            ),

            // Sub-label + optional progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sub != null)
                  Text(sub!, style: AppTextStyles.caption),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadius.full,
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(accent),
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Compact horizontal stat pill — used inside cards and detail rows
class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}