import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/goal_provider.dart';
import '../../utils/constants.dart';
import '../../models/goal_model.dart';
import '../../models/workout_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    // StatsProvider.init is called by ProxyProvider, but we await here to ensure it's ready
    await context.read<StatsProvider>().init(uid);
    context.read<WorkoutProvider>().subscribe(uid);
    context.read<GoalProvider>().subscribe(uid);
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final stats    = context.watch<StatsProvider>();
    final workouts = context.watch<WorkoutProvider>();
    final goals    = context.watch<GoalProvider>();
    final user     = auth.user;

    // Aggressive loading check: show spinner until the 'today' stats object is fetched.
    // This prevents the UI from rendering zeros while the provider is initializing.
    final bool isInitialLoading = stats.today == null || 
                                (workouts.loading && workouts.workouts.isEmpty);

    // Fetch dynamic goals from GoalProvider
    final double stepGoal = goals.getGoalValue(GoalType.steps, fallback: 10000);
    final double calGoal = goals.getGoalValue(GoalType.calories, fallback: 600);
    final double activeGoal = goals.getGoalValue(GoalType.activeMinutes, fallback: 30);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isInitialLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () => stats.refresh(user?.uid ?? ''),
        child: CustomScrollView(
          slivers: [

            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                name: user?.displayName ?? 'Athlete',
                greeting: _greeting(),
                weeklyCount: workouts.weeklyWorkoutCount,
                onNotifTap: () => context.go('/reminders'),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Hero step ring card ──────────────────────────────
                  _StepRingCard(
                    steps: stats.liveSteps,
                    goal: stepGoal.toInt(),
                    progress: (stats.liveSteps / stepGoal).clamp(0.0, 1.0),
                    calories: stats.today?.caloriesBurned ?? 0,
                    activeMin: stats.today?.activeMinutes ?? 0,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Stats row ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _GlowStatCard(
                          label: 'Calories',
                          value: (stats.today?.caloriesBurned ?? 0)
                              .toStringAsFixed(0),
                          unit: 'kcal',
                          accent: AppColors.amber,
                          progress: ((stats.today?.caloriesBurned ?? 0) / calGoal)
                              .clamp(0.0, 1.0),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _GlowStatCard(
                          label: 'Active',
                          value: '${stats.today?.activeMinutes ?? 0}',
                          unit: 'min',
                          accent: AppColors.primary,
                          progress: ((stats.today?.activeMinutes ?? 0) / activeGoal)
                              .clamp(0.0, 1.0),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _GlowStatCard(
                          label: 'Workouts',
                          value: '${workouts.weeklyWorkoutCount}',
                          unit: '/ 5',
                          accent: AppColors.coral,
                          progress: (workouts.weeklyWorkoutCount / 5).clamp(0.0, 1.0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Quick actions ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _PrimaryAction(
                          icon: Icons.timer_rounded,
                          label: 'Start timer',
                          sub: 'Interval session',
                          color: AppColors.primary,
                          onTap: () => context.go('/timer'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: _SecondaryAction(
                          icon: Icons.add_rounded,
                          label: 'Log workout',
                          color: AppColors.teal,
                          onTap: () => context.go('/log'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Goals ─────────────────────────────────────────────
                  if (goals.goals.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Goal progress',
                      actionLabel: 'See all',
                      onAction: () => context.go('/goals'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...goals.goals.take(3).map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _GoalRow(goal: g),
                    )),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ── Recent workouts ───────────────────────────────────
                  if (workouts.workouts.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Recent workouts',
                      actionLabel: 'View all',
                      onAction: () => context.go('/progress'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...workouts.workouts.take(3).map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _WorkoutRow(workout: w),
                    )),
                  ],

                  // ── Empty state ───────────────────────────────────────
                  if (!workouts.loading && !goals.loading && 
                      workouts.workouts.isEmpty && goals.goals.isEmpty)
                    _EmptyState(onTap: () => context.go('/log')),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ... (rest of the file remains same)

class _Header extends StatelessWidget {
  final String name, greeting;
  final int weeklyCount;
  final VoidCallback onNotifTap;

  const _Header({
    required this.name, required this.greeting,
    required this.weeklyCount, required this.onNotifTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 56, AppSpacing.lg, AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(name, style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$weeklyCount workout${weeklyCount == 1 ? '' : 's'} this week',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.teal),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onNotifTap,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRingCard extends StatelessWidget {
  final int steps, goal;
  final double progress, calories;
  final int activeMin;

  const _StepRingCard({
    required this.steps, required this.goal, required this.progress,
    required this.calories, required this.activeMin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 110, height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: AppColors.border,
                    valueColor:
                    const AlwaysStoppedAnimation(AppColors.teal),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortSteps(steps),
                      style: AppTextStyles.heading1
                          .copyWith(color: AppColors.teal, fontSize: 26),
                    ),
                    Text('steps',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.teal)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),

          // Right side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily steps', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% of $goal goal',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                _MiniStatRow(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.amber,
                  label: '${calories.toStringAsFixed(0)} kcal',
                ),
                const SizedBox(height: AppSpacing.sm),
                _MiniStatRow(
                  icon: Icons.access_time_rounded,
                  color: AppColors.primary,
                  label: '$activeMin min active',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortSteps(int s) =>
      s >= 1000 ? '${(s / 1000).toStringAsFixed(1)}k' : '$s';
}

class _MiniStatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MiniStatRow(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _GlowStatCard extends StatelessWidget {
  final String label, value, unit;
  final Color accent;
  final double progress;

  const _GlowStatCard({
    required this.label, required this.value, required this.unit,
    required this.accent, required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: accent.withOpacity(0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.statValue
                      .copyWith(fontSize: 20, color: accent),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: accent.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(accent),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon, required this.label, required this.sub,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.heading3
                          .copyWith(color: Colors.white)),
                  Text(sub,
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.md,
          border: Border.all(color: color.withOpacity(0.35), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: color, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title, required this.actionLabel, required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.label),
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  final GoalModel goal;
  const _GoalRow({required this.goal});

  Color _accentFor(String type) {
    switch (type) {
      case GoalType.steps:          return AppColors.teal;
      case GoalType.calories:       return AppColors.amber;
      case GoalType.activeMinutes:  return AppColors.primary;
      case GoalType.weeklyWorkouts: return AppColors.coral;
      default:                      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = goal.isCompleted ? AppColors.teal : _accentFor(goal.type);
    final pct    = (goal.progressPercent * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.sm,
        border: Border.all(
          color: goal.isCompleted
              ? AppColors.teal.withOpacity(0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (goal.isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.check_circle_rounded,
                          color: AppColors.teal, size: 14),
                    ),
                  Text(goal.type,
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              Text(
                '$pct%',
                style: AppTextStyles.caption.copyWith(
                    color: accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.full,
                  child: LinearProgressIndicator(
                    value: goal.progressPercent,
                    backgroundColor: accent.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${goal.currentValue.toStringAsFixed(0)} / '
                    '${goal.targetValue.toStringAsFixed(0)} ${goal.unit}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutModel workout;
  const _WorkoutRow({required this.workout});

  IconData _iconFor(String type) {
    switch (type) {
      case WorkoutType.running:  return Icons.directions_run_rounded;
      case WorkoutType.cycling:  return Icons.directions_bike_rounded;
      case WorkoutType.walking:  return Icons.directions_walk_rounded;
      case WorkoutType.swimming: return Icons.pool_rounded;
      case WorkoutType.yoga:     return Icons.self_improvement_rounded;
      case WorkoutType.strength: return Icons.fitness_center_rounded;
      case WorkoutType.hiit:     return Icons.timer_rounded;
      default:                   return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/${workout.workoutId}'),
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
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(_iconFor(workout.type),
                  color: AppColors.primary, size: 20),
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
                  const SizedBox(height: 2),
                  Text(
                    '${workout.durationMin} min · '
                        '${workout.caloriesBurned.toStringAsFixed(0)} kcal',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_relDate(workout.loggedAt),
                    style: AppTextStyles.caption),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _relDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today';
    }
    final y = now.subtract(const Duration(days: 1));
    if (d.year == y.year && d.month == y.month && d.day == y.day) {
      return 'Yesterday';
    }
    return '${d.day}/${d.month}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: AppRadius.md,
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ready to move?', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Log your first workout or set a goal to get started.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: onTap,
            child: const Text('Log first workout'),
          ),
        ],
      ),
    );
  }
}
