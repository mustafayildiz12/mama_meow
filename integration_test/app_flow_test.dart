// Uçtan uca duman (smoke) testi: gerçek Firebase projesine test hesabıyla
// giriş yapar, tüm sekmeleri ve aktivite rapor/hatırlatıcı sayfalarını gezer,
// bu sırada oluşan Flutter hatalarını toplayıp testin sonunda raporlar.
//
// Çalıştırma (kimlik bilgileri .env.example'dan okunur):
//   tool/run_integration_test.sh [device-id]
//
// AI proxy testi varsayılan olarak kapalıdır (günlük kotayı/maliyeti tüketir);
// açmak için: --dart-define=RUN_AI_TEST=true

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mama_meow/constants/app_pages.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/main.dart' as app;
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/gpt_service/gpt_service.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _runAiTest = bool.fromEnvironment('RUN_AI_TEST');

/// [finder] görünene kadar kare kare ilerler. `pumpAndSettle` sonsuz
/// animasyonlu ekranlarda (loader vb.) zaman aşımına düştüğü için kullanılmaz.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Zaman aşımı: ${reason ?? 'koşul sağlanmadı'}');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> settle(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('giriş + tüm ekranları gezme', (tester) async {
    expect(
      _email.isNotEmpty && _password.isNotEmpty,
      isTrue,
      reason: 'TEST_EMAIL / TEST_PASSWORD --dart-define ile verilmeli',
    );

    await app.main();
    await settle(tester);

    // Uygulama hataları Crashlytics'e yönlendiriyor; testte görünür olmaları
    // için kendi toplayıcımızı takıyoruz.
    final errors = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add('${details.exceptionAsString()}\n${details.stack}');
    };

    try {
      // Önceki çalıştırmadan kalan oturum varsa giriş akışını gerçekten
      // test edebilmek için önce çıkış yap.
      if (FirebaseAuth.instance.currentUser != null) {
        await authenticationService.logoutFromFirebase();
        await settle(tester);
      }

      // ---- Giriş ----
      router.go(AppRoutes.loginPage);
      await pumpUntil(
        tester,
        () => find.text('Sign In').evaluate().isNotEmpty,
        reason: 'giriş ekranı açılmadı',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your email'),
        _email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter your password'),
        _password,
      );
      await tester.tap(find.text('Sign In'));
      await pumpUntil(
        tester,
        () => FirebaseAuth.instance.currentUser != null,
        reason: 'Firebase oturumu açılmadı',
      );
      await pumpUntil(
        tester,
        () => find.text('My Baby').evaluate().isNotEmpty,
        reason: 'giriş sonrası alt menü görünmedi',
      );
      await binding.takeScreenshot('01_after_login');

      // ---- Sekmeler ----
      for (final tab in ['My Baby', 'Learn', 'Profile', 'Ask Meow']) {
        await tester.tap(find.text(tab).last);
        await settle(tester, 25);
        await binding.takeScreenshot('tab_${tab.replaceAll(' ', '_')}');
      }

      // ---- Aktivite rapor ve hatırlatıcı sayfaları ----
      const subRoutes = [
        AppRoutes.sleepReport,
        AppRoutes.nursingReport,
        AppRoutes.solidReport,
        AppRoutes.diaperReport,
        AppRoutes.pumpingReport,
        AppRoutes.medicineReport,
        AppRoutes.sleepReminders,
        AppRoutes.nursingReminders,
        AppRoutes.solidReminders,
        AppRoutes.diaperReminders,
        AppRoutes.pumpingReminders,
        AppRoutes.medicineReminders,
      ];
      for (final sub in subRoutes) {
        router.go('${AppRoutes.myBaby}/$sub');
        await settle(tester, 30);
        await binding.takeScreenshot('page_$sub');
      }
      router.go(AppRoutes.myBaby);
      await settle(tester);

      // ---- (Opsiyonel) AI proxy: tek bir gerçek çağrı ----
      if (_runAiTest) {
        final answer = await GptService().askMia(
          'How many hours should a 3 month old sleep?',
        );
        expect(answer, isNotNull, reason: 'openaiChat yanıt vermedi');
      }
    } finally {
      FlutterError.onError = originalOnError;
    }

    if (errors.isNotEmpty) {
      // ignore: avoid_print
      print('=== Gezinti sırasında ${errors.length} Flutter hatası ===');
      for (final e in errors) {
        // ignore: avoid_print
        print('---\n$e');
      }
    }
    expect(errors, isEmpty, reason: 'Ekran gezintisinde Flutter hataları oluştu');
  });
}
