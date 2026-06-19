import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../components/empty_state.dart';
import '../components/course_card.dart';
import '../components/app_pill.dart';
import '../components/course_editor_sheet.dart';
import '../components/app_text_styles.dart';
import '../constants/app_strings.dart';
import 'time_utils.dart';

class GroupedCourseList extends StatelessWidget {
  final List<Course> courses;
  final String scheduleId;
  final String deviceId;

  final ValueNotifier<bool>? isMultiSelectMode;
  final ValueNotifier<Set<String>>? selectedCourseIds;
  final Function(String)? onSelectToggle;
  final Function(String)? onLongPress;

  const GroupedCourseList({
    super.key,
    required this.courses,
    required this.scheduleId,
    required this.deviceId,
    this.isMultiSelectMode,
    this.selectedCourseIds,
    this.onSelectToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final days = activeDays(courses);

    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: AppStrings.noCoursesTitle,
        subtitle: AppStrings.noCoursesSubtitle,
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
              
              Widget cardContent = CourseCard(
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
              );

              if (isMultiSelectMode != null && selectedCourseIds != null) {
                cardContent = ValueListenableBuilder<bool>(
                  valueListenable: isMultiSelectMode!,
                  builder: (context, isMultiSelect, _) {
                    return ValueListenableBuilder<Set<String>>(
                      valueListenable: selectedCourseIds!,
                      builder: (context, selectedIds, _) {
                        return CourseCard(
                          course: entry.course,
                          meetingTime: entry.meetingTime,
                          scheduleId: scheduleId,
                          deviceId: deviceId,
                          isMultiSelectMode: isMultiSelect,
                          isSelected: selectedIds.contains(entry.course.id),
                          onSelectToggle: onSelectToggle != null 
                              ? () => onSelectToggle!(entry.course.id) 
                              : null,
                          onLongPress: onLongPress != null 
                              ? () => onLongPress!(entry.course.id) 
                              : null,
                          onEditTap: () => CourseEditorSheet.show(
                            context,
                            deviceId: deviceId,
                            scheduleId: scheduleId,
                            course: entry.course,
                          ),
                        );
                      },
                    );
                  },
                );
              }

              return Column(
                children: [
                  cardContent,
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
      return EmptyState(
        icon: Icons.wb_sunny_outlined,
        title: AppStrings.noClassesToday(),
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
