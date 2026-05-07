import 'package:cloud_firestore/cloud_firestore.dart';

class AlarmModel {
  final String id;
  final String name;
  final DateTime dateTime;
  final bool isActive;
  final bool hasFired;

  const AlarmModel({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.isActive,
    required this.hasFired,
  });

  factory AlarmModel.fromMap(Map<String, dynamic> map, String id) {
    return AlarmModel(
      id: id,
      name: map['name'] ?? 'Alarm',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      hasFired: map['hasFired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'dateTime': Timestamp.fromDate(dateTime),
        'isActive': isActive,
        'hasFired': hasFired,
      };

  AlarmModel copyWith({
    String? id,
    String? name,
    DateTime? dateTime,
    bool? isActive,
    bool? hasFired,
  }) =>
      AlarmModel(
        id: id ?? this.id,
        name: name ?? this.name,
        dateTime: dateTime ?? this.dateTime,
        isActive: isActive ?? this.isActive,
        hasFired: hasFired ?? this.hasFired,
      );
}
