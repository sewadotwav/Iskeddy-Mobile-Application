import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/draft_course.dart';
import '../../models/meeting_time_model.dart';
import '../../models/course_model.dart';
import '../../services/firestore_service.dart';
import '../../services/device_id_service.dart';
import '../../components/pill_button.dart';
import '../../components/app_toast.dart';
import '../../components/confirm_dialog.dart';
import '../../components/name_schedule_dialog.dart';
import '../../components/color_picker_grid.dart';
import '../../components/circular_icon_button.dart';
import '../../components/app_text_styles.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_enums.dart';
import '../screen3_detail/schedule_detail_screen.dart';

class DraftReviewScreen extends StatefulWidget {
  final List<DraftCourse> draftCourses;

  const DraftReviewScreen({super.key, required this.draftCourses});

  @override
  State<DraftReviewScreen> createState() => _DraftReviewScreenState();
}

class _DraftReviewScreenState extends State<DraftReviewScreen> {
  late List<DraftCourse> _courses;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _courses = List.from(widget.draftCourses);
  }

  int get _includedCount => _courses.where((c) => c.isIncluded).length;

  Future<void> _onBackPressed() async {
    await ConfirmDialog.show(
      context,
      title: 'Discard this draft?',
      message: 'The detected courses will not be saved.',
      cancelLabel: 'Keep Editing',
      confirmLabel: 'Discard',
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _onSave() async {
    final name = await NameScheduleDialog.show(
      context,
      title: 'Name Your Schedule',
      placeholder: 'e.g. Fall Semester 2026',
      confirmLabel: 'Create',
    );
    if (name == null || name.trim().isEmpty) {
      if (name != null && name.trim().isEmpty) {
        if (!mounted) return;
        AppToast.show(context, 'Schedule name is required.');
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final deviceId = await DeviceIdService.getDeviceId();
      final fs = FirestoreService();

      final scheduleId = await fs.createSchedule(deviceId, name.trim());

      const uuid = Uuid();
      final now = DateTime.now();
      final includedCourses = _courses.where((c) => c.isIncluded).toList();

      for (final draft in includedCourses) {
        final meetingTimes = draft.meetingTimes.map((mt) => mt.copyWith(
          classMode: mt.classMode,
          courseType: mt.courseType,
          instructor: draft.instructor,
          roomNo: draft.roomNo,
        )).toList();

        final course = Course(
          id: uuid.v4(),
          title: draft.title.trim(),
          section: '',
          colorHex: draft.colorHex,
          notes: null,
          meetingTimes: meetingTimes,
          maxAbsences: null,
          absenceCount: 0,
          lateCount: 0,
          createdAt: now,
          updatedAt: now,
        );
        await fs.addCourse(deviceId, scheduleId, course);
      }

      if (!mounted) return;

      AppToast.show(context, 'Schedule imported');

      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScheduleDetailScreen(scheduleId: scheduleId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.show(context, 'Failed to save. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8),
                  child: Row(
                    children: [
                      CircularIconButton(
                        icon: Icons.arrow_back,
                        primary: false,
                        onTap: _onBackPressed,
                      ),
                      Expanded(
                        child: Text(
                          'Review Schedule',
                          style: appFont(fontSize: 18, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 38),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
                child: Text(
                  '$_includedCount of ${_courses.length} courses will be saved',
                  style: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) => _DraftCourseCard(
                    course: _courses[index],
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: PillButton(
                label: _isSaving
                    ? 'Saving...'
                    : 'Save as New Schedule ($_includedCount)',
                background: _includedCount > 0 ? accentColor : const Color(0xFFE0E0E0),
                textColor: _includedCount > 0 ? Colors.white : const Color(0xFF8A8A8A),
                onTap: _isSaving 
                    ? () {} 
                    : () {
                        if (_includedCount == 0) {
                          AppToast.show(context, 'Include at least one course to save.');
                          return;
                        }
                        _onSave();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCourseCard extends StatefulWidget {
  final DraftCourse course;
  final VoidCallback onChanged;

  const _DraftCourseCard({required this.course, required this.onChanged});

  @override
  State<_DraftCourseCard> createState() => _DraftCourseCardState();
}

class _DraftCourseCardState extends State<_DraftCourseCard> {
  late TextEditingController _titleController;
  late TextEditingController _instructorController;
  late TextEditingController _roomController;
  bool _showColorPicker = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _instructorController = TextEditingController(text: widget.course.instructor ?? '');
    _roomController = TextEditingController(text: widget.course.roomNo ?? '');

    _titleController.addListener(() {
      widget.course.title = _titleController.text;
      widget.onChanged();
    });
    _instructorController.addListener(() {
      final v = _instructorController.text.trim();
      widget.course.instructor = v.isEmpty ? null : v;
    });
    _roomController.addListener(() {
      final v = _roomController.text.trim();
      widget.course.roomNo = v.isEmpty ? null : v;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructorController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.course.isIncluded ? 1.0 : 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Color(int.parse('FF${widget.course.colorHex.replaceAll('#', '')}', radix: 16)),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: appFont(fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Course title',
                      hintStyle: appFont(fontSize: 16, color: const Color(0xFF8A8A8A)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.course.isIncluded = !widget.course.isIncluded;
                    });
                    widget.onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    child: Icon(
                      widget.course.isIncluded
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.course.meetingTimes.asMap().entries.map((entry) => _MeetingTimeRow(
                  meetingTime: entry.value,
                  onChanged: (newMt) => setState(() {
                    widget.course.meetingTimes[entry.key] = newMt;
                    widget.onChanged();
                  }),
                )),
            if (widget.course.isIncluded) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        widget.course.meetingTimes.add(const MeetingTime(
                            days: [], startTime: '08:00', endTime: '09:00', classMode: ClassMode.onsite));
                      });
                      widget.onChanged();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 16, color: accentColor),
                    label: Text('Add time slot',
                        style: appFont(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showColorPicker = !_showColorPicker),
                    icon: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(int.parse(
                            'FF${widget.course.colorHex.replaceAll('#', '')}',
                            radix: 16)),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                    label: Text('Change Color',
                        style: appFont(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              if (_showColorPicker)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: ColorPickerGrid(
                    selectedIndex: courseColorHexValues
                        .indexOf(widget.course.colorHex)
                        .clamp(0, courseColorHexValues.length - 1),
                    onSelected: (i) {
                      setState(() {
                        widget.course.colorHex = courseColorHexValues[i];
                        _showColorPicker = false;
                      });
                      widget.onChanged();
                    },
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white60, height: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _instructorController,
                            style: appFont(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Instructor Name (Optional)',
                              hintStyle: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white60, height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _roomController,
                            style: appFont(fontSize: 13, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Room Number (Optional)',
                              hintStyle: appFont(fontSize: 13, color: const Color(0xFF8A8A8A)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeetingTimeRow extends StatefulWidget {
  final MeetingTime meetingTime;
  final ValueChanged<MeetingTime> onChanged;

  const _MeetingTimeRow({required this.meetingTime, required this.onChanged});

  @override
  State<_MeetingTimeRow> createState() => _MeetingTimeRowState();
}

class _MeetingTimeRowState extends State<_MeetingTimeRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(7, (i) {
              const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              const dayStrings = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final isSelected = widget.meetingTime.days.contains(dayStrings[i]);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    List<String> newDays = List.from(widget.meetingTime.days);
                    if (isSelected) {
                      newDays.remove(dayStrings[i]);
                    } else {
                      newDays.add(dayStrings[i]);
                    }
                    widget.onChanged(widget.meetingTime.copyWith(days: newDays));
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? accentColor
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                    child: Center(
                      child: Text(
                        letters[i],
                        style: appFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimePill(
                  label: 'Start',
                  time: widget.meetingTime.startTime,
                  onPicked: (picked) {
                    final newStartTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    if (newStartTime.compareTo(widget.meetingTime.endTime) >= 0) {
                      AppToast.show(context, 'Start time must be before end time.');
                      return;
                    }
                    widget.onChanged(widget.meetingTime.copyWith(startTime: newStartTime));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–',
                    style: appFont(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: _TimePill(
                  label: 'End',
                  time: widget.meetingTime.endTime,
                  onPicked: (picked) {
                    final newEndTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    if (newEndTime.compareTo(widget.meetingTime.startTime) <= 0) {
                      AppToast.show(context, 'End time must be after start time.');
                      return;
                    }
                    widget.onChanged(widget.meetingTime.copyWith(endTime: newEndTime));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<ClassMode>(
                    value: widget.meetingTime.classMode,
                    underline: const SizedBox.shrink(),
                    isExpanded: true,
                    isDense: false,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: appFont(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
                    items: ClassMode.values.map((m) =>
                        DropdownMenuItem(
                            value: m, child: Text(m.label, style: appFont(fontSize: 12, fontWeight: FontWeight.w500)))).toList(),
                    onChanged: (val) {
                      if (val != null) widget.onChanged(widget.meetingTime.copyWith(classMode: val));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<CourseType?>(
                    value: widget.meetingTime.courseType,
                    underline: const SizedBox.shrink(),
                    isExpanded: true,
                    isDense: false,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    hint: Text('Type', style: appFont(fontSize: 12, color: const Color(0xFF8A8A8A))),
                    style: appFont(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text('None', style: appFont(fontSize: 12, fontWeight: FontWeight.w500))),
                      ...CourseType.values.map((t) =>
                          DropdownMenuItem(
                              value: t, child: Text(t.label, style: appFont(fontSize: 12, fontWeight: FontWeight.w500)))),
                    ],
                    onChanged: (val) {
                      widget.onChanged(widget.meetingTime.copyWith(courseType: val));
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  final String label;
  final String time;
  final ValueChanged<TimeOfDay> onPicked;

  const _TimePill({
    required this.label,
    required this.time,
    required this.onPicked,
  });

  String _display() {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    final displayM = m.toString().padLeft(2, '0');
    return '$displayH:$displayM $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final initial =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked =
            await showTimePicker(context: context, initialTime: initial);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 13, color: accentColor),
            const SizedBox(width: 5),
            Text(_display(), style: appFont(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
