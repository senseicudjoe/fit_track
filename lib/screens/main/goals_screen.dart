import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../models/goal_model.dart';
import '../../utils/constants.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Goals')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddGoalDialog(context, uid),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: goalProvider.loading && goalProvider.goals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : goalProvider.goals.isEmpty
          ? _EmptyGoals(onAdd: () => _showAddGoalDialog(context, uid))
          : ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (goalProvider.activeGoals.isNotEmpty) ...[
            _SectionHeader('Active'),
            ...goalProvider.activeGoals.map((g) => _GoalCard(goal: g, uid: uid)),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (goalProvider.completedGoals.isNotEmpty) ...[
            _SectionHeader('Completed'),
            ...goalProvider.completedGoals.map((g) => _GoalCard(goal: g, uid: uid)),
          ],
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddGoalDialog(uid: uid),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  final String uid;
  const _AddGoalDialog({required this.uid});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  String _type = GoalType.steps;
  final _targetCtrl = TextEditingController();
  String _period = 'daily';

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.read<GoalProvider>();

    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('New goal', style: AppTextStyles.heading3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: GoalType.all.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Goal type'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target value',
                suffixText: GoalType.unitFor(_type),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _period,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _period = v!),
              decoration: const InputDecoration(labelText: 'Period'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final target = double.tryParse(_targetCtrl.text) ?? 0;
            if (target <= 0) return;

            final ok = await goalProvider.addGoal(
              uid: widget.uid,
              type: _type,
              targetValue: target,
              period: _period,
            );
            if (ok && mounted) {
              Navigator.of(context).pop(); // Correctly pop the dialog
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String uid;
  const _GoalCard({required this.goal, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.type, style: AppTextStyles.heading3),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.textHint, size: 20),
                onPressed: () => context.read<GoalProvider>().deleteGoal(uid, goal.goalId),
              ),
            ],
          ),
          Text('${goal.period.toUpperCase()} GOAL', style: AppTextStyles.label.copyWith(fontSize: 10)),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue.toStringAsFixed(0)} ${goal.unit}',
                style: AppTextStyles.body,
              ),
              Text(
                '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.heading3.copyWith(color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.full,
            child: LinearProgressIndicator(
              value: goal.progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title.toUpperCase(), style: AppTextStyles.label),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text('No goals set', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text('Set a target to keep yourself motivated!', style: AppTextStyles.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: onAdd, child: const Text('Set first goal')),
        ],
      ),
    );
  }
}
