// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mama_meow/constants/app_colors.dart';

class CustomSnackBar {
  factory CustomSnackBar() => _singleton;
  CustomSnackBar._internal();
  static final CustomSnackBar _singleton = CustomSnackBar._internal();

  // Snackbar Görünüm Sabitleri
  final Duration _duration = const Duration(seconds: 4, milliseconds: 500);
  final double _borderRadius = 8.0;
  final EdgeInsets _margin = const EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 12.0,
  );
  final EdgeInsets _padding = const EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  // İkon Boyutları ve Stiller
  final TextStyle _titleStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  final TextStyle _messageStyle = const TextStyle(
    fontSize: 13,
    color: Colors.white,
    height: 1.2,
  );

  Future<void> _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required Icon icon,
  }) async {
    if (Get.context == null) {
      return;
    }
    if (Get.isSnackbarOpen) {
      await Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      titleText: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Text(title, style: _titleStyle),
        ],
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Text(message, style: _messageStyle),
      ),
      backgroundColor: backgroundColor,
      borderRadius: _borderRadius,
      margin: _margin,
      padding: _padding,
      duration: _duration,
      snackPosition: SnackPosition.TOP,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      overlayBlur: 0.0,
      overlayColor: Colors.black12,
      mainButton: TextButton(
        onPressed: () => Get.closeCurrentSnackbar(),
        child: Text(
          "Ok",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> success(String message) async {
    _showSnackbar(
      title: "Success",
      message: message,
      backgroundColor: Colors.blue.shade500,
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Future<void> error(String message) async {
    _showSnackbar(
      title: "Error",
      message: message,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Future<void> warning(String message) async {
    _showSnackbar(
      title: "Warning",
      message: message,

      backgroundColor: Colors.orange.withValues(alpha: 0.75),
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Future<void> tips(String message) async {
    _showSnackbar(
      title: "Tips",
      message: message,

      backgroundColor: AppColors.pink500.withValues(alpha: 0.75),
      icon: const Icon(Icons.info, color: Colors.white, size: 20),
    );
  }
}

final CustomSnackBar customSnackBar = CustomSnackBar();
