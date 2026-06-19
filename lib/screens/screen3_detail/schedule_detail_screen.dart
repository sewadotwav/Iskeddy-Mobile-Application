import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../components/app_text_styles.dart';
import '../../components/circular_icon_button.dart';
import '../../components/empty_state.dart';
import '../../components/app_toast.dart';
import '../../components/confirm_dialog.dart';
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

  // Cached data — updated by stream subscriptions without loading flash
  Schedule? _schedule;
  List<Course> _courses = [];
  bool _initialLoading = true;

  StreamSubscription<List<Schedule>>? _scheduleSub;
  StreamSubscription<List<Course>>? _coursesSub;

  final ValueNotifier<bool> _isMultiSelectMode = ValueNotifier(false);
  final ValueNotifier<Set<String>> _selectedCourseIds = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _initDevice();
  }

  Future<void> _initDevice() async {
    final id = await DeviceIdService.getDeviceId();
    if (!mounted) return;
    _deviceId = id;
    _subscribeStreams(id);
  }

  void _subscribeStreams(String deviceId) {
    final fs = FirestoreService();

    _scheduleSub?.cancel();
    _scheduleSub = fs.getSchedulesStream(deviceId).listen((schedules) {
      if (!mounted) return;
      final found = schedules.cast<Schedule?>().firstWhere(
        (s) => s?.id == widget.scheduleId,
        orElse: () => null,
      );
      if (found == null && _schedule != null) {
        // Schedule was deleted — pop back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
        return;
      }
      setState(() {
        _schedule = found;
        if (_initialLoading && found != null) _initialLoading = false;
      });
    });

    _coursesSub?.cancel();
    _coursesSub = fs.getCoursesStream(deviceId, widget.scheduleId).listen((courses) {
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _initialLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _scheduleSub?.cancel();
    _coursesSub?.cancel();
    _isMultiSelectMode.dispose();
    _selectedCourseIds.dispose();
    super.dispose();
  }

  void _clearSelection() {
    _selectedCourseIds.value = {};
    _isMultiSelectMode.value = false;
  }

  void _toggleSelection(String courseId) {
    final next = Set<String>.from(_selectedCourseIds.value);
    if (next.contains(courseId)) {
      next.remove(courseId);
    } else {
      next.add(courseId);
    }
    _selectedCourseIds.value = next;
  }

  void _selectAll() {
    _selectedCourseIds.value = _courses.map((c) => c.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading || _deviceId == null || _schedule == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isMultiSelectMode,
      builder: (context, isMultiSelect, _) {
        return PopScope(
          canPop: !isMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && isMultiSelect) _clearSelection();
          },
          child: _buildScreen(context, _schedule!, _courses, isMultiSelect),
        );
      },
    );
  }

  Widget _buildMultiSelectHeader() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _selectedCourseIds,
      builder: (context, selectedIds, _) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularIconButton(
                icon: Icons.close,
                primary: false,
                onTap: _clearSelection,
              ),
              Column(
                children: [
                  Text(
                    AppStrings.selectedCount(selectedIds.length),
                    style: appFont(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _selectAll,
                    child: Text(
                      AppStrings.selectAll,
                      style: appFont(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF8A8A8A)),
                    ),
                  ),
                ],
              ),
              Opacity(
                opacity: selectedIds.isEmpty ? 0.3 : 1.0,
                child: CircularIconButton(
                  icon: Icons.delete_outline,
                  primary: false,
                  onTap: selectedIds.isEmpty
                      ? () {}
                      : () {
                          ConfirmDialog.show(
                            context,
                            title: AppStrings.deleteCoursesTitle(selectedIds.length),
                            message: AppStrings.deleteCoursesMessage,
                            onConfirm: () async {
                              final count = selectedIds.length;
                              await FirestoreService().deleteMultipleCourses(
                                  _deviceId!, widget.scheduleId, selectedIds.toList());
                              _clearSelection();
                              if (!mounted) return;
                              AppToast.show(context, AppStrings.coursesDeleted(count));
                            },
                          );
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNormalHeader(Schedule schedule, List<Course> courses) {
    return Column(
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
    );
  }

  Widget _buildScreen(BuildContext context, Schedule schedule, List<Course> courses, bool isMultiSelect) {
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
                  child: isMultiSelect
                      ? _buildMultiSelectHeader()
                      : _buildNormalHeader(schedule, courses),
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
                              border: Border.all(color: accentColor, width: 2),
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
                              border: Border.all(color: accentColor, width: 2),
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
                          isMultiSelectMode: _isMultiSelectMode,
                          selectedCourseIds: _selectedCourseIds,
                          onSelectToggle: _toggleSelection,
                          onLongPress: (id) {
                            _isMultiSelectMode.value = true;
                            _toggleSelection(id);
                          },
                        ),
                      ),
                    ),
            ],
          ),
          if (!isMultiSelect)
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
