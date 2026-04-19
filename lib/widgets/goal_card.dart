import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../utils/constants.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onDelete,
  });

  Color get _accentColor {
    switch (goal.type) {
      case GoalType.steps:          return AppColors.teal;
      case GoalType.calories:       return AppColors.amber;
      case GoalType.activeMinutes:  return AppColors.primary;
      case GoalType.weeklyWorkouts: return AppColors.coral;
      case GoalType.distanceKm:     return AppColors.teal;
      default:                      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct   = (goal.progressPercent * 100).toStringAsFixed(0);
    final color = goal.isCompleted ? AppColors.teal : _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: goal.isCompleted
                ? AppColors.teal.withOpacity(0.4)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (goal.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Icon(Icons.check_circle,
                            color: AppColors.teal, size: 16),
                      ),
                    Text(
                      goal.type,
                      style: AppTextStyles.heading3.copyWith(
                        color: goal.isCompleted
                            ? AppColors.teal
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$pct%',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${goal.currentValue.toStringAsFixed(0)} / '
                  '${goal.targetValue.toStringAsFixed(0)} ${goal.unit} · ${goal.period}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.full,
              child: LinearProgressIndicator(
                value: goal.progressPercent,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}