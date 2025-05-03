import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterLoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Color backgroundColor;
  final Duration duration;
  final String? loadingText;

  const WaterLoadingAnimation({
    super.key,
    this.size = 200.0,
    this.color = const Color(0xFF1976D2),
    this.backgroundColor = Colors.white,
    this.duration = const Duration(seconds: 2),
    this.loadingText,
  });

  @override
  State<WaterLoadingAnimation> createState() => _WaterLoadingAnimationState();
}

class _WaterLoadingAnimationState extends State<WaterLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waveAnimation;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _heightAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundColor,
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
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _WaterPainter(
                  waveOffset: _waveAnimation.value,
                  fillLevel: _heightAnimation.value,
                  color: widget.color,
                  droplets: 5 + (_controller.value * 5).toInt(),
                ),
              );
            },
          ),
        ),
        if (widget.loadingText != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.loadingText!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ],
      ],
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double waveOffset;
  final double fillLevel;
  final Color color;
  final int droplets;

  _WaterPainter({
    required this.waveOffset,
    required this.fillLevel,
    required this.color,
    required this.droplets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    // Draw tank outline
    final outlinePaint =
        Paint()
          ..color = color.withAlpha(77) // 0.3 * 255 = 76.5, rounded to 77
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(centerX, centerY), radius - 2, outlinePaint);

    // Create a clip path for the circle
    final clipPath =
        Path()..addOval(
          Rect.fromCircle(center: Offset(centerX, centerY), radius: radius - 4),
        );

    canvas.clipPath(clipPath);

    // Draw water
    final waterPaint =
        Paint()
          ..color = color.withAlpha(179) // 0.7 * 255 = 178.5, rounded to 179
          ..style = PaintingStyle.fill;

    final waterPath = Path();
    final waterHeight = size.height * (1 - fillLevel);

    // Starting point for the wave
    waterPath.moveTo(0, waterHeight);

    // Draw the wave
    for (double i = 0; i <= size.width; i++) {
      final waveHeight = 10.0 * math.sin((i / 30) + waveOffset);
      waterPath.lineTo(i, waterHeight + waveHeight);
    }

    // Complete the path
    waterPath.lineTo(size.width, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();

    canvas.drawPath(waterPath, waterPaint);

    // Draw water droplets
    final dropletPaint =
        Paint()
          ..color = color.withAlpha(153) // 0.6 * 255 = 153
          ..style = PaintingStyle.fill;

    final random = math.Random(droplets);
    for (int i = 0; i < droplets; i++) {
      final dropX = random.nextDouble() * size.width;
      final dropY = waterHeight - (random.nextDouble() * 40) - 10;
      final dropSize = 2 + random.nextDouble() * 4;

      canvas.drawCircle(Offset(dropX, dropY), dropSize, dropletPaint);
    }

    // Draw bubbles in the water
    final bubblePaint =
        Paint()
          ..color = Colors.white.withAlpha(
            128,
          ) // 0.5 * 255 = 127.5, rounded to 128
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final bubbleX = random.nextDouble() * size.width;
      final bubbleY =
          waterHeight + (random.nextDouble() * (size.height - waterHeight));
      final bubbleSize = 2 + random.nextDouble() * 5;

      canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleSize, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillLevel != fillLevel ||
        oldDelegate.droplets != droplets;
  }
}
