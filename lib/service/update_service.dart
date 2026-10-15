import 'package:firebase_database/firebase_database.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  final DatabaseReference _root = FirebaseDatabase.instance.ref();
  DatabaseReference get _updatesRef => _root.child('updates');

  /// RTDB anahtarlarında '.' kullanılamaz: "1.0.5" → "1x0x5".
  static String _key(String version) => version.trim().replaceAll('.', 'x');

  /// ADMIN: Versiyonu oluştur/güncelle (yayınlama dahil). Hata fırlatır.
  /// publishedAt için ServerValue.timestamp kullanıyoruz.
  Future<void> publishUpdate({
    required String version,
    required List<String> highlights,
    bool isPublished = true,
    bool forceUpdate = false,
  }) async {
    await _updatesRef.child(_key(version)).set({
      'version': version.trim(),
      'highlights': highlights,
      'isPublished': isPublished,
      'forceUpdate': forceUpdate,
      'publishedAt': ServerValue.timestamp,
    });
  }

  /// ADMIN: Bir versiyonu yayından kaldır
  Future<void> unpublish(String version) async {
    await _updatesRef.child(_key(version)).update({'isPublished': false});
  }
}
