class PumpingModel {
  final String startTime;
  final bool isLeft;
  final int duration; // minute
  final String createdAt;

  PumpingModel({
    required this.startTime,
    required this.isLeft,
    required this.duration,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'startTime': startTime,
    'isLeft': isLeft,
    'duration': duration,
    'createdAt': createdAt,
  };

  factory PumpingModel.fromMap(Map<String, dynamic> map) {
    return PumpingModel(
      startTime: map['startTime'] as String,
      createdAt: map['createdAt'] as String,
      isLeft: map['isLeft'] as bool,
      duration: map['duration'] as int,
    );
  }
}
