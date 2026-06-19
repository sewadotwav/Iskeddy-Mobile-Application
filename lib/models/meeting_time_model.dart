import '../constants/app_enums.dart';

class MeetingTime {
  final List<String> days; // e.g. ["Mon", "Wed", "Fri"]
  final String startTime;  // 24h format, e.g. "08:00"
  final String endTime;    // 24h format, e.g. "09:30"
  final ClassMode classMode;
  final CourseType? courseType;

  const MeetingTime({
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.classMode,
    this.courseType,
  });

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'startTime': startTime,
      'endTime': endTime,
      'classMode': classMode.value,
      'courseType': courseType?.label,
    };
  }

  factory MeetingTime.fromMap(Map<String, dynamic> map, {ClassMode? fallbackClassMode, CourseType? fallbackCourseType}) {
    return MeetingTime(
      days: List<String>.from(map['days'] ?? []),
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '00:00',
      classMode: map['classMode'] != null ? ClassModeLabel.fromValue(map['classMode']) : (fallbackClassMode ?? ClassMode.onsite),
      courseType: map.containsKey('courseType') ? CourseTypeLabel.fromValue(map['courseType']) : fallbackCourseType,
    );
  }

  MeetingTime copyWith({
    List<String>? days,
    String? startTime,
    String? endTime,
    ClassMode? classMode,
    CourseType? courseType,
  }) {
    return MeetingTime(
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classMode: classMode ?? this.classMode,
      courseType: courseType ?? this.courseType,
    );
  }
}