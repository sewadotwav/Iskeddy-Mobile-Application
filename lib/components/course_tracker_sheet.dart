import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import '../utils/tracker_utils.dart';
import 'app_text_styles.dart';
import '../constants/app_colors.dart';
import 'circular_icon_button.dart';
import 'app_pill.dart';
import 'pill_button.dart';
import 'app_toast.dart';

class CourseTrackerSheet extends StatefulWidget {
  final String deviceId;
  final String scheduleId;
  final Course course;

  const CourseTrackerSheet({
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
      builder: (ctx) => CourseTrackerSheet(
        deviceId: deviceId,
        scheduleId: scheduleId,
        course: course,
      ),
    );
  }

  @override
  State<CourseTrackerSheet> createState() => _CourseTrackerSheetState();
}

class _CourseTrackerSheetState extends State<CourseTrackerSheet> {
  late int _maxAbsences;
  late int _absenceCount;
  late int _lateCount;
  bool _saving = false;
  bool _isEditingLimit = false;

  @override
  void initState() {
    super.initState();
    _maxAbsences = widget.course.maxAbsences ?? 3;
    _absenceCount = widget.course.absenceCount;
    _lateCount = widget.course.lateCount;
  }

  TrackerState get _state => computeTrackerState(widget.course.copyWith(
        maxAbsences: widget.course.maxAbsences == null ? null : _maxAbsences,
        absenceCount: _absenceCount,
        lateCount: _lateCount,
      ));

  int get _effectiveAbsences => _state.effectiveAbsences;

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirestoreService().updateCourseTracker(
      widget.deviceId,
      widget.scheduleId,
      widget.course.id,
      maxAbsences: _maxAbsences,
      absenceCount: _absenceCount,
      lateCount: _lateCount,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    AppToast.show(context, 'Tracker updated');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(
        int.parse('FF${widget.course.colorHex.replaceAll('#', '')}', radix: 16));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.course.title,
                    style: appFont(
                        fontSize: 18, fontWeight: FontWeight.w700, color: accentColor),
                  ),
                ),
                if (widget.course.maxAbsences != null && !_isEditingLimit)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Color(0xFF8A8A8A)),
                    onPressed: () => setState(() => _isEditingLimit = true),
                  ),
                CircularIconButton(
                  icon: Icons.close,
                  primary: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.course.maxAbsences == null || _isEditingLimit)
              _buildSetupState()
            else
              _buildActiveState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppPill(
              label: widget.course.maxAbsences == null ? 'Not yet set up' : 'Edit Limit',
              fillColor: const Color(0xFFF2F2F2)),
        ),
        const SizedBox(height: 20),
        Text(
          'ABSENCE LIMIT',
          style: appFont(
              fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8A8A8A)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularIconButton(
              icon: Icons.remove,
              primary: false,
              size: 40,
              onTap: _maxAbsences > 1
                  ? () => setState(() => _maxAbsences--)
                  : () {},
            ),
            const SizedBox(width: 16),
            Text(
              '$_maxAbsences',
              style: appFont(
                  fontSize: 36, fontWeight: FontWeight.w800, color: accentColor),
            ),
            const SizedBox(width: 16),
            CircularIconButton(
              icon: Icons.add,
              primary: false,
              size: 40,
              onTap: () => setState(() => _maxAbsences++),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'MAXIMUM ABSENCES ALLOWED',
            style: appFont(
                fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'LATE RULE',
          style: appFont(
              fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF8A8A8A)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '3 lates = 1 absence (applied globally)',
                  style: appFont(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PillButton(
          label: widget.course.maxAbsences == null ? 'Set Up Tracker' : 'Update Limit',
          background: accentColor,
          textColor: Colors.white,
          onTap: _saving
              ? () {}
              : () async {
                  setState(() => _saving = true);
                  await FirestoreService().updateCourseTracker(
                    widget.deviceId,
                    widget.scheduleId,
                    widget.course.id,
                    maxAbsences: _maxAbsences,
                    absenceCount: 0,
                    lateCount: 0,
                  );
                  if (!mounted) return;
                  setState(() => _saving = false);
                  AppToast.show(context, 'Tracker set up');
                  Navigator.of(context).pop();
                },
        ),
      ],
    );
  }

  Widget _buildActiveState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. TWO STAT CARDS
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
                      'ABSENCES',
                      style: appFont(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A8A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_effectiveAbsences / $_maxAbsences',
                      style: appFont(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _state.status == TrackerStatus.dropped
                            ? getSaturatedCourseColor(widget.course)
                            : _state.status == TrackerStatus.atRisk
                                ? getCourseColor(widget.course)
                                : accentColor,
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
                      'LATES',
                      style: appFont(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A8A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_lateCount',
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
        const SizedBox(height: 16),

        // 2. STATUS PILL
        Align(
          alignment: Alignment.center,
          child: _buildStatusPill(),
        ),
        const SizedBox(height: 16),

        // 3. WARNING BANNER
        if (_state.status == TrackerStatus.atRisk ||
            _state.status == TrackerStatus.dropped) ...[
          _buildWarningBanner(),
          const SizedBox(height: 16),
        ],

        // 4. LOG ABSENCE ROW
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOG ABSENCE',
                        style: appFont(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('$_absenceCount logged this semester',
                        style: appFont(
                            fontSize: 11, color: const Color(0xFF8A8A8A))),
                  ],
                ),
              ),
              _CounterControls(
                count: _absenceCount,
                onDecrement: _absenceCount > 0
                    ? () => setState(() => _absenceCount--)
                    : null,
                onIncrement: _state.status != TrackerStatus.dropped
                    ? () => setState(() => _absenceCount++)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. LOG LATE ROW
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOG LATE',
                        style: appFont(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('$_lateCount logged this semester',
                        style: appFont(
                            fontSize: 11, color: const Color(0xFF8A8A8A))),
                  ],
                ),
              ),
              _CounterControls(
                count: _lateCount,
                onDecrement: _lateCount > 0
                    ? () => setState(() => _lateCount--)
                    : null,
                onIncrement: () => setState(() => _lateCount++),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. INFO BOX
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3 lates = 1 effective absence',
                        style: appFont(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      'Currently: $_lateCount lates (${_state.latesConverted} added)',
                      style: appFont(fontSize: 11, color: const Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 7. DONE BUTTON
        PillButton(
          label: 'Done',
          background: accentColor,
          textColor: Colors.white,
          onTap: _saving ? () {} : _save,
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    switch (_state.status) {
      case TrackerStatus.safe:
        return AppPill(
            label: 'SAFE — ${_state.remaining} ABSENCES REMAINING',
            fillColor: const Color(0xFFF2F2F2),
            icon: Icons.check_circle_outline);
      case TrackerStatus.atRisk:
        return AppPill(
            label: 'AT RISK — ${_state.remaining} ABSENCE(S) REMAINING',
            fillColor: getCourseColor(widget.course).withValues(alpha: 0.15),
            icon: Icons.warning_amber_outlined);
      case TrackerStatus.dropped:
        return AppPill(
            label: 'DROPPED — LIMIT REACHED',
            fillColor: getSaturatedCourseColor(widget.course).withValues(alpha: 0.15),
            icon: Icons.cancel_outlined);
      case TrackerStatus.notSetUp:
        return const SizedBox();
    }
  }

  Widget _buildWarningBanner() {
    if (_state.status == TrackerStatus.atRisk) {
      return Column(
        children: [
          Text('Lock in!',
              style: appFont(fontSize: 14, fontWeight: FontWeight.w700, color: getCourseColor(widget.course))),
          Text(
            "You're only ${_state.remaining} absence(s) away from being dropped.",
            style: appFont(fontSize: 12, color: const Color(0xFF8A8A8A)),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text("You've reached the absence limit.",
              style: appFont(fontSize: 14, fontWeight: FontWeight.w700, color: getSaturatedCourseColor(widget.course))),
          Text(
            "Your professor may have unofficially dropped you from this class.",
            style: appFont(fontSize: 12, color: const Color(0xFF8A8A8A)),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }
}

class _CounterControls extends StatelessWidget {
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _CounterControls({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildButton(Icons.remove, false, onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$count',
            style: appFont(
                fontSize: 16, fontWeight: FontWeight.w700, color: accentColor),
          ),
        ),
        _buildButton(Icons.add, true, onIncrement),
      ],
    );
  }

  Widget _buildButton(IconData icon, bool primary, VoidCallback? onTap) {
    final btn = CircularIconButton(
      icon: icon,
      primary: primary,
      onTap: onTap ?? () {},
    );
    if (onTap == null) {
      return Opacity(
        opacity: 0.3,
        child: IgnorePointer(child: btn),
      );
    }
    return btn;
  }
}
