import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../utils/constants.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback? onTap;

  const WorkoutCard({super.key, required this.workout, this.onTap});

  IconData get _icon {
    switch (workout.type) {
      case WorkoutType.running:  return Icons.directions_run;
      case WorkoutType.cycling:  return Icons.directions_bike;
      case WorkoutType.walking:  return Icons.directions_walk;
      case WorkoutType.swimming: return Icons.pool;
      case WorkoutType.yoga:     return Icons.self_improvement;
      case WorkoutType.strength: return Icons.fitness_center;
      case WorkoutType.hiit:     return Icons.timer;
      default:                   return Icons.sports;
    }
  }

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
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(_icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.type,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _subtitle,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Date + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_date, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>['${workout.durationMin} min'];
    parts.add('${workout.caloriesBurned.toStringAsFixed(0)} kcal');
    if (workout.distanceKm > 0) {
      parts.add('${workout.distanceKm.toStringAsFixed(1)} km');
    }
    return parts.join(' · ');
  }

  String get _date {
    final d   = workout.loggedAt;
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${d.day}/${d.month}';
  }
}