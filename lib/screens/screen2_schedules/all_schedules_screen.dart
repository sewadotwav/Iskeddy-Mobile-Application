import 'dart:async';
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
import '../../components/digital_clock.dart';
import '../../components/schedule_heatmap.dart';


class AllSchedulesScreen extends StatefulWidget {
  const AllSchedulesScreen({super.key});

  @override
  State<AllSchedulesScreen> createState() => _AllSchedulesScreenState();
}

class _AllSchedulesScreenState extends State<AllSchedulesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // ── Stream subscription — cached list avoids loading flash on re-emissions ──
  String? _deviceId;
  List<Schedule> _schedules = [];
  bool _schedulesLoading = true;
  StreamSubscription<List<Schedule>>? _schedulesSub;

  // Pinned schedule courses for the heatmap
  List<Course> _pinnedCourses = [];
  StreamSubscription<List<Course>>? _pinnedCoursesSub;

  // ── Selection state as ValueNotifiers — changes never cause Scaffold rebuild ──
  final ValueNotifier<bool> _isMultiSelectMode = ValueNotifier(false);
  final ValueNotifier<Set<String>> _selectedIds = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _initDevice();
  }

  Future<void> _initDevice() async {
    final id = await DeviceIdService.getDeviceId();
    if (!mounted) return;
    setState(() => _deviceId = id);
    _subscribeSchedules(id);
  }

  void _subscribeSchedules(String deviceId) {
    _schedulesSub?.cancel();
    _schedulesSub = _firestoreService.getSchedulesStream(deviceId).listen((data) {
      if (!mounted) return;
      final sorted = List<Schedule>.from(data)
        ..sort((a, b) {
          if (a.isPinned == b.isPinned) return 0;
          return a.isPinned ? -1 : 1;
        });
      setState(() {
        _schedules = sorted;
        _schedulesLoading = false;
      });
      // Re-subscribe courses whenever pinned schedule changes
      final pinned = sorted.firstWhere(
        (s) => s.isPinned,
        orElse: () => sorted.isNotEmpty ? sorted.first : Schedule(id: '', name: '', isPinned: false, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      if (sorted.isEmpty) {
        _pinnedCoursesSub?.cancel();
        _pinnedCourses = [];
        return;
      }
      _pinnedCoursesSub?.cancel();
      _pinnedCoursesSub = _firestoreService.getCoursesStream(deviceId, pinned.id).listen((courses) {
        if (!mounted) return;
        setState(() => _pinnedCourses = courses);
      });
    });
  }

  @override
  void dispose() {
    _schedulesSub?.cancel();
    _pinnedCoursesSub?.cancel();
    _isMultiSelectMode.dispose();
    _selectedIds.dispose();
    super.dispose();
  }

  void _clearSelection() {
    _selectedIds.value = {};
    _isMultiSelectMode.value = false;
  }

  void _toggleSelection(String scheduleId) {
    final next = Set<String>.from(_selectedIds.value);
    if (next.contains(scheduleId)) {
      next.remove(scheduleId);
    } else {
      next.add(scheduleId);
    }
    _selectedIds.value = next;
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceId == null || _schedulesLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF040505))),
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
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: AppHeader(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20.0, top: 8.0, bottom: 12.0),
                    child: isMultiSelect
                        ? _buildMultiSelectHeader()
                        : _buildNormalHeader(),
                  ),
                  if (!isMultiSelect) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: DigitalClock(),
                    ),
                    if (_schedules.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0),
                        child: ScheduleHeatmap(
                          pinnedSchedule: _schedules.firstWhere(
                            (s) => s.isPinned,
                            orElse: () => _schedules.first,
                          ),
                          courses: _pinnedCourses,
                        ),
                      ),
                  ],
                  Expanded(
                    child: _schedules.isEmpty
                        ? EmptyState(
                            icon: Icons.calendar_today,
                            title: AppStrings.noSchedules,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 12.0),
                            itemCount: _schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _schedules[index];
                              return _ScheduleCardItem(
                                key: ValueKey(schedule.id),
                                schedule: schedule,
                                deviceId: _deviceId!,
                                firestoreService: _firestoreService,
                                isMultiSelectMode: _isMultiSelectMode,
                                selectedIds: _selectedIds,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleDetailScreen(
                                      scheduleId: schedule.id,
                                    ),
                                  ),
                                ),
                                onLongPress: () {
                                  _isMultiSelectMode.value = true;
                                  _toggleSelection(schedule.id);
                                },
                                onSelectToggle: () =>
                                    _toggleSelection(schedule.id),
                                onDelete: () {
                                  final ctx = context;
                                  ConfirmDialog.show(
                                    ctx,
                                    title: AppStrings.deleteScheduleTitle,
                                    message: AppStrings.deleteScheduleMessage,
                                    onConfirm: () async {
                                      await _firestoreService.deleteSchedule(
                                          _deviceId!, schedule.id);
                                      if (!ctx.mounted) return;
                                      AppToast.show(
                                          ctx, AppStrings.scheduleDeleted);
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
            floatingActionButton: !isMultiSelect
                ? FloatingActionButton(
                    onPressed: () async {
                      final ctx = context;
                      final name = await NameScheduleDialog.show(ctx);
                      if (name == null || name.trim().isEmpty) return;
                      final newId = await _firestoreService.createSchedule(
                          _deviceId!, name.trim());
                      if (!ctx.mounted) return;
                      AppToast.show(ctx, AppStrings.scheduleCreated);
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              ScheduleDetailScreen(scheduleId: newId),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFF040505),
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildNormalHeader() {
    return Row(
      children: [
        Text(
          AppStrings.yourSchedules,
          style: appFont(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 12),
        AppPill(label: '${_schedules.length} ${AppStrings.schedulesCount}'),
      ],
    );
  }

  Widget _buildMultiSelectHeader() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _selectedIds,
      builder: (context, selectedIds, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircularIconButton(
              icon: Icons.close,
              primary: false,
              onTap: _clearSelection,
            ),
            Text(
              AppStrings.selectedCount(selectedIds.length),
              style: appFont(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Opacity(
              opacity: selectedIds.isEmpty ? 0.3 : 1.0,
              child: CircularIconButton(
                icon: Icons.delete_outline,
                primary: false,
                onTap: selectedIds.isEmpty
                    ? () {}
                    : () {
                        final ctx = context;
                        ConfirmDialog.show(
                          ctx,
                          title:
                              AppStrings.bulkDeleteTitle(selectedIds.length),
                          message: AppStrings.bulkDeleteMessage,
                          onConfirm: () async {
                            final count = selectedIds.length;
                            await _firestoreService.deleteMultipleSchedules(
                              _deviceId!, selectedIds.toList());
                            _clearSelection();
                            if (!ctx.mounted) return;
                            AppToast.show(
                                ctx, AppStrings.schedulesDeleted(count));
                          },
                        );
                      },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Per-card widget that independently subscribes to course count ─────────────
class _ScheduleCardItem extends StatefulWidget {
  final Schedule schedule;
  final String deviceId;
  final FirestoreService firestoreService;
  final ValueNotifier<bool> isMultiSelectMode;
  final ValueNotifier<Set<String>> selectedIds;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSelectToggle;
  final VoidCallback onDelete;

  const _ScheduleCardItem({
    super.key,
    required this.schedule,
    required this.deviceId,
    required this.firestoreService,
    required this.isMultiSelectMode,
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectToggle,
    required this.onDelete,
  });

  @override
  State<_ScheduleCardItem> createState() => _ScheduleCardItemState();
}

class _ScheduleCardItemState extends State<_ScheduleCardItem> {
  int _courseCount = 0;
  StreamSubscription<List<Course>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.firestoreService
        .getCoursesStream(widget.deviceId, widget.schedule.id)
        .listen((courses) {
      if (mounted) setState(() => _courseCount = courses.length);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.isMultiSelectMode,
        builder: (context, isMultiSelect, _) {
          return ValueListenableBuilder<Set<String>>(
            valueListenable: widget.selectedIds,
            builder: (context, selectedIds, _) {
              return RepaintBoundary(
                child: ScheduleCard(
                  name: widget.schedule.name,
                  courseCount: _courseCount,
                  isPinned: widget.schedule.isPinned,
                  isMultiSelectMode: isMultiSelect,
                  isSelected: selectedIds.contains(widget.schedule.id),
                  onTap: isMultiSelect ? widget.onSelectToggle : widget.onTap,
                  onLongPress: isMultiSelect ? () {} : widget.onLongPress,
                  onDeleteTap: widget.onDelete,
                  onSelectToggle: widget.onSelectToggle,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
