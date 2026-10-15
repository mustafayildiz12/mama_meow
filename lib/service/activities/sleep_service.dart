import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/activities/sleep_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/utils/date_range.dart';

// Tarih yardımcıları artık ortak; eski importlar kırılmasın diye yeniden dışa aktarılıyor.
export 'package:mama_meow/utils/date_range.dart' show DateParts;

/// Uyku kayıtları: `sleeps/<uid>/<epochMsKey>`.
class SleepService extends ActivityStore<SleepModel> {
  SleepService() : super('sleeps', analyticsName: 'sleep');

  @override
  Map<String, dynamic> encode(SleepModel item) => item.toJson();

  @override
  SleepModel decode(String key, Map<String, dynamic> map) =>
      SleepModel.fromJson(map);

  /// Kaydı ekler. Gece yarısını geçen uykular iki kayıt olarak art arda
  /// eklenir; anahtarlar çakışmaz (bkz. [ActivityRtdb.nextKey]).
  Future<void> addSleep(SleepModel sleepModel) => addRecord(sleepModel);

  /// Belirli bir tarih aralığındaki sleep'leri getirir (anahtar = epoch ms)
  Future<List<SleepModel>> getUserSleepsInRange(DateTime start, DateTime end) =>
      recordsInRange(start, end);

  /// Günlük
  Future<List<SleepModel>> todaySleeps() =>
      recordsForPeriod(ReportPeriod.today);

  /// Haftalık (TR: Pazartesi başlangıç)
  Future<List<SleepModel>> weekSleeps() => recordsForPeriod(ReportPeriod.week);

  /// Aylık
  Future<List<SleepModel>> monthSleeps() =>
      recordsForPeriod(ReportPeriod.month);

  /// Gece yarısında ikiye bölünmüş uyku tek uyku sayılır.
  @override
  int countSnapshot(DataSnapshot snapshot) =>
      mergeSleepSessions(decodeChildren(snapshot)).length;

  /// Bugünkü uyku sayısı (oturum ve gün değişimine duyarlı stream);
  /// bölünmüş gece uykuları tek sayılır.
  Stream<int> todaySleepCountStream() => todayCountStream();
}

final SleepService sleepService = SleepService();
