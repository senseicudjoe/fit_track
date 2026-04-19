import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../models/reminder_model.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersOn  = true;
  bool _soundOn      = true;
  bool _metricUnits  = true;
  String _reminderTime = '07:00';
  final _notif = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersOn   = prefs.getBool('reminders_on')  ?? true;
      _soundOn       = prefs.getBool('sound_on')      ?? true;
      _metricUnits   = prefs.getBool('metric_units')  ?? true;
      _reminderTime  = prefs.getString('reminder_time') ?? '07:00';
    });
    await _syncDailyReminder();
  }

  Future<void> _setPref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)   await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  ReminderModel? _dailyReminderModel() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null || uid.isEmpty) return null;
    return ReminderModel(
      reminderId: 'settings_daily_reminder',
      uid: uid,
      label: 'Daily workout reminder',
      timeOfDay: _reminderTime,
      repeatDays: const [0, 1, 2, 3, 4, 5, 6],
      isActive: _remindersOn,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _syncDailyReminder() async {
    final reminder = _dailyReminderModel();
    if (reminder == null) return;
    await _notif.cancelReminder(reminder);
    if (_remindersOn) {
      await _notif.scheduleReminder(reminder);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Sign out', style: AppTextStyles.heading3),
        content: Text('Are you sure you want to sign out?',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Sign out',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                _Avatar(name: user?.displayName ?? 'U'),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? '—',
                          style: AppTextStyles.heading3),
                      Text(user?.email ?? '—', style: AppTextStyles.caption),
                      if (user != null)
                        Text(
                          '${user.weightKg.toStringAsFixed(0)} kg · '
                              '${user.heightCm.toStringAsFixed(0)} cm · '
                              '${user.fitnessGoal}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel('Preferences'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(children: [
            _SwitchRow(
              label: 'Metric units (kg / km)',
              value: _metricUnits,
              onChanged: (v) {
                setState(() => _metricUnits = v);
                _setPref('metric_units', v);
              },
            ),
            _SwitchRow(
              label: 'Workout reminders',
              value: _remindersOn,
              onChanged: (v) async {
                setState(() => _remindersOn = v);
                await _setPref('reminders_on', v);
                await _syncDailyReminder();
              },
            ),
            _SwitchRow(
              label: 'Sound on completion',
              value: _soundOn,
              onChanged: (v) {
                setState(() => _soundOn = v);
                _setPref('sound_on', v);
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel('Reminders'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(children: [
            _TapRow(
              label: 'Daily reminder time',
              trailing: Text(_reminderTime,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.primary)),
              onTap: () async {
                final parts = _reminderTime.split(':');
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(parts[0]),
                    minute: int.parse(parts[1]),
                  ),
                );
                if (picked != null) {
                  final formatted =
                      '${picked.hour.toString().padLeft(2, '0')}:'
                      '${picked.minute.toString().padLeft(2, '0')}';
                  setState(() => _reminderTime = formatted);
                  await _setPref('reminder_time', formatted);
                  await _syncDailyReminder();
                }
              },
            ),
            _TapRow(
              label: 'Manage reminders',
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 18),
              onTap: () => context.go('/reminders'),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel('Account'),
          const SizedBox(height: AppSpacing.sm),
          _SettingsCard(children: [
            _TapRow(
              label: 'Sign out',
              trailing: const Icon(Icons.logout,
                  color: AppColors.red, size: 18),
              onTap: _signOut,
              labelColor: AppColors.red,
            ),
          ]),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text('FitTrack v1.0.0',
                style: AppTextStyles.caption),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTextStyles.label);
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
                const Divider(
                    height: 1, thickness: 0.5,
                    color: AppColors.border, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback onTap;
  final Color? labelColor;
  const _TapRow({required this.label, required this.trailing, required this.onTap, this.labelColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body.copyWith(color: labelColor ?? AppColors.textSecondary)),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'U'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.full),
      alignment: Alignment.center,
      child: Text(initials, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
    );
  }
}
