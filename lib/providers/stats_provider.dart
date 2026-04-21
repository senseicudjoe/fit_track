import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import '../services/pedometer_service.dart';
import '../models/daily_stats_model.dart';
import 'goal_provider.dart';

class StatsProvider extends ChangeNotifier {
  final _firestore  = FirestoreService.instance;
  final _db         = DatabaseService.instance;
  final _pedometer  = PedometerService.instance;

  DailyStatsModel? _today;
  List<DailyStatsModel> _weekStats  = [];
  List<DailyStatsModel> _monthStats = [];

  int _liveSteps = 0;
  bool _loading  = false;
  Timer? _midnightTimer;
  Timer? _syncTimer;
  String? _initializedUid;

  GoalProvider? _goalProvider;

  DailyStatsModel? get today      => _today;
  List<DailyStatsModel> get weekStats  => _weekStats;
  List<DailyStatsModel> get monthStats => _monthStats;
  int get liveSteps               => _liveSteps;
  bool get loading                => _loading;

  double get stepProgress {
    if (_today == null) return 0;
    const defaultGoal = 10000;
    return (_liveSteps / defaultGoal).clamp(0.0, 1.0);
  }

  // ── Auto-update from ProxyProvider ──────────────────────────────────────────
  void update(String? uid, GoalProvider? goalProvider) {
    if (uid == null) {
      _initializedUid = null;
      _today = null;
      _liveSteps = 0;
      _pedometer.stop();
      _syncTimer?.cancel();
      _midnightTimer?.cancel();
      return;
    }
    if (_initializedUid != uid) {
      init(uid, goalProvider: goalProvider);
    } else {
      _goalProvider = goalProvider;
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────────────
  Future<void> init(String uid, {GoalProvider? goalProvider}) async {
    // Prevent redundant initialization for the same user
    if (_initializedUid == uid && !_loading && _today != null) return;

    _initializedUid = uid;
    _goalProvider = goalProvider;
    _setLoading(true);

    try {
      _today = await _firestore.fetchTodayStats(uid);
      _liveSteps = _today?.steps ?? 0;

      await _loadRange(uid);

      _pedometer.onStepUpdate = (steps) {
        _liveSteps = steps;
        _syncGoalsLocally(uid);
        notifyListeners();
      };
      // Pass the steps from Firestore as the initial baseline if the local cache is empty
      await _pedometer.start(uid, initialSteps: _today?.steps);

      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(
        const Duration(minutes: 5),
            (_) => _syncStepsToFirestore(uid),
      );

      _midnightTimer?.cancel();
      _scheduleMidnightReset(uid);
    } catch (e) {
      debugPrint('Error initializing StatsProvider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Update stats after a workout is logged ────────────────────────────────────
  Future<void> onWorkoutLogged({
    required String uid,
    required double calories,
    required int durationMin,
    double distanceKm = 0,
  }) async {
    if (_today == null) return;

    final updated = _today!.copyWith(
      caloriesBurned: _today!.caloriesBurned + calories,
      activeMinutes:  _today!.activeMinutes  + durationMin,
      distanceKm:     _today!.distanceKm     + distanceKm,
      workoutCount:   _today!.workoutCount   + 1,
      updatedAt:      DateTime.now(),
    );

    await _firestore.updateTodayStats(updated);
    _today = updated;

    await _syncGoalsLocally(uid);
    notifyListeners();
  }

  // ── Local sync to GoalProvider ────────────────────────────────────────────────
  Future<void> _syncGoalsLocally(String uid) async {
    if (_goalProvider == null || _today == null) return;

    await _goalProvider!.syncFromStats(
      uid: uid,
      steps: _liveSteps,
      calories: _today!.caloriesBurned,
      activeMinutes: _today!.activeMinutes,
      weeklyWorkouts: _calculateWeeklyWorkouts(),
      distanceKm: _today!.distanceKm,
    );
  }

  int _calculateWeeklyWorkouts() {
    final historical = _weekStats
        .where((s) => s.date != _today?.date)
        .fold(0, (sum, day) => sum + day.workoutCount);
    return historical + (_today?.workoutCount ?? 0);
  }

  // ── Flush SQLite step cache to Firestore ──────────────────────────────────────
  Future<void> _syncStepsToFirestore(String uid) async {
    final unsynced = await _db.getUnsyncedSteps(uid);
    for (final row in unsynced) {
      final date  = row['date'] as String;
      final steps = row['steps'] as int;

      if (_today != null && date == _today!.date) {
        final updated = _today!.copyWith(
          steps:     steps,
          updatedAt: DateTime.now(),
        );
        await _firestore.updateTodayStats(updated);
        _today = updated;
      }
      await _db.markSynced(uid, date);
    }
    await _syncGoalsLocally(uid);
    notifyListeners();
  }

  void _scheduleMidnightReset(String uid) {
    final now      = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = midnight.difference(now);

    _midnightTimer = Timer(untilMidnight, () async {
      _pedometer.resetForNewDay();
      _liveSteps = 0;
      _today = await _firestore.fetchTodayStats(uid);
      await _loadRange(uid);
      await _syncGoalsLocally(uid);
      notifyListeners();
      _scheduleMidnightReset(uid);
    });
  }

  Future<void> _loadRange(String uid) async {
    final now  = DateTime.now();
    final week = now.subtract(const Duration(days: 7));
    final month = now.subtract(const Duration(days: 30));

    _weekStats  = await _firestore.fetchStatRange(uid, week, now);
    _monthStats = await _firestore.fetchStatRange(uid, month, now);
    notifyListeners();
  }

  Future<void> refresh(String uid) async {
    _today = await _firestore.fetchTodayStats(uid);
    await _loadRange(uid);
    await _syncGoalsLocally(uid);
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _pedometer.stop();
    _syncTimer?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }
}
