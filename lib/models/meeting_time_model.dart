import '../constants/app_enums.dart';

class MeetingTime {
  final List<String> days; // e.g. ["Mon", "Wed", "Fri"]
  final String startTime;  // 24h format, e.g. "08:00"
  final String endTime;    // 24h format, e.g. "09:30"
  final ClassMode classMode;
  final CourseType? courseType;
  final String? instructor;
  final String? roomNo;

  const MeetingTime({
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.classMode,
    this.courseType,
    this.instructor,
    this.roomNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'startTime': startTime,
      'endTime': endTime,
      'classMode': classMode.value,
      'courseType': courseType?.label,
      if (instructor != null) 'instructor': instructor,
      if (roomNo != null) 'roomNo': roomNo,
    };
  }

  factory MeetingTime.fromMap(Map<String, dynamic> map, {
    ClassMode? fallbackClassMode, 
    CourseType? fallbackCourseType,
    String? fallbackInstructor,
    String? fallbackRoomNo,
  }) {
    return MeetingTime(
      days: List<String>.from(map['days'] ?? []),
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '00:00',
      classMode: map['classMode'] != null ? ClassModeLabel.fromValue(map['classMode']) : (fallbackClassMode ?? ClassMode.onsite),
      courseType: map.containsKey('courseType') ? CourseTypeLabel.fromValue(map['courseType']) : fallbackCourseType,
      instructor: map['instructor'] as String? ?? fallbackInstructor,
      roomNo: map['roomNo'] as String? ?? fallbackRoomNo,
    );
  }

  MeetingTime copyWith({
    List<String>? days,
    String? startTime,
    String? endTime,
    ClassMode? classMode,
    CourseType? courseType,
    String? instructor,
    String? roomNo,
  }) {
    return MeetingTime(
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classMode: classMode ?? this.classMode,
      courseType: courseType ?? this.courseType,
      instructor: instructor ?? this.instructor,
      roomNo: roomNo ?? this.roomNo,
    );
  }
}