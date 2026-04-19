import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutModel {
  final String workoutId;
  final String uid;
  final String type;
  final int durationMin;
  final double caloriesBurned;
  final double distanceKm;
  final int? sets;
  final int? reps;
  final String notes;
  final List<int> timerSplits; // seconds per round
  final DateTime loggedAt;

  const WorkoutModel({
    required this.workoutId,
    required this.uid,
    required this.type,
    required this.durationMin,
    required this.caloriesBurned,
    required this.distanceKm,
    this.sets,
    this.reps,
    required this.notes,
    required this.timerSplits,
    required this.loggedAt,
  });

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WorkoutModel(
      workoutId:      doc.id,
      uid:            d['uid'] as String,
      type:           d['type'] as String,
      durationMin:    d['durationMin'] as int,
      caloriesBurned: (d['caloriesBurned'] as num).toDouble(),
      distanceKm:     (d['distanceKm'] as num).toDouble(),
      sets:           d['sets'] as int?,
      reps:           d['reps'] as int?,
      notes:          d['notes'] as String? ?? '',
      timerSplits:    List<int>.from(d['timerSplits'] ?? []),
      loggedAt:       (d['loggedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid':            uid,
    'type':           type,
    'durationMin':    durationMin,
    'caloriesBurned': caloriesBurned,
    'distanceKm':     distanceKm,
    'sets':           sets,
    'reps':           reps,
    'notes':          notes,
    'timerSplits':    timerSplits,
    'loggedAt':       Timestamp.fromDate(loggedAt),
  };

  WorkoutModel copyWith({
    String? type,
    int? durationMin,
    double? caloriesBurned,
    double? distanceKm,
    int? sets,
    int? reps,
    String? notes,
    List<int>? timerSplits,
  }) => WorkoutModel(
    workoutId:      workoutId,
    uid:            uid,
    type:           type           ?? this.type,
    durationMin:    durationMin    ?? this.durationMin,
    caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    distanceKm:     distanceKm     ?? this.distanceKm,
    sets:           sets           ?? this.sets,
    reps:           reps           ?? this.reps,
    notes:          notes          ?? this.notes,
    timerSplits:    timerSplits    ?? this.timerSplits,
    loggedAt:       loggedAt,
  );
}

// Supported workout types
class WorkoutType {
  WorkoutType._();
  static const running   = 'Running';
  static const cycling   = 'Cycling';
  static const walking   = 'Walking';
  static const hiit      = 'HIIT';
  static const strength  = 'Strength';
  static const yoga      = 'Yoga';
  static const swimming  = 'Swimming';
  static const other     = 'Other';

  static const all = [
    running, cycling, walking, hiit, strength, yoga, swimming, other,
  ];
}