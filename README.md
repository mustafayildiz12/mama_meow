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

---

## 🛠️ Teknik Altyapı

### Frontend
- **Framework**: Flutter & Dart (SDK ^3.9.0)
- **Navigasyon**: `go_router`
- **State Management**: Service Pattern + `setState` / Native
- **Yerel Depolama**: `get_storage`

### Backend & Servisler
- **Firebase**:
  - **Authentication**: Kullanıcı kimlik doğrulama.
  - **Realtime Database**: Veri senkronizasyonu.
  - **Storage**: Medya dosyaları (fotoğraf, ses).
  - **Analytics & Crashlytics**: Uygulama analizi ve hata takibi.
  - **Remote Config**: Uzaktan yapılandırma.
- **Yapay Zeka**: OpenAI GPT entegrasyonu (Özel servis katmanı).
- **Ödeme**: RevenueCat (`purchases_flutter`).

### 📦 Temel Paketler
```yaml
# Core
flutter: sdk
go_router: ^17.0.1          # Sayfa yönlendirmesi
get_storage: ^2.1.1         # Basit veri saklama

# Firebase
firebase_core: ^4.0.0
firebase_auth: ^6.0.2
firebase_database: ^12.0.0
firebase_storage: ^13.0.6

# Medya
just_audio: ^0.10.5         # Ses oynatma
audio_service: ^0.18.18     # Arka plan ses servisi
record: ^6.1.1              # Ses kaydı
image_picker: ^1.2.0        # Resim seçimi

# UI & Yardımcılar
flutter_svg: ^2.2.1
cached_network_image: ^3.4.1
intl: ^0.20.2               # Tarih/Saat formatlama
syncfusion_flutter_charts: ^31.1.17 # Grafikler
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
│   └── premium/        # Ödeme duvarı (Paywall)
├── service/            # İş mantığı ve servis katmanı
│   ├── audio/          # Ses işleyici servisi
│   ├── gpt_service/    # AI servisleri
│   ├── authentication_service.dart
│   ├── database_service.dart
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