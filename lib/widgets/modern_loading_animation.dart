import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utilities/constants.dart';

class ModernLoadingAnimation extends StatefulWidget {
  final String? loadingText;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const ModernLoadingAnimation({
    super.key,
    this.loadingText,
    this.primaryColor = Constants.primaryColor,
    this.secondaryColor = Constants.secondaryColor,
    this.size = 200.0,
  });

  @override
  State<ModernLoadingAnimation> createState() => _ModernLoadingAnimationState();
}

class _ModernLoadingAnimationState extends State<ModernLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(20),
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

                  // Animated circular progress
                  Center(
                    child: SizedBox(
                      width: widget.size * 0.7,
                      height: widget.size * 0.7,
                      child: CircularProgressIndicator(
                        value: null, // Indeterminate
                        strokeWidth: 6,
                        backgroundColor: widget.primaryColor.withAlpha(
                          51,
                        ), // 0.2 * 255 = 51
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  // Pulsing circle
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Container(
                          width: widget.size * 0.4 * value,
                          height: widget.size * 0.4 * value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryColor.withAlpha(
                              ((1 - value) * 255).round(),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        setState(() {});
                      },
                    ),
                  ),

                  // Center icon
                  Center(
                    child: Icon(
                      Icons.water_drop,
                      size: widget.size * 0.25,
                      color: widget.primaryColor,
                    ),
                  ),

                  // Rotating dots
                  ...List.generate(4, (index) {
                    final angle = 2 * math.pi * (index / 4 + _controller.value);
                    final radius = widget.size * 0.35;
                    final x = widget.size / 2 + radius * math.cos(angle);
                    final y = widget.size / 2 + radius * math.sin(angle);

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
                            index / 4,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
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
