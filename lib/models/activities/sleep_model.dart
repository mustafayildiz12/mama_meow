class SleepModel {
  final String startTime; // hh:mm
  final String endTime; // hh:mm
  final String sleepDate; // yyyy-MM-dd hh:mm
  final String? sleepNote;

  /// seçeneklerden birisi olacak
  /// upset, crying, content, under 10 min to fall asleep, 10-30 min, more than 30 min
  final String? startOfSleep;

  /// seçeneklerden birisi olacak
  /// woke up child, upset, content, crying
  final String? endOfSleep;

  /// seçeneklerden birisi olacak
  /// nursing, on own in bed, warm or health, next to caregiver, co-sleep, bottle, stroller, car, swing
  final String? howItHappened;

  SleepModel({
    required this.startTime,
    required this.endTime,
    required this.sleepDate,
    this.sleepNote,
    this.startOfSleep,
    this.endOfSleep,
    this.howItHappened,
  });

  factory SleepModel.fromJson(Map<String, dynamic> json) {
    return SleepModel(
      startTime: json['startTime'],
      endTime: json['endTime'],
      sleepDate: json['sleepDate'],
      sleepNote: json['sleepNote'],
      startOfSleep: json['startOfSleep'],
      endOfSleep: json['endOfSleep'],
      howItHappened: json['howItHappened'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'sleepDate': sleepDate,
      'sleepNote': sleepNote,
      'startOfSleep': startOfSleep,
      'endOfSleep': endOfSleep,
      'howItHappened': howItHappened,
    };
  }
}
