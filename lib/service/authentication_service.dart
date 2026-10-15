import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/meow_user_model.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/service/reminders/reminders.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Google / Apple ile giriş sonuç kodları. Giriş ekranı bunlara göre yönlenir.
abstract final class SocialSignInResult {
  /// Kayıtlı kullanıcı → doğrudan uygulamaya.
  static const int existingUser = 0;

  /// Yeni kullanıcı → önce bebek bilgisi.
  static const int newUser = 1;

  /// Hata (mesaj servis tarafından gösterildi).
  static const int failed = 2;

  /// Kullanıcı vazgeçti → hiçbir şey yapma.
  static const int cancelled = 3;
}

/// Firebase Authentication üzerinden giriş, kayıt, çıkış işlemleri.
class AuthenticationService {
  factory AuthenticationService() => _singleton;
  AuthenticationService._internal();
  static final AuthenticationService _singleton =
      AuthenticationService._internal();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool _googleInitialized = false;

  User? getUser() => firebaseAuth.currentUser;

  /// E-posta/şifre ile giriş.
  ///
  /// 1 = başarılı, 2 = hesap kalıcı olarak silinmiş, 0 = başarısız (mesaj
  /// gösterildi). [context] geriye dönük uyumluluk için duruyor.
  Future<int> login(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) return 0;

      var hasProfile = await databaseService.getAdminBasicInfoFromRealTime(
        user.uid,
      );
      if (!hasProfile) {
        // Auth hesabı var ama users/<uid> kaydı yok (ör. kayıt yarıda
        // kaldıysa): kullanıcıyı içeride bırakıp profilsiz bırakmak yerine
        // kaydı yeniden oluştur.
        await databaseService.addUserToRealTime(
          MeowUserModel(
            uid: user.uid,
            userEmail: user.email ?? email.trim(),
            userName: user.displayName,
            createDateTimeStamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        hasProfile = await databaseService.getAdminBasicInfoFromRealTime(
          user.uid,
        );
      }
      if (!hasProfile) {
        customSnackBar.warning("Could not load your profile. Please try again.");
        await firebaseAuth.signOut();
        return 0;
      }

      await analyticService.emailLoginSuccess();
      return currentMeowUser?.status == 1 ? 2 : 1;
    } on FirebaseAuthException catch (e) {
      await analyticService.emailLoginFailed(e.message ?? e.code);
      customSnackBar.warning(switch (e.code) {
        'user-not-found' => "User not found",
        'wrong-password' || 'invalid-credential' => "Wrong email or password",
        'invalid-email' => "Invalid email address",
        'user-disabled' => "This account has been disabled",
        'too-many-requests' => "Too many attempts. Please try again later.",
        'network-request-failed' => "No internet connection",
        _ => "Could not log in",
      });
      return 0;
    } catch (e) {
      await analyticService.emailLoginFailed(e.toString());
      debugPrint("login failed: $e");
      customSnackBar.warning("Could not log in");
      return 0;
    }
  }

  /// Yeni kullanıcı kaydı. Veritabanı kaydı başarısız olursa yarım kalmış
  /// Auth hesabı geri silinir; böylece "profilsiz" kullanıcı oluşmaz.
  Future<bool> registerAndSaveUser({
    required String name,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    UserCredential? credential;
    try {
      credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await databaseService.addUserToRealTime(
        MeowUserModel(
          uid: uid,
          babyName: currentMeowUser?.babyName,
          ageRange: currentMeowUser?.ageRange,
          userEmail: email.trim(),
          userName: name.trim(),
          createDateTimeStamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await databaseService.getAdminBasicInfoFromRealTime(uid);
      await analyticService.registerSuccess();
      return true;
    } on FirebaseAuthException catch (e) {
      await analyticService.registerFailed(e.message ?? e.code);
      customSnackBar.warning(switch (e.code) {
        'email-already-in-use' => "Email already in use",
        'invalid-email' => "Invalid email address",
        'weak-password' => "Password should be at least 6 characters",
        'network-request-failed' => "No internet connection",
        _ => "Unable to register",
      });
      return false;
    } catch (e) {
      await analyticService.registerFailed(e.toString());
      debugPrint("register failed: $e");
      try {
        await credential?.user?.delete();
      } catch (_) {}
      customSnackBar.warning("Unable to register. Please try again.");
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
      customSnackBar.success("Password reset email sent");
      return true;
    } catch (e) {
      debugPrint("forgotPassword failed: $e");
      customSnackBar.error("Could not send password reset email");
      return false;
    }
  }

  /// Çıkış yapar ve cihazdaki kullanıcıya ait durumu temizler. Adımlar
  /// birbirinden bağımsızdır; biri hata verse de diğerleri çalışır.
  Future<bool> logoutFromFirebase() async {
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint("Google signOut failed: $e");
    }

    try {
      await firebaseAuth.signOut();
    } catch (e) {
      await analyticService.logoutFailed(e.toString());
      debugPrint("Firebase signOut failed: $e");
      return false;
    }

    await InAppPurchaseService().logoutSubs();
    // Hatırlatıcılar cihazda tutulur; bir sonraki kullanıcıya geçmesin.
    await cancelAndClearAllReminders();
    currentMeowUser = null;
    await localStorage.erase();
    await analyticService.logoutSuccess();
    return true;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // Android: google-services.json'daki web istemcisi, iOS: Info.plist
    // GIDClientID otomatik kullanılır.
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  /// Google hesabı ile giriş. Sonuç: [SocialSignInResult].
  Future<int> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      await analyticService.googleLoginSuccess();
      return await _completeSocialSignIn(userCredential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return SocialSignInResult.cancelled;
      }
      return _socialSignInFailed(
        analyticService.googleLoginFailed,
        '${e.code.name}: ${e.description}',
      );
    } catch (e) {
      return _socialSignInFailed(analyticService.googleLoginFailed, '$e');
    }
  }

  /// Apple hesabı ile giriş. Sonuç: [SocialSignInResult].
  Future<int> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256ofString(rawNonce),
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      await analyticService.appleLoginSuccess();

      // Apple adı yalnızca ilk girişte verir; null parçaları atla.
      final nameParts = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((p) => p.trim().isNotEmpty);
      return await _completeSocialSignIn(
        userCredential,
        displayName: nameParts.isEmpty ? null : nameParts.join(' '),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return SocialSignInResult.cancelled;
      }
      return _socialSignInFailed(
        analyticService.appleLoginFailed,
        '${e.code.name}: ${e.message}',
      );
    } catch (e) {
      return _socialSignInFailed(analyticService.appleLoginFailed, '$e');
    }
  }

  /// Sosyal girişlerin ortak devamı: profil yoksa oluştur, silinmiş hesabı
  /// içeri alma.
  Future<int> _completeSocialSignIn(
    UserCredential userCredential, {
    String? displayName,
  }) async {
    final user = userCredential.user;
    if (user == null) {
      customSnackBar.warning("Failed to login");
      return SocialSignInResult.failed;
    }

    if (await databaseService.getAdminBasicInfoFromRealTime(user.uid)) {
      if (currentMeowUser?.status == 1) {
        customSnackBar.warning("This account is deleted permanently");
        await logoutFromFirebase();
        return SocialSignInResult.failed;
      }
      return SocialSignInResult.existingUser;
    }

    final profile = userCredential.additionalUserInfo?.profile;
    await databaseService.addUserToRealTime(
      MeowUserModel(
        uid: user.uid,
        userEmail: (profile?['email'] as String?) ?? user.email ?? '',
        userName:
            displayName ?? (profile?['name'] as String?) ?? user.displayName,
        createDateTimeStamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await databaseService.getAdminBasicInfoFromRealTime(user.uid);
    return SocialSignInResult.newUser;
  }

  Future<int> _socialSignInFailed(
    Future<void> Function(String) logFailure,
    String error,
  ) async {
    debugPrint("Social sign-in failed: $error");
    await logFailure(error);
    customSnackBar.warning("Failed to login");
    return SocialSignInResult.failed;
  }

  /// Apple girişi için kriptografik olarak güvenli rastgele nonce.
  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /// Oturumdaki kullanıcının giriş sağlayıcısı ('password', 'google.com',
  /// 'apple.com'); oturum yoksa null.
  String? findUserProvider() {
    final providers = getUser()?.providerData;
    if (providers == null || providers.isEmpty) return null;
    return providers.first.providerId;
  }
}

final AuthenticationService authenticationService = AuthenticationService();
