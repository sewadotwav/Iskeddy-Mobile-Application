import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../components/app_text_styles.dart';
import '../../components/circular_icon_button.dart';
import '../../components/empty_state.dart';
import '../../components/app_toast.dart';
import '../../components/name_schedule_dialog.dart';
import '../../components/course_editor_sheet.dart';
import '../../utils/time_utils.dart';
import '../../utils/course_list_builder.dart';
import '../../services/firestore_service.dart';
import '../../services/device_id_service.dart';
import '../../models/schedule_model.dart';
import '../../models/course_model.dart';

const Color kTextSecondary = Color(0xFF8A8A8A);

class ScheduleDetailScreen extends StatefulWidget {
  final String scheduleId;

  const ScheduleDetailScreen({super.key, required this.scheduleId});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _initDevice();
  }

  Future<void> _initDevice() async {
    final id = await DeviceIdService.getDeviceId();
    if (mounted) {
      setState(() {
        _deviceId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    return StreamBuilder<List<Schedule>>(
      stream: FirestoreService().getSchedulesStream(_deviceId!),
      builder: (context, scheduleSnapshot) {
        if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(
             backgroundColor: Colors.white,
             body: Center(child: CircularProgressIndicator(color: accentColor)),
           );
        }

        final schedules = scheduleSnapshot.data ?? [];
        final schedule = schedules.cast<Schedule?>().firstWhere(
          (s) => s?.id == widget.scheduleId,
          orElse: () => null,
        );

        if (schedule == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
          return Container(color: Colors.white);
        }

        return StreamBuilder<List<Course>>(
          stream: FirestoreService().getCoursesStream(_deviceId!, widget.scheduleId),
          builder: (context, courseSnapshot) {
             if (courseSnapshot.connectionState == ConnectionState.waiting) {
               return const Scaffold(
                 backgroundColor: Colors.white,
                 body: Center(child: CircularProgressIndicator(color: accentColor)),
               );
             }
             final courses = courseSnapshot.data ?? [];
             return _buildScreen(context, schedule, courses);
          },
        );
      },
    );
  }

  Widget _buildScreen(BuildContext context, Schedule schedule, List<Course> courses) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 20, top: 12),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: accentColor),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    schedule.name,
                                    style: appFont(fontSize: 24, fontWeight: FontWeight.w800, color: accentColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    schedule.isPinned
                                        ? 'Active Schedule · ${courses.length} Courses'
                                        : '${courses.length} Courses',
                                    style: appFont(fontSize: 13, color: kTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                CircularIconButton(
                                  icon: schedule.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  primary: false,
                                  onTap: () async {
                                    final fs = FirestoreService();
                                    if (schedule.isPinned) {
                                      await fs.unpinSchedule(_deviceId!, widget.scheduleId);
                                      if (!mounted) return;
                                      AppToast.show(context, AppStrings.scheduleUnpinned);
                                    } else {
                                      await fs.pinSchedule(_deviceId!, widget.scheduleId);
                                      if (!mounted) return;
                                      AppToast.show(context, AppStrings.schedulePinned);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                CircularIconButton(
                                  icon: Icons.edit_outlined,
                                  primary: false,
                                  onTap: () async {
                                    final newName = await NameScheduleDialog.show(
                                      context,
                                      title: 'Rename Schedule',
                                      placeholder: AppStrings.newSchedulePlaceholder,
                                      confirmLabel: 'Save',
                                      initialValue: schedule.name,
                                    );
                                    if (newName == null || newName.trim().isEmpty) return;
                                    await FirestoreService().updateScheduleName(
                                      _deviceId!, widget.scheduleId, newName.trim(),
                                    );
                                    if (!mounted) return;
                                    AppToast.show(context, AppStrings.scheduleRenamed);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (courses.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL HOURS',
                                  style: appFont(fontSize: 10, fontWeight: FontWeight.w600, color: kTextSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatTotalHours(courses),
                                  style: appFont(fontSize: 22, fontWeight: FontWeight.w800, color: accentColor),
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
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CLASS DAYS',
                                  style: appFont(fontSize: 10, fontWeight: FontWeight.w600, color: kTextSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatClassDays(courses),
                                  style: appFont(fontSize: 22, fontWeight: FontWeight.w800, color: accentColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              courses.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: EmptyState(
                            icon: Icons.school_outlined,
                            title: AppStrings.noCoursesTitle,
                            subtitle: AppStrings.noCoursesSubtitle,
                          ),
                        ),
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
                        child: GroupedCourseList(
                          courses: courses,
                          scheduleId: widget.scheduleId,
                          deviceId: _deviceId!,
                        ),
                      ),
                    ),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 20,
            child: CircularIconButton(
              icon: Icons.add,
              primary: true,
              size: 56,
              onTap: () => CourseEditorSheet.show(
                context,
                deviceId: _deviceId!,
                scheduleId: widget.scheduleId,
                course: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
