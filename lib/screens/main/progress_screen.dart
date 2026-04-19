import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/daily_stats_model.dart';
import '../../models/workout_model.dart';
import '../../utils/constants.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _rangeIndex = 0; // 0=week, 1=month
  static const _ranges = ['Week', 'Month'];

  @override
  Widget build(BuildContext context) {
    final stats    = context.watch<StatsProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final uid      = context.read<AuthProvider>().user?.uid ?? '';

    final data = _rangeIndex == 0 ? stats.weekStats : stats.monthStats;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => stats.refresh(uid),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [

            // ── Range selector ───────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: List.generate(_ranges.length, (i) {
                  final sel = i == _rangeIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rangeIndex = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: AppRadius.sm,
                        ),
                        alignment: Alignment.center,
                        child: Text(_ranges[i],
                            style: AppTextStyles.caption.copyWith(
                              color: sel ? Colors.white : AppColors.textSecondary,
                              fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Steps chart ──────────────────────────────────────────────
            _ChartCard(
              title: 'Steps',
              child: data.isEmpty
                  ? _NoData()
                  : _StepsBarChart(stats: data),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Summary stats ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total workouts',
                    value: '${workouts.weeklyWorkoutCount}',
                    sub: _rangeIndex == 0 ? 'this week' : 'this month',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    label: 'Avg daily steps',
                    value: data.isEmpty
                        ? '—'
                        : (data.map((s) => s.steps).reduce((a, b) => a + b) /
                        data.length)
                        .toStringAsFixed(0),
                    sub: 'per day',
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total calories',
                    value: data.isEmpty
                        ? '—'
                        : data
                        .map((s) => s.caloriesBurned)
                        .reduce((a, b) => a + b)
                        .toStringAsFixed(0),
                    sub: 'kcal burned',
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    label: 'Active minutes',
                    value: data.isEmpty
                        ? '—'
                        : '${data.map((s) => s.activeMinutes).reduce((a, b) => a + b)}',
                    sub: 'total',
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Workout history ──────────────────────────────────────────
            Text('Workout history'.toUpperCase(), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            if (workouts.workouts.isEmpty)
              _NoData()
            else
              ...workouts.workouts.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _WorkoutHistoryRow(workout: w),
              )),
          ],
        ),
      ),
    );
  }
}

// ── Chart card wrapper ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: 120, child: child),
        ],
      ),
    );
  }
}

// ── Bar chart using fl_chart ──────────────────────────────────────────────────
class _StepsBarChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  const _StepsBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxSteps =
    stats.map((s) => s.steps).fold(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: (maxSteps * 1.2).toDouble().clamp(1000, double.infinity),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= stats.length) return const SizedBox();
                final date = stats[idx].date;
                final parts = date.split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${parts[2]}',
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(stats.length, (i) {
          final isToday = stats[i].date ==
              DateTime.now().toIso8601String().substring(0, 10);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: stats[i].steps.toDouble(),
                color: isToday ? AppColors.primary : AppColors.border,
                width: 14,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Summary stat card ─────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value,
        required this.sub, required this.color});

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
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTextStyles.statValue
                  .copyWith(fontSize: 20, color: color)),
          Text(sub, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Workout history row ───────────────────────────────────────────────────────
class _WorkoutHistoryRow extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutHistoryRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/workout/${workout.workoutId}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: const Icon(Icons.fitness_center,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.type,
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  Text(
                    '${workout.durationMin} min · '
                        '${workout.caloriesBurned.toStringAsFixed(0)} kcal · '
                        '${_formatDate(workout.loggedAt)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
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
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _NoData extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text('No data yet', style: AppTextStyles.caption),
  );
}