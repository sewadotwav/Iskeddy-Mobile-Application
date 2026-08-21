import 'package:flutter_test/flutter_test.dart';
import 'package:iskeddy/utils/time_utils.dart';
import 'package:iskeddy/models/meeting_time_model.dart';
import 'package:iskeddy/constants/app_enums.dart';

void main() {
  test('timeToMinutes', () {
    expect(timeToMinutes("09:30"), 570);
  });

  test('formatTimeRange', () {
    expect(formatTimeRange("08:00", "10:30"), "08:00 AM – 10:30 AM");
  });

  test('hasBreakBefore', () {
    expect(
      hasBreakBefore(
        MeetingTime(days: [], startTime: "08:00", endTime: "09:30", classMode: ClassMode.onsite),
        MeetingTime(days: [], startTime: "10:00", endTime: "11:30", classMode: ClassMode.onsite)
      ),
      true
    );

    expect(
      hasBreakBefore(
        MeetingTime(days: [], startTime: "08:00", endTime: "09:30", classMode: ClassMode.onsite),
        MeetingTime(days: [], startTime: "09:45", endTime: "11:00", classMode: ClassMode.onsite)
      ),
      false
    );
  });

  test('weekdayString', () {
    expect(weekdayString(DateTime.monday), "Mon");
    expect(weekdayString(DateTime.sunday), "Sun");
  });
}
