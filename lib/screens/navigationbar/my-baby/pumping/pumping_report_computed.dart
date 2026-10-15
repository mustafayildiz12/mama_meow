import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/utils/date_range.dart';

class PumpingReportComputed {
  final int sessions;
  final int totalMinutes;
  final int avgSessionMinutes;

  final int leftMinutes;
  final int rightMinutes;

  final double frequencyPerDay;
  final double longestGapHours;

  final String mostFrequentTime; // "05:00 - 09:00"
  final String lastSessionTime; // "HH:mm" veya "-"

  final Map<int, int> minutesByHour; // 0..23 -> total minutes

  const PumpingReportComputed({
    required this.sessions,
    required this.totalMinutes,
    required this.avgSessionMinutes,
    required this.leftMinutes,
    required this.rightMinutes,
    required this.frequencyPerDay,
    required this.longestGapHours,
    required this.mostFrequentTime,
    required this.lastSessionTime,
    required this.minutesByHour,
  });
}

class PumpingAiCompute {
  /// Rapor metrikleri. Saat dağılımı, aralıklar ve "son seans" kullanıcının
  /// seçtiği başlangıç saatine göredir (`createdAt` kaydetme anıdır).
  /// Günlük sıklık, dönemin bugüne kadar geçen gün sayısına bölünür.
  static PumpingReportComputed compute({
    required List<PumpingModel> pumpings,
    required ReportPeriod mode,
    DateTime? now,
  }) {
    if (pumpings.isEmpty) {
      return const PumpingReportComputed(
        sessions: 0,
        totalMinutes: 0,
        avgSessionMinutes: 0,
        leftMinutes: 0,
        rightMinutes: 0,
        frequencyPerDay: 0,
        longestGapHours: 0,
        mostFrequentTime: "-",
        lastSessionTime: "-",
        minutesByHour: {},
      );
    }

    final sessions = pumpings.length;

    var totalMinutes = 0;
    var leftMinutes = 0;
    var rightMinutes = 0;
    final minutesByHour = <int, int>{for (var i = 0; i < 24; i++) i: 0};
    final times = <DateTime>[];
    PumpingModel? lastPumping;
    DateTime? lastAt;

    for (final p in pumpings) {
      totalMinutes += p.duration;
      if (p.isLeft) {
        leftMinutes += p.duration;
      } else {
        rightMinutes += p.duration;
      }

      final at = p.eventAt;
      final hour = at?.hour ?? parseHourMinute(p.startTime)?.$1 ?? 0;
      minutesByHour[hour] = (minutesByHour[hour] ?? 0) + p.duration;

      if (at != null) {
        times.add(at);
        if (lastAt == null || at.isAfter(lastAt)) {
          lastAt = at;
          lastPumping = p;
        }
      }
    }

    final avgSessionMinutes = (totalMinutes / sessions).round();

    // last session time (kullanıcının seçtiği saat)
    final lastSessionTime = lastAt != null
        ? DateFormat('HH:mm').format(lastAt)
        : (lastPumping?.startTime ?? pumpings.last.startTime);

    // longest gap hours (ardışık seanslar arası)
    times.sort();
    var longestGapHours = 0.0;
    for (var i = 1; i < times.length; i++) {
      final gap = times[i].difference(times[i - 1]).inMinutes / 60.0;
      if (gap > longestGapHours) longestGapHours = gap;
    }

    // frequency per day: dönemin bugüne kadar geçen günü
    final days = DateRange.forPeriod(mode, now: now).elapsedDays(now: now);
    final frequencyPerDay = sessions / days;

    // most frequent time block
    int sumBlock(int start, int endExclusive) {
      var s = 0;
      for (var h = start; h < endExclusive; h++) {
        s += minutesByHour[h] ?? 0;
      }
      return s;
    }

    final blocks = <String, int>{
      "05:00 - 09:00": sumBlock(5, 9),
      "09:00 - 13:00": sumBlock(9, 13),
      "13:00 - 17:00": sumBlock(13, 17),
      "17:00 - 21:00": sumBlock(17, 21),
      "21:00 - 05:00": sumBlock(21, 24) + sumBlock(0, 5),
    };
    final mostTimeLabel = blocks.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;

    return PumpingReportComputed(
      sessions: sessions,
      totalMinutes: totalMinutes,
      avgSessionMinutes: avgSessionMinutes,
      leftMinutes: leftMinutes,
      rightMinutes: rightMinutes,
      frequencyPerDay: double.parse(frequencyPerDay.toStringAsFixed(1)),
      longestGapHours: double.parse(longestGapHours.toStringAsFixed(1)),
      mostFrequentTime: mostTimeLabel,
      lastSessionTime: lastSessionTime,
      minutesByHour: minutesByHour,
    );
  }
}
