import 'package:mama_meow/models/activities/solid_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';

// Tarih yardımcıları artık ortak; eski importlar kırılmasın diye yeniden dışa aktarılıyor.
export 'package:mama_meow/utils/date_range.dart' show DateParts;

/// Ek gıda (solid) kayıtları: `solids/<uid>/<epochMsKey>`.
class SolidService extends ActivityStore<SolidModel> {
  SolidService() : super('solids', analyticsName: 'solid');

  @override
  Map<String, dynamic> encode(SolidModel item) => item.toMap();

  @override
  SolidModel decode(String key, Map<String, dynamic> map) =>
      SolidModel.fromMap(ActivityStore.withCreatedAtFromKey(key, map));

  /// Kaydı ekler. Çoklu yiyecek art arda kaydedildiğinde anahtarlar çakışmaz
  /// (bkz. [ActivityRtdb.nextKey]).
  Future<void> addSolid(SolidModel solid) => addRecord(solid);

  /// Kullanıcının tüm solid kayıtları (aralıksız okuma).
  Future<List<SolidModel>> getUserSolidList() => allRecords();

  /// Belirli bir tarih aralığındaki solid'leri getirir (anahtar = epoch ms)
  Future<List<SolidModel>> getUserSolidsInRange(DateTime start, DateTime end) =>
      recordsInRange(start, end);

  /// Bugünkü kayıt sayısı (oturum ve gün değişimine duyarlı stream)
  Stream<int> todaySolidCountStream() => todayCountStream();
}

final SolidService solidService = SolidService();
