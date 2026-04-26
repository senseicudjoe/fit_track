import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/reminder_model.dart';
import '../../utils/constants.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _firestore = FirestoreService.instance;
  final _notif     = NotificationService.instance;
  final _uuid      = const Uuid();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showReminderSheet(context, uid),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<ReminderModel>>(
        stream: _firestore.remindersStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snap.data ?? [];
          if (reminders.isEmpty) {
            return _EmptyState(onAdd: () => _showReminderSheet(context, uid));
          }

          final active   = reminders.where((r) => r.isActive).toList();
          final inactive = reminders.where((r) => !r.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (active.isNotEmpty) ...[
                Text('Active'.toUpperCase(), style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                ...active.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ReminderCard(
                    reminder: r, uid: uid,
                    onToggle: (v) => _toggle(r, uid, v),
                    onDelete: () => _delete(r, uid),
                    onTap: () => _showReminderSheet(context, uid, reminder: r),
                  ),
                )),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (inactive.isNotEmpty) ...[
                Text('Inactive'.toUpperCase(), style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                ...inactive.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ReminderCard(
                    reminder: r, uid: uid,
                    onToggle: (v) => _toggle(r, uid, v),
                    onDelete: () => _delete(r, uid),
                    onTap: () => _showReminderSheet(context, uid, reminder: r),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(ReminderModel r, String uid, bool active) async {
    await _firestore.toggleReminder(uid, r.reminderId, active);
    if (active) {
      await _notif.scheduleReminder(r.copyWith(isActive: true));
    } else {
      await _notif.cancelReminder(r);
    }
  }

  Future<void> _delete(ReminderModel r, String uid) async {
    await _notif.cancelReminder(r);
    await _firestore.deleteReminder(uid, r.reminderId);
  }

  void _showReminderSheet(BuildContext context, String uid, {ReminderModel? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReminderSheet(
        uid: uid,
        reminder: reminder,
        onSave: (r) async {
          await _firestore.saveReminder(r);
          if (r.isActive) {
            await _notif.cancelReminder(r); // Cancel old schedule if updating
            await _notif.scheduleReminder(r);
          } else {
            await _notif.cancelReminder(r);
          }
        },
        uuid: _uuid,
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────
class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final String uid;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder, required this.uid,
    required this.onToggle, required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reminder.reminderId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.15),
          borderRadius: AppRadius.md,
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.md,
            border: Border.all(
              color: reminder.isActive
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: reminder.isActive
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.cardAlt,
                  borderRadius: AppRadius.sm,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: reminder.isActive
                      ? AppColors.primary
                      : AppColors.textHint,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.label,
                        style: AppTextStyles.heading3.copyWith(
                          color: reminder.isActive
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        )),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${reminder.timeOfDay} · ${reminder.repeatLabel}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: reminder.isActive,
                onChanged: onToggle,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add/Edit reminder bottom sheet ─────────────────────────────────────────────
class _ReminderSheet extends StatefulWidget {
  final String uid;
  final ReminderModel? reminder;
  final Future<void> Function(ReminderModel) onSave;
  final Uuid uuid;

  const _ReminderSheet({
    required this.uid, this.reminder, required this.onSave, required this.uuid,
  });

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late TextEditingController _labelCtrl;
  late String _timeOfDay;
  late List<int> _days;
  bool _saving = false;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.reminder?.label ?? '');
    _timeOfDay = widget.reminder?.timeOfDay ?? '07:00';
    _days = widget.reminder != null ? List.from(widget.reminder!.repeatDays) : [0, 1, 2, 3, 4];
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _timeOfDay.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _timeOfDay =
        '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final reminder = ReminderModel(
      reminderId: widget.reminder?.reminderId ?? widget.uuid.v4(),
      uid:        widget.uid,
      label:      _labelCtrl.text.trim(),
      timeOfDay:  _timeOfDay,
      repeatDays: _days,
      isActive:   widget.reminder?.isActive ?? true,
      createdAt:  widget.reminder?.createdAt ?? DateTime.now(),
    );

    await widget.onSave(reminder);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xl, AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Update reminder' : 'Add reminder', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.xl),

          // Label
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. Morning run',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Time picker
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardAlt,
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Time', style: AppTextStyles.body),
                  Text(_timeOfDay,
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Day selector
          Text('Repeat', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _days.contains(i);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selected ? _days.remove(i) : _days.add(i);
                    _days.sort();
                  });
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.cardAlt,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _dayLabels[i],
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? Colors.white : AppColors.textHint,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              height: 20, width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : Text(isEdit ? 'Update reminder' : 'Save reminder'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Text('No reminders yet', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text('Tap + to add your first reminder', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(onPressed: onAdd, child: const Text('Add reminder')),
        ],
      ),
    );
  }
}
