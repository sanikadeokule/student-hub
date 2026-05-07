import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alarm_model.dart';

class AlarmService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('alarms');

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<AlarmModel>> getAlarms() {
    if (_userId == null) return Stream.value([]);
    return _col
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AlarmModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      // Upcoming first, then past (by dateTime ascending)
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return list;
    });
  }

  Future<void> addAlarm({required String name, required DateTime dateTime}) async {
    if (_userId == null) throw Exception('Not authenticated');
    await _col.add({
      ...AlarmModel(
        id: '',
        name: name,
        dateTime: dateTime,
        isActive: true,
        hasFired: false,
      ).toMap(),
      'userId': _userId,
    });
  }

  Future<void> updateAlarm(String id, {
    DateTime? dateTime,
    bool? isActive,
    bool? hasFired,
  }) async {
    final updates = <String, dynamic>{};
    if (dateTime != null) updates['dateTime'] = Timestamp.fromDate(dateTime);
    if (isActive != null) updates['isActive'] = isActive;
    if (hasFired != null) updates['hasFired'] = hasFired;
    if (updates.isEmpty) return;
    await _col.doc(id).update(updates);
  }

  Future<void> deleteAlarm(String id) async {
    await _col.doc(id).delete();
  }
}
