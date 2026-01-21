class NursingReportComputed {
  final int sessionCount;
  final int totalDuration; // minutes
  final int avgDuration; // minutes
  final String lastTimeLabel;

  final Map<String, int> distHourCount; // "00".."23" -> count
  final Map<String, int> sideCounts; // left/right -> count
  final Map<String, int> feedingTypeCounts; // nursing/bottle -> count
  final Map<String, int> milkTypeCounts; // breastmilk/formula -> count
  final Map<String, double> amountTypeTotals; // ml/oz -> total

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
  });
}
