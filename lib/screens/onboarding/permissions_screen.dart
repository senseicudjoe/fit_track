import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notifGranted = false;
  bool _motionGranted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    final status = await Permission.activityRecognition.status;
    // For notifications, we'll rely on our service or check here too
    if (mounted) {
      setState(() {
        _motionGranted = status.isGranted;
      });
    }
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);

    // Request notification permission
    final notif = await NotificationService.instance.requestPermissions();
    
    // Request motion/pedometer permission explicitly
    final motionStatus = await Permission.activityRecognition.request();

    if (mounted) {
      setState(() {
        _notifGranted = notif;
        _motionGranted = motionStatus.isGranted;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text('App permissions', style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'FitTrack needs these to work fully. You can change them in Settings anytime.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Permission items
              _PermissionItem(
                icon: Icons.directions_walk,
                iconColor: AppColors.primary,
                title: 'Motion & Pedometer',
                description:
                'Counts your daily steps using the device\'s motion sensor.',
                granted: _motionGranted,
              ),
              const SizedBox(height: AppSpacing.md),
              _PermissionItem(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.teal,
                title: 'Notifications',
                description:
                'Sends workout reminders and goal completion alerts.',
                granted: _notifGranted,
              ),
              const SizedBox(height: AppSpacing.md),
              _PermissionItem(
                icon: Icons.storage_outlined,
                iconColor: AppColors.amber,
                title: 'Storage',
                description:
                'Saves workouts and audio files locally on your device.',
                granted: true, // Always granted — SQLite needs no permission
              ),

              const Spacer(),

              // Grant button
              if (!_notifGranted || !_motionGranted)
                ElevatedButton(
                  onPressed: _loading ? null : _requestAll,
                  child: _loading
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Allow all & continue'),
                ),

              if (_notifGranted && _motionGranted) ...[
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Get started'),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: Text(
                    'Skip for now',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, description;
  final bool granted;

  const _PermissionItem({
    required this.icon, required this.iconColor,
    required this.title, required this.description,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: granted ? AppColors.teal.withOpacity(0.4) : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? AppColors.teal : AppColors.border,
            size: 20,
          ),
        ],
      ),
    );
  }
}