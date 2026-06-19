import 'package:flutter/material.dart';
import '../../components/app_header.dart';
import '../../components/app_pill.dart';
import '../../components/schedule_card.dart';
import '../../components/empty_state.dart';
import '../../components/circular_icon_button.dart';
import '../../components/confirm_dialog.dart';
import '../../components/app_toast.dart';
import '../../components/name_schedule_dialog.dart';
import '../../components/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/device_id_service.dart';
import '../../constants/app_strings.dart';
import '../screen3_detail/schedule_detail_screen.dart';
import '../../models/schedule_model.dart';
import '../../models/course_model.dart';

class AllSchedulesScreen extends StatefulWidget {
  const AllSchedulesScreen({super.key});

  @override
  State<AllSchedulesScreen> createState() => _AllSchedulesScreenState();
}

class _AllSchedulesScreenState extends State<AllSchedulesScreen> {
  String? _deviceId;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedScheduleIds = {};
  final FirestoreService _firestoreService = FirestoreService();

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

  void _clearSelection() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedScheduleIds.clear();
    });
  }

  void _toggleSelection(String scheduleId) {
    setState(() {
      if (_selectedScheduleIds.contains(scheduleId)) {
        _selectedScheduleIds.remove(scheduleId);
      } else {
        _selectedScheduleIds.add(scheduleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF040505))),
      );
    }

    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isMultiSelectMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: AppHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: _isMultiSelectMode ? _buildMultiSelectHeader() : _buildNormalHeader(),
            ),
            Expanded(
              child: StreamBuilder<List<Schedule>>(
                stream: _firestoreService.getSchedulesStream(_deviceId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF040505)));
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading schedules.'));
                  }

                  final schedules = snapshot.data ?? [];
                  if (schedules.isEmpty) {
                    return EmptyState(
                      icon: Icons.calendar_today,
                      title: AppStrings.noSchedules,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      return StreamBuilder<List<Course>>(
                        stream: _firestoreService.getCoursesStream(_deviceId!, schedule.id),
                        builder: (context, courseSnapshot) {
                          final courseCount = courseSnapshot.data?.length ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ScheduleCard(
                              name: schedule.name,
                              courseCount: courseCount,
                              isPinned: schedule.isPinned,
                              isMultiSelectMode: _isMultiSelectMode,
                              isSelected: _selectedScheduleIds.contains(schedule.id),
                              onTap: () {
                                if (!_isMultiSelectMode) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScheduleDetailScreen(scheduleId: schedule.id),
                                    ),
                                  );
                                } else {
                                  _toggleSelection(schedule.id);
                                }
                              },
                              onLongPress: () {
                                if (!_isMultiSelectMode) {
                                  setState(() {
                                    _isMultiSelectMode = true;
                                    _selectedScheduleIds.add(schedule.id);
                                  });
                                }
                              },
                              onDeleteTap: () {
                                ConfirmDialog.show(
                                  context,
                                  title: AppStrings.deleteScheduleTitle,
                                  message: AppStrings.deleteScheduleMessage,
                                  onConfirm: () async {
                                    await _firestoreService.deleteSchedule(_deviceId!, schedule.id);
                                    if (!mounted) return;
                                    AppToast.show(context, AppStrings.scheduleDeleted);
                                  },
                                );
                              },
                              onSelectToggle: () => _toggleSelection(schedule.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isMultiSelectMode
          ? FloatingActionButton(
              onPressed: () async {
                final name = await NameScheduleDialog.show(context);
                if (name == null || name.trim().isEmpty) return;
                
                final newId = await _firestoreService.createSchedule(_deviceId!, name.trim());
                if (!mounted) return;
                AppToast.show(context, AppStrings.scheduleCreated);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleDetailScreen(scheduleId: newId),
                  ),
                );
              },
              backgroundColor: const Color(0xFF040505),
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    ));
  }

  Widget _buildNormalHeader() {
    return StreamBuilder<List<Schedule>>(
      stream: _firestoreService.getSchedulesStream(_deviceId!),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          children: [
            Text('Your Schedules', style: appFont(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(width: 12),
            AppPill(label: '$count SCHEDULES'),
          ],
        );
      },
    );
  }

  Widget _buildMultiSelectHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircularIconButton(
          icon: Icons.close,
          primary: false,
          onTap: _clearSelection,
        ),
        Text(
          '${_selectedScheduleIds.length} selected',
          style: appFont(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Opacity(
          opacity: _selectedScheduleIds.isEmpty ? 0.3 : 1.0,
          child: CircularIconButton(
            icon: Icons.delete_outline,
            primary: false,
            onTap: _selectedScheduleIds.isEmpty ? () {} : () {
              ConfirmDialog.show(
                context,
                title: AppStrings.bulkDeleteTitle(_selectedScheduleIds.length),
                message: AppStrings.bulkDeleteMessage,
                onConfirm: () async {
                  final count = _selectedScheduleIds.length;
                  await _firestoreService.deleteMultipleSchedules(_deviceId!, _selectedScheduleIds.toList());
                  _clearSelection();
                  if (!mounted) return;
                  AppToast.show(context, AppStrings.schedulesDeleted(count));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
