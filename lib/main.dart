import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_globals.dart';
import 'package:mama_meow/constants/app_localization.dart';
import 'package:mama_meow/constants/app_pages.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/service/app_init_service.dart';
import 'package:mama_meow/service/audio/background_handler.dart';

late final PodcastAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitService.initApp();

  audioHandler = await AudioService.init(
    builder: () => PodcastAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yildiz.mama_meow.podcast',
      androidNotificationChannelName: 'Podcast Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runMyApp();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => AppInitService.initAfterFirstFrame(),
  );
}

void runMyApp() {
  return runApp(
    MaterialApp.router(
      title: 'Coo Care Baby Tracker',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: AppLocalization.locale,
      supportedLocales: AppLocalization.supportedLocales,
      localizationsDelegates: AppLocalization.localizationsDelegates,
      routerConfig: router,
    ),
  );
}
