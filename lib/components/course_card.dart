import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/meeting_time_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import 'app_text_styles.dart';
import 'app_pill.dart';
import '../utils/time_utils.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final MeetingTime meetingTime;
  final String scheduleId;
  final String deviceId;
  final VoidCallback onEditTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.meetingTime,
    required this.scheduleId,
    required this.deviceId,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(int.parse('FF${course.colorHex.replaceAll('#', '')}', radix: 16)),
        borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEditTap,
                child: const Icon(Icons.edit_outlined, size: 18, color: accentColor),
              ),
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
          if (course.roomNo != null && course.roomNo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  course.roomNo!,
                  style: appFont(fontSize: 12, color: accentColor),
                ),
              ],
            ),
          ],
          if (course.classMode != ClassMode.onsite) ...[
            const SizedBox(height: 8),
            AppPill(
              label: course.classMode.label,
              fillColor: Colors.white.withOpacity(0.6),
              textColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}
