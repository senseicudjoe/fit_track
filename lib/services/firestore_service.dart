import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../models/goal_model.dart';
import '../models/daily_stats_model.dart';
import '../models/reminder_model.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Helpers ──────────────────────────────────────────────────────────────────
  CollectionReference _workouts(String uid) =>
      _db.collection('users').doc(uid).collection('workouts');

  CollectionReference _goals(String uid) =>
      _db.collection('users').doc(uid).collection('goals');

  CollectionReference _stats(String uid) =>
      _db.collection('users').doc(uid).collection('dailyStats');

  CollectionReference _reminders(String uid) =>
      _db.collection('users').doc(uid).collection('reminders');

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  // ── Workouts ─────────────────────────────────────────────────────────────────
  Future<void> saveWorkout(WorkoutModel w) async {
    await _workouts(w.uid).doc(w.workoutId).set(w.toMap());
  }

  Future<void> deleteWorkout(String uid, String workoutId) async {
    await _workouts(uid).doc(workoutId).delete();
  }

  Stream<List<WorkoutModel>> workoutsStream(String uid, {int limit = 20}) {
    return _workouts(uid)
        .orderBy('loggedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(WorkoutModel.fromFirestore).toList());
  }

  Future<WorkoutModel?> fetchWorkout(String uid, String workoutId) async {
    final doc = await _workouts(uid).doc(workoutId).get();
    if (!doc.exists) return null;
    return WorkoutModel.fromFirestore(doc);
  }

  // ── Goals ────────────────────────────────────────────────────────────────────
  Future<void> saveGoal(GoalModel g) async {
    await _goals(g.uid).doc(g.goalId).set(g.toMap());
  }

  Future<void> updateGoalProgress(
      String uid, String goalId, double currentValue) async {
    await _goals(uid).doc(goalId).update({'currentValue': currentValue});
  }

  Future<void> deleteGoal(String uid, String goalId) async {
    await _goals(uid).doc(goalId).delete();
  }

  Stream<List<GoalModel>> goalsStream(String uid) {
    return _goals(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(GoalModel.fromFirestore).toList());
  }

  // ── Daily stats ──────────────────────────────────────────────────────────────
  Future<DailyStatsModel> fetchTodayStats(String uid) async {
    final key = _todayKey();
    final doc = await _stats(uid).doc(key).get();
    if (!doc.exists) {
      final empty = DailyStatsModel.empty(uid, DateTime.now());
      await _stats(uid).doc(key).set(empty.toMap());
      return empty;
    }
    return DailyStatsModel.fromFirestore(doc);
  }

  Future<void> updateTodayStats(DailyStatsModel stats) async {
    await _stats(stats.uid)
        .doc(stats.date)
        .set(stats.toMap(), SetOptions(merge: true));
  }

  Future<List<DailyStatsModel>> fetchStatRange(
      String uid, DateTime from, DateTime to) async {
    final fromKey =
        '${from.year}-${from.month.toString().padLeft(2,'0')}-${from.day.toString().padLeft(2,'0')}';
    final toKey =
        '${to.year}-${to.month.toString().padLeft(2,'0')}-${to.day.toString().padLeft(2,'0')}';

    final snap = await _stats(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: fromKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: toKey)
        .orderBy(FieldPath.documentId)
        .get();

    return snap.docs.map(DailyStatsModel.fromFirestore).toList();
  }

  // ── Reminders ────────────────────────────────────────────────────────────────
  Future<void> saveReminder(ReminderModel r) async {
    await _reminders(r.uid).doc(r.reminderId).set(r.toMap());
  }

  Future<void> toggleReminder(
      String uid, String reminderId, bool isActive) async {
    await _reminders(uid).doc(reminderId).update({'isActive': isActive});
  }

  Future<void> deleteReminder(String uid, String reminderId) async {
    await _reminders(uid).doc(reminderId).delete();
  }

  Stream<List<ReminderModel>> remindersStream(String uid) {
    return _reminders(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ReminderModel.fromFirestore).toList());
  }
}