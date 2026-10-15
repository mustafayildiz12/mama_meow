import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/utils/platform_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

/// Mağaza linkleri (paylaşım/davet metinleri için).
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.yildiz.mama_meow';

/// App Store numeric ID (App Store Connect).
const String kAppStoreId = '6752356932';

/// Locale-bağımsız App Store linki (paylaşım için).
const String kAppStoreUrl = 'https://apps.apple.com/app/id$kAppStoreId';

class GlobalFunction {
  factory GlobalFunction() => _singleton;
  GlobalFunction._internal();
  static final GlobalFunction _singleton = GlobalFunction._internal();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-z0-9.!#$%&*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$',
    caseSensitive: false,
  );

  String? nonEmptyRule(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  bool validateAndSave(GlobalKey<FormState> formKey) {
    final form = formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  /// Büyük/küçük harf duyarsız; baştaki/sondaki boşluklar (otomatik
  /// doldurma) hata sayılmaz.
  String? emailValidator(Object? value) {
    final email = value?.toString().trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    if (!_emailRegExp.hasMatch(email)) return 'Please enter a valid email';
    return null;
  }

  Future<String> getApplicationVersionNumber() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  Future<String> getDeviceVersionFunction() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (PlatformInfo.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return "Android ${androidInfo.version.release}";
      } else if (PlatformInfo.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return "iOS ${iosInfo.systemVersion}";
      }
    } catch (e) {
      debugPrint("getDeviceVersionFunction failed: $e");
    }
    return "unknown";
  }

  /// Uygulamayı önermek için davet metni (mağaza linkiyle).
  String appInviteText() {
    final link = PlatformInfo.isIOS ? kAppStoreUrl : kPlayStoreUrl;
    return "I'm using Coo Care Baby Tracker to track my baby and get instant AI parenting "
        "answers 🐾 Try it: $link";
  }

  /// iPad/Mac'te paylaşım sayfasının (popover) nereden açılacağını belirten
  /// kaynak dikdörtgen. iOS'ta bu verilmezse paylaşım sayfası açılamaz/çöker.
  /// iPhone'da etkisizdir.
  Rect? _shareOrigin(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Düz metin paylaşımı (AI cevabı, davet vb.).
  ///
  /// [context] verilirse iPad/Mac'te paylaşım popover'ı doğru konumdan açılır.
  Future<void> shareText(
    String text, {
    String? subject,
    BuildContext? context,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: _shareOrigin(context),
        ),
      );
    } catch (e) {
      debugPrint("shareText error: $e");
    }
  }

  /// Uygulamayı arkadaşa öner (mağaza linki + davet metni).
  Future<void> shareAppInvite({BuildContext? context}) =>
      shareText(appInviteText(), context: context);

  /// Bir PDF dosyasını paylaş (rapor paylaşımı).
  Future<void> sharePdf(
    String path, {
    String? text,
    BuildContext? context,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: text ?? appInviteText(),
          sharePositionOrigin: _shareOrigin(context),
        ),
      );
    } catch (e) {
      debugPrint("sharePdf error: $e");
    }
  }

  /// PDF baytlarını geçici dizine yazar ve dosya yolunu döner.
  Future<String> downloadBytes(Uint8List bytes, String filename) async {
    final safeName = filename.trim().isEmpty ? 'report.pdf' : filename.trim();
    final name = safeName.toLowerCase().endsWith('.pdf')
        ? safeName
        : '$safeName.pdf';

    final file = File('${Directory.systemTemp.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

final globalFunctions = GlobalFunction();
