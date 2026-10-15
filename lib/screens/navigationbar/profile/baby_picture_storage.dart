import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Bebek fotoğrafının Firebase Storage işlemleri
/// (`users/<uid>/babyPicture.jpg`, her yüklemede üzerine yazılır).
class BabyPictureStorage {
  const BabyPictureStorage();

  Reference _ref(String uid) =>
      FirebaseStorage.instance.ref().child("users/$uid/babyPicture.jpg");

  /// Fotoğrafı yükler ve indirme adresini döner. `putData` kullanıldığı için
  /// `dart:io` gerektirmez.
  Future<String> upload({required String uid, required XFile file}) async {
    final ref = _ref(uid);
    await ref.putData(
      await file.readAsBytes(),
      SettableMetadata(contentType: "image/jpeg"),
    );
    return ref.getDownloadURL();
  }

  /// Fotoğrafı siler; dosya yoksa ya da silinemezse sessizce geçer.
  Future<void> delete(String uid) async {
    try {
      await _ref(uid).delete();
    } catch (e) {
      debugPrint("babyPicture delete skipped: $e");
    }
  }
}
