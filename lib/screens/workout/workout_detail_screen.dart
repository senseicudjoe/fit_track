import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_model.dart';
import '../../utils/constants.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  WorkoutModel? _workout;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final w = await context.read<WorkoutProvider>()
        .fetchWorkout(uid, widget.workoutId);
    if (mounted) setState(() { _workout = w; _loading = false; });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete workout', style: AppTextStyles.heading3),
        content: Text('This cannot be undone.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      await context.read<WorkoutProvider>()
          .deleteWorkout(uid, widget.workoutId);
      // Return to previous screen after deletion
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(
          child: Text('Workout not found', style: AppTextStyles.body),
        ),
      );
    }

    final w = _workout!;

    return Scaffold(
      appBar: AppBar(
        title: Text(w.type),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            _formatDateTime(w.loggedAt),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
            children: [
              _StatBox(
                label: 'Duration',
                value: '${w.durationMin}',
                unit: 'min',
                color: AppColors.primary,
              ),
              _StatBox(
                label: 'Calories',
                value: w.caloriesBurned.toStringAsFixed(0),
                unit: 'kcal',
                color: AppColors.amber,
              ),
              if (w.distanceKm > 0)
                _StatBox(
                  label: 'Distance',
                  value: w.distanceKm.toStringAsFixed(2),
                  unit: 'km',
                  color: AppColors.teal,
                ),
              if (w.distanceKm > 0)
                _StatBox(
                  label: 'Avg pace',
                  value: _pace(w),
                  unit: '/km',
                  color: AppColors.coral,
                ),
              if (w.sets != null)
                _StatBox(
                  label: 'Sets',
                  value: '${w.sets}',
                  unit: '',
                  color: AppColors.teal,
                ),
              if (w.reps != null)
                _StatBox(
                  label: 'Reps',
                  value: '${w.reps}',
                  unit: '',
                  color: AppColors.coral,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (w.timerSplits.isNotEmpty) ...[
            Text('Timer splits'.toUpperCase(), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: SizedBox(
                height: 120,
                child: _SplitsChart(splits: w.timerSplits),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          Text('Details'.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                _DetailRow('Type', w.type),
                _DetailRow('Duration', '${w.durationMin} min'),
                _DetailRow('Calories burned',
                    '${w.caloriesBurned.toStringAsFixed(0)} kcal'),
                if (w.distanceKm > 0)
                  _DetailRow('Distance', '${w.distanceKm.toStringAsFixed(2)} km'),
                if (w.sets != null)
                  _DetailRow('Sets', '${w.sets}'),
                if (w.reps != null)
                  _DetailRow('Reps', '${w.reps}'),
                if (w.timerSplits.isNotEmpty)
                  _DetailRow('Rounds', '${w.timerSplits.length}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (w.notes.isNotEmpty) ...[
            Text('Notes'.toUpperCase(), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(w.notes, style: AppTextStyles.body),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          OutlinedButton.icon(
            onPressed: () => context.go('/log'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.border, width: 0.5),
              foregroundColor: AppColors.textSecondary,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log another workout'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = d.hour.toString().padLeft(2, '0');
    final min  = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hour:$min';
  }

  String _pace(WorkoutModel w) {
    if (w.distanceKm == 0) return '—';
    final secPerKm = (w.durationMin * 60) / w.distanceKm;
    final m = (secPerKm ~/ 60).toString();
    final s = (secPerKm % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$s';
  }
}

class _StatBox extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.unit, required this.color});
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTextStyles.statValue.copyWith(fontSize: 22, color: color)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(unit, style: AppTextStyles.caption),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SplitsChart extends StatelessWidget {
  final List<int> splits;
  const _SplitsChart({required this.splits});
  @override
  Widget build(BuildContext context) {
    final maxVal = splits.reduce((a, b) => a > b ? a : b).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxVal * 1.3,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('R${v.toInt() + 1}', style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5)),
        borderData: FlBorderData(show: false),
        barGroups: splits.indexed.map((entry) {
          final (i, s) = entry;
          return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: s.toDouble(), color: AppColors.primary, width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]);
        }).toList(),
      ),
    );
  }
}
