import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat'te premium erişimi veren entitlement kimliği.
const String premiumEntitlementId = 'premium';

/// Uygulama içi satın alma işlemlerini (RevenueCat) yöneten servis.
class InAppPurchaseService {
  factory InAppPurchaseService() => _singleton;
  InAppPurchaseService._internal();
  static final InAppPurchaseService _singleton =
      InAppPurchaseService._internal();

  CustomerInfo? _customerInfo;
  bool _configured = false;

  /// RevenueCat kimlik/müşteri bilgisi çağrılarını sıraya koyar: giriş
  /// sırasında `logIn` ile eşzamanlı bir `getCustomerInfo` anonim kullanıcının
  /// bilgisini sonradan yazıp premium durumunu ezmesin.
  Future<void> _queue = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _queue.then((_) => op());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Premium durumunu dinlemek isteyen ekranlar için.
  final ValueNotifier<bool> premiumNotifier = ValueNotifier<bool>(false);

  CustomerInfo? get customerInfo => _customerInfo;

  void _setCustomerInfo(CustomerInfo? info) {
    _customerInfo = info;
    premiumNotifier.value = _hasPremium(info);
  }

  static bool _hasPremium(CustomerInfo? info) =>
      info?.entitlements.active.containsKey(premiumEntitlementId) ?? false;

  /// RevenueCat'i platforma uygun anahtarla yapılandırır ve müşteri
  /// bilgisi değişikliklerini dinlemeye başlar.
  Future<void> initPlatformState() async {
    final String apiKey;
    if (PlatformInfo.isAndroid) {
      apiKey = "goog_XNLNOWirMulrzrbickLvpMvDgta";
    } else if (PlatformInfo.isIOS) {
      apiKey = "appl_jppIgRAPMvmyaXVorOLxBifTKyG";
    } else {
      debugPrint("RevenueCat: platform not supported");
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_setCustomerInfo);
    } catch (e, st) {
      // Bu noktada henüz ScaffoldMessenger yok; snackbar gösterilemez.
      debugPrint("RevenueCat configure failed: $e\n$st");
    }
  }

  /// Önceki satın alımları geri yükler. Geri yükleme sonrası premium
  /// aktifse true döner; kullanıcıya sonucu snackbar ile bildirir.
  Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      _setCustomerInfo(info);
      if (_hasPremium(info)) {
        customSnackBar.success("Your subscription has been restored.");
        return true;
      }
      customSnackBar.warning("No active subscription found.");
      return false;
    } on PlatformException catch (e) {
      debugPrint("Restore failed: $e");
      customSnackBar.error("Restore failed. Please try again.");
      return false;
    }
  }

  /// Oturum açmış kullanıcıyı RevenueCat'e uid ile tanıtır.
  Future<void> loginSubscription() async {
    if (!_configured) return;
    final String uid = authenticationService.getUser()?.uid ?? '';
    if (uid.isEmpty) return;
    await _serial(() async {
      try {
        final LogInResult result = await Purchases.logIn(uid);
        _setCustomerInfo(result.customerInfo);
      } catch (e) {
        debugPrint("RevenueCat logIn failed: $e");
      }
    });
  }

  /// RevenueCat oturumunu kapatır. Anonim kullanıcıda `logOut` hata verdiği
  /// için önce kontrol edilir; bir sonraki kullanıcı önceki kullanıcının
  /// RevenueCat kimliğini devralmasın.
  Future<void> logoutSubs() async {
    if (!_configured) return;
    await _serial(() async {
      try {
        if (!await Purchases.isAnonymous) {
          _setCustomerInfo(await Purchases.logOut());
        } else {
          _setCustomerInfo(null);
        }
      } catch (e) {
        debugPrint("RevenueCat logOut failed: $e");
        _setCustomerInfo(null);
      }
    });
  }

  /// Önbellekteki müşteri bilgisine göre premium (deneme dahil) aktif mi.
  bool checkUserHaveProduct() => _hasPremium(_customerInfo);

  /// RevenueCat'ten güncel müşteri bilgisini alarak premium durumunu döner.
  /// SDK bilgiyi önbellekten verdiği için hızlıdır.
  Future<bool> isPremium() async {
    if (!_configured) return false;
    return _serial(() async {
      try {
        _setCustomerInfo(await Purchases.getCustomerInfo());
      } catch (e) {
        debugPrint("RevenueCat getCustomerInfo failed: $e");
      }
      return checkUserHaveProduct();
    });
  }

  /// Geçerli offering'i yükler; yoksa veya hata olursa null döner.
  Future<Offering?> loadOfferings() async {
    if (!_configured) return null;
    try {
      final Offerings offerings = await Purchases.getOfferings();
      return offerings.current;
    } on PlatformException catch (e) {
      debugPrint("Error loading offerings: $e");
      return null;
    }
  }

  /// Paketi satın alır; premium aktif olduysa true döner. Kullanıcı iptal
  /// ederse hata gösterilmeden false döner.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _setCustomerInfo(result.customerInfo);

      if (!checkUserHaveProduct()) return false;

      await analyticService.purchaseSuccess(
        package.identifier,
        package.storeProduct.price,
      );
      final trialDays = getTrialDays(package);
      if (trialDays != null && trialDays != "0") {
        await analyticService.trialStarted(package.identifier);
      }
      customSnackBar.success("Purchase successful");
      return true;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        await analyticService.purchaseCancelled();
        return false;
      }
      await analyticService.purchaseFailed(code.name);
      debugPrint("Purchase error: $e");
      customSnackBar.error("Purchase failed. Please try again.");
      return false;
    } catch (e) {
      await analyticService.purchaseFailed(e.runtimeType.toString());
      debugPrint("Purchase error: $e");
      customSnackBar.error("Purchase failed. Please try again.");
      return false;
    }
  }

  /// Paketteki ücretsiz deneme süresini gün olarak döner, yoksa null.
  String? getTrialDays(Package package) {
    final product = package.storeProduct;

    // RevenueCat tarafında option listesi bazen boş olabiliyor.
    final options = <SubscriptionOption>[
      if (product.defaultOption != null) product.defaultOption!,
      ...?product.subscriptionOptions,
    ];

    // iOS: deneme bilgisi introductoryPrice'ta gelir.
    final intro = product.introductoryPrice;
    if (options.isEmpty) {
      if (intro == null || intro.price != 0) return null;
      return _periodToDays(intro.periodUnit, intro.periodNumberOfUnits);
    }

    for (final opt in options) {
      for (final ph in opt.pricingPhases) {
        if (ph.price.amountMicros == 0 && ph.billingPeriod != null) {
          return _periodToDays(
            ph.billingPeriod!.unit,
            ph.billingPeriod!.value,
          );
        }
      }
    }
    return null;
  }

  static String? _periodToDays(PeriodUnit unit, int count) => switch (unit) {
    PeriodUnit.day => '$count',
    PeriodUnit.week => '${count * 7}',
    PeriodUnit.month => '${count * 30}',
    PeriodUnit.year => '${count * 365}',
    _ => null,
  };

  /// Paketin tipini belirler (monthly, yearly).
  String getPackageType(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 'monthly';
      case PackageType.annual:
        return 'yearly';
      default:
        final id = package.identifier.toLowerCase();
        if (id.contains('month')) return 'monthly';
        if (id.contains('year') || id.contains('annual')) return 'yearly';
        return 'unknown';
    }
  }
}
