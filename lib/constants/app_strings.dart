class AppStrings {
  static const String scheduleCreated = 'Schedule created';
  static const String scheduleRenamed = 'Schedule renamed';
  static const String schedulePinned = 'Set as default timetable';
  static const String scheduleUnpinned = 'Default timetable removed';
  static const String changesSaved = 'Changes saved';
  static const String scheduleDeleted = 'Schedule deleted';

  static String courseAdded(String title) => '$title added';
  static String courseRemoved(String title) => '$title removed';
  static String schedulesDeleted(int count) => '$count schedules deleted';

  static const String deleteScheduleTitle = 'Delete this schedule?';
  static const String deleteScheduleMessage =
      'This cannot be undone. All courses within this schedule will be permanently removed.';

  static String bulkDeleteTitle(int count) => 'Delete $count schedules?';
  static const String bulkDeleteMessage =
      'This cannot be undone. All courses within these schedules will be permanently removed.';

  static String deleteCourseTitle(String title) => 'Remove $title?';
  static const String deleteCourseMessage = 'This cannot be undone.';

  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String create = 'Create';

  static const String noPinnedScheduleTitle = 'No default schedule set.';
  static const String noPinnedScheduleSubtitle = 'Pin one from your schedules.';
  static const String goToSchedules = 'Go to Schedules';
  static const String noSchedules = 'No schedules yet. Tap + to create one.';
  static const String noCoursesTitle = 'No courses yet.';
  static const String noCoursesSubtitle = 'Tap + to add your first course.';
  static const String addCourse = '+ Add Course';
  static String noClassesToday() => 'No classes scheduled for today.';
  static const String breakLabel = 'Break';

  static const String newScheduleTitle = 'Name Your Schedule';
  static const String newSchedulePlaceholder = 'e.g. Fall Semester 2024';
}
