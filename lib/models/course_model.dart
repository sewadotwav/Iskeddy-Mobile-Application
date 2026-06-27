import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_enums.dart';
import 'meeting_time_model.dart';

class Course {
  final String id;
  final String title;
  final String colorHex;
  final String? notes;
  final List<MeetingTime> meetingTimes; 
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? maxAbsences;
  final int absenceCount;
  final int lateCount;

  const Course({
    required this.id,
    required this.title,
    required this.colorHex,
    this.notes,
    required this.meetingTimes,
    required this.createdAt,
    required this.updatedAt,
    this.maxAbsences,
    this.absenceCount = 0,
    this.lateCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'colorHex': colorHex,
      'notes': notes,
      'meetingTimes': meetingTimes.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'maxAbsences': maxAbsences,
      'absenceCount': absenceCount,
      'lateCount': lateCount,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    // Fallbacks for older courses that have classMode and courseType at the root
    final ClassMode? rootClassMode = map['classMode'] != null ? ClassModeLabel.fromValue(map['classMode']) : null;
    final CourseType? rootCourseType = map.containsKey('courseType') ? CourseTypeLabel.fromValue(map['courseType']) : null;
    final String? rootInstructor = map['instructor'] as String?;
    final String? rootRoomNo = map['roomNo'] as String?;

    return Course(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      colorHex: map['colorHex'] ?? '#F9E9D0',
      notes: map['notes'],
      meetingTimes: (map['meetingTimes'] as List<dynamic>? ?? [])
          .map((m) => MeetingTime.fromMap(
                m as Map<String, dynamic>,
                fallbackClassMode: rootClassMode,
                fallbackCourseType: rootCourseType,
                fallbackInstructor: rootInstructor,
                fallbackRoomNo: rootRoomNo,
              ))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxAbsences: map['maxAbsences'] as int?,
      absenceCount: (map['absenceCount'] as int?) ?? 0,
      lateCount: (map['lateCount'] as int?) ?? 0,
    );
  }

  Course copyWith({
    String? title,
    String? colorHex,
    String? notes,
    List<MeetingTime>? meetingTimes,
    DateTime? updatedAt,
    int? maxAbsences,
    int? absenceCount,
    int? lateCount,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      meetingTimes: meetingTimes ?? this.meetingTimes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      maxAbsences: maxAbsences ?? this.maxAbsences,
      absenceCount: absenceCount ?? this.absenceCount,
      lateCount: lateCount ?? this.lateCount,
    );
  }
}