import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mama_meow/models/activities/custom_solid_model.dart';
import 'package:mama_meow/service/activities/activity_store.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// Kullanıcının eklediği özel yiyecekler: `customSolids/<uid>/<epochMsKey>`
/// (görseller Storage'da `customSolids/<uid>/<fileName>`).
class AddCustomSolidService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  String _requireUid() {
    final user = authenticationService.getUser();
    if (user == null) {
      throw StateError('Adding a custom food requires a signed-in user.');
    }
    return user.uid;
  }

  /// Yeni özel yiyeceği kaydeder; giriş yoksa [StateError] fırlatır.
  Future<void> addCustomSolid(CustomSolidModel customSolid) async {
    final uid = _requireUid();
    await ActivityRtdb.write(
      _realtimeDatabase
          .ref('customSolids')
          .child(uid)
          .child(ActivityRtdb.nextKey())
          .set(customSolid.toMap()),
      label: 'customSolids add',
    );
  }

  /// Kullanıcının özel yiyecekleri; giriş yoksa boş liste.
  Future<List<CustomSolidModel>> getCustomSolids() async {
    final user = authenticationService.getUser();
    if (user == null) return [];

    final snapshot = await _realtimeDatabase
        .ref('customSolids')
        .child(user.uid)
        .get();

    final customSolids = <CustomSolidModel>[];
    for (final child in snapshot.children) {
      final value = child.value;
      if (value is! Map) continue;
      try {
        customSolids.add(
          CustomSolidModel.fromMap(Map<String, dynamic>.from(value)),
        );
      } catch (e, st) {
        ActivityRtdb.reportNonFatal(
          e,
          st,
          reason: 'Skipped malformed customSolids record (${child.key})',
        );
      }
    }
    return customSolids;
  }

  /// Görseli Storage'a yükler ve indirme URL'sini döner; giriş yoksa
  /// [StateError] fırlatır.
  Future<String> uploadFile({
    required File file,
    required String fileName,
    String? contentType,
  }) async {
    final uid = _requireUid();
    try {
      final ref = _storage.ref('customSolids/$uid/$fileName');
      final metadata = SettableMetadata(contentType: contentType);
      final snapshot = await ref.putFile(file, metadata);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
    }
  }
}

final AddCustomSolidService addCustomSolidService = AddCustomSolidService();
