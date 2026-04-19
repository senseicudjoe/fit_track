import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderModel {
  final String reminderId;
  final String uid;
  final String label;
  final String timeOfDay;   // 'HH:mm' e.g. '07:00'
  final List<int> repeatDays; // 0=Mon … 6=Sun (ISO weekday - 1)
  final bool isActive;
  final DateTime createdAt;

  const ReminderModel({
    required this.reminderId,
    required this.uid,
    required this.label,
    required this.timeOfDay,
    required this.repeatDays,
    required this.isActive,
    required this.createdAt,
  });

  // Derive a stable int ID for flutter_local_notifications
  int get notificationId => reminderId.hashCode.abs() % 100000;

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      reminderId: doc.id,
      uid:        d['uid'] as String,
      label:      d['label'] as String,
      timeOfDay:  d['timeOfDay'] as String,
      repeatDays: List<int>.from(d['repeatDays'] ?? []),
      isActive:   d['isActive'] as bool,
      createdAt:  (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid':        uid,
    'label':      label,
    'timeOfDay':  timeOfDay,
    'repeatDays': repeatDays,
    'isActive':   isActive,
    'createdAt':  Timestamp.fromDate(createdAt),
  };

  ReminderModel copyWith({
    String? label,
    String? timeOfDay,
    List<int>? repeatDays,
    bool? isActive,
  }) => ReminderModel(
    reminderId: reminderId,
    uid:        uid,
    label:      label       ?? this.label,
    timeOfDay:  timeOfDay   ?? this.timeOfDay,
    repeatDays: repeatDays  ?? this.repeatDays,
    isActive:   isActive    ?? this.isActive,
    createdAt:  createdAt,
  );

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get repeatLabel {
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.isEmpty)     return 'Once';
    if (repeatDays.toSet().containsAll({0, 1, 2, 3, 4}) &&
        repeatDays.length == 5) return 'Weekdays';
    return repeatDays.map((d) => dayNames[d]).join(', ');
  }
}