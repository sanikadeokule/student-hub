import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { high, medium, low }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final Timestamp deadline;
  final TaskPriority priority;
  final bool isCompleted;
  final Timestamp createdAt;
  final Timestamp? completedAt;
  final String? subjectId;
  final String recurrence; // 'None', 'Daily', 'Weekly'

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.subjectId,
    this.recurrence = 'None',
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: map['deadline'] ?? Timestamp.now(),
      priority: _priorityFromString(map['priority'] ?? 'low'),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      completedAt: map['completedAt'] as Timestamp?,
      subjectId: map['subjectId'] as String?,
      recurrence: map['recurrence'] ?? 'None',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline,
      'priority': priority.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'subjectId': subjectId,
      'recurrence': recurrence,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    Timestamp? deadline,
    TaskPriority? priority,
    bool? isCompleted,
    Timestamp? createdAt,
    Timestamp? completedAt,
    String? subjectId,
    String? recurrence,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      subjectId: subjectId ?? this.subjectId,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  // Colours match the unified pastel palette in app_theme.dart
  static int getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 0xFFFF9AA2; // kCoral
      case TaskPriority.medium:
        return 0xFFFECF6A; // kAmber
      case TaskPriority.low:
        return 0xFF6ECFBF; // kMint
    }
  }

  static TaskPriority _priorityFromString(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  bool isDueToday() {
    final now = DateTime.now();
    final dl = deadline.toDate();
    return dl.year == now.year && dl.month == now.month && dl.day == now.day;
  }

  bool isOverdue() {
    if (isCompleted) return false;
    final now = DateTime.now();
    final dl = deadline.toDate();
    return dl.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool completedToday() {
    if (completedAt == null) return false;
    final now = DateTime.now();
    final completedDate = completedAt!.toDate();
    return completedDate.year == now.year &&
        completedDate.month == now.month &&
        completedDate.day == now.day;
  }
}
