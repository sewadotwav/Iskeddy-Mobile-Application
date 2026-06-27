import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../models/meeting_time_model.dart';

int timeToMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String minutesToDisplay(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final dt = DateTime(2020, 1, 1, hour, minute);
  return DateFormat("hh:mm a").format(dt);
}

String formatTime(String time) {
  final parts = time.split(':');
  final dt = DateTime(2020, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  return DateFormat("hh:mm a").format(dt);
}

String formatTimeRange(String startTime, String endTime) {
  return '${formatTime(startTime)} – ${formatTime(endTime)}';
}

bool hasBreakBefore(MeetingTime a, MeetingTime b) {
  return timeToMinutes(b.startTime) - timeToMinutes(a.endTime) >= 30;
}

String formatBreakDuration(MeetingTime a, MeetingTime b) {
  final diff = timeToMinutes(b.startTime) - timeToMinutes(a.endTime);
  if (diff <= 0) return '';
  final hours = diff ~/ 60;
  final minutes = diff % 60;
  if (hours > 0 && minutes > 0) {
    return 'Break: ${hours}hr and ${minutes}mins';
  } else if (hours > 0) {
    return 'Break: ${hours}hr';
  } else {
    return 'Break: ${minutes}mins';
  }
}

int totalWeeklyMinutes(List<Course> courses) {
  int total = 0;
  for (final course in courses) {
    for (final meetingTime in course.meetingTimes) {
      final duration = timeToMinutes(meetingTime.endTime) - timeToMinutes(meetingTime.startTime);
      total += duration * meetingTime.days.length;
    }
  }
  return total;
}

int distinctClassDays(List<Course> courses) {
  final Set<String> days = {};
  for (final course in courses) {
    for (final meetingTime in course.meetingTimes) {
      days.addAll(meetingTime.days);
    }
  }
  return days.length;
}

String formatTotalHours(List<Course> courses) {
  final minutes = totalWeeklyMinutes(courses);
  final hours = minutes / 60.0;
  if (hours == hours.truncateToDouble()) {
    return '${hours.toInt()} hrs / wk';
  } else {
    return '${hours.toStringAsFixed(1)} hrs / wk';
  }
}

String formatClassDays(List<Course> courses) {
  final days = distinctClassDays(courses);
  return '$days Days';
}

class DayCourseEntry {
  final Course course;
  final MeetingTime meetingTime;

  DayCourseEntry({required this.course, required this.meetingTime});
}

const List<String> kWeekdayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

List<DayCourseEntry> coursesForDay(List<Course> courses, String day) {
  final List<DayCourseEntry> entries = [];
  for (final course in courses) {
    for (final meetingTime in course.meetingTimes) {
      if (meetingTime.days.contains(day)) {
        entries.add(DayCourseEntry(course: course, meetingTime: meetingTime));
      }
    }
  }
  entries.sort((a, b) => timeToMinutes(a.meetingTime.startTime).compareTo(timeToMinutes(b.meetingTime.startTime)));
  return entries;
}

List<String> activeDays(List<Course> courses) {
  final Set<String> days = {};
  for (final course in courses) {
    for (final meetingTime in course.meetingTimes) {
      days.addAll(meetingTime.days);
    }
  }
  return kWeekdayOrder.where((day) => days.contains(day)).toList();
}

String weekdayString(int dartWeekday) {
  if (dartWeekday >= 1 && dartWeekday <= 7) {
    return kWeekdayOrder[dartWeekday - 1];
  }
  return 'Mon';
}
