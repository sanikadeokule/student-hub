import 'package:cloud_firestore/cloud_firestore.dart';

class StudySessionModel {
  final String id;
  final int durationSeconds;
  final Timestamp createdAt;
  final String? subjectId; // which subject this session was for

  const StudySessionModel({
    required this.id,
    required this.durationSeconds,
    required this.createdAt,
    this.subjectId,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  DateTime get date => createdAt.toDate();

  factory StudySessionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudySessionModel(
      id: documentId,
      durationSeconds: map['durationSeconds'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      subjectId: map['subjectId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'durationSeconds': durationSeconds,
      'createdAt': createdAt,
      'subjectId': subjectId,
    };
  }

  bool isToday() {
    final now = DateTime.now();
    final sessionDate = date;
    return sessionDate.year == now.year &&
        sessionDate.month == now.month &&
        sessionDate.day == now.day;
  }
}
