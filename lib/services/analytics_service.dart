import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_session_model.dart';
import '../models/task_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _taskCollection = 'tasks';
  static const String _studyCollection = 'study_sessions';

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<StudySessionModel>> getStudySessionsStream() {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection(_studyCollection)
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudySessionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<StudySessionModel>> getStudySessionsForLastDays(int days) {
    if (_userId == null) return Stream.value([]);
    final now = DateTime.now();
    final startDate =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return _firestore
        .collection(_studyCollection)
        .where('userId', isEqualTo: _userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudySessionModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> logStudySession(Duration duration, {String? subjectId}) async {
    if (duration.inSeconds < 10) return;
    if (_userId == null) return;

    final session = StudySessionModel(
      id: '',
      durationSeconds: duration.inSeconds,
      createdAt: Timestamp.now(),
      subjectId: subjectId,
    );

    await _firestore
        .collection(_studyCollection)
        .add({...session.toMap(), 'userId': _userId});
  }

  Stream<int> getTodayStudyTimeSeconds() {
    if (_userId == null) return Stream.value(0);
    final now = DateTime.now();
    final dayStart =
        Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final dayEnd = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 23, 59, 59));
    return _firestore
        .collection(_studyCollection)
        .where('userId', isEqualTo: _userId)
        .where('createdAt', isGreaterThanOrEqualTo: dayStart)
        .where('createdAt', isLessThanOrEqualTo: dayEnd)
        .snapshots()
        .map((s) => s.docs.fold<int>(0, (acc, d) {
              final model = StudySessionModel.fromMap(d.data(), d.id);
              return acc + model.durationSeconds;
            }));
  }

  Stream<int> getLast7DaysStudyTimeSeconds() {
    if (_userId == null) return Stream.value(0);
    final now = DateTime.now();
    final startDate =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    return _firestore
        .collection(_studyCollection)
        .where('userId', isEqualTo: _userId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .snapshots()
        .map((s) => s.docs.fold<int>(0, (acc, d) {
              final model = StudySessionModel.fromMap(d.data(), d.id);
              return acc + model.durationSeconds;
            }));
  }

  Stream<int> getTotalCompletedTasksCount() {
    if (_userId == null) return Stream.value(0);
    return _firestore
        .collection(_taskCollection)
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> getTasksCompletedTodayCount() {
    if (_userId == null) return Stream.value(0);
    final now = DateTime.now();
    final dayStart =
        Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final dayEnd = Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 23, 59, 59));
    return _firestore
        .collection(_taskCollection)
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: true)
        .where('completedAt', isGreaterThanOrEqualTo: dayStart)
        .where('completedAt', isLessThanOrEqualTo: dayEnd)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> getPendingTasksCount() {
    if (_userId == null) return Stream.value(0);
    return _firestore
        .collection(_taskCollection)
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<int> calculateStudyStreak({int lookbackDays = 30}) async {
    if (_userId == null) return 0;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: lookbackDays - 1));
    final startTimestamp = Timestamp.fromDate(startDate);

    final sessionsSnap = await _firestore
        .collection(_studyCollection)
        .where('userId', isEqualTo: _userId)
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .get();

    final completedSnap = await _firestore
        .collection(_taskCollection)
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: true)
        .where('completedAt', isGreaterThanOrEqualTo: startTimestamp)
        .get();

    final activeDays = <DateTime>{};

    for (final doc in sessionsSnap.docs) {
      final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
      activeDays
          .add(DateTime(createdAt.year, createdAt.month, createdAt.day));
    }
    for (final doc in completedSnap.docs) {
      final completedAt = (doc.data()['completedAt'] as Timestamp).toDate();
      activeDays.add(
          DateTime(completedAt.year, completedAt.month, completedAt.day));
    }

    var streak = 0;
    for (var dayOffset = 0; dayOffset < lookbackDays; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: dayOffset));
      if (activeDays.contains(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Stream<List<TaskModel>> getCompletedTasksForChart() {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection(_taskCollection)
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<TaskModel>> getPendingTasksForChart() {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection(_taskCollection)
        .where('userId', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => TaskModel.fromMap(d.data(), d.id)).toList());
  }
}
