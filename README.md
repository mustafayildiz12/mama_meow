# 🐱 MamaMeow - Akıllı Bebek Bakım Asistanı

MamaMeow, ebeveynlerin bebeklerinin günlük aktivitelerini takip etmelerine, gelişimlerini izlemelerine ve yapay zeka destekli asistan ile sorularına cevap bulmalarına yardımcı olan kapsamlı bir Flutter uygulamasıdır.

## 📱 Özellikler

### 🤖 Ask Meow (Yapay Zeka Asistanı)
- **AI Sohbet**: Bebek bakımı ve annelik hakkında sorular sorabileceğiniz akıllı asistan.
- **Sesli ve Görsel Giriş**: Sorularınızı yazarak, sesli mesajla veya fotoğraf yükleyerek sorabilirsiniz.
- **Hızlı Sorular**: Sık sorulan sorulara hızlı erişim.
- **Geçmiş**: Sorulan soruları ve alınan cevapları kaydeder.

### 👶 Bebeğim (Aktivite Takibi)
Bebekle ilgili tüm önemli aktivitelerin kaydı ve takibi:
- **Bez Değişimi**: Kakalı, çişli bez takibi ve zamanlaması.
- **Beslenme**: Emzirme (sağ/sol), Biberon (süt tipi/miktar) ve Katı Gıda takibi.
- **Uyku**: Uyku süreleri ve düzeni.
- **Diğer**: İlaç takibi, büyüme verileri, aşı takvimi ve günlük notlar.
- **Hatırlatıcılar**: Bez değişimi, ilaç vb. için özelleştirilebilir alarmlar.

### 🎧 Öğren (Podcast & Eğitim)
- **Podcast Oynatıcı**: Ebeveynlik üzerine podcastleri dinleyin.
- **Gelişmiş Oynatıcı**: Hız kontrolü, atlama, arka planda çalma desteği.

### 📊 Raporlar ve Analizler
- Aktiviteler için detaylı grafikler ve özetler.
- Bebeğin gelişim takibi.

### 💎 Premium Özellikler
- Reklamsız deneyim.
- Sınırsız AI kullanımı.
- Özel içeriklere erişim.
- Premium erişimi RevenueCat `"premium"` entitlement'ı ile kontrol edilir.

### 📣 Büyüme & Etkileşim
- **Mağaza Değerlendirmesi**: "Mutlu an"larda (örn. 3 başarılı AI cevabı/rapor) ve frekans
  kapağıyla native `in_app_review` akışını tetikler.
- **Paylaşım**: AI cevaplarını, PDF raporlarını ve uygulama davet linkini `share_plus` ile paylaşma.
- **Geri Kazanım Bildirimleri (Re-engagement)**: Hareketsizlik dürtüleri (3/7 gün uygulamayı
  açmayan kullanıcıya) ve haftalık özet bildirimi (Pazar 19:00). Uygulama açılışı etkileşim sayılır
  ve sayaç sıfırlanır.
- **Analitik & Funnel**: Onboarding, aktivite kaydı, paywall gösterimi, deneme başlatma ve AI
  cevap başarı/başarısızlık olayları Firebase Analytics'e loglanır.

---

## 🛠️ Teknik Altyapı

### Frontend
- **Framework**: Flutter & Dart (SDK ^3.9.0)
- **Navigasyon**: `go_router`
- **State Management**: Service Pattern + `setState` / Native
- **Yerel Depolama**: `get_storage`

### Backend & Servisler
- **Firebase**:
  - **Authentication**: E-posta/şifre, Google ve Apple ile giriş.
  - **Realtime Database**: Aktivite ve kullanıcı verisi senkronizasyonu (disk persistansı açık).
  - **Storage**: Medya dosyaları (fotoğraf, ses).
  - **Analytics & Crashlytics**: Funnel/etkileşim olayları ve hata takibi.
  - **Remote Config / `appInfo` node**: OpenAI anahtarı, model, sistem promptları ve sürüm
    bilgileri uzaktan çekilir (uygulamaya gömülü değildir).
  - **Cloud Functions** (`functions/`, TypeScript, Node 22): `wipeUser` callable fonksiyonu,
    kullanıcının tüm Realtime Database verisini siler.
- **Yapay Zeka**: OpenAI GPT entegrasyonu — doğrudan HTTP üzerinden (backend proxy yok). Sohbet,
  öneriler, Whisper ses transkripsiyonu ve aktivite raporu analizleri için özel servis katmanı.
- **Ödeme**: RevenueCat (`purchases_flutter`), `"premium"` entitlement'ı.
- **Bildirimler**: `flutter_local_notifications` + `timezone` ile hatırlatıcılar ve geri kazanım
  bildirimleri.
- **Büyüme**: `in_app_review` (mağaza puanı) ve `share_plus` (paylaşım/davet).

### 📦 Temel Paketler
```yaml
# Core
flutter: sdk
go_router: ^17.0.1          # Sayfa yönlendirmesi
get_storage: ^2.1.1         # Basit veri saklama
http: ^1.5.0                # OpenAI API çağrıları
crypto: ^3.0.6

# Firebase
firebase_core: ^4.0.0
firebase_auth: ^6.0.2
firebase_database: ^12.0.0
firebase_storage: ^13.0.6
firebase_analytics: ^12.1.1
firebase_crashlytics: ^5.0.7
firebase_remote_config: ^6.1.4

# Kimlik Doğrulama
google_sign_in: ^6.3.0
sign_in_with_apple: ^7.0.1

# Medya
just_audio: ^0.10.5         # Ses oynatma
audio_service: ^0.18.18     # Arka plan ses servisi
audio_session: ^0.2.2
record: ^6.1.1              # Ses kaydı
image_picker: ^1.2.0        # Resim seçimi
flutter_image_compress: ^2.4.0

# Bildirimler
flutter_local_notifications: ^19.4.2
timezone: ^0.10.1
flutter_timezone: ^5.0.0

# Ödeme & Büyüme
purchases_flutter: ^9.6.1   # RevenueCat (premium)
in_app_review: ^2.0.10      # Mağaza puanı isteme
share_plus: ^10.1.4         # Paylaşım / davet

# Raporlar
pdf: ^3.11.3                # PDF rapor üretimi
open_filex: ^4.7.0          # Dosya açma
syncfusion_flutter_charts: ^31.1.17 # Grafikler

# UI & Yardımcılar
flutter_svg: ^2.2.1
flutter_markdown: ^0.7.7+1
cached_network_image: ^3.4.1
intl: ^0.20.2               # Tarih/Saat formatlama
url_launcher: ^6.3.2
package_info_plus: ^9.0.0
device_info_plus: ^12.3.0
```

---

## 📂 Proje Yapısı

```
lib/
├── constants/           # Uygulama geneli sabitler (Renkler, route'lar, vb.)
├── models/             # Veri modelleri
│   ├── ai_models/      # AI cevap ve soru modelleri
│   └── ...             # Aktivite ve kullanıcı modelleri
├── screens/            # Kullanıcı arayüzü (UI)
│   ├── auth/           # Giriş/Kayıt ekranları
│   ├── navigationbar/  # Ana uygulama iskeleti
│   │   ├── home/       # Ask Meow (Ana sayfa)
│   │   ├── learn/      # Podcast ekranları
│   │   ├── my-baby/    # Aktivite takip ekranları
│   │   └── profile/    # Profil ayarları
│   ├── get-started/    # Onboarding (bebek bilgisi)
│   └── premium/        # Ödeme duvarı (Paywall)
├── service/            # İş mantığı ve servis katmanı (global singleton'lar)
│   ├── activities/     # Aktivite servisleri (uyku, emzirme, bez, katı gıda...)
│   ├── audio/          # Arka plan ses işleyici (audio_service)
│   ├── gpt_service/    # AI servisleri (sohbet, öneri, rapor analizi)
│   ├── permissions/    # Android exact-alarm izin/politikası
│   ├── authentication_service.dart
│   ├── database_service.dart
│   ├── in_app_purchase_service.dart  # RevenueCat
│   ├── analytic_service.dart         # Firebase Analytics olayları
│   ├── re_engagement_service.dart    # Geri kazanım bildirimleri
│   ├── review_service.dart           # Mağaza puanı isteme
│   ├── motification_service.dart     # Yerel bildirimler (dosya adı kasıtlı yazım)
│   └── ...
├── utils/              # Yardımcı araçlar ve widget'lar
└── main.dart           # Uygulama giriş noktası
```

---

## 🚀 Kurulum

1. **Repoyu Klonlayın**
   ```bash
   git clone [repo-url]
   cd mama_meow
   ```

2. **Bağımlılıkları Yükleyin**
   ```bash
   flutter pub get
   ```

3. **Firebase Yapılandırması**
   - Firebase projenizi oluşturun.
   - `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını ilgili klasörlere ekleyin.

4. **Uygulamayı Çalıştırın**
   ```bash
   flutter run
   ```

## 🔐 Lisans

Bu proje gizlidir ve izinsiz kopyalanması veya dağıtılması yasaktır.