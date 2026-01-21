class DiaperReportComputed {
  final int totalCount;
  final String lastChangeLabel; // "HH:mm" or "-"
  final int avgGapMinutes;
  final int maxGapMinutes;

  final Map<String, int> distHourCount; // "00".."23" -> count
  final Map<String, int> typeCounts; // wet/poop/mixed/pee/other/dry

  final List<DiaperDetail> timeline; // chronological

  DiaperReportComputed({
    required this.totalCount,
    required this.lastChangeLabel,
    required this.avgGapMinutes,
    required this.maxGapMinutes,
    required this.distHourCount,
    required this.typeCounts,
    required this.timeline,
  });
}

class DiaperDetail {
  final String time; // HH:mm
  final String label; // diaperName
  final String createdAt; // ISO

  DiaperDetail({
    required this.time,
    required this.label,
    required this.createdAt,
  });
}
