import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GlobalFunction {
  factory GlobalFunction() {
    return _singleton;
  }

  GlobalFunction._internal();
  static final GlobalFunction _singleton = GlobalFunction._internal();

  ///Bu fonksiyonu sadece main.dart'da sayfalarımızın URL'leri set ederken kullanacağız.
  bool isMobile() {
    final Size size =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final double pixelRatio =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final double width = size.width; //Resolution olarak width verir
    if (width / pixelRatio < 768) {
      return true;
    } else {
      return false;
    }
  }

  bool isNullOrEmpty(String? value) {
    if (value == null) {
      return true;
    } else if (value.isEmpty) {
      return true;
    } else if (value == "") {
      return true;
    } else {
      return false;
    }
  }

  String? nonEmptyRule(value) {
    if (value == null) {
      return '';
    }
    if (value == "") {
      return '';
    }
    return null;
  }

  String? phoneValidator(String? value) {
    if (value == null) {
      return '';
    }
    if (value == "") {
      return '';
    }

    if (value.length < 12 || value.length > 19) {
      return '';
    }

    return null;
  }

  bool validateAndSave(formKey) {
    final form = formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  String? emailValidator(value) {
    const String p =
        r'^[a-z0-9!#$%&"*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&"*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$';

    if (RegExp(p).hasMatch(value)) {
      return null;
    } else {
      return '';
    }
  }

  String formatedDateHourWUI(String date) {
    if (isDate(date)) {
      return DateFormat('dd.MM.yyyy HH:mm', 'tr').format(DateTime.parse(date));
    } else {
      return "";
    }
  }

  String formatedDateHour(String date) {
    if (isDate(date)) {
      return DateFormat('dd.MM.yyyy', 'tr').format(DateTime.parse(date));
    } else {
      return "";
    }
  }

  bool isDate(String str) {
    try {
      DateTime.parse(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Image imageFromBase64String(String base64String) {
    return Image.memory(base64Decode(base64String));
  }

  Uint8List dataFromBase64String(String base64String) {
    return base64Decode(base64String);
  }

  String base64StringConverter(Uint8List data) {
    return base64Encode(data);
  }

  bool isImageFile(String fileName) {
    final imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff',
      '.svg',
    ];
    return imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  bool isPdf(String fileName) {
    final imageExtensions = ['.pdf'];
    return imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  String checkNullableFloatString(String? nullableFloatString) {
    if (nullableFloatString != null) {
      return nullableFloatString;
    }
    return "";
  }

  Future<String> getApplicationVersionNumber() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint(e.toString());
      return "";
    }
  }

  Future<String> getDeviceVersionFunction() async {
    String deviceVersion = "unknown";

    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceVersion = "Android ${androidInfo.version.release}";
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceVersion = "iOS ${iosInfo.systemVersion}";
      }
    } catch (e) {
      deviceVersion = "unknown";
    }

    return deviceVersion;
  }

    Future<String> downloadBytes(Uint8List bytes, String filename) async {
    final safeName = filename.trim().isEmpty ? 'report.pdf' : filename.trim();
    final name = safeName.toLowerCase().endsWith('.pdf')
        ? safeName
        : '$safeName.pdf';

    final dir = Directory.systemTemp; // mobilde hızlı ve garanti
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

final globalFunctions = GlobalFunction();
