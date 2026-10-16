import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({
    required this.child,
    required this.inAsyncCall,
    super.key,
    this.opacity = 0.4,
    this.color = AppColors.deepCharcoal,
  });
  final Widget child;
  final bool inAsyncCall;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetList = [];
    widgetList.add(child);
    if (inAsyncCall) {
      final modal = Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: color.withValues(alpha: opacity),
              child: const ModalBarrier(
                dismissible: false,
                color: Colors.transparent,
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cottonWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.floatShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.pinkTint,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.activeBerry,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Loading",
                      style: TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      widgetList.add(modal);
    }
    return Stack(children: widgetList);
  }
}
