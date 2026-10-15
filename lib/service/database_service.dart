import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/meow_user_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/platform_info.dart';

/// Kullanıcı kaydı (`users/<uid>`), uygulama yapılandırması (`appInfo`) ve
/// hesap silme işlemleri.
class DatabaseService {
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance;

  /// `users/<uid>` kaydını okuyup [currentMeowUser]'a atar; kayıt varsa true.
  /// Ardından RevenueCat oturumunu ve `appInfo` yapılandırmasını yükler.
  Future<bool> getAdminBasicInfoFromRealTime(String userId) async {
    try {
      final snapshot = await _realtimeDatabase.ref("users/$userId").get();
      final value = snapshot.value;
      if (!snapshot.exists || value is! Map) return false;

      final data = Map<String, dynamic>.from(value);
      // Eski sürümler şifreyi düz metin olarak saklıyordu; kullanıcı her
      // giriş yaptığında bu alan temizlenir.
      if (data.containsKey('userPassword')) {
        await _realtimeDatabase.ref("users/$userId/userPassword").remove();
      }

      final userModel = MeowUserModel.fromMap(data);
      currentMeowUser = userModel;
      await localStorage.write("username", userModel.userName);
    } catch (e) {
      debugPrint("getAdminBasicInfoFromRealTime failed: $e");
      return false;
    }

    // Bunlar profil yüklemesinin başarısını etkilememeli.
    await InAppPurchaseService().loginSubscription();
    try {
      await getBasicAppInfo();
    } catch (e) {
      debugPrint("getBasicAppInfo failed: $e");
    }
    return true;
  }

  Future<void> addUserToRealTime(MeowUserModel user) async {
    await _realtimeDatabase.ref('users').child(user.uid!).set(user.toMap());
  }

  Future<void> updateBaby(MeowUserModel? meowUserModel) async {
    final uid = meowUserModel?.uid;
    if (uid == null) return;
    await _realtimeDatabase.ref("users").child(uid).update({
      "babyName": meowUserModel!.babyName,
      "ageRange": meowUserModel.ageRange,
      "userEmail": meowUserModel.userEmail,
    });
    customSnackBar.success("Saved successfully");
  }

  Future<void> updateBabyPicture(MeowUserModel? meowUserModel) async {
    final uid = meowUserModel?.uid;
    if (uid == null) return;
    await _realtimeDatabase.ref("users").child(uid).update({
      "babyPicture": meowUserModel!.babyPicture,
    });
    customSnackBar.success("Saved successfully");
  }

  /// `appInfo` düğümündeki uzaktan yapılandırmayı (model, promptlar, sürüm)
  /// global değişkenlere yükler. Eksik alanlar varsayılanlarda kalır.
  Future<String> getBasicAppInfo() async {
    final snapshot = await _realtimeDatabase.ref("appInfo").get();
    final value = snapshot.value;
    if (!snapshot.exists || value is! Map) return "";

    String str(String key) => value[key]?.toString() ?? "";

    String appInfoVersion = "";
    if (PlatformInfo.isIOS) {
      iosVersion = str("iosVersion");
      iosUrl = str("iosUrl");
      appInfoVersion = iosVersion;
    } else if (PlatformInfo.isAndroid) {
      androidVersion = str("androidVersion");
      androidUrl = str("androidUrl");
      appInfoVersion = androidVersion;
    }
    // OpenAI anahtarı istemciye indirilmez; sunucudaki OPENAI_API_KEY
    // secret'ı kullanılır (bkz. functions/src/index.ts).
    if (str("askMiaModel").isNotEmpty) askMiaModel = str("askMiaModel");
    if (str("systemPrompt").isNotEmpty) systemPrompt = str("systemPrompt");
    if (str("suggestionPrompt").isNotEmpty) {
      suggestionPrompt = str("suggestionPrompt");
    }
    return appInfoVersion;
  }

  /// Hesabı ve kullanıcıya ait tüm verileri siler, ardından yerel oturumu
  /// temizler. Başarılıysa true döner.
  ///
  /// Önce sunucudaki `deleteAccount` callable'ı denenir (RTDB + Storage +
  /// Auth kullanıcısını sunucuda siler, yeniden giriş gerektirmez). Fonksiyon
  /// henüz dağıtılmamışsa (`not-found`) eski yola düşülür: `wipeUser` ile
  /// veriler silinir, Auth kullanıcısı istemciden silinir.
  ///
  /// Son giriş eskiyse [FirebaseAuthException] (`requires-recent-login`)
  /// fırlatır; arayüz kullanıcıdan çıkış yapıp tekrar girmesini istemelidir.
  Future<bool> deleteAccount() async {
    final User? user = authenticationService.getUser();
    if (user == null) return false;

    await analyticService.userDeleteAccount();
    final functions = FirebaseFunctions.instance;

    var deletedOnServer = false;
    try {
      await functions.httpsCallable('deleteAccount').call();
      deletedOnServer = true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code != 'not-found') {
        debugPrint("deleteAccount callable failed: ${e.code} ${e.message}");
        customSnackBar.error("Could not delete your account. Please try again.");
        return false;
      }
    }

    if (!deletedOnServer) {
      // Veriyi silip Auth silmede "requires-recent-login" alınırsa hesap
      // verisiz kalır; bu yüzden ön kontrol yapılır (Firebase ~5 dk ister).
      final lastSignIn = user.metadata.lastSignInTime;
      if (lastSignIn == null ||
          DateTime.now().difference(lastSignIn) > const Duration(minutes: 5)) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Please sign in again before deleting your account.',
        );
      }
      try {
        await functions.httpsCallable('wipeUser').call();
        await user.delete();
      } on FirebaseAuthException {
        rethrow;
      } catch (e) {
        debugPrint("Account deletion failed: $e");
        customSnackBar.error("Could not delete your account. Please try again.");
        return false;
      }
    }

    await authenticationService.logoutFromFirebase();
    customSnackBar.success("Account deleted");
    return true;
  }
}

final DatabaseService databaseService = DatabaseService();
