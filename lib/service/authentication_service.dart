// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/models/meow_user_model.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  Future<void> logoutFromFirebase(BuildContext context) async {
    try {
      await firebaseAuth.signOut();

      final User? currentUser = getUser();

      currentMeowUser = null;
      // kullanıcının çıktığından emin olduktan sonra
      // locali silme ve navgationu temizleme işlemi yapıyoruz.
      if (currentUser == null) {
        await localStorage.erase();

        await Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.loginPage,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Google hesabı ile giriş yapar
  ///
  /// [context] - BuildContext
  ///
  /// Google hesabı ile giriş yapar, kullanıcı bilgilerini Firebase'e kaydeder
  /// ve tercihExamsPath sayfasına yönlendirir.
  /// Hata durumunda uygun hata mesajını gösterir.
  Future<void> signInWithGoogle({required BuildContext context}) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        /// isUserDataExist true ise bu kullanıcı db'ye kaydedilmiş demektir
        final bool isUserDataExist = await databaseService
            .getAdminBasicInfoFromRealTime(uid);

        if (!isUserDataExist) {
          final Map<String, dynamic>? profile =
              userCredential.additionalUserInfo?.profile;
          await databaseService
              .addUserToRealTime(
                MeowUserModel(
                  uid: uid,
                  babyName: currentMeowUser?.babyName,
                  ageRange: currentMeowUser?.ageRange,
                  userEmail: profile!['email'],
                  userName: profile['name'],
                  createDateTimeStamp: DateTime.now().millisecondsSinceEpoch,
                ),
              )
              .then((v) async {
                await databaseService.getAdminBasicInfoFromRealTime(uid);
              });
        }

        await Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.navigationBarPage,
          (route) => false,
        );
      } else {
        debugPrint("User bulunamadı.");
      }
    } catch (e) {
      customSnackBar.warning("fail_to_login".tr);
      debugPrint("Hata: $e");
      if (e is PlatformException) {
        debugPrint("PlatformException: ${e.message}");
        debugPrint("Details: ${e.details}");
      }
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final AuthCredential appleAuthCredential = OAuthProvider('apple.com')
          .credential(
            idToken: credential.identityToken,
            rawNonce: rawNonce,
            accessToken: credential.authorizationCode,
          );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(appleAuthCredential);

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        /// isUserDataExist true ise bu kullanıcı db'ye kaydedilmiş demektir
        final bool isUserDataExist = await databaseService
            .getAdminBasicInfoFromRealTime(uid);

        if (!isUserDataExist) {
          final Map<String, dynamic>? profile =
              userCredential.additionalUserInfo?.profile;

          final String? fullName = (credential.givenName != null)
              ? '${credential.givenName} ${credential.familyName}'
              : userCredential
                    .user
                    ?.displayName; // çoğunlukla null olur, yine de deneriz

          print("FullName: $fullName");

          await databaseService
              .addUserToRealTime(
                MeowUserModel(
                  uid: uid,
                  babyName: currentMeowUser?.babyName,
                  ageRange: currentMeowUser?.ageRange,
                  userName: fullName,
                  userEmail: profile!['email'] ?? "",
                  createDateTimeStamp: DateTime.now().millisecondsSinceEpoch,
                ),
              )
              .then((v) async {
                await databaseService.getAdminBasicInfoFromRealTime(uid);
              });
        }

        await Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.navigationBarPage,
          (route) => false,
        );
      } else {
        debugPrint("User bulunamadı.");
      }
    } catch (e) {
      customSnackBar.warning("fail_to_login".tr);
      debugPrint("Hata: $e");

      if (e is PlatformException) {
        debugPrint("PlatformException: ${e.message}");
        debugPrint("Details: ${e.details}");
      }
    }
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

// Singleton instance
final AuthenticationService authenticationService = AuthenticationService();
