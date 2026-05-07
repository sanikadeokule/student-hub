import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject_model.dart';

/// 📚 Subject Service — handles CRUD operations for subjects
class SubjectService {
  final CollectionReference _subjectsCollection =
      FirebaseFirestore.instance.collection('subjects');

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// ➕ Create a new subject
  Future<String> createSubject({
    required String name,
    required String description,
    required String color,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final docRef = await _subjectsCollection.add({
      'name': name,
      'description': description,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _userId,
    });

    return docRef.id;
  }

  /// 📖 Get all subjects for current user
  Stream<List<SubjectModel>> getSubjects() {
    if (_userId == null) return Stream.value([]);

    return _subjectsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// 📝 Update a subject
  Future<void> updateSubject(String subjectId, {
    String? name,
    String? description,
    String? color,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (color != null) updates['color'] = color;

    await _subjectsCollection.doc(subjectId).update(updates);
  }

  /// ❌ Delete a subject
  Future<void> deleteSubject(String subjectId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _subjectsCollection.doc(subjectId).delete();
  }

  /// 🔍 Get a single subject by ID
  Future<SubjectModel?> getSubject(String subjectId) async {
    if (_userId == null) return null;

    final doc = await _subjectsCollection.doc(subjectId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != _userId) return null; // Security check

    return SubjectModel.fromMap(data, doc.id);
  }
}