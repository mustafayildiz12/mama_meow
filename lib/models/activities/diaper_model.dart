import 'package:mama_meow/models/activities/record_parsing.dart';
import 'package:mama_meow/utils/date_range.dart';

class DiaperModel {
  final String diaperName;
  final String createdAt; // ISO-8601 (DateTime.now().toIso8601String())
  final String diaperTime; // "HH:mm"

  DiaperModel({
    required this.diaperName,
    required this.createdAt,
    required this.diaperTime,
  });

  Map<String, dynamic> toMap() => {
    'diaperName': diaperName,
    'createdAt': createdAt,
    'diaperTime': diaperTime,
  };

  factory DiaperModel.fromMap(Map<String, dynamic> map) {
    return DiaperModel(
      diaperName: recordString(map['diaperName']),
      createdAt: recordString(map['createdAt']),
      diaperTime: recordString(map['diaperTime']),
    );
  }

  /// Kullanıcının seçtiği saate göre olayın gerçek zamanı
  /// (`createdAt` kaydetme anıdır). `createdAt` okunamazsa null.
  DateTime? get eventAt {
    final saved = parseCreatedAt(createdAt);
    return saved == null ? null : resolveEventTime(saved, diaperTime);
  }
}
