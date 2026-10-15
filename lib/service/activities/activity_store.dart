import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/date_range.dart';
import 'package:rxdart/rxdart.dart';

/// Aktivite kayıtları için ortak RTDB yardımcıları: anahtar üretimi, offline
/// dayanıklı yazma, hata loglama ve "bugün" sayaç stream'i.
abstract final class ActivityRtdb {
  static int _lastKeyMs = 0;

  /// Yeni kayıt anahtarı: 13 haneli epoch-ms metni.
  ///
  /// Aynı milisaniyede art arda kaydedilen kayıtlar (çoklu mama, gece yarısında
  /// bölünen uyku) birbirinin üzerine yazılmasın diye süreç içinde kesin
  /// artandır. Rapor sorguları `orderByKey().startAt/endAt` ile çalıştığı için
  /// format değişmez.
  static String nextKey() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastKeyMs = math.max(now, _lastKeyMs + 1);
    return _lastKeyMs.toString();
  }

  /// Offline'da yazmanın "kuyruğa alındı" sayılacağı süre.
  static const Duration offlineWriteTimeout = Duration(seconds: 4);

  /// RTDB yazmasını ([DatabaseReference.set]/`update`/`remove`) bekler.
  ///
  /// Disk persistence açıkken bu future'lar ancak sunucu onayıyla tamamlanır;
  /// offline'da ekleme sayfaları sonsuza kadar bekler. Yazma yerelde
  /// kalıcılaştırılıp bağlantı gelince senkronlandığı için zaman aşımı başarı
  /// sayılır. Zaman aşımından önce gelen gerçek hatalar (ör. permission-denied)
  /// fırlatılır, sonra gelenler loglanır.
  static Future<void> write(
    Future<void> operation, {
    required String label,
  }) async {
    try {
      await operation.timeout(offlineWriteTimeout);
    } on TimeoutException {
      developer.log(
        'RTDB write queued until reconnect: $label',
        name: 'ActivityRtdb',
      );
      unawaited(
        operation.catchError((Object e, StackTrace st) {
          reportNonFatal(e, st, reason: 'Queued RTDB write failed: $label');
        }),
      );
    }
  }

  /// Konsola ve Crashlytics'e (non-fatal) loglar; asla fırlatmaz.
  static void reportNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) {
    developer.log(
      reason,
      name: 'ActivityRtdb',
      error: error,
      stackTrace: stackTrace,
    );
    if (kIsWeb) return; // Crashlytics web'i desteklemiyor.
    try {
      unawaited(
        FirebaseCrashlytics.instance
            .recordError(error, stackTrace, reason: reason, fatal: false)
            .catchError((Object _) {}),
      );
    } catch (_) {
      // Firebase henüz hazır değilse sessizce geç.
    }
  }

  /// `<rootPath>/<uid>` altında bugünkü kayıt sayısı.
  ///
  /// - Oturum değişince (giriş/çıkış) yeniden bağlanır; misafirken 0 yayar.
  /// - Yerel gece yarısını geçince yeni günün aralığına geçer.
  /// - Yayın (broadcast) akışıdır: her dinleyici kendi RTDB dinleyicisini açar
  ///   ve aboneliğini iptal edince kapatır; `.asBroadcastStream()` gerekmez.
  ///
  /// [counter] snapshot'tan sayıyı üretir (varsayılan: çocuk sayısı).
  static Stream<int> todayCount(
    String rootPath, {
    int Function(DataSnapshot snapshot)? counter,
  }) => Rx.defer(
    () => FirebaseAuth.instance
        .authStateChanges()
        .map((user) => user?.uid)
        .distinct()
        .switchMap(
          (uid) => uid == null
              ? Stream<int>.value(0)
              : _localDays().switchMap(
                  (day) =>
                      _countBetween(rootPath, uid, day, day.endOfDay, counter),
                ),
        )
        .distinct(),
    reusable: true,
  );

  /// Bugünün başlangıcını yayar; gün değişince (dakikalık kontrol) yenisini.
  /// Uygulama arka plandan dönünce gecikmiş periyodik tetik hemen çalışır.
  static Stream<DateTime> _localDays() => Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now().startOfDay,
  ).startWith(DateTime.now().startOfDay).distinct();

  static Stream<int> _countBetween(
    String rootPath,
    String uid,
    DateTime start,
    DateTime end,
    int Function(DataSnapshot snapshot)? counter,
  ) {
    return FirebaseDatabase.instance
        .ref(rootPath)
        .child(uid)
        .orderByKey()
        .startAt(start.millisecondsSinceEpoch.toString())
        .endAt(end.millisecondsSinceEpoch.toString())
        .onValue
        .map(
          (event) => counter != null
              ? counter(event.snapshot)
              : event.snapshot.children.length,
        )
        .handleError((Object e, StackTrace st) {
          // Son değeri koru; geçici hatada sayaç 0'a düşmesin.
          reportNonFatal(e, st, reason: 'todayCount($rootPath) failed');
        });
  }
}

/// `<rootPath>/<uid>/<epochMsKey>` şeklinde tutulan aktivite kayıtları için
/// ortak okuma/yazma mantığı. Her aktivite servisi bunu genişletir ve eski
/// metot adlarını (ör. `addSleep`, `todaySleeps`) ince sarmalayıcı olarak
/// sunar.
abstract class ActivityStore<T> {
  ActivityStore(this.rootPath, {this.analyticsName});

  /// RTDB kök düğümü (ör. `sleeps`, `nursing`).
  final String rootPath;

  /// Kayıt eklenince analytics'e gönderilen aktivite adı.
  final String? analyticsName;

  /// Modeli RTDB'ye yazılacak Map'e çevirir.
  Map<String, dynamic> encode(T item);

  /// RTDB kaydını modele çevirir. Bozuk kayıtta fırlatabilir; çağıran taraf
  /// kaydı atlayıp loglar.
  T decode(String key, Map<String, dynamic> map);

  DatabaseReference? userRef() {
    final user = authenticationService.getUser();
    if (user == null) return null;
    return FirebaseDatabase.instance.ref(rootPath).child(user.uid);
  }

  /// Kaydı yeni bir epoch-ms anahtarıyla ekler. Giriş yapılmamışsa hiçbir şey
  /// yapmaz (eski davranış). Offline'da kısa bir beklemeden sonra döner.
  Future<void> addRecord(T item) async {
    final ref = userRef();
    if (ref == null) return;
    await ActivityRtdb.write(
      ref.child(ActivityRtdb.nextKey()).set(encode(item)),
      label: '$rootPath add',
    );
    final name = analyticsName;
    if (name != null) unawaited(analyticService.activityLogged(name));
  }

  /// `[start, end]` aralığındaki kayıtlar (anahtar = epoch ms).
  Future<List<T>> recordsInRange(DateTime start, DateTime end) async {
    final ref = userRef();
    if (ref == null) return [];
    final snap = await ref
        .orderByKey()
        .startAt(start.millisecondsSinceEpoch.toString())
        .endAt(end.millisecondsSinceEpoch.toString())
        .get();
    return decodeChildren(snap);
  }

  /// Rapor dönemindeki kayıtlar (Bugün / Hafta (Pzt-Paz) / Ay).
  Future<List<T>> recordsForPeriod(ReportPeriod period) {
    final range = DateRange.forPeriod(period);
    return recordsInRange(range.start, range.end);
  }

  /// Kullanıcının tüm kayıtları (aralıksız okuma).
  Future<List<T>> allRecords() async {
    final ref = userRef();
    if (ref == null) return [];
    return decodeChildren(await ref.get());
  }

  /// Bugünkü kayıt sayısı; bkz. [ActivityRtdb.todayCount].
  Stream<int> todayCountStream() =>
      ActivityRtdb.todayCount(rootPath, counter: countSnapshot);

  /// "Bugün" sayacının snapshot'tan sayısı; varsayılan kayıt sayısı.
  /// Alt sınıflar farklı sayım için ezebilir (ör. bölünmüş uykular).
  int countSnapshot(DataSnapshot snapshot) => snapshot.children.length;

  /// Snapshot çocuklarını tek tek çözer; bozuk kayıt tüm listeyi düşürmez,
  /// atlanır ve loglanır.
  List<T> decodeChildren(DataSnapshot snap) {
    final out = <T>[];
    for (final child in snap.children) {
      final value = child.value;
      if (value is! Map) continue;
      final key = child.key ?? '';
      try {
        out.add(decode(key, Map<String, dynamic>.from(value)));
      } catch (e, st) {
        ActivityRtdb.reportNonFatal(
          e,
          st,
          reason: 'Skipped malformed $rootPath record ($key)',
        );
      }
    }
    return out;
  }

  /// `createdAt` yoksa/boşsa anahtardan (epoch ms) yerel ISO zaman üretir.
  static Map<String, dynamic> withCreatedAtFromKey(
    String key,
    Map<String, dynamic> map,
  ) {
    final current = map['createdAt'];
    if (current != null && current.toString().trim().isNotEmpty) return map;
    final ms = int.tryParse(key);
    if (ms != null) {
      map['createdAt'] = DateTime.fromMillisecondsSinceEpoch(
        ms,
      ).toIso8601String();
    }
    return map;
  }
}
