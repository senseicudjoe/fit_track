import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String goalId;
  final String uid;
  final String type;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String period; // 'daily' | 'weekly'
  final DateTime createdAt;

  const GoalModel({
    required this.goalId,
    required this.uid,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.period,
    required this.createdAt,
  });

  double get progressPercent =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => currentValue >= targetValue;

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GoalModel(
      goalId:       doc.id,
      uid:          d['uid'] as String,
      type:         d['type'] as String,
      targetValue:  (d['targetValue'] as num).toDouble(),
      currentValue: (d['currentValue'] as num).toDouble(),
      unit:         d['unit'] as String,
      period:       d['period'] as String,
      createdAt:    (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid':          uid,
    'type':         type,
    'targetValue':  targetValue,
    'currentValue': currentValue,
    'unit':         unit,
    'period':       period,
    'createdAt':    Timestamp.fromDate(createdAt),
  };

  GoalModel copyWith({
    double? targetValue,
    double? currentValue,
    String? period,
  }) => GoalModel(
    goalId:       goalId,
    uid:          uid,
    type:         type,
    targetValue:  targetValue  ?? this.targetValue,
    currentValue: currentValue ?? this.currentValue,
    unit:         unit,
    period:       period       ?? this.period,
    createdAt:    createdAt,
  );
}

// Supported goal types
class GoalType {
  GoalType._();
  static const steps          = 'Daily steps';
  static const calories       = 'Calorie burn';
  static const activeMinutes  = 'Active minutes';
  static const weeklyWorkouts = 'Weekly workouts';
  static const distanceKm     = 'Distance (km)';

  static const all = [
    steps, calories, activeMinutes, weeklyWorkouts, distanceKm,
  ];

  static String unitFor(String type) {
    switch (type) {
      case steps:          return 'steps';
      case calories:       return 'kcal';
      case activeMinutes:  return 'min';
      case weeklyWorkouts: return 'sessions';
      case distanceKm:     return 'km';
      default:             return '';
    }
  }
}