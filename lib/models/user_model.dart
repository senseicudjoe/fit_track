import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final int age;
  final double weightKg;
  final double heightCm;
  final String fitnessGoal;
  final String activityLevel;
  final bool isOnboarded;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.isOnboarded,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:           doc.id,
      displayName:   d['displayName'] as String,
      email:         d['email'] as String,
      age:           d['age'] as int,
      weightKg:      (d['weightKg'] as num).toDouble(),
      heightCm:      (d['heightCm'] as num).toDouble(),
      fitnessGoal:   d['fitnessGoal'] as String,
      activityLevel: d['activityLevel'] as String,
      isOnboarded:   d['isOnboarded'] as bool,
      createdAt:     (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid':           uid,
    'displayName':   displayName,
    'email':         email,
    'age':           age,
    'weightKg':      weightKg,
    'heightCm':      heightCm,
    'fitnessGoal':   fitnessGoal,
    'activityLevel': activityLevel,
    'isOnboarded':   isOnboarded,
    'createdAt':     Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({
    String? displayName,
    int? age,
    double? weightKg,
    double? heightCm,
    String? fitnessGoal,
    String? activityLevel,
    bool? isOnboarded,
  }) => UserModel(
    uid:           uid,
    displayName:   displayName   ?? this.displayName,
    email:         email,
    age:           age           ?? this.age,
    weightKg:      weightKg     ?? this.weightKg,
    heightCm:      heightCm     ?? this.heightCm,
    fitnessGoal:   fitnessGoal  ?? this.fitnessGoal,
    activityLevel: activityLevel ?? this.activityLevel,
    isOnboarded:   isOnboarded  ?? this.isOnboarded,
    createdAt:     createdAt,
  );
}