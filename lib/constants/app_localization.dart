import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalization {
  static const Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates =
      [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static const Locale locale = Locale("en");

  static const List<Locale> supportedLocales = [Locale("en")];

}
