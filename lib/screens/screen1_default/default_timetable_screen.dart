import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../components/app_header.dart';
import '../../components/empty_state.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_colors.dart';
import '../../components/app_text_styles.dart';
import '../../utils/time_utils.dart';
import '../../utils/course_list_builder.dart';
import '../../services/firestore_service.dart';
import '../../services/device_id_service.dart';
import '../../models/schedule_model.dart';
import '../../models/course_model.dart';

class DefaultTimetableScreen extends StatefulWidget {
  final VoidCallback? onGoToSchedules;

  const DefaultTimetableScreen({super.key, this.onGoToSchedules});

  @override
  State<DefaultTimetableScreen> createState() => _DefaultTimetableScreenState();
}

class _DefaultTimetableScreenState extends State<DefaultTimetableScreen> {
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

  String _todayLabel() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d').format(now);
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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: accentColor)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                "Could not load schedule.",
                style: appFont(fontSize: 14, color: const Color(0xFF8A8A8A)),
              ),
            ),
          );
        }

        final schedules = snapshot.data ?? [];
        final schedule = schedules.where((s) => s.isPinned).firstOrNull;

        if (schedule == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  const AppHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.push_pin_outlined,
                      iconBackground: const Color(0xFFF2F2F2),
                      title: AppStrings.noPinnedScheduleTitle,
                      subtitle: AppStrings.noPinnedScheduleSubtitle,
                      buttonLabel: AppStrings.goToSchedules,
                      onButtonTap: widget.onGoToSchedules,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(),
                  const SizedBox(height: 20),
                  Text(
                    schedule.name,
                    style: appFont(fontSize: 24, fontWeight: FontWeight.w800, color: accentColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _todayLabel(),
                    style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<Course>>(
                    stream: FirestoreService().getCoursesStream(_deviceId!, schedule.id),
                    builder: (context, courseSnapshot) {
                      if (courseSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator(color: accentColor)),
                        );
                      }
                      
                      final courses = courseSnapshot.data ?? [];
                      
                      return TodayCourseList(
                        courses: courses,
                        scheduleId: schedule.id,
                        deviceId: _deviceId!,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
