import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Form state
  final _nameCtrl   = TextEditingController();
  int _age          = 25;
  double _weightKg  = 70;
  double _heightCm  = 170;
  String _goal      = 'Lose weight';
  String _activity  = 'Moderately active';

  static const _goals = [
    'Lose weight', 'Build muscle', 'Improve endurance',
    'Stay active', 'Train for an event',
  ];

  static const _activities = [
    'Sedentary', 'Lightly active', 'Moderately active',
    'Very active', 'Athlete',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) _nameCtrl.text = user.displayName;
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final goalProvider = context.read<GoalProvider>();
    
    // 1. Save user profile
    await auth.completeOnboarding(
      age:           _age,
      weightKg:      _weightKg,
      heightCm:      _heightCm,
      fitnessGoal:   _goal,
      activityLevel: _activity,
    );

    // 2. Create tailored default goals based on intensity
    final uid = auth.user?.uid;
    if (uid != null) {
      await goalProvider.createDefaultGoals(uid, _activity);
    }

    if (!mounted) return;
    context.go('/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= _page
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: AppRadius.full,
                    ),
                  ),
                )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _PageOne(nameCtrl: _nameCtrl),
                  _PageTwo(
                    age: _age, weightKg: _weightKg, heightCm: _heightCm,
                    onAge: (v) => setState(() => _age = v),
                    onWeight: (v) => setState(() => _weightKg = v),
                    onHeight: (v) => setState(() => _heightCm = v),
                  ),
                  _PageThree(
                    goal: _goal, activity: _activity,
                    goals: _goals, activities: _activities,
                    onGoal: (v) => setState(() => _goal = v),
                    onActivity: (v) => setState(() => _activity = v),
                  ),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_page < 2 ? 'Continue' : 'Get started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome + name ────────────────────────────────────────────────────
class _PageOne extends StatelessWidget {
  final TextEditingController nameCtrl;
  const _PageOne({required this.nameCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: AppRadius.lg,
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 36),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Welcome to FitTrack', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Let's set up your profile so we can personalise your experience.",
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'What should we call you?'),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Body metrics ──────────────────────────────────────────────────────
class _PageTwo extends StatelessWidget {
  final int age;
  final double weightKg, heightCm;
  final ValueChanged<int> onAge;
  final ValueChanged<double> onWeight, onHeight;

  const _PageTwo({
    required this.age, required this.weightKg, required this.heightCm,
    required this.onAge, required this.onWeight, required this.onHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your body metrics', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          Text('Used to calculate calorie estimates', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xxl),

          _SliderField(
            label: 'Age',
            value: age.toDouble(),
            min: 13, max: 90, divisions: 77,
            display: '$age years',
            onChanged: (v) => onAge(v.round()),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SliderField(
            label: 'Weight',
            value: weightKg,
            min: 30, max: 200, divisions: 170,
            display: '${weightKg.toStringAsFixed(1)} kg',
            onChanged: onWeight,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SliderField(
            label: 'Height',
            value: heightCm,
            min: 120, max: 220, divisions: 100,
            display: '${heightCm.toStringAsFixed(0)} cm',
            onChanged: onHeight,
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Goals + activity level ───────────────────────────────────────────
class _PageThree extends StatelessWidget {
  final String goal, activity;
  final List<String> goals, activities;
  final ValueChanged<String> onGoal, onActivity;

  const _PageThree({
    required this.goal, required this.activity,
    required this.goals, required this.activities,
    required this.onGoal, required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your fitness goal', style: AppTextStyles.heading1),
          const SizedBox(height: AppSpacing.sm),
          Text('What are you aiming to achieve?', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xxl),

          ...goals.map((g) => _SelectTile(
            label: g,
            selected: g == goal,
            onTap: () => onGoal(g),
          )),

          const SizedBox(height: AppSpacing.xl),
          Text('Activity level', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),

          ...activities.map((a) => _SelectTile(
            label: a,
            selected: a == activity,
            onTap: () => onActivity(a),
          )),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _SliderField extends StatelessWidget {
  final String label, display;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label, required this.value, required this.min,
    required this.max, required this.divisions, required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            Text(display,
                style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: value, min: min, max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SelectTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectTile({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.card,
          borderRadius: AppRadius.sm,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.body.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
