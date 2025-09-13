import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalization {
  static Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates =
      const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static Locale locale = const Locale("en");

  static List<Locale> supportedLocales = const [Locale("en")];

  static Locale fallbackLocale = const Locale("en");

  /// Cihaz dili (uygulamanın dili değil)
  static String get deviceLanguageCode =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
}
