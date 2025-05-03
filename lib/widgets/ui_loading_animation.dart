import 'package:flutter/material.dart';

class UILoadingAnimation extends StatefulWidget {
  final String? loadingText;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const UILoadingAnimation({
    super.key,
    this.loadingText,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.lightBlue,
    this.size = 200.0,
  });

  @override
  State<UILoadingAnimation> createState() => _UILoadingAnimationState();
}

class _UILoadingAnimationState extends State<UILoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          red: 0,
                          green: 0,
                          blue: 0,
                          alpha: 26, // 0.1 * 255 = 25.5, rounded to 26
                        ),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background gradient
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.primaryColor.withAlpha(
                                26,
                              ), // 0.1 * 255 = 25.5, rounded to 26
                              widget.secondaryColor.withAlpha(
                                26,
                              ), // 0.1 * 255 = 25.5, rounded to 26
                            ],
                          ),
                        ),
                      ),

                      // Animated elements
                      ...List.generate(4, (index) {
                        final delay = index * 0.25;
                        final progress = (_controller.value + delay) % 1.0;
                        final size = widget.size * 0.15 * (1 + progress * 0.5);
                        final opacity = (1 - progress) * 0.8;

                        return Positioned(
                          left: widget.size / 2 - size / 2,
                          top: widget.size / 2 - size / 2,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  widget.primaryColor,
                                  widget.secondaryColor,
                                  progress,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Pulsing circles
                      ...List.generate(3, (index) {
                        final progress =
                            (_controller.value + index * 0.33) % 1.0;
                        final size = widget.size * progress * 0.9;
                        final opacity = (1 - progress) * 0.5;

                        return Positioned(
                          left: widget.size / 2 - size / 2,
                          top: widget.size / 2 - size / 2,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Color.lerp(
                                        widget.primaryColor,
                                        widget.secondaryColor,
                                        progress,
                                      )!,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Center icon
                      Center(
                        child: Icon(
                          Icons.water_drop,
                          size: widget.size * 0.3,
                          color: widget.primaryColor,
                        ),
                      ),

                      // Progress indicators
                      ...List.generate(4, (index) {
                        final angle = index * (3.14159 / 2); // 90 degrees apart
                        final progress =
                            (_controller.value + index * 0.25) % 1.0;
                        final radius = widget.size * 0.4;
                        final x = widget.size / 2 + radius * cos(angle);
                        final y = widget.size / 2 + radius * sin(angle);

                        return Positioned(
                          left: x - 5,
                          top: y - 5,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                widget.primaryColor,
                                widget.secondaryColor,
                                progress,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.loadingText != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.loadingText!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.primaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

// Helper function to convert degrees to radians
double cos(double angle) {
  return Math.cos(angle);
}

double sin(double angle) {
  return Math.sin(angle);
}

// Math utilities
class Math {
  static double cos(double angle) {
    return SimpleMath.cos(angle);
  }

  static double sin(double angle) {
    return SimpleMath.sin(angle);
  }
}

// Simple math implementation to avoid importing dart:math
class SimpleMath {
  static double cos(double angle) {
    // Simple cosine approximation
    // For a proper implementation, use dart:math
    final double a = angle % (2 * 3.14159);
    if (a < 3.14159 / 2) {
      return 1 - 2 * (a / (3.14159 / 2)) * (a / (3.14159 / 2));
    }
    if (a < 3.14159) {
      return -cos(3.14159 - a);
    }
    return cos(a - 3.14159);
  }

  static double sin(double angle) {
    return cos(angle - 3.14159 / 2);
  }
}
