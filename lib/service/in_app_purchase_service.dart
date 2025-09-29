// ignore_for_file: cast_from_null_always_fails

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Abonelik ürünlerinin listesi
List<StoreProduct>? _subsProducts;

/// Müşteri bilgileri
CustomerInfo? _customerInfo;

/// Abonelik ürünlerinin listesini döndürür
List<StoreProduct>? get getSubsProducts => _subsProducts;

/// Müşteri bilgilerini döndürür
CustomerInfo? get customerInfo => _customerInfo;

/// Müşteri bilgilerini ayarlar
set customerInfo(CustomerInfo? customerInfo) => _customerInfo = customerInfo;

/// InAppPurchaseService, uygulama içi satın alma işlemlerini yöneten servis sınıfıdır.
/// RevenueCat kütüphanesi kullanılarak abonelik ve tek seferlik satın alma işlemleri gerçekleştirilir.
class InAppPurchaseService {
  factory InAppPurchaseService() {
    return _singleton;
  }

  InAppPurchaseService._internal();
  // Singleton pattern uygulaması - yalnızca tek bir nesne üzerinden işlem yapılır
  static final InAppPurchaseService _singleton =
      InAppPurchaseService._internal();

  /// RevenueCat platformunu başlatır ve yapılandırır
  ///
  /// Platform türüne göre (Android, iOS) uygun API anahtarını kullanarak
  /// RevenueCat'i yapılandırır ve müşteri bilgilerini dinlemeye başlar.
  Future<void> initPlatformState() async {
    try {
      PurchasesConfiguration configuration;

      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(
          "goog_XNLNOWirMulrzrbickLvpMvDgta",
        );
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(
          "appl_jppIgRAPMvmyaXVorOLxBifTKyG",
        );
      } else {
        configuration = PurchasesConfiguration("");
        debugPrint("Not supported platform");
      }
      await Purchases.configure(configuration);

      await Purchases.setLogLevel(LogLevel.debug);

      Purchases.addCustomerInfoUpdateListener((info) {
        customerInfo = info;
      });
    } catch (e) {
      customSnackBar.error("İnitiliaze Error. ${e.toString()}");
    }
  }

  /// Önceki satın alımları geri yükler
  ///
  /// Kullanıcının önceki satın alımlarını RevenueCat üzerinden geri yükler.
  /// Hata durumunda uygun hata mesajını gösterir.
  Future<void> restorePurchases() async {
    try {
      final CustomerInfo customerInfo = await Purchases.restorePurchases();

      final entitlements = customerInfo.entitlements.active;

      if (entitlements.containsKey('premium')) {
        // Kullanıcının Premium hakkı zaten vardı, sadece geri yükledik
        customSnackBar.success("Aboneliğiniz geri yüklendi.");
      } else {
        // Kullanıcının geçerli bir aboneliği yok
        customSnackBar.warning("Aktif abonelik bulunamadı.");
      }
    } on PlatformException catch (_) {
      customSnackBar.error("Restore işlemi başarısız oldu.");
    }
  }

  /// Abonelik ürünlerini yükler
  ///
  /// RevenueCat üzerinden abonelik ürünlerini yükler ve _subsProducts değişkenine atar.
  /// Hata durumunda konsola hata mesajı yazdırır.
  Future<List<StoreProduct>> loadSubs() async {
    try {
      List<StoreProduct> items = await Purchases.getProducts(
        productCategory: ProductCategory.subscription,
        [
          'mama_monthly',
          'mama_yearly',
          'mama_apple_monthly',
          'mama_apple_yearly',
        ],
      );

      return items;
    } on PlatformException catch (e) {
      debugPrint("Error loading offerings info: $e");
      return [];
    }
  }

  /// Müşteri bilgilerini yükler
  ///
  /// RevenueCat üzerinden müşteri bilgilerini yükler ve _customerInfo değişkenine atar.
  /// Hata durumunda konsola hata mesajı yazdırır.
  Future<void> loadCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      debugPrint("Error loading purchaser info: $e");
    }
  }

  /// Abonelik için giriş yapar
  ///
  /// Kullanıcının UID'sini kullanarak RevenueCat üzerinde giriş yapar.
  /// Web platformunda çalışmaz.
  Future<void> loginSubscription() async {
    if (kIsWeb) {
      return;
    }
    try {
      final String uid = authenticationService.getUser()?.uid ?? '';
      if (uid.isNotEmpty) {
        LogInResult logInResult = await Purchases.logIn(uid);
        customerInfo = logInResult.customerInfo;
      }
    } on Exception catch (e) {
      debugPrint("Unable to logIn or logOut user in RevenueCat: $e");
    }
  }

  /// Abonelik ürünü satın alır
  ///
  /// [storeProduct] - Satın alınacak ürün
  /// [context] - BuildContext
  ///
  /// RevenueCat üzerinden abonelik ürünü satın alır.
  /// Başarılı satın alma durumunda kullanıcıyı bilgilendirir ve modalı kapatır.
  /// Hata durumunda uygun hata mesajını gösterir.
  Future<void> purchaseSubsItem(
    StoreProduct storeProduct,
    BuildContext context,
  ) async {
    try {
      var purchaseProduct = await Purchases.purchase(
        PurchaseParams.storeProduct(storeProduct),
      );
      customerInfo = purchaseProduct.customerInfo;
      if (customerInfo!.activeSubscriptions.isNotEmpty) {
        customSnackBar.success("Purchase success");
        Navigator.pop(context);
      }
    } catch (e) {
      // Kullanıcı iptal etmiş olabilir vs.
      debugPrint("Purchase error: $e");
      customSnackBar.error("Purchase failed");
    }
  }

  /// Kullanıcının aktif aboneliği olup olmadığını kontrol eder
  ///
  /// Kullanıcının aktif abonelikleri varsa true, yoksa false döndürür.
  bool checkUserHaveProduct() {
    if (customerInfo != null) {
      final entitlement = customerInfo!.entitlements.all["premium"];
      if (entitlement != null && entitlement.isActive) {
        // Trial mı kontrol et
        return entitlement.periodType == PeriodType.trial;
      }
      if (customerInfo!.activeSubscriptions.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Future<bool> isTrial() async {
    int? trialCount = infoStorage.read("trialCount");

    // demek ki ücretsiz deniyor uygulamayı
    if (trialCount != null && trialCount < 4) {
      await infoStorage.write("trialCount", trialCount + 1);
      return true;
    }
    return false;
  }

  ///
  /// RevenueCat üzerinde çıkış yapar ve müşteri bilgilerini günceller.
  Future<void> logoutSubs() async {
    try {
      if (customerInfo != null &&
          customerInfo!.activeSubscriptions.isNotEmpty) {
        customerInfo = await Purchases.logOut();
      }
    } catch (e) {
      customSnackBar.warning(e.toString());
    }
  }

  // InAppPurchaseService sınıfınıza bu metodları ekleyin:

  /// Offerings'leri yükler
  ///
  /// RevenueCat üzerinden offerings'leri yükler.
  /// Hata durumunda boş liste döndürür.
  Future<List<Package>> loadOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        // Current offering'deki tüm paketleri döndür
        return offerings.current!.availablePackages;
      }

      return [];
    } on PlatformException catch (e) {
      debugPrint("Error loading offerings: $e");
      return [];
    }
  }

  /// Belirli bir offering'i yükler
  ///
  /// [offeringIdentifier] - Yüklenecek offering'in identifier'ı
  /// Belirli bir offering'deki paketleri döndürür.
  Future<List<Package>> loadSpecificOffering(String offeringIdentifier) async {
    try {
      Offerings offerings = await Purchases.getOfferings();

      final offering = offerings.all[offeringIdentifier];
      if (offering != null) {
        return offering.availablePackages;
      }

      return [];
    } on PlatformException catch (e) {
      debugPrint("Error loading specific offering: $e");
      return [];
    }
  }

  /// Package satın alır
  ///
  /// [package] - Satın alınacak paket
  /// [context] - BuildContext
  ///
  /// RevenueCat üzerinden package satın alır.
  /// Package'ler trial bilgilerini içerir.
  Future<bool> purchasePackage(Package package) async {
    bool isPurchaseSuccess = false;
    try {
      var purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      customerInfo = purchaseResult.customerInfo;

      if (customerInfo!.activeSubscriptions.isNotEmpty) {
        customSnackBar.success("Purchase success");
        isPurchaseSuccess = true;
      }
    } catch (e) {
      isPurchaseSuccess = false;
      debugPrint("Purchase error: $e");
      customSnackBar.error("Purchase failed");
    }
    return isPurchaseSuccess;
  }

  /// Package'in trial bilgilerini alır
  ///
  /// [package] - İncelenecek paket
  /// Trial gün sayısını string olarak döndürür, yoksa null.
  String? getTrialDays(Package package) {
    try {
      final product = package.storeProduct;
      final opt =
          product.defaultOption ?? (product.subscriptionOptions?.firstOrNull);
      if (opt == null) return null;

      // Fiyatı 0 olan ilk phase'i trial kabul et
      final trialPhase = opt.pricingPhases.firstWhere(
        (ph) => (ph.price.amountMicros) == 0,
        orElse: () => null as PricingPhase,
      );

      final per = trialPhase.billingPeriod;
      if (per == null) return null;

      final unit = per.unit.name.toLowerCase();
      final count = per.value;

      if (unit.startsWith('day')) return '$count';
      if (unit.startsWith('week')) return '${count * 7}';
      if (unit.startsWith('month')) return '${count * 30}';
      if (unit.startsWith('year')) return '${count * 365}';

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Package'in tipini belirler (monthly, yearly)
  String getPackageType(Package package) {
    // Package type'ına göre
    switch (package.packageType) {
      case PackageType.monthly:
        return 'monthly';
      case PackageType.annual:
        return 'yearly';

      default:
        // Identifier'dan çıkarmaya çalış
        final id = package.identifier.toLowerCase();
        if (id.contains('month')) return 'monthly';
        if (id.contains('year') || id.contains('annual')) return 'yearly';
        return 'unknown';
    }
  }

  Future<bool> isPremium() async {
    bool isUserPremium = await checkUserHaveProduct() || await isTrial();
    return isUserPremium;
  }
}
