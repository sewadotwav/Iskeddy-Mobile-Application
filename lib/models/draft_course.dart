import '../models/meeting_time_model.dart';

class DraftCourse {
  String title;
  String colorHex;
  List<MeetingTime> meetingTimes;
  String? instructor;
  String? roomNo;
  bool isIncluded;

  DraftCourse({
    required this.title,
    required this.colorHex,
    required this.meetingTimes,
    this.instructor,
    this.roomNo,
    this.isIncluded = true,
  });
}
