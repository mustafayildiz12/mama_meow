// ignore_for_file: use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/meow_user_model.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

/// TercihService sınıfı, Firebase Realtime Database ile etkileşim için gerekli metodları içerir.
/// Kullanıcı tercihleri, sınav bilgileri ve diğer verilerin yönetimini sağlar.
class DatabaseService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// Kullanıcının temel bilgilerini Firebase'den alır ve mevcut kullanıcı nesnesine atar.
  /// @param userId - Kullanıcının benzersiz kimliği
  /// @return bool - Kullanıcı bilgilerinin başarıyla alınıp alınmadığını belirten boolean değer
  Future<bool> getAdminBasicInfoFromRealTime(String userId) async {
    bool isExist = false;

    try {
      final MeowUserModel? userModel =
          await getDataFromRealtimeDatabase<MeowUserModel?>(
            "users/$userId",
            (d) => MeowUserModel.fromMap(d),
          );

      if (userModel != null) {
        await localStorage.write("username", userModel.userName);
        isExist = true;
        currentMeowUser = userModel;

        await InAppPurchaseService().loginSubscription();
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    return isExist;
  }

  /// Firebase'den belirli bir yoldaki veriyi alır ve istenen tipe dönüştürür.
  /// @param path - Verinin alınacağı yol
  /// @param fromMap - Veriyi dönüştürecek fonksiyon
  /// @return Future<`T`?> - Dönüştürülmüş veri
  Future<T?> getDataFromRealtimeDatabase<T>(
    String path,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    try {
      final DataSnapshot snapshot = await _realtimeDatabase.ref(path).get();

      if (snapshot.exists && snapshot.value is Map<Object?, Object?>) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          snapshot.value as Map,
        );
        return fromMap(data);
      }
    } catch (e) {
      debugPrint("Firebase veri çekme hatası: $e");
    }
    return null;
  }

  /// Yeni bir kullanıcıyı Firebase'e ekler.
  /// @param user - Eklenecek kullanıcı modeli
  Future<void> addUserToRealTime(MeowUserModel user) async {
    await _realtimeDatabase.ref('users').child(user.uid!).set(user.toMap());
  }

  /// Kullanıcı hesabını siler.
  /// @param context - BuildContext nesnesi
  Future<bool> deleteAccount(BuildContext context) async {
    bool isSuccess = false;
    await _realtimeDatabase
        .ref("users")
        .child(currentMeowUser!.uid!)
        .remove()
        .then((_) async {
          customSnackBar.success("Account Deleted");
          isSuccess = true;
        });
    return isSuccess;
  }

  Future<void> updateBaby(MeowUserModel? meowUserModel) async {
    await _realtimeDatabase.ref("users").child(meowUserModel!.uid!).update({
      "babyName": meowUserModel.babyName,
      "ageRange": meowUserModel.ageRange,
      "userEmail": meowUserModel.userEmail,
      "userPassword": meowUserModel.userPassword,
    });
    customSnackBar.success("Saved successfully");
  }
}

final DatabaseService databaseService = DatabaseService();
