class MeetingTime {
  final List<String> days; // e.g. ["Mon", "Wed", "Fri"]
  final String startTime;  // 24h format, e.g. "08:00"
  final String endTime;    // 24h format, e.g. "09:30"

  const MeetingTime({
    required this.days,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory MeetingTime.fromMap(Map<String, dynamic> map) {
    return MeetingTime(
      days: List<String>.from(map['days'] ?? []),
      startTime: map['startTime'] ?? '00:00',
      endTime: map['endTime'] ?? '00:00',
    );
  }

  MeetingTime copyWith({
    List<String>? days,
    String? startTime,
    String? endTime,
  }) {
    return MeetingTime(
      days: days ?? this.days,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}