import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/utils/date_range.dart';

// Tarih yardımcıları artık ortak; eski importlar kırılmasın diye yeniden dışa aktarılıyor.
export 'package:mama_meow/utils/date_range.dart' show DateParts;

/// İlaç kayıtları: `medicine/<uid>/<epochMsKey>`.
class MedicineService extends ActivityStore<MedicineModel> {
  MedicineService() : super('medicine', analyticsName: 'medicine');

  @override
  Map<String, dynamic> encode(MedicineModel item) => item.toMap();

  @override
  MedicineModel decode(String key, Map<String, dynamic> map) =>
      MedicineModel.fromMap(ActivityStore.withCreatedAtFromKey(key, map));

  Future<void> addMedicine(MedicineModel medicine) => addRecord(medicine);

  /// Belirli tarih aralığı (Realtime DB key=epoch ms)
  Future<List<MedicineModel>> getUserMedicinesInRange(
    DateTime start,
    DateTime end,
  ) => recordsInRange(start, end);

  Future<List<MedicineModel>> todayMedicines() =>
      recordsForPeriod(ReportPeriod.today);

  Future<List<MedicineModel>> weekMedicines() =>
      recordsForPeriod(ReportPeriod.week);

  Future<List<MedicineModel>> monthMedicines() =>
      recordsForPeriod(ReportPeriod.month);

  /// Bugünkü kayıt sayısı (oturum ve gün değişimine duyarlı stream)
  Stream<int> todayMedicineCountStream() => todayCountStream();
}

final MedicineService medicineService = MedicineService();
