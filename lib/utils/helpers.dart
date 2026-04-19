import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  // ── Date formatting ───────────────────────────────────────────────────────────
  static String formatDate(DateTime d) =>
      DateFormat('MMM d, yyyy').format(d);

  static String formatTime(DateTime d) =>
      DateFormat('HH:mm').format(d);

  static String formatDateTime(DateTime d) =>
      DateFormat('MMM d, yyyy · HH:mm').format(d);

  static String relativeDate(DateTime d) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target    = DateTime(d.year, d.month, d.day);

    if (target == today)     return 'Today';
    if (target == yesterday) return 'Yesterday';

    final diff = today.difference(target).inDays;
    if (diff < 7) return '$diff days ago';

    return DateFormat('MMM d').format(d);
  }

  static String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ── Duration formatting ───────────────────────────────────────────────────────
  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatDurationFromSeconds(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Calorie estimation ────────────────────────────────────────────────────────
  // MET-based estimate (MET × weight × time in hours)
  static double estimateCalories({
    required String workoutType,
    required int durationMin,
    required double weightKg,
  }) {
    const metValues = {
      'Running':  9.8,
      'Cycling':  7.5,
      'Walking':  3.5,
      'HIIT':     8.0,
      'Strength': 5.0,
      'Yoga':     3.0,
      'Swimming': 7.0,
      'Other':    5.0,
    };
    final met   = metValues[workoutType] ?? 5.0;
    final hours = durationMin / 60;
    return (met * weightKg * hours).roundToDouble();
  }

  // ── Pace calculation ──────────────────────────────────────────────────────────
  static String calculatePace(int durationMin, double distanceKm) {
    if (distanceKm == 0) return '—';
    final secPerKm = (durationMin * 60) / distanceKm;
    final m = (secPerKm ~/ 60).toString();
    final s = (secPerKm % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$s /km';
  }

  // ── Number formatting ─────────────────────────────────────────────────────────
  static String formatNumber(num value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  static String formatCalories(double kcal) =>
      '${kcal.toStringAsFixed(0)} kcal';

  static String formatDistance(double km) =>
      km < 1 ? '${(km * 1000).toStringAsFixed(0)}m' : '${km.toStringAsFixed(2)}km';

  // ── Greeting ──────────────────────────────────────────────────────────────────
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Goal progress label ───────────────────────────────────────────────────────
  static String progressLabel(double current, double target, String unit) {
    return '${current.toStringAsFixed(0)} / '
        '${target.toStringAsFixed(0)} $unit';
  }

  // ── Week range ────────────────────────────────────────────────────────────────
  static List<DateTime> currentWeekDays() {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  // ── Initials from display name ────────────────────────────────────────────────
  static String initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}