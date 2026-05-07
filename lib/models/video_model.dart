import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎥 Video Model — represents a saved video (YouTube or local) in Firestore
class VideoModel {
  final String id; // Firestore document ID
  final String title;
  final String url; // YouTube URL or local file path
  final String type; // 'youtube' or 'local'
  final Timestamp createdAt;
  final String? subjectId; // Link to subject

  const VideoModel({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    required this.createdAt,
    this.subjectId,
  });

  /// 🏭 Create a VideoModel from Firestore document data
  factory VideoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VideoModel(
      id: documentId,
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'youtube',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      subjectId: map['subjectId'] as String?,
    );
  }

  /// 🗺️ Convert VideoModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'type': type,
      'createdAt': createdAt,
      'subjectId': subjectId,
    };
  }

  /// 🎨 Copy with modifications
  VideoModel copyWith({
    String? id,
    String? title,
    String? url,
    String? type,
    Timestamp? createdAt,
    String? subjectId,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  /// 📺 Check if it's a YouTube video
  bool get isYouTube => type == 'youtube';

  /// 🎵 Check if it's a local video
  bool get isLocal => type == 'local';
}