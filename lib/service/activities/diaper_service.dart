import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/utils/date_range.dart';

// Tarih yardımcıları artık ortak; eski importlar kırılmasın diye yeniden dışa aktarılıyor.
export 'package:mama_meow/utils/date_range.dart' show DateParts;

/// Bez kayıtları: `diapers/<uid>/<epochMsKey>`.
class DiaperService extends ActivityStore<DiaperModel> {
  DiaperService() : super('diapers', analyticsName: 'diaper');

  @override
  Map<String, dynamic> encode(DiaperModel item) => item.toMap();

  @override
  DiaperModel decode(String key, Map<String, dynamic> map) =>
      DiaperModel.fromMap(ActivityStore.withCreatedAtFromKey(key, map));

  Future<void> addDiaper(DiaperModel diaper) => addRecord(diaper);

  /// Belirli bir tarih aralığındaki diaper kayıtları (anahtar = epoch ms)
  Future<List<DiaperModel>> getUserDiapersInRange(
    DateTime start,
    DateTime end,
  ) => recordsInRange(start, end);

  /// Günlük
  Future<List<DiaperModel>> todayDiapers() =>
      recordsForPeriod(ReportPeriod.today);

  /// Haftalık (TR: Pazartesi başlangıç)
  Future<List<DiaperModel>> weekDiapers() =>
      recordsForPeriod(ReportPeriod.week);

  /// Aylık
  Future<List<DiaperModel>> monthDiapers() =>
      recordsForPeriod(ReportPeriod.month);

  /// Bugünkü kayıt sayısı (oturum ve gün değişimine duyarlı stream)
  Stream<int> todayDiaperCountStream() => todayCountStream();
}

final DiaperService diaperService = DiaperService();
