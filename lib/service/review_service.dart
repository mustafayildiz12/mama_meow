import 'package:in_app_review/in_app_review.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/service/global_functions.dart';

/// Mağaza puanı/yorumu isteme servisi.
///
/// Puanlar mağaza sıralamasını ve organik keşfi doğrudan besler. Native
/// `requestReview()` kullanır (kendi modalımızı YAPMAYIZ — mağaza kuralları).
/// Yalnızca "mutlu an"larda ve frekans kapağıyla tetiklenir; kullanıcıyı
/// rahatsız etmemek esastır.
class ReviewService {
  factory ReviewService() => _singleton;
  ReviewService._internal();
  static final ReviewService _singleton = ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  static const String _lastPromptKey = 'review_last_prompt_ms';
  static const String _engagementKey = 'review_engagement_count';

  /// En fazla ~120 günde bir iste.
  static const int _cooldownMs = 120 * 24 * 60 * 60 * 1000;

  /// Bu kadar olumlu etkileşimden sonra iste (örn. 3 başarılı AI cevabı / rapor).
  static const int _engagementThreshold = 3;

  /// Olumlu bir an gerçekleştiğinde çağır (başarılı AI cevabı, rapor PDF açma vb.).
  /// Eşik + cooldown sağlanırsa native değerlendirme akışını başlatır.
  Future<void> recordPositiveMomentAndMaybeAsk() async {
    final int count = (infoStorage.read(_engagementKey) as int? ?? 0) + 1;
    await infoStorage.write(_engagementKey, count);
    if (count < _engagementThreshold) return;

    final bool asked = await _tryRequestReview();
    if (asked) {
      await infoStorage.write(_engagementKey, 0);
    }
  }

  Future<bool> _tryRequestReview() async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int last = (infoStorage.read(_lastPromptKey) as int?) ?? 0;
    if (now - last < _cooldownMs) return false;

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await infoStorage.write(_lastPromptKey, now);
        return true;
      }
    } catch (_) {
      // Sessizce geç; değerlendirme isteği kritik bir akış değil.
    }
    return false;
  }

  /// "Bizi değerlendir" gibi açık bir butondan mağaza sayfasını açar.
  ///
  /// iOS'ta App Store sayfasını açmak için [appStoreId] gerekir.
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: kAppStoreId, // iOS App Store numeric ID
      );
    } catch (e) {
      print("Hata: $e");
      // iOS'ta App Store ID girilmemişse mağaza sayfası açılamaz; native
      // değerlendirme akışına düş.
      try {
        await _inAppReview.requestReview();
      } catch (e) {
        print("Hata 2: $e");
        // Sessizce geç.
      }
    }
  }
}

final ReviewService reviewService = ReviewService();
