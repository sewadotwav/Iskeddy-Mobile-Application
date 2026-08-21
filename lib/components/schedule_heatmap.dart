import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import '../utils/time_utils.dart';
import 'app_text_styles.dart';

// The green bg color of the schedule card calendar icon
const Color _heatBase = Color(0xFFC1EDDC);

// Days in order: Mon Tue Wed Thu Fri Sat Sun
const _dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Computes hours of class time per day from the course list.
Map<String, double> _hoursPerDay(List<Course> courses) {
  final map = <String, double>{for (final d in _dayKeys) d: 0};
  for (final course in courses) {
    for (final mt in course.meetingTimes) {
      final mins = (timeToMinutes(mt.endTime) - timeToMinutes(mt.startTime))
          .clamp(0, 24 * 60)
          .toDouble();
      final hours = mins / 60.0;
      for (final day in mt.days) {
        if (map.containsKey(day)) {
          map[day] = map[day]! + hours;
        }
      }
    }
  }
  return map;
}

Color _cellColor(double hours, double maxHours) {
  if (hours == 0 || maxHours == 0) {
    // No class — very faint tint
    return _heatBase.withValues(alpha: 0.18);
  }
  // Normalize 0..1 where 1 is the busiest day
  final t = (hours / maxHours).clamp(0.0, 1.0);
  // Low heat  → light desaturated version of the base
  // High heat → rich saturated version closer to HSL with lower lightness
  final hsl = HSLColor.fromColor(_heatBase);
  // At t=0 (low): saturation 20%, lightness 92%
  // At t=1 (high): saturation 70%, lightness 52%
  final saturation = (0.20 + t * 0.50).clamp(0.0, 1.0);
  final lightness = (0.92 - t * 0.40).clamp(0.0, 1.0);
  return hsl.withSaturation(saturation).withLightness(lightness).toColor();
}

class ScheduleHeatmap extends StatelessWidget {
  /// Pass the pinned schedule and its courses. If no pinned schedule/no
  /// courses, the widget shows an empty heat row with a subtle label.
  final Schedule? pinnedSchedule;
  final List<Course> courses;

  const ScheduleHeatmap({
    super.key,
    required this.pinnedSchedule,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    final hours = _hoursPerDay(courses);
    final maxHours = hours.values.fold(0.0, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF040505), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WEEKLY LOAD',
                style: appFont(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF040505)),
              ),
              if (pinnedSchedule != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pinnedSchedule!.name,
                    style: appFont(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF040505)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(7, (i) {
              final day = _dayKeys[i];
              final label = _dayLabels[i];
              final h = hours[day] ?? 0;
              final cellColor = _cellColor(h, maxHours);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: h > 0
                            ? Text(
                                _formatH(h),
                                style: appFont(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D4A3E)),
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: appFont(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF040505)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatH(double h) {
    if (h == h.roundToDouble()) return '${h.round()}h';
    // e.g. 1.5 → "1.5h"
    return '${h.toStringAsFixed(1).replaceAll('.0', '')}h';
  }
}
