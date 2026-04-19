import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/stats_provider.dart';
import '../../models/workout_model.dart';
import '../../utils/constants.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final _formKey       = GlobalKey<FormState>();
  String _type         = WorkoutType.running;
  final _durationCtrl  = TextEditingController();
  final _caloriesCtrl  = TextEditingController();
  final _distanceCtrl  = TextEditingController();
  final _setsCtrl      = TextEditingController();
  final _repsCtrl      = TextEditingController();
  final _notesCtrl     = TextEditingController();
  bool _showStrength   = false;
  bool _isSubmitting   = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final draft = await context.read<WorkoutProvider>().loadDraft(uid);
    if (draft == null || !mounted) return;
    setState(() {
      _type = draft['type'] as String? ?? WorkoutType.running;
      _durationCtrl.text = '${draft['duration_min'] ?? ''}';
      _caloriesCtrl.text = '${draft['calories'] ?? ''}';
      _distanceCtrl.text = '${draft['distance_km'] ?? ''}';
      _notesCtrl.text    = draft['notes'] as String? ?? '';
    });
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    _distanceCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    await context.read<WorkoutProvider>().saveDraft(uid, {
      'type':         _type,
      'duration_min': int.tryParse(_durationCtrl.text) ?? 0,
      'calories':     double.tryParse(_caloriesCtrl.text) ?? 0,
      'distance_km':  double.tryParse(_distanceCtrl.text) ?? 0,
      'notes':        _notesCtrl.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved!')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    try {
      final calories = double.tryParse(_caloriesCtrl.text) ?? 0;
      final duration = int.tryParse(_durationCtrl.text) ?? 0;
      final distance = double.tryParse(_distanceCtrl.text) ?? 0;

      final ok = await context.read<WorkoutProvider>().logWorkout(
        uid:            uid,
        type:           _type,
        durationMin:    duration,
        caloriesBurned: calories,
        distanceKm:     distance,
        sets:           int.tryParse(_setsCtrl.text),
        reps:           int.tryParse(_repsCtrl.text),
        notes:          _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (ok) {
        // Update today's stats including distance
        await context.read<StatsProvider>().onWorkoutLogged(
          uid: uid, 
          calories: calories, 
          durationMin: duration,
          distanceKm: distance,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout saved!')),
          );
          context.go('/progress');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log workout'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveDraft,
            child: Text('Save draft',
                style: AppTextStyles.caption
                    .copyWith(color: _isSubmitting ? AppColors.textHint : AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Exercise type picker ─────────────────────────────────────
              Text('Exercise type', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: WorkoutType.all.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final t = WorkoutType.all[i];
                    final selected = t == _type;
                    return GestureDetector(
                      onTap: _isSubmitting ? null : () => setState(() {
                        _type = t;
                        _showStrength = t == WorkoutType.strength;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.card,
                          borderRadius: AppRadius.full,
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(t,
                            style: AppTextStyles.caption.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Core metrics ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'Duration (min)'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesCtrl,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'Calories (kcal)'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _distanceCtrl,
                enabled: !_isSubmitting,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Distance (km)', hintText: 'Optional'),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Strength-only fields ─────────────────────────────────────
              if (_showStrength) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsCtrl,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration:
                        const InputDecoration(labelText: 'Sets'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _repsCtrl,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        decoration:
                        const InputDecoration(labelText: 'Reps'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Notes ────────────────────────────────────────────────────
              TextFormField(
                controller: _notesCtrl,
                enabled: !_isSubmitting,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'How did it feel? Any PBs?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Submit ───────────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Save workout'),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Start timer shortcut ─────────────────────────────────────
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => context.go('/timer'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                  foregroundColor: AppColors.textSecondary,
                ),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('Use workout timer instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
