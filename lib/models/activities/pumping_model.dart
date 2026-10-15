import 'package:mama_meow/models/activities/record_parsing.dart';
import 'package:mama_meow/utils/date_range.dart';

class PumpingModel {
  final String startTime; // "HH:mm"
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
      startTime: recordString(map['startTime']),
      createdAt: recordString(map['createdAt']),
      isLeft: recordBool(map['isLeft']),
      duration: recordInt(map['duration']),
    );
  }

  /// Kullanıcının seçtiği saate göre olayın gerçek zamanı; `createdAt`
  /// okunamazsa null.
  DateTime? get eventAt {
    final saved = parseCreatedAt(createdAt);
    return saved == null ? null : resolveEventTime(saved, startTime);
  }
}
