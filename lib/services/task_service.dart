import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

/// ☁️ Firestore Service for Task CRUD and real-time streams
class TaskService {
  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference name
  static const String _collection = 'tasks';

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// ➕ Add a new task to Firestore
  /// Returns the document ID of the newly created task
  Future<String> addTask(TaskModel task) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final taskData = task.toMap();
      taskData['userId'] = _userId; // Add userId for security
      final docRef = await _firestore.collection(_collection).add(taskData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add task: \$e');
    }
  }

  /// ✏️ Update an existing task by ID
  Future<void> updateTask(String taskId, TaskModel task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(taskId)
          .update(task.toMap());
    } catch (e) {
      throw Exception('Failed to update task: \$e');
    }
  }

  /// ✅ Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(taskId)
          .update({
            'isCompleted': !currentStatus,
            'completedAt': !currentStatus ? Timestamp.now() : null,
          });
    } catch (e) {
      throw Exception('Failed to toggle completion: \$e');
    }
  }

  /// 🗑️ Delete a task by ID
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: \$e');
    }
  }

  /// 📥 Stream of ALL tasks for the current user (real-time updates)
  Stream<List<TaskModel>> getTasksStream({String? subjectId}) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (subjectId != null) {
        tasks = tasks.where((t) => t.subjectId == subjectId).toList();
      }
      tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
      return tasks;
    });
  }

  /// 📅 Stream of tasks DUE TODAY (real-time)
  Stream<List<TaskModel>> getDueTodayTasks({String? subjectId}) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((t) =>
              !t.isCompleted &&
              !t.deadline.toDate().isBefore(startOfDay) &&
              !t.deadline.toDate().isAfter(endOfDay))
          .toList();
      if (subjectId != null) {
        tasks = tasks.where((t) => t.subjectId == subjectId).toList();
      }
      tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
      return tasks;
    });
  }

  /// 🔢 Stream of PENDING tasks count (for home screen)
  Stream<int> getPendingTasksCount({String? subjectId}) {
    if (_userId == null) return Stream.value(0);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((t) => !t.isCompleted);
      if (subjectId != null) {
        tasks = tasks.where((t) => t.subjectId == subjectId);
      }
      return tasks.length;
    });
  }

  /// 📋 Stream of PENDING tasks sorted by deadline (for home preview)
  Stream<List<TaskModel>> getPendingTasks({int limitCount = 3, String? subjectId}) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      var tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((t) => !t.isCompleted)
          .toList();
      if (subjectId != null) {
        tasks = tasks.where((t) => t.subjectId == subjectId).toList();
      }
      tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
      return tasks.take(limitCount).toList();
    });
  }
}

