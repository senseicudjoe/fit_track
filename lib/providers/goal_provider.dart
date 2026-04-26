import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  final _firestore = FirestoreService.instance;
  final _uuid      = const Uuid();

  List<GoalModel> _goals = [];
  bool _loading = false;
  String? _error;
  String? _currentUid;
  StreamSubscription<List<GoalModel>>? _sub;

  List<GoalModel> get goals   => _goals;
  bool get loading            => _loading;
  String? get error           => _error;

  List<GoalModel> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();

  List<GoalModel> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();

  // Helper to get a specific goal value
  double getGoalValue(String type, {double fallback = 0}) {
    final goal = _goals.cast<GoalModel?>().firstWhere(
      (g) => g?.type == type,
      orElse: () => null,
    );
    return goal?.targetValue ?? fallback;
  }

  // ── Auto-update from ProxyProvider ──────────────────────────────────────────
  void update(String? uid) {
    if (uid == null) {
      unsubscribe();
      return;
    }
    if (_currentUid != uid) {
      subscribe(uid);
    }
  }

  // ── Subscribe ──────────────────────────────────────────────────────────────────
  void subscribe(String uid) {
    if (_currentUid == uid && _sub != null) return;

    _currentUid = uid;
    _setLoading(true);
    _sub?.cancel();
    _sub = _firestore.goalsStream(uid).listen(
          (list) {
        _goals = list;
        _setLoading(false);
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
      },
    );
  }

  void unsubscribe() {
    _sub?.cancel();
    _sub = null;
    _currentUid = null;
    _goals = [];
    _loading = false;
  }

  // ── Add goal ──────────────────────────────────────────────────────────────────
  Future<bool> addGoal({
    required String uid,
    required String type,
    required double targetValue,
    required String period,
  }) async {
    _setLoading(true);
    try {
      final goal = GoalModel(
        goalId:       _uuid.v4(),
        uid:          uid,
        type:         type,
        targetValue:  targetValue,
        currentValue: 0,
        unit:         GoalType.unitFor(type),
        period:       period,
        createdAt:    DateTime.now(),
      );
      await _firestore.saveGoal(goal).timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint('Goal save queued offline'),
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Initialize Default Goals ─────────────────────────────────────────────────
  Future<void> createDefaultGoals(String uid, String activityLevel) async {
    final targets = _calculateDefaultTargets(activityLevel);

    await addGoal(uid: uid, type: GoalType.steps, targetValue: targets[GoalType.steps]!, period: 'daily');
    await addGoal(uid: uid, type: GoalType.calories, targetValue: targets[GoalType.calories]!, period: 'daily');
    await addGoal(uid: uid, type: GoalType.activeMinutes, targetValue: 30.0, period: 'daily');
  }

  // ── Update Default Goals Based on Activity Level ─────────────────────────────
  Future<void> updateGoalsForActivityLevel(String uid, String activityLevel) async {
    final targets = _calculateDefaultTargets(activityLevel);
    
    for (final type in [GoalType.steps, GoalType.calories]) {
      final existingGoal = _goals.cast<GoalModel?>().firstWhere(
        (g) => g?.type == type && g?.period == 'daily',
        orElse: () => null,
      );

      if (existingGoal != null) {
        // Update existing goal target with timeout
        await _firestore.saveGoal(existingGoal.copyWith(
          targetValue: targets[type]!,
        )).timeout(
          const Duration(seconds: 2),
          onTimeout: () => debugPrint('Goal update queued offline'),
        );
      } else {
        // Create it if it somehow doesn't exist
        await addGoal(uid: uid, type: type, targetValue: targets[type]!, period: 'daily');
      }
    }
  }

  Map<String, double> _calculateDefaultTargets(String activityLevel) {
    final stepTarget = switch (activityLevel) {
      'Sedentary'         => 5000.0,
      'Lightly active'    => 7500.0,
      'Moderately active' => 10000.0,
      'Very active'       => 12500.0,
      'Athlete'           => 15000.0,
      _                   => 10000.0,
    };

    final calorieTarget = switch (activityLevel) {
      'Sedentary'         => 200.0,
      'Lightly active'    => 400.0,
      'Moderately active' => 600.0,
      'Very active'       => 800.0,
      'Athlete'           => 1000.0,
      _                   => 600.0,
    };

    return {
      GoalType.steps: stepTarget,
      GoalType.calories: calorieTarget,
    };
  }

  // ── Update goal progress ──────────────────────────────────────────────────────
  Future<void> updateProgress(
      String uid, String goalId, double currentValue) async {
    // Non-blocking for offline
    await _firestore.updateGoalProgress(uid, goalId, currentValue).timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('Progress update queued offline'),
    );
  }

  // ── Sync progress from today's stats ──────────────────────────────────────────
  Future<void> syncFromStats({
    required String uid,
    required int steps,
    required double calories,
    required int activeMinutes,
    required int weeklyWorkouts,
    required double distanceKm,
  }) async {
    for (final goal in _goals) {
      final value = switch (goal.type) {
        GoalType.steps          => steps.toDouble(),
        GoalType.calories       => calories,
        GoalType.activeMinutes  => activeMinutes.toDouble(),
        GoalType.weeklyWorkouts => weeklyWorkouts.toDouble(),
        GoalType.distanceKm     => distanceKm,
        _                       => goal.currentValue,
      };
      if (value != goal.currentValue) {
        await updateProgress(uid, goal.goalId, value);
      }
    }
  }

  // ── Delete goal ───────────────────────────────────────────────────────────────
  Future<void> deleteGoal(String uid, String goalId) async {
    await _firestore.deleteGoal(uid, goalId).timeout(
      const Duration(seconds: 2),
      onTimeout: () => debugPrint('Goal delete queued offline'),
    );
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
