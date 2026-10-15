import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/utils/date_range.dart';

// Tarih yardımcıları artık ortak; eski importlar kırılmasın diye yeniden dışa aktarılıyor.
export 'package:mama_meow/utils/date_range.dart' show DateParts;

/// Emzirme kayıtları servisi: `nursing/<uid>/<epochMsKey>`.
class NursingService extends ActivityStore<NursingModel> {
  NursingService() : super('nursing', analyticsName: 'nursing');

  @override
  Map<String, dynamic> encode(NursingModel item) => item.toMap();

  @override
  NursingModel decode(String key, Map<String, dynamic> map) =>
      NursingModel.fromMap(ActivityStore.withCreatedAtFromKey(key, map));

  Future<void> addNursing(NursingModel nursing) => addRecord(nursing);

  /// Belirli bir tarih aralığındaki emzirmeleri getir (anahtar = epoch ms)
  Future<List<NursingModel>> getUserNursingsInRange(
    DateTime start,
    DateTime end,
  ) => recordsInRange(start, end);

  /// Günlük
  Future<List<NursingModel>> todayNursings() =>
      recordsForPeriod(ReportPeriod.today);

  /// Haftalık (TR: Pazartesi başlangıç)
  Future<List<NursingModel>> weekNursings() =>
      recordsForPeriod(ReportPeriod.week);

  /// Aylık
  Future<List<NursingModel>> monthNursings() =>
      recordsForPeriod(ReportPeriod.month);

  /// Bugünkü emzirme sayısı (oturum ve gün değişimine duyarlı stream)
  Stream<int> todayNursingCountStream() => todayCountStream();
}

final NursingService nursingService = NursingService();
