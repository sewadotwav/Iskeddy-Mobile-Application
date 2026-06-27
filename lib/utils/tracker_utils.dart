import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../constants/app_colors.dart';

enum TrackerStatus { notSetUp, safe, atRisk, dropped }

class TrackerState {
  final int effectiveAbsences;   // rawAbsences + (rawLates ~/ 3)
  final int? remaining;          // null if maxAbsences not set
  final int latesConverted;      // rawLates ~/ 3
  final TrackerStatus status;

  const TrackerState({
    required this.effectiveAbsences,
    required this.remaining,
    required this.latesConverted,
    required this.status,
  });
}

TrackerState computeTrackerState(Course course) {
  if (course.maxAbsences == null) {
    return TrackerState(
      effectiveAbsences: 0,
      remaining: null,
      latesConverted: 0,
      status: TrackerStatus.notSetUp,
    );
  }
  final latesConverted = course.lateCount ~/ 3;
  final effective = course.absenceCount + latesConverted;
  final remaining = course.maxAbsences! - effective;
  final TrackerStatus status;
  if (effective >= course.maxAbsences!) {
    status = TrackerStatus.dropped;
  } else if (remaining <= 3) {
    status = TrackerStatus.atRisk;
  } else {
    status = TrackerStatus.safe;
  }
  return TrackerState(
    effectiveAbsences: effective,
    remaining: remaining,
    latesConverted: latesConverted,
    status: status,
  );
}

// Returns count of courses that are atRisk or dropped.
int dropRiskCount(List<Course> courses) =>
  courses.where((c) {
    final s = computeTrackerState(c).status;
    return s == TrackerStatus.atRisk || s == TrackerStatus.dropped;
  }).length;

// Returns sum of effectiveAbsences across all courses.
int totalEffectiveAbsences(List<Course> courses) =>
  courses.fold(0, (sum, c) => sum + computeTrackerState(c).effectiveAbsences);

// Color Helpers

Color getCourseColor(Course course) {
  return Color(int.parse('FF${course.colorHex.replaceAll('#', '')}', radix: 16));
}

Color getSaturatedCourseColor(Course course) {
  final baseColor = getCourseColor(course);
  // Blend with accentColor slightly to get a more saturated/darker in-brand color
  return Color.lerp(baseColor, accentColor, 0.4) ?? baseColor;
}
