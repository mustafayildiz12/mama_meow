import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/utils/date_range.dart';

// Tarih yardımcıları artık ortak; eski importlar kırılmasın diye yeniden dışa aktarılıyor.
export 'package:mama_meow/utils/date_range.dart' show DateParts;

/// Süt sağma kayıtları: `pumpings/<uid>/<epochMsKey>`.
class PumpingService extends ActivityStore<PumpingModel> {
  PumpingService() : super('pumpings', analyticsName: 'pumping');

  @override
  Map<String, dynamic> encode(PumpingModel item) => item.toMap();

  @override
  PumpingModel decode(String key, Map<String, dynamic> map) =>
      PumpingModel.fromMap(ActivityStore.withCreatedAtFromKey(key, map));

  Future<void> addPumping(PumpingModel pumping) => addRecord(pumping);

  /// Belirli tarih aralığı (key = epoch ms)
  Future<List<PumpingModel>> getUserPumpingsInRange(
    DateTime start,
    DateTime end,
  ) => recordsInRange(start, end);

  Future<List<PumpingModel>> todayPumpings() =>
      recordsForPeriod(ReportPeriod.today);

  Future<List<PumpingModel>> weekPumpings() =>
      recordsForPeriod(ReportPeriod.week);

  Future<List<PumpingModel>> monthPumpings() =>
      recordsForPeriod(ReportPeriod.month);

  /// Bugünkü kayıt sayısı (oturum ve gün değişimine duyarlı stream)
  Stream<int> todayPumpingCountStream() => todayCountStream();
}

final PumpingService pumpingService = PumpingService();
