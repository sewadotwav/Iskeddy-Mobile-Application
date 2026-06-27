import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/meeting_time_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import '../services/firestore_service.dart';
import '../utils/time_utils.dart';
import 'app_text_styles.dart';
import 'app_pill.dart';
import 'pill_button.dart';
import 'circular_icon_button.dart';
import 'app_toast.dart';

const Color kTextSecondary = Color(0xFF8A8A8A);

class CourseDetailSheet extends StatefulWidget {
  final String deviceId;
  final String scheduleId;
  final Course course;

  const CourseDetailSheet({
    super.key,
    required this.deviceId,
    required this.scheduleId,
    required this.course,
  });

  static Future<void> show(
    BuildContext context, {
    required String deviceId,
    required String scheduleId,
    required Course course,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => CourseDetailSheet(
        deviceId: deviceId,
        scheduleId: scheduleId,
        course: course,
      ),
    );
  }

  @override
  State<CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends State<CourseDetailSheet> {
  late TextEditingController _notesController;
  late Course _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _notesController = TextEditingController(text: _course.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFF9E9D0);
    }
  }

  String _courseHrsPerWeek() {
    int totalMinutes = 0;
    for (final mt in _course.meetingTimes) {
      final duration = timeToMinutes(mt.endTime) - timeToMinutes(mt.startTime);
      totalMinutes += duration * mt.days.length;
    }
    final hours = totalMinutes / 60.0;
    if (hours == hours.truncateToDouble()) {
      return '${hours.toInt()} hrs / wk';
    }
    return '${hours.toStringAsFixed(1)} hrs / wk';
  }

  Widget _buildMeetingTime(MeetingTime meetingTime) {
    final color = _parseColor(_course.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meetingTime.days.join(', '),
                  style: appFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatTimeRange(meetingTime.startTime, meetingTime.endTime),
            style: appFont(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextSecondary),
          ),
          if (meetingTime.instructor != null && meetingTime.instructor!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, color: accentColor, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meetingTime.instructor!,
                    style: appFont(fontSize: 12, color: kTextSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (meetingTime.roomNo != null && meetingTime.roomNo!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: accentColor, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meetingTime.roomNo!,
                    style: appFont(fontSize: 12, color: kTextSecondary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SmallPill(label: meetingTime.classMode.label),
              if (meetingTime.courseType != null)
                _SmallPill(label: meetingTime.courseType!.label),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final color = _parseColor(_course.colorHex);

    // Collect unique class modes / course types across all meeting times for the pills row
    final classModes = _course.meetingTimes.map((m) => m.classMode).toSet().toList();
    final courseTypes = _course.meetingTimes.map((m) => m.courseType).where((t) => t != null).toSet().toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header row
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _course.title,
                    style: appFont(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircularIconButton(
                  icon: Icons.close,
                  primary: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pills row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (classModes.isNotEmpty)
                  AppPill(
                    label: classModes.first.label,
                    fillColor: const Color(0xFFF2F2F2),
                  ),
                if (courseTypes.isNotEmpty)
                  AppPill(
                    label: courseTypes.first!.label,
                    fillColor: const Color(0xFFF2F2F2),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Hours per week for this course
            if (_course.meetingTimes.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, color: accentColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _courseHrsPerWeek(),
                    style: appFont(fontSize: 13, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // Meeting Times
            Text(
              'MEETING TIMES',
              style: appFont(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (_course.meetingTimes.isEmpty)
              Text(
                'No meeting times set.',
                style: appFont(
                  fontSize: 13,
                  color: kTextSecondary,
                ),
              )
            else
              ..._course.meetingTimes.map(_buildMeetingTime),
            const SizedBox(height: 24),

            // Notes
            Text(
              'NOTES',
              style: appFont(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                minLines: 3,
                style: appFont(fontSize: 14, color: accentColor),
                decoration: InputDecoration(
                  hintText: 'Add a short note for this course...',
                  hintStyle: appFont(fontSize: 14, color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            PillButton(
              label: 'Save Note',
              background: accentColor,
              textColor: Colors.white,
              onTap: () async {
                await FirestoreService().updateCourseNotes(
                  widget.deviceId,
                  widget.scheduleId,
                  _course.id,
                  _notesController.text.trim(),
                );
                if (!context.mounted) return;
                AppToast.show(context, AppStrings.noteSaved);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  const _SmallPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: appFont(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kTextSecondary,
        ),
      ),
    );
  }
}
