import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📚 Subject Model — represents a subject/category for organizing content
class SubjectModel {
  final String id; // Firestore document ID
  final String name;
  final String description;
  final String color; // Hex color code
  final Timestamp createdAt;
  final String userId; // Owner of the subject

  const SubjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.userId,
  });

  /// 🏭 Create a SubjectModel from Firestore document data
  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubjectModel(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#5C6BC0',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      userId: map['userId'] ?? '',
    );
  }

  /// 🗺️ Convert SubjectModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  /// 🎨 Copy with modifications
  SubjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    Timestamp? createdAt,
    String? userId,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  /// 🎨 Get Color object from hex string
  Color getColor() {
    String hex = color.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha if not present
    }
    return Color(int.parse(hex, radix: 16));
  }
}