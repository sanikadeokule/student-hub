import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';

/// 📝 Note Service — handles CRUD operations for notes
class NoteService {
  final CollectionReference _notesCollection =
      FirebaseFirestore.instance.collection('notes');

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// ➕ Create a new note
  Future<String> createNote({
    required String text,
    String? subjectId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final docRef = await _notesCollection.add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'subjectId': subjectId,
      'userId': _userId, // Add userId for security
    });

    return docRef.id;
  }

  /// 📖 Get all notes for current user
  Stream<List<NoteModel>> getNotes({String? subjectId}) {
    if (_userId == null) return Stream.value([]);

    Query query = _notesCollection.where('userId', isEqualTo: _userId);

    if (subjectId != null) {
      query = query.where('subjectId', isEqualTo: subjectId);
    }

    return query
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// 📝 Update a note
  Future<void> updateNote(String noteId, {
    String? text,
    String? subjectId,
    bool? isPinned,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (text != null) updates['text'] = text;
    if (subjectId != null) updates['subjectId'] = subjectId;
    if (isPinned != null) updates['isPinned'] = isPinned;

    await _notesCollection.doc(noteId).update(updates);
  }

  /// ❌ Delete a note
  Future<void> deleteNote(String noteId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _notesCollection.doc(noteId).delete();
  }

  /// 🔍 Get a single note by ID
  Future<NoteModel?> getNote(String noteId) async {
    if (_userId == null) return null;

    final doc = await _notesCollection.doc(noteId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != _userId) return null; // Security check

    return NoteModel.fromMap(data, doc.id);
  }
}