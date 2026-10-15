import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/utils/date_range.dart';

class MedicineReportComputed {
  final int totalCount;
  final int uniqueMedicineCount;
  final String lastTimeLabel;

  final Map<String, int> distHourCount; // "00".."23" -> count
  final Map<String, int> medicineCounts; // name -> count
  final Map<String, double> amountTypeTotals; // "ml/oz/..." -> total amount

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

  /// Kayıtlardan rapor metrikleri. Saat dağılımı ve "son doz" kullanıcının
  /// seçtiği saate (`startTime`) göredir; [details] kronolojik sıralıdır.
  factory MedicineReportComputed.fromMedicines(List<MedicineModel> medicines) {
    final byHourRaw = <int, int>{};
    final byMedicine = <String, int>{};
    final byAmountType = <String, double>{};
    final details = <(DateTime?, MedicineDetail)>[];

    var lastTime = '-';
    DateTime? latest;

    for (final m in medicines) {
      final at = m.eventAt;
      final hour = parseHourMinute(m.startTime)?.$1 ?? at?.hour ?? 0;
      byHourRaw[hour] = (byHourRaw[hour] ?? 0) + 1;

      final nameKey = m.medicineName.trim().toLowerCase();
      byMedicine[nameKey] = (byMedicine[nameKey] ?? 0) + 1;

      byAmountType[m.amountType] =
          (byAmountType[m.amountType] ?? 0) + m.amount.toDouble();

      final time = medicineDisplayTime(m);
      details.add((
        at,
        MedicineDetail(
          name: m.medicineName,
          time: time,
          amount: m.amount,
          amountType: m.amountType,
          createdAt: m.createdAt,
        ),
      ));

      if (at != null && (latest == null || at.isAfter(latest))) {
        latest = at;
        lastTime = time;
      }
    }

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    details.sort((a, b) => (a.$1 ?? epoch).compareTo(b.$1 ?? epoch));

    return MedicineReportComputed(
      totalCount: medicines.length,
      uniqueMedicineCount: byMedicine.length,
      lastTimeLabel: lastTime,
      distHourCount: {
        for (var h = 0; h < 24; h++)
          h.toString().padLeft(2, '0'): byHourRaw[h] ?? 0,
      },
      medicineCounts: byMedicine,
      amountTypeTotals: byAmountType,
      details: [for (final d in details) d.$2],
    );
  }
}

class MedicineDetail {
  final String name;
  final String time; // HH:mm

  /// Doz miktarı (int veya ondalıklı).
  final num amount;
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

/// Gösterilecek saat: kullanıcının seçtiği "HH:mm", yoksa kaydetme saati.
String medicineDisplayTime(MedicineModel m) {
  final t = m.startTime.trim();
  if (t.isNotEmpty) return t;
  final at = m.eventAt;
  return at != null ? DateFormat('HH:mm').format(at) : '-';
}
