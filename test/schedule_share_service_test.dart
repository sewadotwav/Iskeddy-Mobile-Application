import 'package:flutter_test/flutter_test.dart';
import 'package:iskeddy/models/schedule_model.dart';
import 'package:iskeddy/models/course_model.dart';
import 'package:iskeddy/models/meeting_time_model.dart';
import 'package:iskeddy/constants/app_enums.dart';
import 'package:iskeddy/services/schedule_share_service.dart';

void main() {
  group('ScheduleShareService JSON export and import', () {
    test('exports and parses schedule with courses accurately', () {
      final schedule = Schedule(
        id: 'test-sched-1',
        name: 'First Term 2026',
        isPinned: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final course = Course(
        id: 'test-course-1',
        title: 'Computer Science 101',
        section: 'CS1A',
        colorHex: '#C5D2C1',
        notes: 'Room 304, Bring Laptop',
        meetingTimes: const [
          MeetingTime(
            days: ['Mon', 'Wed', 'Fri'],
            startTime: '08:00',
            endTime: '09:30',
            classMode: ClassMode.onsite,
            courseType: CourseType.lecture,
            instructor: 'Dr. Alan Turing',
            roomNo: 'RM 304',
          ),
        ],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        maxAbsences: 3,
        absenceCount: 1,
        lateCount: 0,
      );

      // 1. Export to Base64
      final exportCode = ScheduleShareService.exportScheduleToJson(schedule, [course]);
      expect(exportCode, isNotEmpty);

      // 2. Import from Base64
      final importedData = ScheduleShareService.importScheduleFromJson(exportCode);
      expect(importedData, isNotNull);
      expect(importedData!['scheduleName'], equals('First Term 2026'));

      // 3. Parse Courses
      final courses = ScheduleShareService.parseCoursesFromExport(importedData['courses']);
      expect(courses.length, equals(1));
      final parsedCourse = courses.first;
      expect(parsedCourse.title, equals('Computer Science 101'));
      expect(parsedCourse.section, equals('CS1A'));
      expect(parsedCourse.colorHex, equals('#C5D2C1'));
      expect(parsedCourse.notes, equals('Room 304, Bring Laptop'));
      expect(parsedCourse.meetingTimes.length, equals(1));
      expect(parsedCourse.meetingTimes.first.days, equals(['Mon', 'Wed', 'Fri']));
      expect(parsedCourse.meetingTimes.first.startTime, equals('08:00'));
      expect(parsedCourse.meetingTimes.first.endTime, equals('09:30'));
      expect(parsedCourse.meetingTimes.first.instructor, equals('Dr. Alan Turing'));
      expect(parsedCourse.meetingTimes.first.roomNo, equals('RM 304'));
      expect(parsedCourse.meetingTimes.first.classMode, equals(ClassMode.onsite));
      expect(parsedCourse.maxAbsences, equals(3));
    });

    test('returns null for invalid or corrupted export codes', () {
      expect(ScheduleShareService.importScheduleFromJson(''), isNull);
      expect(ScheduleShareService.importScheduleFromJson('not-a-valid-base64!'), isNull);
      expect(ScheduleShareService.importScheduleFromJson('SGVsbG8gV29ybGQ='), isNull); // "Hello World"
    });
  });
}
