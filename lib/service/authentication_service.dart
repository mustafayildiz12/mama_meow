import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/meow_user_model.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

/// AuthenticationService, kullanıcı kimlik doğrulama işlemlerini yöneten servis sınıfıdır.
/// Firebase Authentication kullanarak kullanıcı girişi, kayıt, çıkış ve anonim giriş gibi
/// işlemleri gerçekleştirir.
class AuthenticationService {
  factory AuthenticationService() {
    return _singleton;
  }

  AuthenticationService._internal();
  // Singleton pattern uygulaması - yalnızca tek bir nesne üzerinden işlem yapılır
  static final AuthenticationService _singleton =
      AuthenticationService._internal();

  // Firebase Authentication nesnesi
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  /// Kullanıcı girişi yapar
  ///
  /// [context] - BuildContext
  /// [email] - Kullanıcı e-posta adresi
  /// [password] - Kullanıcı şifresi
  ///
  /// Başarılı giriş durumunda kullanıcıyı tercihExamsPath sayfasına yönlendirir.
  /// Hata durumunda uygun hata mesajını gösterir.
  Future<int> login(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    int isSuccess = 0;
    try {
      await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((UserCredential userCredential) async {
            final bool isUserExist = await checkUserExist(
              userCredential: userCredential,
            );

            final bool isUserDataExist = await databaseService
                .getAdminBasicInfoFromRealTime(userCredential.user!.uid);

            if (isUserExist && isUserDataExist) {
              if (currentMeowUser?.status != 1) {
                isSuccess = 1;
              } else {
                isSuccess = 2;
              }
            }
          });
    } on FirebaseAuthException catch (e) {
      isSuccess = 0;
      if (e.code == 'user-not-found') {
        customSnackBar.warning("user_not_found".tr);
      } else if (e.code == 'wrong-password') {
        customSnackBar.warning("wrong_password".tr);
      } else {
        customSnackBar.warning("wrong_password".tr);
      }
    } catch (e) {
      debugPrint(e.toString());
      isSuccess = 0;
    }
    return isSuccess;
  }

  /// Yeni kullanıcı kaydı oluşturur
  ///
  /// [email] - Kullanıcı e-posta adresi
  /// [password] - Kullanıcı şifresi
  /// [context] - BuildContext
  ///
  /// Başarılı kayıt durumunda kullanıcıyı tercihExamsPath sayfasına yönlendirir.
  /// Hata durumunda uygun hata mesajını gösterir.
  Future<bool> registerAndSaveUser({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    bool isSuccess = false;
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final bool isUserExist = await checkUserExist(userCredential: credential);
      if (isUserExist) {
        await Future.wait([
          databaseService.addUserToRealTime(
            MeowUserModel(
              uid: credential.user!.uid,
              babyName: currentMeowUser?.babyName,
              ageRange: currentMeowUser?.ageRange,
              userEmail: email,
              userName: name,
              userPassword: password,
              createDateTimeStamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        ]);

        await databaseService.getAdminBasicInfoFromRealTime(
          credential.user!.uid,
        );
        isSuccess = true;
      }
    } on FirebaseAuthException catch (e) {
      isSuccess = false;
      if (e.code == 'user-not-found') {
        customSnackBar.warning("user_not_found".tr);
      } else if (e.code == 'wrong-password') {
        customSnackBar.warning("wrong_password".tr);
      }
    }
    return isSuccess;
  }

  /// Kullanıcının var olup olmadığını kontrol eder
  ///
  /// [userCredential] - Firebase'den dönen kullanıcı bilgileri
  ///
  /// Kullanıcı varsa true, yoksa false döner
  Future<bool> checkUserExist({required UserCredential userCredential}) async {
    if (userCredential.user != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    bool isSendResetEmailSuccess = false;
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      isSendResetEmailSuccess = true;
      customSnackBar.success("rest_pass_send".tr);
    } catch (e) {
      isSendResetEmailSuccess = false;
      customSnackBar.error("rest_pass_not_send".tr);
    }
    return isSendResetEmailSuccess;
  }

  /// Mevcut kullanıcının ID'sini döndürür
  Future<String?> userId() async {
    return firebaseAuth.currentUser!.uid;
  }

  /// Mevcut kullanıcı nesnesini döndürür
  User? getUser() {
    return firebaseAuth.currentUser;
  }

  /// Kullanıcı çıkışı yapar
  ///
  /// [context] - BuildContext
  ///
  /// Google hesabından çıkış yapar, Firebase'den çıkış yapar,
  /// abonelikleri iptal eder ve kullanıcıyı tercihLoginPath sayfasına yönlendirir.
  Future<bool> logoutFromFirebase() async {
    bool isSuccess = false;
    try {
      await firebaseAuth.signOut();

      final User? currentUser = getUser();

      currentMeowUser = null;
      // kullanıcının çıktığından emin olduktan sonra
      // locali silme ve navgationu temizleme işlemi yapıyoruz.
      if (currentUser == null) {
        await localStorage.erase();

        isSuccess = true;
      }
    } catch (e) {
      debugPrint(e.toString());
      isSuccess = false;
    }
    return isSuccess;
  }
}

// Singleton instance
final AuthenticationService authenticationService = AuthenticationService();
