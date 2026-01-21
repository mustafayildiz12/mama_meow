import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/pumping_report_page.dart';

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
  static PumpingReportComputed compute({
    required List<PumpingModel> pumpings,
    required PumpingReportMode mode,
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

    // sort by createdAt (fallback)
    final sorted = [...pumpings]
      ..sort((a, b) {
        final aDt =
            DateTime.tryParse(a.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDt =
            DateTime.tryParse(b.createdAt) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDt.compareTo(bDt);
      });

    final sessions = pumpings.length;

    int totalMinutes = 0;
    int leftMinutes = 0;
    int rightMinutes = 0;

    final minutesByHour = <int, int>{for (int i = 0; i < 24; i++) i: 0};

    for (final p in pumpings) {
      totalMinutes += p.duration;

      if (p.isLeft) {
        leftMinutes += p.duration;
      } else {
        rightMinutes += p.duration;
      }

      final dt = DateTime.tryParse(p.createdAt);
      final hour = dt?.hour ?? int.tryParse(p.startTime.split(':').first) ?? 0;
      final h = (hour < 0 || hour > 23) ? 0 : hour;

      minutesByHour[h] = (minutesByHour[h] ?? 0) + p.duration;
    }

    final avgSessionMinutes = sessions == 0
        ? 0
        : (totalMinutes / sessions).round();

    // last session time
    String lastSessionTime = '-';
    final last = sorted.last;
    final lastDt = DateTime.tryParse(last.createdAt);
    lastSessionTime = lastDt != null
        ? DateFormat('HH:mm').format(lastDt)
        : last.startTime;

    // longest gap hours (between createdAt)
    double longestGapHours = 0;
    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.tryParse(sorted[i - 1].createdAt);
      final cur = DateTime.tryParse(sorted[i].createdAt);
      if (prev == null || cur == null) continue;
      final gap = cur.difference(prev).inMinutes.abs() / 60.0;
      if (gap > longestGapHours) longestGapHours = gap;
    }

    // frequency per day (rough by period)
    final days = switch (mode) {
      PumpingReportMode.today => 1.0,
      PumpingReportMode.week => 7.0,
      PumpingReportMode.month => 30.0, // basit yaklaşım
    };
    final frequencyPerDay = sessions / days;

    // most frequent time block (4 block)
    // 05-09, 09-13, 13-17, 17-21, 21-05 (night)
    int sumBlock(int start, int endExclusive) {
      int s = 0;
      for (int h = start; h < endExclusive; h++) {
        s += (minutesByHour[h] ?? 0);
      }
      return s;
    }

    final blocks = <String, int>{
      "05:00 - 09:00": sumBlock(5, 9),
      "09:00 - 13:00": sumBlock(9, 13),
      "13:00 - 17:00": sumBlock(13, 17),
      "17:00 - 21:00": sumBlock(17, 21),
      "21:00 - 05:00": (sumBlock(21, 24) + sumBlock(0, 5)),
    };

    final mostFrequentTime = blocks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostTimeLabel = mostFrequentTime.isEmpty
        ? "-"
        : mostFrequentTime.first.key;

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

  /// ✅ AI’ya gidecek optimize payload
  static Map<String, dynamic> buildAiPayload({
    required PumpingReportMode mode,
    required PumpingReportComputed c,
    List<String> notes = const [],
    String periodLabel = '',
  }) {
    String modeText = switch (mode) {
      PumpingReportMode.today => "Daily",
      PumpingReportMode.week => "Weekly",
      PumpingReportMode.month => "Monthly",
    };

    return {
      "period": modeText,
      "rangeLabel": periodLabel,
      "sessions": c.sessions,
      "stats": {
        "totalMinutes": c.totalMinutes,
        "avgSessionTime": c.avgSessionMinutes,
        "sides": {"leftMinutes": c.leftMinutes, "rightMinutes": c.rightMinutes},
        "frequencyPerDay": c.frequencyPerDay,
      },
      "patterns": {
        "mostFrequentTime": c.mostFrequentTime,
        "longestGapHours": c.longestGapHours,
      },
      "notes": notes,
    };
  }
}
