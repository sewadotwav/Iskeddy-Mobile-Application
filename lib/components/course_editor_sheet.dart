import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import '../models/course_model.dart';
import '../models/meeting_time_model.dart';
import '../services/firestore_service.dart';
import '../services/device_id_service.dart';
import '../utils/time_utils.dart';

import 'color_picker_grid.dart';
import 'pill_button.dart';
import 'circular_icon_button.dart';
import 'app_toast.dart';
import 'confirm_dialog.dart';

class _MeetingTimeInput {
  List<String> days;
  String startTime;
  String endTime;
  ClassMode classMode;
  CourseType? courseType;
  TextEditingController instructorController;
  TextEditingController roomController;

  _MeetingTimeInput({
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.classMode,
    this.courseType,
    required this.instructorController,
    required this.roomController,
  });

  void dispose() {
    instructorController.dispose();
    roomController.dispose();
  }
}

class CourseEditorSheet extends StatefulWidget {
  final String deviceId;
  final String scheduleId;
  final Course? course;

  const CourseEditorSheet({
    super.key,
    required this.deviceId,
    required this.scheduleId,
    this.course,
  });

  static Future<void> show(
    BuildContext context, {
    required String deviceId,
    required String scheduleId,
    Course? course,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => CourseEditorSheet(
        deviceId: deviceId,
        scheduleId: scheduleId,
        course: course,
      ),
    );
  }

  @override
  State<CourseEditorSheet> createState() => _CourseEditorSheetState();
}

class _CourseEditorSheetState extends State<CourseEditorSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();

  int _selectedColorIndex = 0;
  List<_MeetingTimeInput> _meetingTimes = [];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    if (c != null) {
      _titleController.text = c.title;
      _sectionController.text = c.section;
      _selectedColorIndex = courseColorHexValues.indexOf(c.colorHex);
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;
      _meetingTimes = c.meetingTimes.map((m) => _MeetingTimeInput(
        days: List.from(m.days),
        startTime: m.startTime,
        endTime: m.endTime,
        classMode: m.classMode,
        courseType: m.courseType,
        instructorController: TextEditingController(text: m.instructor ?? ''),
        roomController: TextEditingController(text: m.roomNo ?? ''),
      )).toList();
    } else {
      _meetingTimes = [
        _MeetingTimeInput(
          days: [], 
          startTime: '08:00', 
          endTime: '09:30', 
          classMode: ClassMode.onsite,
          instructorController: TextEditingController(),
          roomController: TextEditingController(),
        )
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sectionController.dispose();
    for (var m in _meetingTimes) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, int index, bool isStart) async {
    final currentTimeString = isStart ? _meetingTimes[index].startTime : _meetingTimes[index].endTime;
    final parts = currentTimeString.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              primaryContainer: Colors.black12,
              onPrimaryContainer: Colors.black,
              secondaryContainer: Colors.black12,
              onSecondaryContainer: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
              error: Colors.red,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontFamily: 'ZalandoSansSemiExpanded',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.black12;
                }
                return const Color(0xFFF2F2F2);
              }),
              hourMinuteTextColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.black;
                }
                return Colors.black87;
              }),
              dayPeriodColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.black;
                }
                return const Color(0xFFF2F2F2);
              }),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              dialHandColor: Colors.black,
              dialBackgroundColor: const Color(0xFFF2F2F2),
              dialTextColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              entryModeIconColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _meetingTimes[index].startTime = formattedTime;
        } else {
          _meetingTimes[index].endTime = formattedTime;
        }
      });
    }
  }

  String _formatTimeDisplay(String hhmm) {
    final parts = hhmm.split(':');
    final dt = DateTime(2020, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat("hh:mm a").format(dt);
  }

  void _onSave() async {
    if (_titleController.text.trim().isEmpty) {
      AppToast.show(context, 'Course title is required', isError: true);
      return;
    }

    if (_sectionController.text.trim().isEmpty) {
      AppToast.show(context, 'Course section is required', isError: true);
      return;
    }

    for (int i = 0; i < _meetingTimes.length; i++) {
      var m = _meetingTimes[i];
      if (m.days.isEmpty) {
        AppToast.show(context, 'Please pick at least one day for meeting time ${i + 1}', isError: true);
        return;
      }
      if (m.roomController.text.trim().isEmpty) {
        AppToast.show(context, 'Room number is required for meeting time ${i + 1}', isError: true);
        return;
      }
      if (timeToMinutes(m.endTime) <= timeToMinutes(m.startTime)) {
        AppToast.show(context, AppStrings.invalidTimeMessage, isError: true);
        return;
      }
    }

    final isAdd = widget.course == null;
    final now = DateTime.now();
    
    final saved = Course(
      id: isAdd ? const Uuid().v4() : widget.course!.id,
      title: _titleController.text.trim(),
      section: _sectionController.text.trim(),
      colorHex: courseColorHexValues[_selectedColorIndex],
      meetingTimes: _meetingTimes.map((m) => MeetingTime(
        days: m.days,
        startTime: m.startTime,
        endTime: m.endTime,
        classMode: m.classMode,
        courseType: m.courseType,
        instructor: m.instructorController.text.trim().isEmpty ? null : m.instructorController.text.trim(),
        roomNo: m.roomController.text.trim().isEmpty ? null : m.roomController.text.trim(),
      )).toList(),
      createdAt: isAdd ? now : widget.course!.createdAt,
      updatedAt: now,
    );

    final deviceId = await DeviceIdService.getDeviceId();
    try {
      if (isAdd) {
        await FirestoreService().addCourse(deviceId, widget.scheduleId, saved);
        if (!mounted) return;
        AppToast.show(context, AppStrings.courseAdded(saved.title));
      } else {
        await FirestoreService().updateCourse(deviceId, widget.scheduleId, saved);
        if (!mounted) return;
        AppToast.show(context, AppStrings.changesSaved);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        'Could not save. Check your connection and try again.',
        isError: true,
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _onDelete() {
    ConfirmDialog.show(
      context,
      title: AppStrings.deleteCourseTitle(widget.course!.title),
      message: AppStrings.deleteCourseMessage,
      cancelLabel: AppStrings.cancel,
      confirmLabel: AppStrings.delete,
      onConfirm: () async {
        try {
          final deviceId = await DeviceIdService.getDeviceId();
          await FirestoreService().deleteCourse(deviceId, widget.scheduleId, widget.course!.id);
          if (!mounted) return;
          AppToast.show(context, AppStrings.courseRemoved(widget.course!.title));
          Navigator.of(context).pop();
        } catch (e) {
          if (!mounted) return;
          AppToast.show(
            context,
            'Could not delete. Check your connection and try again.',
            isError: true,
          );
        }
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'ZalandoSansSemiExpanded',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF757575),
      ),
    );
  }

  Widget _buildClassModeDropdown(int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClassMode>(
          value: _meetingTimes[index].classMode,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down, color: accentColor),
          items: ClassMode.values.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e.label, style: const TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _meetingTimes[index].classMode = val);
          },
        ),
      ),
    );
  }

  Widget _buildCourseTypeDropdown(int index) {
    final List<DropdownMenuItem<CourseType?>> items = [
      const DropdownMenuItem<CourseType?>(
        value: null,
        child: Text('None', style: TextStyle(fontSize: 14)),
      ),
      ...CourseType.values.map((e) => DropdownMenuItem<CourseType?>(
        value: e,
        child: Text(e.label, style: const TextStyle(fontSize: 14)),
      )),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CourseType?>(
          value: _meetingTimes[index].courseType,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down, color: accentColor),
          items: items,
          onChanged: (val) {
            setState(() => _meetingTimes[index].courseType = val);
          },
        ),
      ),
    );
  }

  Widget _buildDaysRow(int index) {
    final daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final daysLetters = ["M", "T", "W", "T", "F", "S", "S"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final dayStr = daysOfWeek[i];
        final letter = daysLetters[i];
        final isSelected = _meetingTimes[index].days.contains(dayStr);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _meetingTimes[index].days.remove(dayStr);
              } else {
                _meetingTimes[index].days.add(dayStr);
              }
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accentColor : const Color(0xFFF2F2F2),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontFamily: 'ZalandoSansSemiExpanded',
                color: isSelected ? Colors.white : accentColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimePill(int index, bool isStart) {
    final timeStr = isStart ? _meetingTimes[index].startTime : _meetingTimes[index].endTime;
    return GestureDetector(
      onTap: () => _pickTime(context, index, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, color: accentColor, size: 16),
            const SizedBox(width: 8),
            Text(
              _formatTimeDisplay(timeStr),
              style: const TextStyle(
                fontFamily: 'ZalandoSansSemiExpanded',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMeetingTimesList() {
    List<Widget> items = [];
    for (int i = 0; i < _meetingTimes.length; i++) {
      if (_meetingTimes.length > 1) {
        if (i > 0) {
          items.add(const Divider(color: Color(0xFFE5E5E5), height: 32, thickness: 1));
        }
        items.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meeting Time ${i + 1}',
                style: const TextStyle(
                  fontFamily: 'ZalandoSansSemiExpanded',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF757575),
                ),
              ),
              CircularIconButton(
                icon: Icons.remove_circle_outline,
                size: 28,
                primary: false,
                onTap: () {
                  setState(() {
                    _meetingTimes.removeAt(i);
                  });
                },
              ),
            ],
          ),
        );
        items.add(const SizedBox(height: 12));
      } else {
        items.add(_buildSectionLabel('DAYS'));
        items.add(const SizedBox(height: 8));
      }

      items.add(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('CLASS MODE'),
                  const SizedBox(height: 8),
                  _buildClassModeDropdown(i),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('COURSE TYPE'),
                  const SizedBox(height: 8),
                  _buildCourseTypeDropdown(i),
                ],
              ),
            ),
          ],
        ),
      );
      items.add(const SizedBox(height: 16));

      items.add(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('INSTRUCTOR'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _meetingTimes[i].instructorController,
                    style: const TextStyle(fontFamily: 'ZalandoSansSemiExpanded', fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('ROOM NO.'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _meetingTimes[i].roomController,
                    style: const TextStyle(fontFamily: 'ZalandoSansSemiExpanded', fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      items.add(const SizedBox(height: 16));

      items.add(_buildSectionLabel('MEETING DAYS'));
      items.add(const SizedBox(height: 8));
      items.add(_buildDaysRow(i));
      items.add(const SizedBox(height: 16));

      items.add(
        Row(
          children: [
            Expanded(child: _buildTimePill(i, true)),
            const SizedBox(width: 16),
            Expanded(child: _buildTimePill(i, false)),
          ],
        ),
      );
      items.add(const SizedBox(height: 16));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: SingleChildScrollView(
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
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.course == null ? 'Add Course' : 'Edit Course',
                  style: const TextStyle(
                    fontFamily: 'ZalandoSansSemiExpanded',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CircularIconButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title & Section
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('COURSE TITLE'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontFamily: 'ZalandoSansSemiExpanded', fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. Intro to Psychology',
                          hintStyle: const TextStyle(
                            fontFamily: 'ZalandoSansSemiExpanded',
                            color: Color(0xFF757575),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('SECTION'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _sectionController,
                        style: const TextStyle(fontFamily: 'ZalandoSansSemiExpanded', fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. A',
                          hintStyle: const TextStyle(
                            fontFamily: 'ZalandoSansSemiExpanded',
                            color: Color(0xFF757575),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color
            _buildSectionLabel('COURSE COLOR'),
            const SizedBox(height: 8),
            ColorPickerGrid(
              selectedIndex: _selectedColorIndex,
              onSelected: (i) => setState(() => _selectedColorIndex = i),
            ),
            const SizedBox(height: 24),

            // Meeting Times
            ..._buildMeetingTimesList(),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _meetingTimes.add(_MeetingTimeInput(
                      days: [], 
                      startTime: '08:00', 
                      endTime: '09:30', 
                      classMode: ClassMode.onsite,
                      instructorController: TextEditingController(),
                      roomController: TextEditingController(),
                    ));
                  });
                },
                icon: const Icon(Icons.add_circle_outline, color: accentColor),
                label: const Text(
                  '+ Add another meeting time',
                  style: TextStyle(color: accentColor, fontFamily: 'ZalandoSansSemiExpanded'),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // Save
            PillButton(
              label: 'Save Course',
              background: accentColor,
              textColor: Colors.white,
              onTap: _onSave,
            ),
            
            // Delete
            if (widget.course != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _onDelete,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'ZalandoSansSemiExpanded',
                    color: Color(0xFFFF5252),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
