import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/goal_provider.dart';
import '../../utils/constants.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats    = context.watch<StatsProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final goals    = context.watch<GoalProvider>();

    final insights = _generateInsights(stats, workouts, goals);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [

          // ── This week summary ────────────────────────────────────────────
          Text('This week'.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'vs last week',
                  value: _stepsDelta(stats),
                  color: _stepsDeltaColor(stats),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: 'Goals completed',
                  value: '${goals.completedGoals.length}/${goals.goals.length}',
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: 'Workouts',
                  value: '${workouts.weeklyWorkoutCount}',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Performance insights ─────────────────────────────────────────
          Text('Performance tips'.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InsightCard(insight: insight),
          )),

          if (insights.isEmpty)
            _EmptyInsights(),

          const SizedBox(height: AppSpacing.xl),

          // ── Best workout day ─────────────────────────────────────────────
          if (workouts.workouts.isNotEmpty) ...[
            Text('Workout breakdown'.toUpperCase(), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            _WorkoutBreakdown(workouts: workouts),
          ],
        ],
      ),
    );
  }

  String _stepsDelta(StatsProvider stats) {
    if (stats.weekStats.length < 2) return '—';
    final thisWeek = stats.weekStats
        .take(7)
        .fold(0, (sum, s) => sum + s.steps);
    final lastWeek = stats.monthStats
        .skip(7)
        .take(7)
        .fold(0, (sum, s) => sum + s.steps);
    if (lastWeek == 0) return '+${thisWeek}';
    final delta = ((thisWeek - lastWeek) / lastWeek * 100).toStringAsFixed(0);
    return '${thisWeek > lastWeek ? '+' : ''}$delta%';
  }

  Color _stepsDeltaColor(StatsProvider stats) {
    if (stats.weekStats.length < 2) return AppColors.textHint;
    final thisWeek = stats.weekStats.take(7).fold(0, (s, e) => s + e.steps);
    final lastWeek =
    stats.monthStats.skip(7).take(7).fold(0, (s, e) => s + e.steps);
    return thisWeek >= lastWeek ? AppColors.teal : AppColors.coral;
  }

  List<_Insight> _generateInsights(
      StatsProvider stats,
      WorkoutProvider workouts,
      GoalProvider goals) {
    final insights = <_Insight>[];

    // Streak insight
    int streak = 0;
    for (final s in stats.weekStats.reversed) {
      if (s.steps >= 10000) streak++;
      else break;
    }
    if (streak >= 3) {
      insights.add(_Insight(
        title: 'Step streak: $streak days',
        body: 'You\'ve hit your step goal $streak days in a row. Keep it up!',
        color: AppColors.teal,
        icon: Icons.local_fire_department_outlined,
      ));
    }

    // Rest day insight
    if (workouts.weeklyWorkoutCount >= 5) {
      insights.add(_Insight(
        title: 'Rest day reminder',
        body: 'You\'ve worked out ${workouts.weeklyWorkoutCount} days this week. A rest day helps muscle recovery.',
        color: AppColors.amber,
        icon: Icons.bedtime_outlined,
      ));
    }

    // Low step day
    final today = stats.today;
    if (today != null && today.steps < 3000) {
      insights.add(_Insight(
        title: 'Steps are low today',
        body: 'You\'re at ${today.steps} steps. A 20-min walk could add around 2,000 more.',
        color: AppColors.coral,
        icon: Icons.directions_walk_outlined,
      ));
    }

    // Goal completion insight
    if (goals.completedGoals.isNotEmpty) {
      insights.add(_Insight(
        title: '${goals.completedGoals.length} goal${goals.completedGoals.length > 1 ? 's' : ''} completed today',
        body: 'Great work! You hit: ${goals.completedGoals.map((g) => g.type).join(', ')}.',
        color: AppColors.primary,
        icon: Icons.emoji_events_outlined,
      ));
    }

    // Calorie gap
    if (today != null && today.caloriesBurned < 200 &&
        today.workoutCount == 0) {
      insights.add(_Insight(
        title: 'Calorie burn is low',
        body: 'No workout logged today. Even a 15-min session makes a difference.',
        color: AppColors.amber,
        icon: Icons.local_fire_department_outlined,
      ));
    }

    return insights;
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _Insight {
  final String title, body;
  final Color color;
  final IconData icon;
  const _Insight(
      {required this.title, required this.body,
        required this.color, required this.icon});
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final _Insight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border(
          left: BorderSide(color: insight.color, width: 3),
          top: BorderSide(color: AppColors.border, width: 0.5),
          right: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, color: insight.color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: AppTextStyles.heading3
                        .copyWith(color: insight.color)),
                const SizedBox(height: AppSpacing.xs),
                Text(insight.body, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTextStyles.statValue
                  .copyWith(fontSize: 18, color: color)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _WorkoutBreakdown extends StatelessWidget {
  final WorkoutProvider workouts;
  const _WorkoutBreakdown({required this.workouts});

  @override
  Widget build(BuildContext context) {
    // Count by type
    final counts = <String, int>{};
    for (final w in workouts.workouts) {
      counts[w.type] = (counts[w.type] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: sorted.take(5).map((e) {
          final pct = e.value / workouts.workouts.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: AppTextStyles.body),
                    Text('${e.value} sessions',
                        style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: AppRadius.full,
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.border,
                    valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text('Log a few workouts to unlock insights',
              style: AppTextStyles.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}