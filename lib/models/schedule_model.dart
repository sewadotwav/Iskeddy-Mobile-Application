import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String name;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Schedule({
    required this.id,
    required this.name,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled Schedule',
      isPinned: map['isPinned'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  
  Schedule copyWith({
    String? name,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id,
      name: name ?? this.name,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}