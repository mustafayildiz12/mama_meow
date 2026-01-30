import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static const _defaultPlayUrl =
      'https://play.google.com/store/apps/details?id=com.yildiz.mama_meow';
  static const _defaultAppStoreUrl =
      'https://apps.apple.com/us/app/mamameow-baby-tracker-ai/id6752356932';

  Future<void> checkAndShowUpdateIfNeeded(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // "1.2.3"

      final rc = FirebaseRemoteConfig.instance;

      await rc.ensureInitialized();

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );

      final ok = await rc.fetchAndActivate();

      debugPrint('RC fetchAndActivate ok: $ok');
      debugPrint('RC lastFetchStatus: ${rc.lastFetchStatus}');
      debugPrint('RC lastFetchTime: ${rc.lastFetchTime}');
      debugPrint('RC all keys: ${rc.getAll().keys.toList()}');

      for (final e in rc.getAll().entries) {
        debugPrint('RC ${e.key} = ${e.value.asString()}');
      }

      final minVersion = Platform.isIOS
          ? rc.getString('min_version_ios')
          : rc.getString('min_version_android');

      final latestVersion = Platform.isIOS
          ? rc.getString('latest_version_ios')
          : rc.getString('latest_version_android');

      final force = Platform.isIOS
          ? rc.getBool('force_update_ios')
          : rc.getBool('force_update_android');

      final message = rc.getString('update_message_tr');
      final storeUrl = Platform.isIOS
          ? (rc.getString('appstore_url').isNotEmpty
                ? rc.getString('appstore_url')
                : _defaultAppStoreUrl)
          : (rc.getString('playstore_url').isNotEmpty
                ? rc.getString('playstore_url')
                : _defaultPlayUrl);

      // Eğer RC boş dönerse, hiç rahatsız etmeyelim:
      if (minVersion.isEmpty && latestVersion.isEmpty) return;

      final mustUpdate =
          minVersion.isNotEmpty && _isVersionLess(current, minVersion);

      final hasUpdate =
          latestVersion.isNotEmpty && _isVersionLess(current, latestVersion);

      if (!mustUpdate && !hasUpdate) return;

      // Zaten ekranda modal varsa üst üste bindirmemek için:
      if (ModalRoute.of(context)?.isCurrent != true) return;

      await _showUpdateDialog(
        context,
        force: mustUpdate || force,
        message: message.isNotEmpty
            ? message
            : (mustUpdate
                  ? 'A new version is available. Update now to get the latest improvements.'
                  : 'A new version is available. Update now to get the latest improvements.'),
        storeUrl: storeUrl,
        latestVersion: latestVersion,
      );
    } catch (e) {
      print("Failed to configure remote config. $e");
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context, {
    required bool force,
    required String message,
    required String storeUrl,
    required String latestVersion,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (_) => WillPopScope(
        onWillPop: () async => !force,
        child: AlertDialog(
          title: Text('Update Available'),
          content: Text(
            latestVersion.isNotEmpty
                ? '$message\n New Version: $latestVersion'
                : message,
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
            FilledButton(
              onPressed: () async {
                final uri = Uri.parse(storeUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!context.mounted) return;
                if (!force) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isVersionLess(String a, String b) {
    // "1.2.3" vs "1.10.0" gibi durumları doğru karşılaştırır
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;

    while (pa.length < len) pa.add(0);
    while (pb.length < len) pb.add(0);

    for (int i = 0; i < len; i++) {
      if (pa[i] < pb[i]) return true;
      if (pa[i] > pb[i]) return false;
    }
    return false;
  }
}
