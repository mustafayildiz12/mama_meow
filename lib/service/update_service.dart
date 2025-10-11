import 'package:firebase_database/firebase_database.dart';
import 'package:mama_meow/models/update_info_modal.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  DatabaseReference get _updatesRef => _root.child('updates');

  /// Belirli versiyonu getir: /updates/{version}
  Future<AppUpdateInfo?> fetchVersion(String version) async {
    final snap = await _updatesRef.child(version).get();
    if (!snap.exists || snap.value == null) return null;
    return AppUpdateInfo.fromMap(snap.value as Map);
  }

  /// Yayında olanlar arasından en son yayınlananı getir (publishedAt en büyük olan).
  Future<AppUpdateInfo?> fetchLatestPublished() async {
    final q = _updatesRef.orderByChild('publishedAt').limitToLast(1);
    final snap = await q.get();
    if (!snap.exists) return null;

    AppUpdateInfo? latest;
    for (final child in snap.children) {
      final m = child.value as Map?;
      if (m == null) continue;
      final info = AppUpdateInfo.fromMap(m);
      if (info.isPublished) {
        latest = info;
      }
    }
    return latest;
  }

  /// Canlı dinlemek istersen: yayınlı en son versiyon değişince akıt.
  Stream<AppUpdateInfo?> listenLatestPublished() {
    final q = _updatesRef.orderByChild('publishedAt').limitToLast(1);
    return q.onValue.map((event) {
      if (!event.snapshot.exists) return null;
      AppUpdateInfo? latest;
      for (final child in event.snapshot.children) {
        final m = child.value as Map?;
        if (m == null) continue;
        final info = AppUpdateInfo.fromMap(m);
        if (info.isPublished) latest = info;
      }
      return latest;
    });
  }

  /// ADMIN: Versiyonu oluştur/güncelle (yayınlama dahil).
  /// publishedAt için ServerValue.timestamp kullanıyoruz.
  Future<void> publishUpdate({
    required String version,
    required List<String> highlights,
    bool isPublished = true,
    bool forceUpdate = false,
  }) async {
    try {
      final ref = _updatesRef.child(version);
      await ref.set({
        'version': version,
        'highlights': highlights,
        'isPublished': isPublished,
        'forceUpdate': forceUpdate,
        'publishedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  /// ADMIN: Bir versiyonu yayından kaldır
  Future<void> unpublish(String version) async {
    await _updatesRef.child(version).update({'isPublished': false});
  }
}
