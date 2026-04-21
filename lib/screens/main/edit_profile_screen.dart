import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late int _age;
  late double _weightKg;
  late double _heightCm;
  late String _goal;
  late String _activity;

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
    final user = context.read<AuthProvider>().user!;
    _nameCtrl = TextEditingController(text: user.displayName);
    _age = user.age;
    _weightKg = user.weightKg;
    _heightCm = user.heightCm;
    _goal = user.fitnessGoal;
    _activity = user.activityLevel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final updated = auth.user!.copyWith(
      displayName: _nameCtrl.text.trim(),
      age: _age,
      weightKg: _weightKg,
      heightCm: _heightCm,
      fitnessGoal: _goal,
      activityLevel: _activity,
    );

    await auth.updateProfile(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
              Text('General info'.toUpperCase(), style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: AppTextStyles.body,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.xl),
              
              Text('Body metrics'.toUpperCase(), style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(children: [
                _EditMetricRow(
                  label: 'Age',
                  value: '$_age',
                  onTap: () => _showSliderDialog('Age', _age.toDouble(), 13, 90, (v) => setState(() => _age = v.round())),
                ),
                _EditMetricRow(
                  label: 'Weight (kg)',
                  value: '${_weightKg.toStringAsFixed(1)} kg',
                  onTap: () => _showSliderDialog('Weight', _weightKg, 30, 200, (v) => setState(() => _weightKg = v)),
                ),
                _EditMetricRow(
                  label: 'Height (cm)',
                  value: '${_heightCm.toStringAsFixed(0)} cm',
                  onTap: () => _showSliderDialog('Height', _heightCm, 120, 220, (v) => setState(() => _heightCm = v)),
                ),
              ]),
              const SizedBox(height: AppSpacing.xl),

              Text('Goals & Activity'.toUpperCase(), style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              _SettingsCard(children: [
                _EditMetricRow(
                  label: 'Fitness goal',
                  value: _goal,
                  onTap: () => _showPicker('Select goal', _goals, _goal, (v) => setState(() => _goal = v)),
                ),
                _EditMetricRow(
                  label: 'Activity level',
                  value: _activity,
                  onTap: () => _showPicker('Activity level', _activities, _activity, (v) => setState(() => _activity = v)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showSliderDialog(String title, double current, double min, double max, ValueChanged<double> onChanged) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(title, style: AppTextStyles.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${current.toStringAsFixed(current == current.roundToDouble() ? 0 : 1)}', 
                style: AppTextStyles.statValue.copyWith(color: AppColors.primary)),
              Slider(
                value: current,
                min: min,
                max: max,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setDialogState(() => current = v);
                  onChanged(v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      ),
    );
  }

  void _showPicker(String title, List<String> options, String selected, ValueChanged<String> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.lg),
            ...options.map((opt) => ListTile(
              title: Text(opt, 
                style: AppTextStyles.body.copyWith(
                  color: opt == selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: opt == selected ? FontWeight.bold : FontWeight.normal,
                )),
              trailing: opt == selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () {
                onChanged(opt);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: children.indexed.map((entry) {
          final (i, child) = entry;
          return Column(
            children: [
              child,
              if (i < children.length - 1)
                const Divider(height: 1, thickness: 0.5, color: AppColors.border, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EditMetricRow extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _EditMetricRow({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: AppTextStyles.body),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}
