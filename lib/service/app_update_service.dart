import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mama_meow/utils/platform_info.dart';

class AppUpdateService {
  static const _defaultPlayUrl =
      'https://play.google.com/store/apps/details?id=com.yildiz.mama_meow';
  static const _defaultAppStoreUrl =
      'https://apps.apple.com/us/app/mamameow-track-learn-ask-ai/id6752356932';

  final DatabaseReference _appInfoRef = FirebaseDatabase.instance.ref(
    'appInfo',
  );

  Future<void> checkAndShowUpdateIfNeeded(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final snapshot = await _appInfoRef.get();
      if (!snapshot.exists || snapshot.value == null) return;

      final data = snapshot.value;
      if (data is! Map) return;
      final latestVersion = PlatformInfo.isIOS
          ? data['iosVersion']?.toString() ?? ''
          : data['androidVersion']?.toString() ?? '';
      final storeUrl = PlatformInfo.isIOS
          ? data['iosUrl']?.toString() ?? ''
          : data['androidUrl']?.toString() ?? '';

      if (latestVersion.isEmpty) return;

      final hasUpdate = _isVersionLess(currentVersion, latestVersion);
      if (!hasUpdate) return;

      if (!context.mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;

      await _showUpdateDialog(
        context,
        force: false,
        message:
            'A new version is available. Update now to get the latest improvements.',
        storeUrl: storeUrl.isNotEmpty
            ? storeUrl
            : (PlatformInfo.isIOS ? _defaultAppStoreUrl : _defaultPlayUrl),
        latestVersion: latestVersion,
      );
    } catch (e) {
      debugPrint('AppUpdateService: $e');
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
      builder: (_) => PopScope(
        canPop: !force,
        // Renkler temadan gelir: beyaz diyalog, charcoal başlık/metin,
        // berry ink "Later", berry hap "Update".
        child: AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            latestVersion.isNotEmpty
                ? '$message\nNew version: $latestVersion'
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

  bool _isVersionLess(String current, String latest) {
    final pa = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;

    while (pa.length < len) {
      pa.add(0);
    }
    while (pb.length < len) {
      pb.add(0);
    }

    for (int i = 0; i < len; i++) {
      if (pa[i] < pb[i]) return true;
      if (pa[i] > pb[i]) return false;
    }
    return false;
  }
}
