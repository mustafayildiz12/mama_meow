import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/utils/date_range.dart';

class SolidReportComputed {
  /// Toplam miktar; ondalıklı miktarlar ("1.5") korunur.
  final num totalAmount;
  final int mealCount;
  final String lastEatTime;

  final Map<String, num> distEatHourAmount; // "00".."23" -> amount
  final Map<String, num> byFoodAmount; // solidName -> amount
  final Map<String, int> reactionCounts; // reactionText -> count

  SolidReportComputed({
    required this.totalAmount,
    required this.mealCount,
    required this.lastEatTime,
    required this.distEatHourAmount,
    required this.byFoodAmount,
    required this.reactionCounts,
  });

  /// Kayıtlardan rapor metrikleri. Miktar [SolidModel.amountValue] ile okunur
  /// ("1.5" → 1.5); saat dağılımı ve "son öğün" kullanıcının seçtiği yeme
  /// saatine göredir.
  factory SolidReportComputed.fromSolids(List<SolidModel> solids) {
    num total = 0;
    final byHour = <int, num>{};
    final byFood = <String, num>{};
    final byReaction = <String, int>{};

    DateTime? latest;
    var lastEatTime = '-';

    for (final s in solids) {
      final amt = s.amountValue ?? 0;
      total += amt;

      final hour = parseHourMinute(s.eatTime)?.$1 ?? s.eventAt?.hour ?? 0;
      byHour[hour] = (byHour[hour] ?? 0) + amt;

      final food = s.solidName.trim().isEmpty ? 'unknown' : s.solidName.trim();
      byFood[food] = (byFood[food] ?? 0) + amt;

      final rx = s.reactions == null ? 'none' : reactionToText(s.reactions!);
      byReaction[rx] = (byReaction[rx] ?? 0) + 1;

      final at = s.eventAt;
      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
        lastEatTime = s.eatTime;
      }
    }

    return SolidReportComputed(
      totalAmount: total,
      mealCount: solids.length,
      lastEatTime: lastEatTime,
      distEatHourAmount: {
        for (var h = 0; h < 24; h++)
          h.toString().padLeft(2, '0'): byHour[h] ?? 0,
      },
      byFoodAmount: byFood,
      reactionCounts: byReaction,
    );
  }
}
