import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import '../utils/tracker_utils.dart';
import 'app_text_styles.dart';
import '../constants/app_colors.dart';
import 'circular_icon_button.dart';
import 'app_pill.dart';
import 'course_tracker_sheet.dart';

class AbsenceTrackerSheet extends StatelessWidget {
  final String deviceId;
  final String scheduleId;

  const AbsenceTrackerSheet({
    super.key,
    required this.deviceId,
    required this.scheduleId,
  });

  static Future<void> show(
    BuildContext context, {
    required String deviceId,
    required String scheduleId,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => AbsenceTrackerSheet(
        deviceId: deviceId,
        scheduleId: scheduleId,
      ),
    );
  }

  Widget _statusPill(TrackerStatus status, int? remaining, Course course) {
    switch (status) {
      case TrackerStatus.notSetUp:
        return const AppPill(label: 'Set Up', fillColor: Color(0xFFF2F2F2));
      case TrackerStatus.safe:
        return const AppPill(label: 'Safe', fillColor: Color(0xFFF2F2F2));
      case TrackerStatus.atRisk:
        return AppPill(label: 'At Risk', fillColor: getCourseColor(course).withValues(alpha: 0.15));
      case TrackerStatus.dropped:
        return AppPill(label: 'Dropped', fillColor: getSaturatedCourseColor(course).withValues(alpha: 0.15));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Course>>(
      stream: FirestoreService().getCoursesStream(deviceId, scheduleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: accentColor));
        }
        final courses = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // a. Drag handle
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

              // b. Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Absence Tracker',
                      style: appFont(fontSize: 20, fontWeight: FontWeight.w800, color: accentColor),
                    ),
                  ),
                  CircularIconButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                    primary: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // c. SUB-STAT ROW
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DROP RISK',
                            style: appFont(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8A8A8A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dropRiskCount(courses)} Courses',
                            style: appFont(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL ABSENCES',
                            style: appFont(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF8A8A8A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalEffectiveAbsences(courses)}',
                            style: appFont(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // e. COURSE LIST
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final state = computeTrackerState(course);
                  final bgColor = Color(int.parse('FF${course.colorHex.replaceAll('#', '')}', radix: 16));

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      CourseTrackerSheet.show(
                        context,
                        deviceId: deviceId,
                        scheduleId: scheduleId,
                        course: course,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              style: appFont(fontSize: 15, fontWeight: FontWeight.w700, color: accentColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusPill(state.status, state.remaining, course),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
