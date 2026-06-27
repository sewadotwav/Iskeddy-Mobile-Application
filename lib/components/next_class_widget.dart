import 'dart:async';
import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../utils/time_utils.dart';
import 'app_text_styles.dart';
import '../constants/app_colors.dart';

class _NextClassInfo {
  final String courseTitle;
  final String colorHex;
  final String timeRange;
  final String? instructor;
  final String? roomNo;
  final bool isNow; // true if class is currently in progress

  const _NextClassInfo({
    required this.courseTitle,
    required this.colorHex,
    required this.timeRange,
    this.instructor,
    this.roomNo,
    this.isNow = false,
  });
}

_NextClassInfo? _resolveNext(List<Course> courses) {
  final now = DateTime.now();
  final today = weekdayString(now.weekday);
  final nowMinutes = now.hour * 60 + now.minute;

  final entries = coursesForDay(courses, today);

  // 1. Check if currently IN a class
  for (final e in entries) {
    final start = timeToMinutes(e.meetingTime.startTime);
    final end = timeToMinutes(e.meetingTime.endTime);
    if (nowMinutes >= start && nowMinutes < end) {
      return _NextClassInfo(
        courseTitle: e.course.title,
        colorHex: e.course.colorHex,
        timeRange: formatTimeRange(e.meetingTime.startTime, e.meetingTime.endTime),
        instructor: e.meetingTime.instructor,
        roomNo: e.meetingTime.roomNo,
        isNow: true,
      );
    }
  }

  // 2. Next upcoming class today
  for (final e in entries) {
    final start = timeToMinutes(e.meetingTime.startTime);
    if (start > nowMinutes) {
      return _NextClassInfo(
        courseTitle: e.course.title,
        colorHex: e.course.colorHex,
        timeRange: formatTimeRange(e.meetingTime.startTime, e.meetingTime.endTime),
        instructor: e.meetingTime.instructor,
        roomNo: e.meetingTime.roomNo,
        isNow: false,
      );
    }
  }

  // 3. Lookahead — find the next class in the coming days (up to 6 days ahead)
  for (int offset = 1; offset <= 6; offset++) {
    final nextDay = weekdayString(((now.weekday - 1 + offset) % 7) + 1);
    final nextEntries = coursesForDay(courses, nextDay);
    if (nextEntries.isNotEmpty) {
      final e = nextEntries.first;
      final dayLabel = offset == 1 ? 'Tomorrow' : nextDay;
      return _NextClassInfo(
        courseTitle: e.course.title,
        colorHex: e.course.colorHex,
        timeRange: '$dayLabel · ${formatTimeRange(e.meetingTime.startTime, e.meetingTime.endTime)}',
        instructor: e.meetingTime.instructor,
        roomNo: e.meetingTime.roomNo,
        isNow: false,
      );
    }
  }

  return null; // No upcoming classes
}

/// A slim card widget that displays the next upcoming class dynamically.
/// Updates every 30 seconds.
class NextClassWidget extends StatefulWidget {
  final List<Course> courses;

  const NextClassWidget({super.key, required this.courses});

  @override
  State<NextClassWidget> createState() => _NextClassWidgetState();
}

class _NextClassWidgetState extends State<NextClassWidget> {
  Timer? _timer;
  _NextClassInfo? _next;

  @override
  void initState() {
    super.initState();
    _next = _resolveNext(widget.courses);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _next = _resolveNext(widget.courses));
    });
  }

  @override
  void didUpdateWidget(NextClassWidget old) {
    super.didUpdateWidget(old);
    _next = _resolveNext(widget.courses);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_next == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: accentColor, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No upcoming classes',
          style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
        ),
      );
    }

    final courseColor = Color(
      int.parse('FF${_next!.colorHex.replaceAll('#', '')}', radix: 16),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: accentColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _next!.isNow ? 'HAPPENING NOW' : 'YOUR NEXT CLASS',
                style: appFont(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _next!.isNow ? courseColor : accentColor,
                ),
              ),
              if (_next!.isNow) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: courseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _next!.courseTitle,
            style: appFont(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _next!.timeRange,
                style: appFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
              if (_next!.roomNo != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('·', style: TextStyle(color: Color(0xFFAAAAAA))),
                ),
                Text(
                  _next!.roomNo!,
                  style: appFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ],
              if (_next!.instructor != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('·', style: TextStyle(color: Color(0xFFAAAAAA))),
                ),
                Flexible(
                  child: Text(
                    _next!.instructor!,
                    style: appFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
