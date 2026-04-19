import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import '../models/workout_model.dart';

class WorkoutProvider extends ChangeNotifier {
  final _firestore = FirestoreService.instance;
  final _db        = DatabaseService.instance;
  final _uuid      = const Uuid();

  List<WorkoutModel> _workouts = [];
  bool _loading = false;
  String? _error;
  String? _currentUid;
  StreamSubscription<List<WorkoutModel>>? _sub;

  List<WorkoutModel> get workouts => _workouts;
  bool get loading               => _loading;
  String? get error              => _error;

  WorkoutModel? get lastWorkout =>
      _workouts.isNotEmpty ? _workouts.first : null;

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

  // ── Subscribe to live workout stream ──────────────────────────────────────────
  void subscribe(String uid) {
    if (_currentUid == uid && _sub != null) return;

    _currentUid = uid;
    _setLoading(true);
    _sub?.cancel();
    _sub = _firestore.workoutsStream(uid).listen(
          (list) {
        _workouts = list;
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
    _workouts = [];
    _loading = false;
  }

  // ── Log a new workout ─────────────────────────────────────────────────────────
  Future<bool> logWorkout({
    required String uid,
    required String type,
    required int durationMin,
    required double caloriesBurned,
    required double distanceKm,
    int? sets,
    int? reps,
    String notes = '',
    List<int> timerSplits = const [],
  }) async {
    _setLoading(true);
    try {
      final workout = WorkoutModel(
        workoutId:      _uuid.v4(),
        uid:            uid,
        type:           type,
        durationMin:    durationMin,
        caloriesBurned: caloriesBurned,
        distanceKm:     distanceKm,
        sets:           sets,
        reps:           reps,
        notes:          notes,
        timerSplits:    timerSplits,
        loggedAt:       DateTime.now(),
      );
      await _firestore.saveWorkout(workout);
      await _db.clearDraft(uid);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteWorkout(String uid, String workoutId) async {
    await _firestore.deleteWorkout(uid, workoutId);
  }

  Future<WorkoutModel?> fetchWorkout(String uid, String workoutId) async {
    return _firestore.fetchWorkout(uid, workoutId);
  }

  Future<void> saveDraft(String uid, Map<String, dynamic> form) async {
    await _db.saveDraft({...form, 'uid': uid,
      'updated_at': DateTime.now().toIso8601String()});
  }

  Future<Map<String, dynamic>?> loadDraft(String uid) async {
    return _db.getDraft(uid);
  }

  Future<void> clearDraft(String uid) async {
    await _db.clearDraft(uid);
  }

  int get weeklyWorkoutCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _workouts.where((w) => w.loggedAt.isAfter(cutoff)).length;
  }

  double get totalCaloriesThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _workouts
        .where((w) => w.loggedAt.isAfter(cutoff))
        .fold(0.0, (sum, w) => sum + w.caloriesBurned);
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
