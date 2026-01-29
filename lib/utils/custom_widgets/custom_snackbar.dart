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
  final double _borderRadius = 8.0;
  final EdgeInsets _margin = const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );
  final EdgeInsets _padding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

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

  void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required Icon icon,
  }) {
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
                    Text(title, style: _titleStyle),
                    const SizedBox(height: 4),
                    Text(message, style: _messageStyle),
                  ],
                ),
              ),
              InkWell(
                onTap: messenger.hideCurrentSnackBar,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    "Ok",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
