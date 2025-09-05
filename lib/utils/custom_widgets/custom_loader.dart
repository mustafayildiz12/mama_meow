import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({
    required this.child,
    required this.inAsyncCall,
    super.key,
    this.opacity = 0.3,
    this.color = Colors.black,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.5, 0.8],
                          colors: [
                            Colors.pink.shade100,
                            Colors.pink.shade400,
                            Colors.pink.shade100,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading",
                      style: TextStyle(
                        color: Colors.pink.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
