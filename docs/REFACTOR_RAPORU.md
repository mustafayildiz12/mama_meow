# MamaMeow (Coo Care) — Refactor ve Sorun Raporu

**Tarih:** 15 Ekim 2026 · **Branch:** `refactor/modernize-2026` (henüz commit edilmedi) · **Başlangıç:** `main` @ `89aa4f3` (v1.0.19)

---

## 1. Özet

Proje 4 paralel denetimle (çekirdek servisler, veri + AI katmanı, genel ekranlar, "My Baby" ekranları) baştan sona incelendi. **170'in üzerinde doğrulanmış bulgu** çıktı. Bunların büyük kısmı düzeltildi, kod tekrarları ortak modüllere toplandı ve tüm paketler güncel sürümlere taşındı.

| Metrik | Önce | Sonra |
|---|---|---|
| `flutter analyze` | 80 bulgu (+ yükseltme sonrası 76 derleme hatası) | **0 bulgu** |
| `lib/` Dart satır sayısı | 34.552 (130 dosya) | **23.806** (141 dosya) — **%31 daha az** |
| Cloud Functions lint | 163 uyarı | **0** |
| `print()` çağrıları | 18 | 0 |
| `// ignore_for_file: use_build_context_synchronously` | 24 dosya | 0 |
| Eski (major sürüm geride) paket | 30+ | 0 (bilinçli 2 istisna, bkz. §4) |
| Kullanılmayan bağımlılık | 6 | 0 |
| Test | Yok | Uçtan uca giriş + ekran gezinti testi |

**En kritik 5 sorun (hepsi düzeltildi):**
1. **Ücretli aboneler premium sayılmıyordu.** Deneme süresi bitip ücretli aboneliğe geçen her kullanıcıya tekrar paywall gösteriliyordu.
2. **Kullanıcı şifreleri veritabanında düz metin olarak saklanıyordu** (`users/<uid>/userPassword`).
3. **"Hesabımı sil" verileri silmiyordu.** Yalnızca Auth hesabı siliniyordu; bebek ve sağlık kayıtları, fotoğraflar ve şifre veritabanında kalıyordu. App Store 5.1.1(v) ve KVKK/GDPR açısından risk.
4. **Firebase Analytics'e kişisel veri gidiyordu.** Her olaya e-posta, Ask Meow olayına da kullanıcının sağlık sorusunun metni ekleniyordu. Bu, Google Analytics politikasına aykırı.
5. **Gece uykuları bozuk kaydediliyordu.** Gece yarısından sonra başlayan bir uyku iki kayda bölünüyor ve raporlarda 23,5 saatlik "hayalet" bir uyku oluşuyordu.

---

## 2. Kritik ve yüksek öncelikli bulgular

### 2.1 Güvenlik ve gizlilik

| # | Sorun | Etki | Yapılan | Dosya |
|---|---|---|---|---|
| G1 | Şifreler kayıtta ve her profil güncellemesinde `users/<uid>/userPassword` alanına düz metin yazılıyordu. Ayarlar ekranı bu şifreyi forma geri dolduruyordu. | Veritabanına erişen herkes tüm şifreleri görebilir. | Alan modelden ve tüm yazma yollarından kaldırıldı. **Mevcut kayıtlar her girişte otomatik siliniyor.** Şifre değişimi yalnızca Firebase Auth üzerinden yapılıyor. | `meow_user_model.dart`, `database_service.dart`, `authentication_service.dart`, `update_email_password.dart` |
| G2 | Hesap silme yalnızca `user.delete()` çağırıyordu; `wipeUser` çağrısı yorum satırındaydı. "Yakın zamanda giriş gerekli" hatası kullanıcıya ham metin olarak gösteriliyordu. | Silinen kullanıcının tüm verisi kalıyordu (uyum riski). | Yeni `deleteAccount` Cloud Function (RTDB + Storage + Auth). İstemci önce onu deniyor; fonksiyon henüz deploy edilmediyse `wipeUser` + istemci tarafı silmeye düşüyor. Ardından yerel oturumu, RevenueCat'i ve hatırlatıcıları temizliyor. | `database_service.dart`, `functions/src/index.ts`, `update_email_password.dart` |
| G3 | Analytics olaylarına e-posta, Ask Meow olayına soru metni ekleniyordu. | GA politikası ihlali, sağlık verisi sızıntısı. | Yalnızca uid ve soru uzunluğu gönderiliyor. Hata mesajları 100 karaktere kırpılıyor (GA sınırı). | `analytic_service.dart` |
| G4 | `/adminUpdate` (sürüm yayınlama aracı) herkese açık bir rotaydı; web'de URL ile açılabiliyordu. | Yetkisiz kişi `updates/` düğümüne yazabilirdi (RTDB kurallarına bağlı). | Rota artık yalnızca **debug derlemelerde** kayıtlı. | `app_pages.dart` |
| G5 | OpenAI proxy istemciden gelen mesajları denetimsiz iletiyordu: rol, boyut, görsel sayısı ve `response_format` sınırsızdı; `maxInstances` yoktu. | Ücretsiz bir hesapla genel amaçlı GPT-4o proxy'si; maliyet riski. | Rol izin listesi, mesaj/metin/görsel/ses boyut sınırları, temperature sınırlama, `response_format` izin listesi, `maxInstances: 10`. Başarısız OpenAI çağrılarında kota iade ediliyor. | `functions/src/index.ts` |
| G6 | Silme işlevi `usage/<uid>` kota kayıtlarını ve Storage dosyalarını silmiyordu. | Artık veri kalıyordu. | `wipeUser` ve `deleteAccount` kota kayıtlarını, `users/<uid>/` ve `customSolids/<uid>/` Storage öneklerini de siliyor. | `functions/src/index.ts` |
| G7 | `.env.example` içinde gerçek test hesabı bilgileri var; dosya izlenmiyordu ama `.gitignore`'da da yoktu. | Yanlışlıkla commit edilebilirdi. | `.env` ve `.env.*` `.gitignore`'a eklendi. | `.gitignore` |

### 2.2 Gelir ve ödeme (RevenueCat)

| # | Sorun | Yapılan |
|---|---|---|
| P1 | `checkUserHaveProduct()` aktif `premium` yetkisinde yalnızca `periodType == trial` ise `true` döndürüyordu. Ücretli aboneler `false` alıyordu. Podcast ekranında bu, sonsuz paywall döngüsüne yol açıyordu. | Aktif `premium` yetkisi varsa her zaman `true`. `premiumNotifier` ile ekranlar anlık güncelleniyor. |
| P2 | Satın alma iptali "Purchase failed" olarak gösteriliyor ve `purchase_failed` olarak loglanıyordu. | İptal sessiz geçiyor ve ayrı bir `purchase_cancelled` olayı loglanıyor. |
| P3 | Satın al butonunda çift dokunma koruması yoktu; art arda birden fazla `purchase` çağrısı başlatılabiliyordu. | Kilit ve spinner eklendi. |
| P4 | Geri yükleme (restore) başarılı olsa bile paywall kapanmıyordu. Mesajlar Türkçeydi. | `restorePurchases()` sonucu `bool` olarak döndürüyor; başarılı olursa paywall kapanıyor. Mesajlar İngilizce. |
| P5 | iOS kullanıcıları "Google Play" ifadelerini görüyordu. App Review abonelik metinlerinin doğru olmasını istiyor. | Platforma göre metin. |
| P6 | Çıkışta yalnızca aktif aboneliği olan kullanıcılar RevenueCat'ten çıkarılıyordu. Aynı cihazdaki bir sonraki kullanıcı önceki kimliği devralıyordu. | Anonim olmayan her kullanıcı çıkarılıyor. Kimlik çağrıları sıraya alındı (giriş sırasındaki yarış durumu giderildi). |
| P7 | Yayın sürümünde RevenueCat `LogLevel.debug` açıktı. Kullanılmayan `isTrial`/`trialCount` mekanizması her zaman `false` döndürüyordu. | Log seviyesi yalnızca debug'da `debug`. Ölü kod silindi. |

### 2.3 Veri doğruluğu (aktivite takibi ve raporlar)

| # | Sorun | Yapılan |
|---|---|---|
| D1 | Gece yarısından sonra başlayan uyku (ör. 00:30–02:00) iki kayda bölünüyordu ve raporda 23,5 saatlik uyku görünüyordu. | Bölme yalnızca gerçekten gece yarısını geçen uykularda yapılıyor. Gece yarısını geçen uykular sayım ve ortalamalarda tek uyku olarak birleştiriliyor (`mergeSleepSessions`). |
| D2 | Bez, pumping ve mama raporları kullanıcının seçtiği saati değil kaydetme anını kullanıyordu. Akşam 21:00'de toplu girilen 3 kayıt grafikte 21:00'de görünüyordu. | Tüm saat bazlı hesaplar `resolveEventTime()` ile gerçek olay saatini kullanıyor. Seçilen saat kayıt anından ilerideyse önceki güne atanıyor. |
| D3 | Günlük ekranı geçmiş bir günde pumping ve ilaç için **bugünün** verisini gösteriyordu. | Seçili günün aralığı sorgulanıyor; sorgular paralel çalışıyor. |
| D4 | Günlükte "bugün mü" kontrolü yalnızca ayın gününü karşılaştırıyordu (15 Eylül = 15 Ekim). | `DateUtils.isSameDay`. |
| D5 | "2.5 ml" gibi ondalıklı ilaç dozu `int.parse` hatasıyla kaydedilemiyordu. | `MedicineModel.amount` artık `num` ("2.5" ve "0,5" kabul ediliyor). Eski int kayıtlar okunmaya devam ediyor. |
| D6 | Pumping'de süre boşken kaydet tıklanınca çökme oluyordu (`&&` yerine `||` olmalıydı). | Doğrulama ve yalnızca rakam girişi. |
| D7 | Emzirme ↔ biberon geçişinde eski taraf/miktar değerleri kayda yazılıyordu; emzirme kayıtlarında hayalet ml oluşuyordu. | Tür değişince alanlar sıfırlanıyor; her tür yalnızca kendi alanlarını yazıyor. |
| D8 | PDF dışa aktarmada veri yoksa yükleme katmanı sonsuza kadar ekranı kilitliyordu (uyku, emzirme). | `finally` + `mounted` kontrolü; hatalar kullanıcı dostu mesajla gösteriliyor. |
| D9 | Offline iken kaydet butonu asılı kalıyordu: persistence açıkken `set()` sunucu onayını bekliyor. Her tekrar dokunma yeni kayıt oluşturuyordu. | En fazla 4 saniye bekleniyor, yazma kuyruğa alınıyor. Tüm sheet'lerde "kaydediliyor" kilidi var. |
| D10 | Aynı milisaniyede kaydedilen kayıtlar (çoklu mama, bölünen uyku) birbirinin üzerine yazılabiliyordu. | Süreç içinde kesin artan anahtar (`ActivityRtdb.nextKey`). |
| D11 | Tek bir bozuk kayıt tüm raporu, tek bir eksik alanlı podcast tüm Learn sekmesini düşürüyordu. | Kayıt bazında hata yakalama ve toleranslı ayrıştırma. |
| D12 | Ana ekrandaki "Bugün: N kez" sayaçları gece yarısından sonra donuyordu ve misafir giriş yapınca güncellenmiyordu. | Sayaç akışları oturum değişikliğini izliyor ve gece yarısında yeni güne geçiyor. Dinleyici sızıntısı giderildi. |
| D13 | Emzirme AI raporunda anne sütü/mama ml her zaman 0 gidiyordu, ortalama aralık sabit 0'dı, sol/sağ dakikalar tahmin ediliyordu. | Gerçek değerler hesaplanıyor. |
| D14 | Uyku AI eşlemesi hatalıydı: "next to caregiver" araba yolculuğu sayılıyordu, ">30 dk" ise "10-30 dk" olarak gidiyordu. Mama raporunda her öğün "en başarılı" sayılıyordu; ilaç toplamları farklı ilaçları topluyordu. | Düzeltildi. |
| D15 | PDF'lerde Türkçe karakterler (ş, ğ, ı) kayboluyordu (Helvetica Latin-1). | Tüm belge Nunito fontuyla üretiliyor; emojiler temizleniyor. |
| D16 | AI çağrıları JSON modu kullanmıyordu; kesilen veya kod bloğu içinde gelen yanıtlar PDF'deki AI bölümünü sessizce boş bırakıyordu. | Tüm çağrılarda `response_format: json_object` kullanılıyor. Ortak şema ve toleranslı ayrıştırıcı var; hatalar Crashlytics'e gidiyor. |
| D17 | Sesli soru başarısız olunca `"Transcribe exception: ..."` metni soru kutusuna yazılıyordu. | Hata durumunda kullanıcıya mesaj gösteriliyor, geçici ses dosyası siliniyor. |

### 2.4 Uygulama akışı ve kararlılık

| # | Sorun | Yapılan |
|---|---|---|
| A1 | Profil ekranında misafir kullanıcı avatar veya kartlara dokununca hiçbir şey olmuyordu (`pushNamed`'e rota adı yerine yol veriliyordu). | Düzeltildi. Giriş ekranı sekmelerin üstünde açılıyor ve kapatılabiliyor. |
| A2 | Kayıtta veritabanı yazımı başarısız olursa yükleme ekranı sonsuza kadar kalıyordu ve profilsiz bir Auth hesabı oluşuyordu. | `try/finally`. Yarım kalan Auth hesabı geri siliniyor. Girişte profil yoksa yeniden oluşturuluyor. |
| A3 | E-posta doğrulaması büyük harfi ve otomatik doldurmanın eklediği sondaki boşluğu reddediyordu. Kayıt ekranında doğrulama yoktu. Hata mesajları boştu. | Harf duyarsız, boşlukları kırpan, açık mesajlı doğrulayıcılar. |
| A4 | Google veya Apple girişinden vazgeçmek "Failed to login" hatası veriyordu. Silinmiş olarak işaretli hesaplar sosyal girişle içeri girebiliyordu. | İptal sessiz geçiyor. Silinmiş hesap kontrolü tüm giriş yollarında ortak. |
| A5 | Bildirim eklentisi her hatırlatıcı sayfasında yeniden başlatılıyor ve bildirime dokunma yönlendirmesini bozuyordu. | Eklenti tek yerde, bir kez başlatılıyor. |
| A6 | Bir kategoride 100'den fazla hatırlatıcı oluşturulursa bildirim ID'leri diğer kategorilerle çakışıyor ve birbirini siliyordu. | Yeni ID şeması; eski ID'ler bir kerelik taşımayla iptal ediliyor. |
| A7 | Hatırlatıcılar çıkış ve hesap silmeden sonra çalmaya devam ediyordu; sonraki kullanıcı bunları devralıyordu. | Çıkışta tümü iptal edilip temizleniyor. |
| A8 | iOS 64 bekleyen bildirim sınırı: her günlük hatırlatıcı 7 ayrı bildirim kaydı kullanıyordu. | 7 gün seçiliyse tek günlük bildirim kaydı kullanılıyor. |
| A9 | Yaz saati geçişinde hatırlatıcı saati 1 saat kayıyordu. | Takvim aritmetiği (`TZDateTime` kurucusu). |
| A10 | RTDB offline persistence, veritabanı zaten kullanıldıktan sonra açıldığı için hiç devreye girmiyordu. | Firebase başlatılır başlatılmaz açılıyor. |
| A11 | `appInfo` okunamazsa AI boş sistem istemiyle çalışıyordu. Varsayılan model adı `'gpt-4o mini'` (boşluklu) geçersizdi. | İstemler varsayılanlarla başlıyor; model `gpt-4o-mini`. |
| A12 | Açılışta ağ beklemeleri (profil, RevenueCat, appInfo, bildirim izni) native splash'i kilitliyordu. | Kritik olmayan adımlar ilk kareden sonraya alındı. Oturum geri yükleme 8 saniye zaman aşımına bağlandı. |
| A13 | Crashlytics kancaları Firebase başlatılmadan kuruluyordu ve debug'da da veri toplanıyordu. | Doğru sıra; debug'da toplama kapalı. |
| A14 | Ask Meow'da soru kutucuklarına arka arkaya dokununca paralel AI çağrıları, mükerrer geçmiş kaydı ve birden fazla paywall oluşuyordu. | Kilit eklendi. Giriş veya satın alma sonrası bekleyen soru otomatik soruluyor. |
| A15 | Podcast'te misafir kullanıcı paywall ↔ paywall döngüsüne giriyordu. Yükleme hatası hiç gösterilmiyordu. | Misafir önce girişe yönlendiriliyor. Hata durumunda "Retry" gösteriliyor. |
| A16 | `dart:io Platform` kullanımı web hedefinde açılışta çöküyordu; 20'den fazla yerde vardı. | Tek `PlatformInfo` yardımcısı kullanılıyor. |
| A17 | Podcast detay rotası web yenilemesinde veya derin bağlantıda `extra!` yüzünden çöküyordu. | Learn'e yönlendiriliyor. Bilinmeyen rotalar ana sekmeye düşüyor. |
| A18 | Yönetici aracında yayından kaldırma hiç çalışmıyordu (anahtar uyuşmazlığı); yayınlama hataları yutuluyordu. | Düzeltildi. |

---

## 3. Mimari refactor (kod tekrarının kaldırılması)

| Alan | Önce | Sonra | Yaklaşım |
|---|---|---|---|
| Hatırlatıcılar (6 model, 7 zamanlayıcı, 6 yönetici sayfası, 6 düzenleyici) | ~3.900 satır, %95 kopya | ~1.050 satır | Yapılandırma tabanlı `ReminderConfig` / `ReminderStore` / `ReminderScheduler` + jenerik sayfa ve sheet (`lib/service/reminders/`) |
| Rapor sayfaları (6) | 6.668 satır | 2.014 satır | `ReportPageMixin`, `ReportScaffold`, ortak rapor widget'ları (`my-baby/widgets/`) |
| Ekleme sheet'leri (8) + My Baby + Günlük | ~5.600 satır | ~3.800 satır | `ActivitySheetScaffold`, `ChipPickerSection`, `pick24hTime` |
| Aktivite servisleri (6) | 6 kopya `DateParts`, kopya CRUD | `ActivityStore<T>` alt sınıfları | Ortak RTDB okuma/yazma, offline zaman aşımı, sayaç akışları |
| AI servisleri (6) | %38 kopya | Ortak şema ve ayrıştırıcı | `gpt_service/common/ai_common.dart`, `AiReportInsight` |
| PDF oluşturucular (6) | %69 kopya | Ortak bloklar | `lib/utils/pdf/report_pdf.dart` |
| Ask Meow ekranı | 1.207 satır, tek dosya | 443 satır + widget'lar | `MiaAnswerCard`, `AskInputCard`, `VoiceRecorderController` … |
| Rapor hesaplama | Aynı metrik sayfada, AI'da ve PDF'te ayrı ayrı hesaplanıyordu (sonuçlar uyuşmuyordu) | Tek hesaplama fabrikası | Sayfa, AI ve PDF aynı `*ReportComputed` nesnesini kullanıyor |
| Tarih yardımcıları | Servis başına 6 kopya, 6 ayrı rapor enum'u | `lib/utils/date_range.dart` | `ReportPeriod`, `DateRange`, `resolveEventTime` |

**Silinen ölü kod:** `push_notiication.dart`, tamamı yorum satırı olan `podcast_form_page.dart`, kopya `medicine_reminder_schecule.dart`, `update_info_modal.dart`, 30'dan fazla kullanılmayan servis metodu, kopya Pumping AI sınıfları, kullanılmayan global değişkenler ve yardımcı fonksiyonlar (13).

---

## 4. Paket güncellemeleri

Ortam: **Flutter 3.44.1 / Dart 3.12.1**. SDK kısıtı `^3.9.0` → `^3.12.0` oldu.

| Paket | Önce | Sonra | Not |
|---|---|---|---|
| firebase_core / auth / database / analytics / crashlytics / storage / cloud_functions | 4.11 / 6.5 / 12.4 / 12.4 / 5.2 / 13.4 / 6.3 | **4.15 / 6.7 / 12.6 / 12.6 / 5.4 / 13.6 / 6.5** | 4.x hattının en günceli (iOS SDK 12.19). 5.x (iOS SDK 13), SPM'de google_sign_in_ios ile çakışıyor; bkz. §6 madde 14-15. |
| google_sign_in | 6.3.0 | **7.2.0** | API tamamen değişti; taşındı (`GoogleSignIn.instance`, `authenticate()`). |
| sign_in_with_apple | 7.0.1 | **8.2.0** | |
| purchases_flutter (RevenueCat) | 9.16.1 | **10.16.0** | Google Play Billing Library 8. |
| flutter_local_notifications | 19.5.0 | **22.3.2** | Parametreler isimli hâle geldi; taşındı. |
| timezone | 0.10.1 | **0.11.2** | `UTC` → `Etc/UTC` |
| share_plus | 10.1.4 | **13.3.1** | `Share` → `SharePlus.instance.share(ShareParams)` |
| go_router | 17.3.0 | **18.1.0** | |
| record | 6.2.1 | **7.1.2** | |
| package_info_plus / device_info_plus | 9.0.1 / 12.4.0 | **10.2.2 / 13.3.0** | |
| cached_network_image | 3.4.1 | **4.0.3** | 4.0.4 Dart 3.13 istiyor; Flutter yükseltilince geçilebilir. |
| syncfusion_flutter_charts | 31.2.18 | **34.2.9** | 35.x dün çıktı ve Flutter 3.47 hedefliyor; bilinçli olarak beklendi. |
| just_audio, audio_service, audio_session, image_picker, flutter_image_compress, flutter_timezone, url_launcher, pdf, cupertino_icons, flutter_lints | | Son sürümler | `ConcatenatingAudioSource` → `setAudioSources`, `Radio` → `RadioGroup`, `onReorder` → `onReorderItem` |
| **Kaldırıldı** | `http`, `http_parser`, `flutter_markdown` (geliştirilmesi durduruldu), `firebase_remote_config`, `googleapis_auth`, `open_filex` | — | Hiçbir yerde kullanılmıyordu. |
| **Açıkça eklendi** | `mime`, `image` (dolaylı yoldan kullanılıyordu), `integration_test` | | `flutter_launcher_icons` dev bağımlılıklarına taşındı. `package:get` doğrudan kullanımı kaldırıldı. |

**Platform:** iOS Xcode projesindeki hedef 13.0 (Podfile'da 15.0 idi) → **15.0**. CocoaPods ile Firebase iOS SDK 12.19.0 kuruldu. Android manifestteki eski `package` özniteliği kaldırıldı. `key.properties` olmadan da debug derlemesi alınabiliyor. `MainActivity` içindeki özel exact-alarm MethodChannel'ı yerine eklentinin kendi API'si kullanılıyor.

---

## 5. Test ve doğrulama

| Kontrol | Sonuç |
|---|---|
| `flutter analyze` (tüm proje) | ✅ No issues found |
| Cloud Functions `npm run lint` + `npm run build` | ✅ 0 uyarı, derleme temiz |
| Uçtan uca test — **refactor öncesi** (iOS 15.5 simülatör, test hesabı) | ✅ Giriş + 4 sekme + 6 rapor + 6 hatırlatıcı sayfası, 0 Flutter hatası |
| iOS simülatör derlemesi — refactor sonrası (Firebase iOS SDK 12.19, `pod update` sonrası) | ✅ Başarılı |
| Uçtan uca test — **refactor sonrası** | ✅ All tests passed — giriş + 4 sekme + 6 rapor + 6 hatırlatıcı sayfası, 0 Flutter hatası (1 dk 8 sn) |
| Uçtan uca test + **gerçek AI çağrısı** (`RUN_AI_TEST=true`) | ✅ Yeni istemci (JSON modu, yeni şema), şu an yayındaki eski `openaiChat` fonksiyonuyla çalışıyor; Ask Meow geçerli yanıt döndü |
| Android debug derlemesi | ⚠️ **Disk dolu** ("No space left on device") olduğu için tamamlanamadı; kod hatası değil. Disk boşaltılınca `flutter build apk --debug` tekrar çalıştırılmalı. |

Test, `tool/run_integration_test.sh <cihaz-id>` ile tekrar çalıştırılabilir. Kimlik bilgilerini `.env.example`'dan okur. `--dart-define=RUN_AI_TEST=true` eklenirse bir gerçek AI çağrısı da yapar.

**Otomatik test edilemeyenler (cihazda elle denenmeli):** Google ve Apple ile giriş (google_sign_in 7 geçişi), gerçek satın alma ve geri yükleme (RevenueCat 10), bildirimlerin zamanında çalması ve dokununca yönlendirmesi, PDF paylaşımı, mikrofonla soru, podcast arka plan çalma.

---

## 6. Sizin yapmanız gerekenler

### Hemen (yayından önce)
1. **Diski boşaltın.** Disk %99 dolu (≈4 GB boş), Android derlemesi bu yüzden başarısız. Xcode DerivedData'nın tamamı yaklaşık 15 GB, simülatörler yaklaşık 8,5 GB, Gradle önbelleği yaklaşık 5 GB.
2. ~~**Cloud Functions'ı deploy edin**~~ — ✅ **Yapıldı (15 Ekim 2026):** `deleteAccount` oluşturuldu; `wipeUser`, `openaiChat` ve `openaiTranscribe` güncellendi. Firebase CLI 15.34.0 `npx` ile kullanıldı, çünkü global 13.5.1 `nodejs22`'yi tanımıyor. Ardından gerçek AI çağrısıyla uçtan uca test geçti.
3. **Cihazda elle test:** Google girişi (Android ve iOS), Apple girişi, satın alma ve geri yükleme, hatırlatıcılar.
4. **OpenAI anahtarı** — ✅ Yeni anahtar `OPENAI_API_KEY` sırrının 3. sürümü olarak kaydedildi ve fonksiyonlar bu sürüme bağlandı (gcloud ile doğrulandı). 1. ve 2. sürümler yok edildi. `appInfo/aiKey` veritabanından silindi. **Kalan tek adım:** eski anahtarı OpenAI panelinden iptal etmek ve bir harcama limiti tanımlamak.
5. **RevenueCat 10 uyarısı:** Tek seferlik ürünler varsa panelde "consumable / non-consumable" ayarlarının doğru olduğundan emin olun; aksi halde geri yükleme çalışmaz.
6. **Android `versionCode`** `build.gradle.kts` içinde sabit (34). Her Play yüklemesinde elle artırılmalı veya `pubspec.yaml`'a `+build` eklenip `flutter.versionCode`'a bağlanmalı.

### Firebase güvenlik kuralları — ✅ Yapıldı (15 Ekim 2026)

**Tespit edilen canlı açık:** `users` ve `questionAi` düğümlerinin kuralı `.read: true, .write: true` idi. Giriş yapmadan yapılan okuma isteği HTTP 200 döndü; veritabanı adresini bilen herkes 70 kullanıcının e-posta ve bebek bilgilerine, AI sorularına ve **40 kullanıcının düz metin şifresine** erişebiliyor, bunları değiştirip silebiliyordu. Ayrıca `appInfo` (AI sistem istemi, mağaza linkleri) giriş yapan her kullanıcı tarafından yazılabiliyordu. Storage'da giriş yapan herkes tüm dosyaları okuyup silebiliyordu.

**Yapılanlar:**
- Kurallar repoya alındı (`database.rules.json`, `storage.rules`, `firebase.json`) ve yayına alındı.
  - Kullanıcı verileri yalnızca sahibine açık.
  - `appInfo`, `updates` ve `podcasts` herkese okunur, istemciden yazılamaz.
  - `userPassword` alanına yazma ve `status` alanını değiştirme engellendi.
  - Storage'a yalnızca kendi klasörüne, 10 MB altı resim yüklenebiliyor.
- Doğrulama: `users` ve `questionAi` artık giriş yapmadan okunamıyor (HTTP 401), `appInfo` herkese okunur (HTTP 200).
- 40 kullanıcının `userPassword` alanı silindi (kalan: 0). 70 kullanıcı kaydı korundu.
- Yeni kurallarla uçtan uca test (AI çağrısı dahil) geçti. Misafirlerin `appInfo` okuyamaması sorunu da çözüldü.

**Not:** Proje sahibinin teyidine göre şifresi açıkta kalan hesaplar test kullanıcılarıydı; şifre sıfırlama veya bildirim gerekmedi.
- Yönetici "güncelleme yayınla" aracı artık `updates/`'e yazamaz. Gerekirse yönetici uid'i için kurala istisna eklenmeli.

### Ürün kararları (bilinçli olarak dokunulmadı)
10. **Onboarding ve Kullanım Koşulları onayı erişilemez durumda.** Router `/myBaby` ile başlıyor; `GetStartedPage` ve `TermsAndPrivacyModal` hiç gösterilmiyor, yani kullanıcılar Koşulları hiç kabul etmiyor. İlk açılışta bir yönlendirme mi, yoksa kayıt sırasında bir onay mı istersiniz?
11. **`updates/` "Yenilikler" özelliği:** Yönetici aracı yazıyor ama uygulamada okuyan bir ekran yok. Ya bağlanmalı ya da tamamen kaldırılmalı.

### Orta vadede
12. **Sunucu tarafı premium ve App Check:** AI kotası şu an premium'dan bağımsız (günde 60). Gerçek koruma için `firebase_app_check` + `enforceAppCheck` ve RevenueCat webhook'u ile sunucuda yetki kontrolü önerilir.
13. **Olay zamanı veri modeli:** Kayıt anahtarı hâlâ kaydetme anı; gece yarısı civarında girilen kayıt, "bugün/hafta" sorgularında yanlış güne düşebilir. Raporlardaki saat dağılımı artık doğru, ancak tam çözüm bir `eventAt` alanı + `orderByChild('eventAt')` + `.indexOn` (veri taşıma gerektirir).
14. ✅ **iOS UIScene yaşam döngüsü — yapıldı:** Flutter derlemede uyarıyor; ileriki iOS sürümlerinde zorunlu olacak. Bildirim ve ses eklentileri test edilerek geçilmeli.
15. ✅ **Swift Package Manager — yapıldı:** CocoaPods tamamen kaldırıldı. FlutterFire, google_sign_in_ios GoogleSignIn 10'a geçene kadar 4.x'te tutuluyor. Eski not: Firebase, Ekim 2026'dan sonra CocoaPods'a yeni sürüm yayınlamıyor. SPM'e geçiş planlanmalı. Henüz desteklemeyenler: `sign_in_with_apple`, `flutter_image_compress_common`.
16. **firebase-functions paketi:** Deploy sırasında CLI `firebase-functions` ^6 için "outdated" uyarısı verdi; 7.x geçişi kırıcı değişiklikler içeriyor, ayrıca planlanmalı.
17. **AGP 9:** Flutter, AGP 9'a geçişte `android.newDsl` ayarı için uyarı veriyor (`gradle.properties`'te şu an `false`). Gradle eklentileri (google-services 4.3.15, crashlytics 2.8.1) de eski; ayrıca güncellenmeli.
18. **Commit:** Değişiklikler `refactor/modernize-2026` branch'inde, commit edilmemiş durumda. İnceledikten sonra mantıksal parçalara bölünerek commit edilmesi önerilir.

---

## 7. Değişen başlıca dosyalar (referans)

- **Çekirdek:** `main.dart`, `service/app_init_service.dart`, `service/authentication_service.dart`, `service/database_service.dart`, `service/in_app_purchase_service.dart`, `service/analytic_service.dart`, `service/global_functions.dart`, `constants/app_pages.dart`, `constants/app_constants.dart`
- **Yeni ortak modüller:** `utils/date_range.dart`, `utils/platform_info.dart`, `utils/url_utils.dart`, `utils/pdf/report_pdf.dart`, `service/activities/activity_store.dart`, `service/reminders/*`, `service/gpt_service/common/ai_common.dart`, `models/ai_models/{ai_report_insight,lenient_json}.dart`, `models/activities/record_parsing.dart`
- **Ekranlar:** `screens/navigationbar/my-baby/widgets/*`, `my-baby/reminders/*`, `home/widgets/*`, `premium/widgets/*`, `auth/widgets/*`, `get-started/widgets/baby_info_form.dart`, `profile/widgets/*`
- **Sunucu:** `functions/src/index.ts`
- **Test:** `integration_test/app_flow_test.dart`, `tool/run_integration_test.sh`
- **Platform:** `ios/Runner.xcodeproj/project.pbxproj`, `ios/Podfile.lock`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt`
- **Dokümantasyon:** `CLAUDE.md` (yeni mimariye göre güncellendi)
