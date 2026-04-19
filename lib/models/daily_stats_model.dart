import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStatsModel {
  final String date;        // 'YYYY-MM-DD' — also the document ID
  final String uid;
  final int steps;
  final double caloriesBurned;
  final int activeMinutes;
  final double distanceKm;
  final int workoutCount;
  final List<String> goalsMet;
  final DateTime updatedAt;

  const DailyStatsModel({
    required this.date,
    required this.uid,
    required this.steps,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.distanceKm,
    required this.workoutCount,
    required this.goalsMet,
    required this.updatedAt,
  });

  factory DailyStatsModel.empty(String uid, DateTime day) {
    final date =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return DailyStatsModel(
      date:           date,
      uid:            uid,
      steps:          0,
      caloriesBurned: 0,
      activeMinutes:  0,
      distanceKm:     0.0,
      workoutCount:   0,
      goalsMet:       [],
      updatedAt:      day,
    );
  }

  factory DailyStatsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DailyStatsModel(
      date:           doc.id,
      uid:            d['uid'] as String,
      steps:          d['steps'] as int,
      caloriesBurned: (d['caloriesBurned'] as num).toDouble(),
      activeMinutes:  d['activeMinutes'] as int,
      distanceKm:     (d['distanceKm'] as num? ?? 0).toDouble(),
      workoutCount:   d['workoutCount'] as int,
      goalsMet:       List<String>.from(d['goalsMet'] ?? []),
      updatedAt:      (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid':            uid,
    'steps':          steps,
    'caloriesBurned': caloriesBurned,
    'activeMinutes':  activeMinutes,
    'distanceKm':     distanceKm,
    'workoutCount':   workoutCount,
    'goalsMet':       goalsMet,
    'updatedAt':      Timestamp.fromDate(updatedAt),
  };

  DailyStatsModel copyWith({
    int? steps,
    double? caloriesBurned,
    int? activeMinutes,
    double? distanceKm,
    int? workoutCount,
    List<String>? goalsMet,
    DateTime? updatedAt,
  }) => DailyStatsModel(
    date:           date,
    uid:            uid,
    steps:          steps          ?? this.steps,
    caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    activeMinutes:  activeMinutes  ?? this.activeMinutes,
    distanceKm:     distanceKm     ?? this.distanceKm,
    workoutCount:   workoutCount   ?? this.workoutCount,
    goalsMet:       goalsMet       ?? this.goalsMet,
    updatedAt:      updatedAt      ?? this.updatedAt,
  );
}
