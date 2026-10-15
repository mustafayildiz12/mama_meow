import 'package:mama_meow/models/activities/record_parsing.dart';
import 'package:mama_meow/utils/date_range.dart';

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
      startTime: recordString(json['startTime']),
      endTime: recordString(json['endTime']),
      sleepDate: recordString(json['sleepDate']),
      sleepNote: recordStringOrNull(json['sleepNote']),
      startOfSleep: recordStringOrNull(json['startOfSleep']),
      endOfSleep: recordStringOrNull(json['endOfSleep']),
      howItHappened: recordStringOrNull(json['howItHappened']),
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

  /// [sleepDate]'in gün kısmı; okunamazsa null.
  DateTime? get day {
    final d = DateTime.tryParse(sleepDate.trim().split(' ').first);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  /// Uykunun başlangıcı (gün + [startTime]); okunamazsa null.
  DateTime? get startAt {
    final d = day;
    final hm = parseHourMinute(startTime);
    if (d == null || hm == null) return null;
    return DateTime(d.year, d.month, d.day, hm.$1, hm.$2);
  }

  /// Uykunun bitişi. Bitiş başlangıçtan önceyse (gece yarısını geçen kayıt,
  /// ör. 22:00 → 00:00) ertesi güne kayar. "24:00" da ertesi gün 00:00'dır.
  DateTime? get endAt {
    final start = startAt;
    final d = day;
    if (start == null || d == null) return null;
    final raw = endTime.trim();
    final is24 = raw.startsWith('24:');
    final hm = is24 ? (0, 0) : parseHourMinute(raw);
    if (hm == null) return null;
    var end = DateTime(d.year, d.month, d.day, hm.$1, hm.$2);
    if (is24 || end.isBefore(start)) {
      end = DateTime(d.year, d.month, d.day + 1, hm.$1, hm.$2);
    }
    return end;
  }

  /// Kaydın süresi (dakika); saatler okunamazsa 0.
  int get durationMinutes {
    final s = startAt;
    final e = endAt;
    if (s == null || e == null) return 0;
    final diff = e.difference(s).inMinutes;
    return diff < 0 ? 0 : diff;
  }
}

/// Bir veya birden fazla [SleepModel] kaydından oluşan tek uyku.
///
/// Gece yarısını geçen uykular kaydedilirken iki kayda bölünür
/// ([start → 00:00] ve ertesi gün [00:00 → bitiş]); sayım ve ortalamalarda
/// bunlar tek uyku olarak ele alınmalıdır.
class SleepSession {
  SleepSession(this.segments) : assert(segments.isNotEmpty);

  /// Kronolojik parçalar (çoğunlukla tek eleman).
  final List<SleepModel> segments;

  SleepModel get first => segments.first;
  SleepModel get last => segments.last;

  DateTime? get start => first.startAt;
  DateTime? get end => last.endAt;

  int get durationMinutes =>
      segments.fold<int>(0, (sum, s) => sum + s.durationMinutes);

  bool get isMerged => segments.length > 1;
}

/// Kayıtları başlangıca göre sıralar ve gece yarısında bölünmüş ardışık
/// parçaları (biri 00:00'da biter, sonraki ertesi gün 00:00'da başlar) tek
/// [SleepSession]'da birleştirir. Saati okunamayan kayıtlar tek başına
/// oturum olarak sona eklenir.
List<SleepSession> mergeSleepSessions(Iterable<SleepModel> sleeps) {
  final timed = <SleepModel>[];
  final untimed = <SleepModel>[];
  for (final s in sleeps) {
    (s.startAt == null || s.endAt == null ? untimed : timed).add(s);
  }
  timed.sort((a, b) => a.startAt!.compareTo(b.startAt!));

  final sessions = <List<SleepModel>>[];
  for (final s in timed) {
    if (sessions.isNotEmpty) {
      final prevEnd = sessions.last.last.endAt!;
      final start = s.startAt!;
      final continuesAtMidnight =
          start.hour == 0 &&
          start.minute == 0 &&
          prevEnd.isAtSameMomentAs(start);
      if (continuesAtMidnight) {
        sessions.last.add(s);
        continue;
      }
    }
    sessions.add([s]);
  }

  return [
    for (final parts in sessions) SleepSession(parts),
    for (final s in untimed) SleepSession([s]),
  ];
}
