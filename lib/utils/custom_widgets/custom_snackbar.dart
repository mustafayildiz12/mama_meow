// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_globals.dart';

class CustomSnackBar {
  factory CustomSnackBar() => _singleton;
  CustomSnackBar._internal();
  static final CustomSnackBar _singleton = CustomSnackBar._internal();

  // Snackbar sabitleri
  final Duration _duration = const Duration(seconds: 4, milliseconds: 500);
  final double _borderRadius = 16.0;
  final EdgeInsets _margin = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );
  final EdgeInsets _padding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
    required Icon icon,
  }) {
    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: foregroundColor,
    );
    final messageStyle = TextStyle(
      fontSize: 13,
      color: foregroundColor,
      height: 1.3,
    );
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: _duration,
        margin: _margin,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: _padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: AppColors.floatShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 4),
                    Text(message, style: messageStyle),
                  ],
                ),
              ),
              InkWell(
                onTap: messenger.hideCurrentSnackBar,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    "Ok",
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === PUBLIC API (AYNI) ===

  Future<void> success(String message) async {
    _showSnackbar(
      title: "Success",
      message: message,
      backgroundColor: AppColors.deepCharcoal,
      foregroundColor: AppColors.cottonWhite,
      icon: const Icon(
        Icons.check_circle_outline,
        color: AppColors.warmPink,
        size: 20,
      ),
    );
  }

  Future<void> error(String message) async {
    _showSnackbar(
      title: "Error",
      message: message,
      backgroundColor: AppColors.berryInk,
      foregroundColor: AppColors.cottonWhite,
      icon: const Icon(
        Icons.error_outline_rounded,
        color: AppColors.cottonWhite,
        size: 20,
      ),
    );
  }

  Future<void> warning(String message) async {
    _showSnackbar(
      title: "Warning",
      message: message,
      backgroundColor: AppColors.peachPastel,
      foregroundColor: AppColors.deepCharcoal,
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.deepCharcoal,
        size: 20,
      ),
    );
  }

  Future<void> tips(String message) async {
    _showSnackbar(
      title: "Tips",
      message: message,
      backgroundColor: AppColors.pinkTint,
      foregroundColor: AppColors.deepCharcoal,
      icon: const Icon(
        Icons.lightbulb_outline,
        color: AppColors.activeBerry,
        size: 20,
      ),
    );
  }
}

final CustomSnackBar customSnackBar = CustomSnackBar();
