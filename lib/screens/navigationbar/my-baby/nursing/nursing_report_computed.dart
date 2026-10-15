import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/utils/date_range.dart';

class NursingReportComputed {
  final int sessionCount;
  final int totalDuration; // minutes
  final int avgDuration; // minutes
  final String lastTimeLabel;

  final Map<String, int> distHourCount; // "00".."23" -> count
  final Map<String, int> sideCounts; // left/right -> count
  final Map<String, int> feedingTypeCounts; // nursing/bottle -> count
  final Map<String, int> milkTypeCounts; // breast milk/formula -> count
  final Map<String, double> amountTypeTotals; // ml/oz -> total

  /// Kayıt bazlı kesin metrikler (taraf dakikaları, süt türüne göre hacim,
  /// beslenme aralığı). [NursingReportComputed.fromNursings] doldurur; elle
  /// kurulan nesnelerde null olabilir.
  final NursingExactStats? exact;

  NursingReportComputed({
    required this.sessionCount,
    required this.totalDuration,
    required this.avgDuration,
    required this.lastTimeLabel,
    required this.distHourCount,
    required this.sideCounts,
    required this.feedingTypeCounts,
    required this.milkTypeCounts,
    required this.amountTypeTotals,
    this.exact,
  });

  /// Kayıtlardan tüm rapor metriklerini hesaplar.
  ///
  /// - Saat dağılımı ve "son" kayıt kullanıcının seçtiği saate göredir.
  /// - [avgDuration] yalnızca süresi > 0 olan oturumların ortalamasıdır
  ///   (süresiz biberon kayıtları ortalamayı düşürmez).
  factory NursingReportComputed.fromNursings(List<NursingModel> nursings) {
    final byHourRaw = <int, int>{};
    final bySide = <String, int>{};
    final byFeedingType = <String, int>{};
    final byMilkType = <String, int>{};
    final byAmountType = <String, double>{};

    var totalDuration = 0;
    var timedSessions = 0;
    DateTime? latest;
    var lastTimeLabel = '-';

    String norm(String s) => s.trim().toLowerCase();

    for (final n in nursings) {
      final hour = parseHourMinute(n.startTime)?.$1 ?? n.eventAt?.hour ?? 0;
      byHourRaw[hour] = (byHourRaw[hour] ?? 0) + 1;

      bySide[norm(n.side)] = (bySide[norm(n.side)] ?? 0) + 1;
      byFeedingType[norm(n.feedingType)] =
          (byFeedingType[norm(n.feedingType)] ?? 0) + 1;

      final milk = n.milkType;
      if (milk != null) {
        byMilkType[norm(milk)] = (byMilkType[norm(milk)] ?? 0) + 1;
      }

      byAmountType[n.amountType] =
          (byAmountType[n.amountType] ?? 0) + n.amount.toDouble();

      totalDuration += n.duration;
      if (n.duration > 0) timedSessions++;

      final at = n.eventAt;
      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
        lastTimeLabel = n.startTime;
      }
    }

    return NursingReportComputed(
      sessionCount: nursings.length,
      totalDuration: totalDuration,
      avgDuration: timedSessions == 0
          ? 0
          : (totalDuration / timedSessions).round(),
      lastTimeLabel: lastTimeLabel,
      distHourCount: {
        for (var h = 0; h < 24; h++)
          h.toString().padLeft(2, '0'): byHourRaw[h] ?? 0,
      },
      sideCounts: bySide,
      feedingTypeCounts: byFeedingType,
      milkTypeCounts: byMilkType,
      amountTypeTotals: byAmountType,
      exact: NursingExactStats.fromNursings(nursings),
    );
  }
}

/// Emzirme kayıtlarından kayıt bazlı (tahminsiz) metrikler.
class NursingExactStats {
  /// Emzirme (nursing) oturumlarında sol/sağ toplam dakika.
  final int leftMinutes;
  final int rightMinutes;

  /// Yalnızca süresi > 0 olan emzirme oturumlarının ortalaması (dakika).
  final int avgNursingDurationMins;

  /// Hacimler ml cinsinden (oz → ml dönüştürülmüş).
  final double totalVolumeMl;
  final double breastMilkMl;
  final double formulaMl;
  final double otherMilkMl;

  /// Ardışık beslenmeler arası ortalama süre (saat, 1 ondalık);
  /// 2'den az beslenmede null.
  final double? avgIntervalHours;

  const NursingExactStats({
    required this.leftMinutes,
    required this.rightMinutes,
    required this.avgNursingDurationMins,
    required this.totalVolumeMl,
    required this.breastMilkMl,
    required this.formulaMl,
    required this.otherMilkMl,
    required this.avgIntervalHours,
  });

  factory NursingExactStats.fromNursings(List<NursingModel> nursings) {
    var left = 0;
    var right = 0;
    var nursingMinutes = 0;
    var nursingTimed = 0;
    var total = 0.0;
    var breast = 0.0;
    var formula = 0.0;
    final times = <DateTime>[];

    for (final n in nursings) {
      if (!n.isBottle && n.duration > 0) {
        nursingMinutes += n.duration;
        nursingTimed++;
        switch (n.side.trim().toLowerCase()) {
          case 'left':
            left += n.duration;
          case 'right':
            right += n.duration;
        }
      }

      final ml = n.amountMl;
      if (ml > 0) {
        total += ml;
        final milk = (n.milkType ?? '').trim().toLowerCase();
        if (milk.contains('breast')) {
          breast += ml;
        } else if (milk.contains('formula')) {
          formula += ml;
        }
      }

      final at = n.eventAt;
      if (at != null) times.add(at);
    }

    times.sort();
    double? avgInterval;
    if (times.length >= 2) {
      final spanMinutes = times.last.difference(times.first).inMinutes;
      final avgMin = spanMinutes / (times.length - 1);
      avgInterval = double.parse((avgMin / 60).toStringAsFixed(1));
    }

    return NursingExactStats(
      leftMinutes: left,
      rightMinutes: right,
      avgNursingDurationMins: nursingTimed == 0
          ? 0
          : (nursingMinutes / nursingTimed).round(),
      totalVolumeMl: total,
      breastMilkMl: breast,
      formulaMl: formula,
      otherMilkMl: (total - breast - formula).clamp(0.0, double.infinity),
      avgIntervalHours: avgInterval,
    );
  }
}
