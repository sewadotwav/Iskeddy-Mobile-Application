import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/meeting_time_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import 'app_text_styles.dart';
import 'app_pill.dart';
import 'app_toast.dart';
import 'confirm_dialog.dart';
import '../services/firestore_service.dart';
import '../services/device_id_service.dart';
import '../utils/time_utils.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final MeetingTime meetingTime;
  final String scheduleId;
  final String deviceId;
  final VoidCallback onEditTap;
  final VoidCallback? onCardTap;
  final bool readOnly;

  // Multi-select properties
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPress;

  const CourseCard({
    super.key,
    required this.course,
    required this.meetingTime,
    required this.scheduleId,
    required this.deviceId,
    required this.onEditTap,
    this.onCardTap,
    this.readOnly = false,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onSelectToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isMultiSelectMode ? null : onLongPress,
      onTap: isMultiSelectMode ? onSelectToggle : onCardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(int.parse('FF${course.colorHex.replaceAll('#', '')}', radix: 16)),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF040505), width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: appFont(fontSize: 15, fontWeight: FontWeight.w700, color: accentColor),
                  ),
                ),
                if (isMultiSelectMode)
                  _SelectionCircle(isSelected: isSelected)
                else if (!readOnly) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onEditTap,
                    child: const Icon(Icons.edit_outlined, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ConfirmDialog.show(
                        context,
                        title: AppStrings.deleteCourseTitle(course.title),
                        message: AppStrings.deleteCourseMessage,
                        cancelLabel: AppStrings.cancel,
                        confirmLabel: AppStrings.delete,
                        onConfirm: () async {
                          final deviceId = await DeviceIdService.getDeviceId();
                          final fs = FirestoreService();
                          final remainingTimes = course.meetingTimes
                              .where((mt) =>
                                  mt.days != meetingTime.days ||
                                  mt.startTime != meetingTime.startTime ||
                                  mt.endTime != meetingTime.endTime)
                              .toList();

                          if (remainingTimes.isEmpty) {
                            // last meeting — delete entire course
                            await fs.deleteCourse(deviceId, scheduleId, course.id);
                          } else {
                            // remove only this meeting time, keep the course
                            await fs.updateCourse(
                              deviceId,
                              scheduleId,
                              course.copyWith(meetingTimes: remainingTimes),
                            );
                          }
                          if (context.mounted) {
                            AppToast.show(context, AppStrings.courseRemoved(course.title));
                          }
                        },
                      );
                    },
                    child: const Icon(Icons.delete_outline, size: 18, color: accentColor),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  formatTimeRange(meetingTime.startTime, meetingTime.endTime),
                  style: appFont(fontSize: 12, color: accentColor),
                ),
              ],
            ),
            if (meetingTime.roomNo != null && meetingTime.roomNo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    meetingTime.roomNo!,
                    style: appFont(fontSize: 12, color: accentColor),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                AppPill(
                  label: meetingTime.classMode.label,
                  fillColor: Colors.white.withValues(alpha: 0.6),
                  textColor: accentColor,
                ),
                if (meetingTime.courseType != null)
                  AppPill(
                    label: meetingTime.courseType!.label,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                    textColor: accentColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  final bool isSelected;
  const _SelectionCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF040505) : Colors.transparent,
        border: Border.all(
          color: isSelected ? const Color(0xFF040505) : const Color(0xFFE5E5E5),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}
