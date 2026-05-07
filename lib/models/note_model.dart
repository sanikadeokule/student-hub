import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String text;
  final Timestamp createdAt;
  final String? subjectId;
  final bool isPinned;

  const NoteModel({
    required this.id,
    required this.text,
    required this.createdAt,
    this.subjectId,
    this.isPinned = false,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NoteModel(
      id: documentId,
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      subjectId: map['subjectId'] as String?,
      isPinned: map['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': createdAt,
      'subjectId': subjectId,
      'isPinned': isPinned,
    };
  }

  NoteModel copyWith({
    String? id,
    String? text,
    Timestamp? createdAt,
    String? subjectId,
    bool? isPinned,
  }) {
    return NoteModel(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      subjectId: subjectId ?? this.subjectId,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
