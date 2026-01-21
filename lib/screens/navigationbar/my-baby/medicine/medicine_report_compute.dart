class MedicineReportComputed {
  final int totalCount;
  final int uniqueMedicineCount;
  final String lastTimeLabel;

  final Map<String, int> distHourCount;        // "00".."23" -> count
  final Map<String, int> medicineCounts;       // name -> count
  final Map<String, double> amountTypeTotals;  // "ml/oz/..." -> total amount

  final List<MedicineDetail> details;

  MedicineReportComputed({
    required this.totalCount,
    required this.uniqueMedicineCount,
    required this.lastTimeLabel,
    required this.distHourCount,
    required this.medicineCounts,
    required this.amountTypeTotals,
    required this.details,
  });
}

class MedicineDetail {
  final String name;
  final String time; // HH:mm
  final int amount;
  final String amountType;
  final String createdAt;

  MedicineDetail({
    required this.name,
    required this.time,
    required this.amount,
    required this.amountType,
    required this.createdAt,
  });
}
