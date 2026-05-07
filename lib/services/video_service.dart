import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';

/// 🎥 Video Service — handles CRUD operations for saved videos
class VideoService {
  final CollectionReference _videosCollection =
      FirebaseFirestore.instance.collection('videos');

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// ➕ Save a new video
  Future<String> saveVideo({
    required String title,
    required String url,
    required String type, // 'youtube' or 'local'
    String? subjectId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final docRef = await _videosCollection.add({
      'title': title,
      'url': url,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'subjectId': subjectId,
      'userId': _userId, // Add userId for security
    });

    return docRef.id;
  }

  /// 📖 Get all videos for current user
  Stream<List<VideoModel>> getVideos({String? subjectId}) {
    if (_userId == null) return Stream.value([]);

    Query query = _videosCollection.where('userId', isEqualTo: _userId);

    if (subjectId != null) {
      query = query.where('subjectId', isEqualTo: subjectId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// 📝 Update a video
  Future<void> updateVideo(String videoId, {
    String? title,
    String? url,
    String? type,
    String? subjectId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (url != null) updates['url'] = url;
    if (type != null) updates['type'] = type;
    if (subjectId != null) updates['subjectId'] = subjectId;

    await _videosCollection.doc(videoId).update(updates);
  }

  /// ❌ Delete a video
  Future<void> deleteVideo(String videoId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _videosCollection.doc(videoId).delete();
  }

  /// 🔍 Get a single video by ID
  Future<VideoModel?> getVideo(String videoId) async {
    if (_userId == null) return null;

    final doc = await _videosCollection.doc(videoId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    if (data['userId'] != _userId) return null; // Security check

    return VideoModel.fromMap(data, doc.id);
  }
}