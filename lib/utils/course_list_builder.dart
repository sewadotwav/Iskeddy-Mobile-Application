import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../components/empty_state.dart';
import '../components/course_card.dart';
import '../components/app_pill.dart';
import '../components/course_editor_sheet.dart';
import '../components/app_text_styles.dart';
import 'time_utils.dart';

class GroupedCourseList extends StatelessWidget {
  final List<Course> courses;
  final String scheduleId;
  final String deviceId;

  const GroupedCourseList({
    super.key,
    required this.courses,
    required this.scheduleId,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final days = activeDays(courses);

    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No courses yet.',
        subtitle: 'Tap + to add your first course.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: days.map((day) {
        final entries = coursesForDay(courses, day);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
              child: Text(
                day.toUpperCase(),
                style: appFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF757575),
                ),
              ),
            ),
            ...List.generate(entries.length, (i) {
              final entry = entries[i];
              return Column(
                children: [
                  CourseCard(
                    course: entry.course,
                    meetingTime: entry.meetingTime,
                    scheduleId: scheduleId,
                    deviceId: deviceId,
                    onEditTap: () => CourseEditorSheet.show(
                      context,
                      deviceId: deviceId,
                      scheduleId: scheduleId,
                      course: entry.course,
                    ),
                  ),
                  if (i < entries.length - 1) ...[
                    if (hasBreakBefore(entries[i].meetingTime, entries[i + 1].meetingTime))
                      const _BreakDivider()
                    else
                      const SizedBox(height: 8),
                  ],
                  if (i == entries.length - 1)
                    const SizedBox(height: 8),
                ],
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

class _BreakDivider extends StatelessWidget {
  const _BreakDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE5E5E5),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: AppPill(
              label: 'Break',
              fillColor: Color(0xFFF2F2F2),
              textColor: Color(0xFF8A8A8A),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE5E5E5),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayCourseList extends StatelessWidget {
  final List<Course> courses;
  final String scheduleId;
  final String deviceId;

  const TodayCourseList({
    super.key,
    required this.courses,
    required this.scheduleId,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final today = weekdayString(DateTime.now().weekday);
    final entries = coursesForDay(courses, today);

    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'No classes scheduled for today.',
        subtitle: null,
        buttonLabel: null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        return Column(
          children: [
            CourseCard(
              course: entry.course,
              meetingTime: entry.meetingTime,
              scheduleId: scheduleId,
              deviceId: deviceId,
              onEditTap: () {},
              readOnly: true,
            ),
            if (i < entries.length - 1) ...[
              if (hasBreakBefore(entries[i].meetingTime, entries[i + 1].meetingTime))
                const _BreakDivider()
              else
                const SizedBox(height: 8),
            ],
          ],
        );
      }),
    );
  }
}
