// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mama_meow/models/activities/custom_solid_model.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// TercihService sınıfı, Firebase Realtime Database ile etkileşim için gerekli metodları içerir.
/// Kullanıcı tercihleri, sınav bilgileri ve diğer verilerin yönetimini sağlar.
class AddCustomSolidService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Yeni bir kullanıcıyı Firebase'e ekler.
  /// @param user - Eklenecek kullanıcı modeli
  Future<void> addCustomSolid(CustomSolidModel customSolid) async {
    final user = authenticationService.getUser()!;
    final String createdAt = DateTime.now().millisecondsSinceEpoch.toString();
    await _realtimeDatabase
        .ref('customSolids')
        .child(user.uid)
        .child(createdAt)
        .set(customSolid.toMap());
  }

  Future<List<CustomSolidModel>> getCustomSolids() async {
    final List<CustomSolidModel> customSolids = [];
    final user = authenticationService.getUser()!;

    final DatabaseReference ref = _realtimeDatabase
        .ref('customSolids')
        .child(user.uid);

    final DataSnapshot snapshot = await ref.get();

    try {
      if (snapshot.exists) {
        final raw = snapshot.value;

        if (raw is Map) {
          for (final value in raw.values) {
            if (value is Map) {
              final map = Map<String, dynamic>.from(value);
              final model = CustomSolidModel.fromMap(map);

              customSolids.add(model);
            }
          }
        } else if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final model = CustomSolidModel.fromMap(map);

              customSolids.add(model);
            }
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }

    return customSolids;
  }

  Future<String> uploadFile({
    required File file,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final user = authenticationService.getUser()!;
      final ref = _storage.ref('customSolids/${user.uid}/$fileName');
      final metadata = SettableMetadata(contentType: contentType);
      final snapshot = await ref.putFile(file, metadata);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Dosya yüklenirken hata: $e');
    }
  }
}

final AddCustomSolidService addCustomSolidService = AddCustomSolidService();
