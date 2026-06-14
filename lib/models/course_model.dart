import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_enums.dart';
import 'meeting_time_model.dart';

/// Represents a single course/subject within a schedule.
class Course {
  final String id;
  final String title;
  final String colorHex;
  final ClassMode classMode;
  final CourseType? courseType; // nullable — "None" is allowed
  final String? instructor;
  final String? roomNo;
  final List<MeetingTime> meetingTimes; // can be empty for async courses
  final DateTime createdAt;
  final DateTime updatedAt;

  const Course({
    required this.id,
    required this.title,
    required this.colorHex,
    required this.classMode,
    this.courseType,
    this.instructor,
    this.roomNo,
    required this.meetingTimes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'colorHex': colorHex,
      'classMode': classMode.value,
      'courseType': courseType?.label, // null if "None"
      'instructor': instructor,
      'roomNo': roomNo,
      'meetingTimes': meetingTimes.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      colorHex: map['colorHex'] ?? '#F9E9D0',
      classMode: ClassModeLabel.fromValue(map['classMode'] ?? 'onsite'),
      courseType: CourseTypeLabel.fromValue(map['courseType']),
      instructor: map['instructor'],
      roomNo: map['roomNo'],
      meetingTimes: (map['meetingTimes'] as List<dynamic>? ?? [])
          .map((m) => MeetingTime.fromMap(m as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Course copyWith({
    String? title,
    String? colorHex,
    ClassMode? classMode,
    CourseType? courseType,
    String? instructor,
    String? roomNo,
    List<MeetingTime>? meetingTimes,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      colorHex: colorHex ?? this.colorHex,
      classMode: classMode ?? this.classMode,
      courseType: courseType ?? this.courseType,
      instructor: instructor ?? this.instructor,
      roomNo: roomNo ?? this.roomNo,
      meetingTimes: meetingTimes ?? this.meetingTimes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}