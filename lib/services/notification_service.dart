import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder_model.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Initialise timezone database — required for zonedSchedule
    tz_data.initializeTimeZones();
    await _setLocalTimeZone();

    // Using @mipmap/ic_launcher with the prefix informs the plugin to look in mipmap resources.
    // This is the standard way to use the app icon for notifications on Android.
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Without this, [tz.local] stays on UTC while [DateTime.now] uses the device
  /// clock — scheduled times and weekdays are wrong and alarms may never match.
  Future<void> _setLocalTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Rare: unknown identifier; stay on UTC so behaviour is at least consistent.
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Prefer exact while-idle alarms on Android (inexact is often heavily deferred on
  /// real devices). Falls back to inexact if [SCHEDULE_EXACT_ALARM] is not granted.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    if (await android.canScheduleExactNotifications() != true) {
      await android.requestExactAlarmsPermission();
    }
    if (await android.canScheduleExactNotifications() == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // ── Request permissions (call on permissions screen) ─────────────────────────
  Future<bool> requestPermissions() async {
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final android = await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (ios ?? false) || (android ?? false);
  }

  // ── Schedule a reminder ───────────────────────────────────────────────────────
  Future<void> scheduleReminder(ReminderModel reminder) async {
    if (!reminder.isActive) return;
    if (reminder.repeatDays.isEmpty) return;

    await requestPermissions();

    final androidMode = await _resolveAndroidScheduleMode();

    final parts  = reminder.timeOfDay.split(':');
    final hour   = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_reminders',
        'Workout Reminders',
        channelDescription: 'Daily workout reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        // Explicitly specifying the app icon for both small and large icon positions
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Schedule for each selected repeat day
    for (final day in reminder.repeatDays) {
      final id = reminder.notificationId + day;
      await _plugin.zonedSchedule(
        id,
        'FitTrack Reminder',
        reminder.label,
        _nextInstanceOfDayTime(day + 1, hour, minute),
        details,
        androidScheduleMode: androidMode,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // ── Cancel a reminder ─────────────────────────────────────────────────────────
  Future<void> cancelReminder(ReminderModel reminder) async {
    for (final day in reminder.repeatDays) {
      await _plugin.cancel(reminder.notificationId + day);
    }
  }

  // ── Cancel all ───────────────────────────────────────────────────────────────
  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── One-off notification (e.g. workout complete) ──────────────────────────────
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'fittrack_alerts', 'FitTrack Alerts',
        channelDescription: 'Workout completion and goal alerts',
        importance: Importance.defaultImportance,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }

  // ── Helper: next TZDateTime for a given weekday + time ───────────────────────
  tz.TZDateTime _nextInstanceOfDayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Advance to the correct weekday, and ensure it's in the future
    while (scheduled.weekday != weekday ||
        scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
