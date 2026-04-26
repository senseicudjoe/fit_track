import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/timer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/stats_provider.dart';
import '../../services/timer_service.dart';
import '../../utils/constants.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Config state (shown before timer starts)
  int _workSec     = 40;
  int _restSec     = 20;
  int _cooldownSec = 60;
  int _rounds      = 8;
  bool _configured = false;

  void _startTimer() {
    final timer = context.read<TimerProvider>();
    timer.configure(
      workSeconds:     _workSec,
      restSeconds:     _restSec,
      cooldownSeconds: _cooldownSec,
      totalRounds:     _rounds,
    );
    timer.start();
    setState(() => _configured = true);
  }

  Future<void> _onFinish(List<int> splits) async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null || !mounted) return;

    // Calculate total seconds to avoid integer division issues
    final totalSeconds = (_workSec * _rounds) + (_restSec * (_rounds - 1)) + _cooldownSec;

    // For logging, we use minutes (rounded up to nearest 1 if > 0)
    final durationMin = (totalSeconds / 60).ceil().clamp(1, 999);

    // Calculate calories based on precise minutes (double)
    final calories = ((totalSeconds / 60) * 7.5).roundToDouble();

    final ok = await context.read<WorkoutProvider>().logWorkout(
      uid:            uid,
      type:           'HIIT',
      durationMin:    durationMin,
      caloriesBurned: calories,
      distanceKm:     0,
      timerSplits:    splits,
      notes:          'Timer session — $_rounds rounds',
    );

    if (ok && mounted) {
      await context.read<StatsProvider>().onWorkoutLogged(
        uid: uid, calories: calories, durationMin: durationMin,
      );
      _showCompletionSheet(splits, durationMin, calories);
    }
  }

  void _showCompletionSheet(List<int> splits, int totalMin, double calories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: AppColors.amber, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Session complete!', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.sm),
            Text('$_rounds rounds · $totalMin min · ${calories.toStringAsFixed(1)} kcal',
                style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<TimerProvider>().reset();
                      setState(() => _configured = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Go again'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/progress');
                    },
                    child: const Text('View progress'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();

    // Listen for completion
    if (timer.isFinished && timer.splits.isNotEmpty && _configured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onFinish(timer.splits);
        setState(() => _configured = false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout timer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<TimerProvider>().reset();
            context.go('/dashboard');
          },
        ),
      ),
      body: _configured
          ? _ActiveTimer(timer: timer)
          : _ConfigView(
        workSec:     _workSec,
        restSec:     _restSec,
        cooldownSec: _cooldownSec,
        rounds:      _rounds,
        onWorkSec:     (v) => setState(() => _workSec = v),
        onRestSec:     (v) => setState(() => _restSec = v),
        onCooldownSec: (v) => setState(() => _cooldownSec = v),
        onRounds:      (v) => setState(() => _rounds = v),
        onStart:       _startTimer,
      ),
    );
  }
}

// ── Config view (shown before start) ─────────────────────────────────────────
class _ConfigView extends StatelessWidget {
  final int workSec, restSec, cooldownSec, rounds;
  final ValueChanged<int> onWorkSec, onRestSec, onCooldownSec, onRounds;
  final VoidCallback onStart;

  const _ConfigView({
    required this.workSec, required this.restSec,
    required this.cooldownSec, required this.rounds,
    required this.onWorkSec, required this.onRestSec,
    required this.onCooldownSec, required this.onRounds,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configure timer', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          Text('Set your intervals and rounds', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xxl),

          _ConfigSlider(
            label: 'Work time',
            value: workSec,
            min: 10, max: 120,
            display: '${workSec}s',
            color: AppColors.primary,
            onChanged: onWorkSec,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ConfigSlider(
            label: 'Rest time',
            value: restSec,
            min: 5, max: 60,
            display: '${restSec}s',
            color: AppColors.teal,
            onChanged: onRestSec,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ConfigSlider(
            label: 'Cool-down time',
            value: cooldownSec,
            min: 30, max: 300,
            display: '${cooldownSec}s',
            color: AppColors.amber,
            onChanged: onCooldownSec,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ConfigSlider(
            label: 'Rounds',
            value: rounds,
            min: 1, max: 20,
            display: '$rounds',
            color: AppColors.coral,
            onChanged: onRounds,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                    label: 'Total time',
                    value: _totalTime(workSec, restSec, cooldownSec, rounds)),
                _SummaryItem(label: 'Rounds', value: '$rounds'),
                _SummaryItem(
                    label: 'Est. kcal',
                    value: _estCalories(workSec, restSec, cooldownSec, rounds)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          ElevatedButton(
            onPressed: onStart,
            child: const Text('Start session'),
          ),
        ],
      ),
    );
  }

  String _totalTime(int w, int r, int c, int rounds) {
    final total = w * rounds + r * (rounds - 1) + c;
    if (total < 60) return '${total}s';
    final m = total ~/ 60;
    final s = total % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  String _estCalories(int w, int r, int c, int rounds) {
    final totalSeconds = (w * rounds + r * (rounds - 1) + c);
    final kcal = (totalSeconds / 60) * 7.5;
    return '${kcal.toStringAsFixed(1)} kcal';
  }
}

// ── Active timer view ─────────────────────────────────────────────────────────
class _ActiveTimer extends StatelessWidget {
  final TimerProvider timer;
  const _ActiveTimer({required this.timer});

  @override
  Widget build(BuildContext context) {
    final phaseColor = switch (timer.phase) {
      TimerPhase.work     => AppColors.primary,
      TimerPhase.rest     => AppColors.teal,
      TimerPhase.cooldown => AppColors.amber,
      TimerPhase.idle     => AppColors.textHint,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Phase pills
          Row(
            children: [
              _PhasePill('Work',      timer.phase == TimerPhase.work,      AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              _PhasePill('Rest',      timer.phase == TimerPhase.rest,      AppColors.teal),
              const SizedBox(width: AppSpacing.sm),
              _PhasePill('Cool-down', timer.phase == TimerPhase.cooldown,  AppColors.amber),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Countdown ring
          SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: timer.phaseProgress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(phaseColor),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(timer.displayTime,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(timer.phaseLabel.toUpperCase(),
                        style: AppTextStyles.label
                            .copyWith(color: phaseColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Round counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Round ', style: AppTextStyles.body),
              Text('${timer.currentRound}',
                  style: AppTextStyles.heading2
                      .copyWith(color: phaseColor)),
              Text(' of ${timer.totalRounds}', style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Session progress bar
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: timer.sessionProgress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(phaseColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CtrlBtn(
                icon: Icons.refresh,
                label: 'Reset',
                onTap: () => context.read<TimerProvider>().reset(),
              ),
              const SizedBox(width: AppSpacing.xl),
              _PlayPauseBtn(
                isRunning: timer.isRunning,
                color: phaseColor,
                onTap: () {
                  final t = context.read<TimerProvider>();
                  t.isRunning ? t.pause() : t.resume();
                },
              ),
              const SizedBox(width: AppSpacing.xl),
              _CtrlBtn(
                icon: Icons.skip_next,
                label: 'Skip',
                onTap: () => context.read<TimerProvider>().skip(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Splits
          if (timer.splits.isNotEmpty) ...[
            Text('Splits'.toUpperCase(), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: timer.splits.indexed.map((entry) {
                final (i, s) = entry;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.full,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    'R${i + 1}: ${s}s',
                    style: AppTextStyles.caption,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reusable timer sub-widgets ────────────────────────────────────────────────
class _PhasePill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  const _PhasePill(this.label, this.active, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : AppColors.card,
          borderRadius: AppRadius.full,
          border: Border.all(
              color: active ? color : AppColors.border, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
              color: active ? Colors.white : AppColors.textHint,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

class _PlayPauseBtn extends StatelessWidget {
  final bool isRunning;
  final Color color;
  final VoidCallback onTap;
  const _PlayPauseBtn(
      {required this.isRunning, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          isRunning ? Icons.pause : Icons.play_arrow,
          color: Colors.white, size: 36,
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CtrlBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ConfigSlider extends StatelessWidget {
  final String label, display;
  final int value, min, max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ConfigSlider({
    required this.label, required this.value, required this.min,
    required this.max, required this.display, required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            Text(display,
                style: AppTextStyles.heading3.copyWith(color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.border,
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}