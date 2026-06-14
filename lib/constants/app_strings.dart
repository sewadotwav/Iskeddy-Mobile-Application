
class AppStrings {
  // ── Toast Messages ─────────────────────────────────────────

  static const String scheduleCreated = 'Schedule created';
  static const String scheduleRenamed = 'Schedule renamed';
  static const String schedulePinned = 'Set as default timetable';
  static const String scheduleUnpinned = 'Default timetable removed';
  static const String changesSaved = 'Changes saved';
  static const String scheduleDeleted = 'Schedule deleted';

  static String courseAdded(String title) => '$title added';
  static String courseRemoved(String title) => '$title removed';
  static String schedulesDeleted(int count) => '$count schedules deleted';

  // ── Confirmation Dialogue Messages ──────────────────────────

  static const String deleteScheduleTitle = 'Delete Schedule?';
  static const String deleteScheduleMessage =
      'Delete this schedule? This cannot be undone.';

  static String bulkDeleteMessage(int count) =>
      'Delete $count schedules? This cannot be undone.';

  static String deleteCourseMessage(String title) =>
      'Remove $title from this schedule? This cannot be undone.';

  // ── Dialogue Button Labels ──────────────────────────────────

  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String remove = 'Remove';

  // ── Empty States ─────────────────────────────────────────────

  static const String noPinnedSchedule =
      'No default schedule set. Pin one from your schedules.';
  static const String noSchedules = 'No schedules yet. Tap + to create one.';
  static const String noCourses = 'Tap + to add your first course';
  static const String goToSchedules = 'Go to Schedules';
}