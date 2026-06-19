// ignore_for_file: use_build_context_synchronously

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/service/authentication_service.dart';

/// TercihAuthService, kullanıcı kimlik doğrulama işlemlerini yöneten servis sınıfıdır.
/// Firebase Authentication kullanarak kullanıcı girişi, kayıt, çıkış ve anonim giriş gibi
/// işlemleri gerçekleştirir.
class AnalyticService {
  factory AnalyticService() {
    return _singleton;
  }

  AnalyticService._internal();
  // Singleton pattern uygulaması - yalnızca tek bir nesne üzerinden işlem yapılır
  static final AnalyticService _singleton = AnalyticService._internal();

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  // login logları
  Future<void> emailLoginFailed(
    String errorMessage, {
    String? errorCode,
  }) async {
    await analytics.logEvent(
      name: 'email_login_failed',
      parameters: {
        ...timeAndDeviceInfo,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  Future<void> googleLoginFailed(
    String errorMessage, {
    String? errorCode,
  }) async {
    await analytics.logEvent(
      name: 'google_login_failed',
      parameters: {
        ...timeAndDeviceInfo,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  Future<void> appleLoginFailed(
    String errorMessage, {
    String? errorCode,
  }) async {
    await analytics.logEvent(
      name: 'apple_login_failed',
      parameters: {
        ...timeAndDeviceInfo,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  // logout logları
  Future<void> logoutFailed(String errorMessage, {String? errorCode}) async {
    await analytics.logEvent(
      name: 'logout_failed',
      parameters: {
        ...timeAndDeviceInfo,
        ...userInfo,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  Future<void> logoutSuccess() async {
    await analytics.logEvent(
      name: 'logout_success',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  // register logları
  Future<void> registerFailed(String errorMessage, {String? errorCode}) async {
    await analytics.logEvent(
      name: 'register_failed',
      parameters: {
        ...timeAndDeviceInfo,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
      },
    );
  }

  Future<void> registerSuccess() async {
    await analytics.logEvent(
      name: 'register_success',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  // purchase failed
  Future<void> purchaseFailed(
    String errorMessage, {
    String? errorCode,
    String? productId,
  }) async {
    await analytics.logEvent(
      name: 'purchase_failed',
      parameters: {
        ...timeAndDeviceInfo,
        ...userInfo,
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
        if (productId != null) 'product_id': productId,
      },
    );
  }

  // Başarılı işlemler için metodlar
  Future<void> emailLoginSuccess() async {
    await analytics.logEvent(
      name: 'email_login_success',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  Future<void> googleLoginSuccess() async {
    await analytics.logEvent(
      name: 'google_login_success',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  Future<void> appleLoginSuccess() async {
    await analytics.logEvent(
      name: 'apple_login_success',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  Future<void> purchaseSuccess(String productId, double price) async {
    await analytics.logEvent(
      name: 'purchase_success',
      parameters: {
        'product_id': productId,
        'price': price,
        ...timeAndDeviceInfo,
        ...userInfo,
      },
    );
  }

  Future<void> appOpen() async {
    await analytics.logEvent(
      name: 'app_open',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  Future<void> userDeleteAccount() async {
    await analytics.logEvent(
      name: 'account_deleted',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  Future<void> screenView(String screenName) async {
    await analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        ...timeAndDeviceInfo,
        ...userInfo,
      },
    );
  }

  Future<void> askMia(String question) async {
    await analytics.logEvent(
      name: 'ask_mia',
      parameters: {'question': question, ...timeAndDeviceInfo, ...userInfo},
    );
  }

  // ---- Büyüme / funnel olayları ----

  /// Kullanıcı onboarding'i (bebek bilgisi) tamamladığında.
  Future<void> onboardingComplete() async {
    await analytics.logEvent(
      name: 'onboarding_complete',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  /// Çekirdek engagement metriği: bir aktivite kaydedildiğinde.
  /// [type] -> sleep | nursing | diaper | solid | pumping | medicine | journal
  Future<void> activityLogged(String type) async {
    await analytics.logEvent(
      name: 'activity_logged',
      parameters: {'activity_type': type, ...timeAndDeviceInfo, ...userInfo},
    );
  }

  /// Paywall kullanıcıya gösterildiğinde. [source] -> ask_meow | learn | profile ...
  Future<void> paywallShown({String? source}) async {
    await analytics.logEvent(
      name: 'paywall_shown',
      parameters: {
        if (source != null) 'source': source,
        ...timeAndDeviceInfo,
        ...userInfo,
      },
    );
  }

  /// Ücretsiz deneme başlatıldığında.
  Future<void> trialStarted(String productId) async {
    await analytics.logEvent(
      name: 'trial_started',
      parameters: {'product_id': productId, ...timeAndDeviceInfo, ...userInfo},
    );
  }

  /// AI cevabı başarıyla alındığında.
  Future<void> aiAnswerSuccess() async {
    await analytics.logEvent(
      name: 'ai_answer_success',
      parameters: {...timeAndDeviceInfo, ...userInfo},
    );
  }

  /// AI cevabı alınamadığında.
  Future<void> aiAnswerFailed(String errorMessage) async {
    await analytics.logEvent(
      name: 'ai_answer_failed',
      parameters: {
        'error_message': errorMessage,
        ...timeAndDeviceInfo,
        ...userInfo,
      },
    );
  }

  static Map<String, dynamic> get timeAndDeviceInfo => {
    "timeStamp": DateTime.now().toIso8601String(),
    "deviceInfo": deviceInfo,
  };

  static Map<String, dynamic> get userInfo {
    User? currentUser = authenticationService.getUser();
    return {"email": currentUser?.email ?? "-", "uid": currentUser?.uid ?? "-"};
  }
}

// Singleton instance
final AnalyticService analyticService = AnalyticService();
