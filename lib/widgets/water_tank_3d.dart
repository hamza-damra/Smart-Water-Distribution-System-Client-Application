import 'package:flutter/material.dart';
import 'dart:math' as math;

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) => Color.fromRGBO(
  (color.r * 255.0).round() & 0xff,
  (color.g * 255.0).round() & 0xff,
  (color.b * 255.0).round() & 0xff,
  opacity,
);

class WaterTank3D extends StatefulWidget {
  final double waterLevel; // 0.0 to 1.0
  final double maxCapacity;
  final double currentLevel;

  const WaterTank3D({
    super.key,
    required this.waterLevel,
    required this.maxCapacity,
    required this.currentLevel,
  });

  @override
  State<WaterTank3D> createState() => _WaterTank3DState();
}

class _WaterTank3DState extends State<WaterTank3D>
    with TickerProviderStateMixin {
  late AnimationController _levelController;
  late AnimationController _waveController;
  late Animation<double> _levelAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    _levelController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _levelAnimation = Tween<double>(begin: 0.0, end: widget.waterLevel).animate(
      CurvedAnimation(parent: _levelController, curve: Curves.easeInOut),
    );

    // Wave animation for realistic water movement
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_waveController);

    _levelController.forward();
    _waveController.repeat(); // Continuous wave animation
  }

  @override
  void didUpdateWidget(WaterTank3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waterLevel != widget.waterLevel) {
      _levelAnimation = Tween<double>(
        begin: _levelAnimation.value,
        end: widget.waterLevel,
      ).animate(
        CurvedAnimation(parent: _levelController, curve: Curves.easeInOut),
      );
      _levelController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _levelController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            withValues(Colors.grey.shade50, 0.95),
            withValues(Colors.blue.shade50, 0.8),
            withValues(Colors.grey.shade100, 0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: withValues(Colors.grey.shade300, 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: withValues(Colors.black, 0.08),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: withValues(Colors.blue, 0.05),
            blurRadius: 40,
            spreadRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Wide tank taking most of the space
          Positioned(
            left: 16,
            top: 20,
            bottom: 20,
            right: 80, // Space for compact indicators
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _levelAnimation,
                    _waveAnimation,
                  ]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: Professional3DTankPainter(
                        waterLevel: _levelAnimation.value,
                        wavePhase: _waveAnimation.value,
                      ),
                      size: const Size(320, 340), // Much wider tank
                    );
                  },
                ),
              ),
            ),
          ),

          // Compact level indicators
          Positioned(
            right: 16,
            top: 50,
            bottom: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLevelIndicator('100%', 1.0),
                _buildLevelIndicator('75%', 0.75),
                _buildLevelIndicator('50%', 0.5),
                _buildLevelIndicator('25%', 0.25),
                _buildLevelIndicator('0%', 0.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIndicator(String label, double level) {
    final isActive = widget.waterLevel >= level;
    final color = isActive ? Colors.blue.shade700 : Colors.grey.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact indicator line
        Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                        Colors.blue.shade700,
                      ],
                    )
                    : null,
            color: isActive ? null : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        // Compact label
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class Professional3DTankPainter extends CustomPainter {
  final double waterLevel; // 0.0 → 1.0
  final double wavePhase; // 0.0 → 2π for wave animation

  Professional3DTankPainter({required this.waterLevel, this.wavePhase = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tankWidth = size.width * 0.85; // Much wider tank
    final tankHeight = size.height * 0.85;
    final tankTopY = center.dy - tankHeight / 2;
    final tankBottomY = center.dy + tankHeight / 2;

    _drawShadow(canvas, center, tankWidth, tankHeight);
    _drawTankBody(canvas, center, tankWidth, tankHeight);

    if (waterLevel > 0) {
      _drawWater(canvas, center, tankWidth, tankHeight, tankBottomY);
    }

    _drawTopRim(canvas, center, tankWidth, tankTopY);
    _drawBottomBase(canvas, center, tankWidth, tankBottomY);
  }

  void _drawShadow(Canvas canvas, Offset c, double w, double h) {
    // 🌟 ENHANCED 3D SHADOWS FOR DEPTH

    // Primary shadow (sharp, close to tank)
    final primaryShadowPaint =
        Paint()
          ..color = withValues(Colors.black, 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + 6, c.dy + h * 0.42),
        width: w * 1.1,
        height: w * 0.28,
      ),
      primaryShadowPaint,
    );

    // Secondary shadow (softer, wider)
    final secondaryShadowPaint =
        Paint()
          ..color = withValues(Colors.black, 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + 10, c.dy + h * 0.46),
        width: w * 1.3,
        height: w * 0.32,
      ),
      secondaryShadowPaint,
    );

    // Ambient shadow (very soft, largest)
    final ambientShadowPaint =
        Paint()
          ..color = withValues(Colors.black, 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + 15, c.dy + h * 0.5),
        width: w * 1.6,
        height: w * 0.4,
      ),
      ambientShadowPaint,
    );
  }

  void _drawTankBody(Canvas canvas, Offset c, double w, double h) {
    final bodyRect = Rect.fromCenter(center: c, width: w, height: h);
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      const Radius.circular(15),
    );

    // 🌟 ENHANCED 3D CYLINDRICAL BODY WITH REALISTIC LIGHTING

    // Main cylindrical gradient (simulates curved surface)
    final cylindricalGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.grey.shade100, // Left highlight
        Colors.grey.shade200,
        Colors.grey.shade300,
        Colors.grey.shade400,
        Colors.grey.shade500, // Center shadow
        Colors.grey.shade600,
        Colors.grey.shade500,
        Colors.grey.shade400,
        Colors.grey.shade300,
        Colors.grey.shade200,
        Colors.grey.shade100, // Right highlight
      ],
      stops: const [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
    );

    final bodyPaint =
        Paint()..shader = cylindricalGradient.createShader(bodyRect);
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Left highlight strip (simulates light reflection on cylinder)
    final leftHighlight = Rect.fromLTWH(
      bodyRect.left + w * 0.05,
      bodyRect.top + h * 0.1,
      w * 0.08,
      h * 0.8,
    );
    final leftHighlightRRect = RRect.fromRectAndRadius(
      leftHighlight,
      const Radius.circular(8),
    );

    final highlightGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        withValues(Colors.white, 0.6),
        withValues(Colors.white, 0.3),
        Colors.transparent,
      ],
    );

    canvas.drawRRect(
      leftHighlightRRect,
      Paint()..shader = highlightGradient.createShader(leftHighlight),
    );

    // Right shadow strip (simulates depth on cylinder)
    final rightShadow = Rect.fromLTWH(
      bodyRect.right - w * 0.12,
      bodyRect.top + h * 0.05,
      w * 0.07,
      h * 0.9,
    );
    final rightShadowRRect = RRect.fromRectAndRadius(
      rightShadow,
      const Radius.circular(6),
    );

    final shadowGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        withValues(Colors.black, 0.15),
        withValues(Colors.black, 0.25),
      ],
    );

    canvas.drawRRect(
      rightShadowRRect,
      Paint()..shader = shadowGradient.createShader(rightShadow),
    );

    // Inner rim for depth
    final innerRect = bodyRect.deflate(2);
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      const Radius.circular(13),
    );

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = withValues(Colors.grey.shade600, 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Outer metallic border
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.grey.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Subtle outer glow for 3D effect
    canvas.drawRRect(
      bodyRRect.inflate(1),
      Paint()
        ..color = withValues(Colors.white, 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawWater(Canvas canvas, Offset c, double w, double h, double bottomY) {
    final waterHeight = h * waterLevel;
    final waterTopY = bottomY - waterHeight;
    final rect = Rect.fromLTWH(c.dx - w / 2 + 3, waterTopY, w - 6, waterHeight);

    // 💧 ENHANCED REALISTIC WATER WITH WAVE EFFECTS

    // Semi-transparent water body gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        withValues(Colors.blue.shade200, 0.75), // More transparent at top
        withValues(Colors.blue.shade400, 0.8),
        withValues(Colors.blue.shade600, 0.85),
        withValues(Colors.blue.shade800, 0.9),
      ],
      stops: const [0, 0.3, 0.7, 1],
    );

    final paint = Paint()..shader = gradient.createShader(rect);

    // Draw water body with rounded corners
    final waterRRect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(waterRRect, paint);

    // Water surface ellipse with subtle wave animation
    final waveOffset = math.sin(wavePhase) * 2; // Gentle wave motion

    final topEllipse = Rect.fromCenter(
      center: Offset(c.dx, waterTopY + waveOffset),
      width: w - 6,
      height: (w - 6) * 0.28,
    );

    // Enhanced surface gradient for realistic 3D water effect
    final surfaceGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3), // Light reflection point
      radius: 1.2,
      colors: [
        withValues(Colors.white, 0.6), // Bright reflection
        withValues(Colors.blue.shade200, 0.8),
        withValues(Colors.blue.shade400, 0.85),
        withValues(Colors.blue.shade600, 0.8),
        withValues(Colors.blue.shade800, 0.75),
      ],
      stops: const [0, 0.2, 0.5, 0.8, 1],
    );

    canvas.drawOval(
      topEllipse,
      Paint()..shader = surfaceGradient.createShader(topEllipse),
    );

    // Animated surface ripples
    for (int i = 0; i < 3; i++) {
      final ripplePhase = (wavePhase * 1.5 + i * 2.1) % (2 * math.pi);
      final rippleRadius = (w - 6) * (0.1 + 0.15 * i);
      final rippleOpacity = (math.sin(ripplePhase) * 0.5 + 0.5) * 0.3;

      if (rippleOpacity > 0.1) {
        final rippleEllipse = Rect.fromCenter(
          center: Offset(c.dx + math.cos(ripplePhase) * 8, waterTopY),
          width: rippleRadius,
          height: rippleRadius * 0.28,
        );

        canvas.drawOval(
          rippleEllipse,
          Paint()
            ..color = withValues(Colors.white, rippleOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Main surface highlight (realistic light reflection)
    final highlightEllipse = Rect.fromCenter(
      center: Offset(c.dx - w * 0.12, waterTopY - 2),
      width: w * 0.3,
      height: (w * 0.3) * 0.15,
    );

    canvas.drawOval(
      highlightEllipse,
      Paint()
        ..color = withValues(Colors.white, 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Secondary smaller reflection
    final smallReflection = Rect.fromCenter(
      center: Offset(c.dx + w * 0.08, waterTopY + 1),
      width: w * 0.15,
      height: (w * 0.15) * 0.12,
    );

    canvas.drawOval(
      smallReflection,
      Paint()
        ..color = withValues(Colors.white, 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawTopRim(Canvas canvas, Offset c, double w, double topY) {
    // 🔷 ENHANCED 3D PROFESSIONAL DOMED LID

    // 3D Dome shadow (creates depth beneath the dome)
    final domeShadow = Rect.fromCenter(
      center: Offset(c.dx + 3, topY - 5),
      width: w * 1.1,
      height: w * 0.3,
    );

    canvas.drawOval(
      domeShadow,
      Paint()
        ..color = withValues(Colors.black, 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main domed lid with enhanced 3D effect
    final lidEllipse = Rect.fromCenter(
      center: Offset(c.dx, topY - 10), // More raised for stronger 3D effect
      width: w * 1.1,
      height: w * 0.4,
    );

    // Enhanced dome gradient with better 3D lighting
    final domeGradient = RadialGradient(
      center: const Alignment(-0.4, -0.5), // Light source from top-left
      radius: 1.4,
      colors: [
        withValues(Colors.white, 0.95), // Bright highlight
        withValues(Colors.grey.shade50, 0.9),
        withValues(Colors.grey.shade200, 0.85),
        withValues(Colors.grey.shade400, 0.8),
        withValues(Colors.grey.shade600, 0.75),
        withValues(Colors.grey.shade800, 0.7),
      ],
      stops: const [0, 0.15, 0.35, 0.6, 0.8, 1],
    );

    canvas.drawOval(
      lidEllipse,
      Paint()..shader = domeGradient.createShader(lidEllipse),
    );

    // Enhanced metallic ring with 3D depth
    final ringEllipse = Rect.fromCenter(
      center: Offset(c.dx, topY - 2),
      width: w * 1.15,
      height: w * 0.35,
    );

    final metallicGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.grey.shade200,
        Colors.grey.shade400,
        Colors.grey.shade700,
        Colors.grey.shade900,
        Colors.grey.shade700,
        Colors.grey.shade500,
        Colors.grey.shade300,
      ],
      stops: const [0, 0.15, 0.35, 0.5, 0.65, 0.85, 1],
    );

    canvas.drawOval(
      ringEllipse,
      Paint()
        ..shader = metallicGradient.createShader(ringEllipse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Enhanced centered inlet with more depth
    final inletRadius = w * 0.09;
    final inletCenter = Offset(c.dx, topY - 8);

    // Multi-layer inlet shadow for depth
    canvas.drawCircle(
      Offset(inletCenter.dx + 2, inletCenter.dy + 2),
      inletRadius + 3,
      Paint()
        ..color = withValues(Colors.black, 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      inletCenter,
      inletRadius + 1,
      Paint()..color = withValues(Colors.black, 0.5),
    );

    // Inlet opening with depth gradient
    final inletGradient = RadialGradient(
      colors: [
        withValues(Colors.black, 0.8),
        Colors.grey.shade800,
        Colors.grey.shade600,
        Colors.grey.shade500,
      ],
      stops: const [0, 0.3, 0.7, 1],
    );
    canvas.drawCircle(
      inletCenter,
      inletRadius,
      Paint()
        ..shader = inletGradient.createShader(
          Rect.fromCircle(center: inletCenter, radius: inletRadius),
        ),
    );

    // Enhanced glossy highlights for realism
    final primaryHighlight = Rect.fromCenter(
      center: Offset(c.dx - w * 0.18, topY - 15),
      width: w * 0.3,
      height: w * 0.1,
    );

    canvas.drawOval(
      primaryHighlight,
      Paint()
        ..color = withValues(Colors.white, 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Secondary highlight
    final secondaryHighlight = Rect.fromCenter(
      center: Offset(c.dx - w * 0.1, topY - 12),
      width: w * 0.15,
      height: w * 0.05,
    );

    canvas.drawOval(
      secondaryHighlight,
      Paint()
        ..color = withValues(Colors.white, 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Tertiary small highlight for extra realism
    final tertiaryHighlight = Rect.fromCenter(
      center: Offset(c.dx + w * 0.12, topY - 8),
      width: w * 0.08,
      height: w * 0.03,
    );

    canvas.drawOval(
      tertiaryHighlight,
      Paint()
        ..color = withValues(Colors.white, 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    // Enhanced outer border with depth
    canvas.drawOval(
      ringEllipse.inflate(2),
      Paint()
        ..color = Colors.grey.shade900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner ring detail for extra depth
    canvas.drawOval(
      ringEllipse.deflate(3),
      Paint()
        ..color = withValues(Colors.grey.shade400, 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawBottomBase(Canvas canvas, Offset c, double w, double bottomY) {
    // 🔶 ENHANCED 3D PROFESSIONAL TANK BASE

    // Enhanced ground shadow with multiple layers for depth
    final primaryShadow = Rect.fromCenter(
      center: Offset(c.dx + 4, bottomY + w * 0.09),
      width: w * 1.15,
      height: w * 0.18,
    );

    final primaryShadowGradient = RadialGradient(
      colors: [
        withValues(Colors.black, 0.15),
        withValues(Colors.black, 0.08),
        Colors.transparent,
      ],
      stops: const [0, 0.5, 1],
    );

    canvas.drawOval(
      primaryShadow,
      Paint()
        ..shader = primaryShadowGradient.createShader(primaryShadow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Secondary softer shadow
    final secondaryShadow = Rect.fromCenter(
      center: Offset(c.dx + 6, bottomY + w * 0.12),
      width: w * 1.3,
      height: w * 0.22,
    );

    canvas.drawOval(
      secondaryShadow,
      Paint()
        ..color = withValues(Colors.black, 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Enhanced tank bottom with 3D depth
    final tankBottom = Rect.fromCenter(
      center: Offset(c.dx, bottomY),
      width: w,
      height: w * 0.28,
    );

    // Enhanced bottom gradient with cylindrical lighting
    final bottomGradient = RadialGradient(
      center: const Alignment(-0.2, -0.5),
      radius: 1.2,
      colors: [
        Colors.grey.shade200,
        Colors.grey.shade300,
        Colors.grey.shade400,
        Colors.grey.shade500,
        Colors.grey.shade600,
        Colors.grey.shade700,
      ],
      stops: const [0, 0.2, 0.4, 0.6, 0.8, 1],
    );

    canvas.drawOval(
      tankBottom,
      Paint()..shader = bottomGradient.createShader(tankBottom),
    );

    // Enhanced supporting base ring with 3D effect
    final baseRing = Rect.fromCenter(
      center: Offset(c.dx, bottomY + w * 0.05),
      width: w * 1.18,
      height: w * 0.2,
    );

    // Enhanced ring gradient with depth
    final ringGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.grey.shade300,
        Colors.grey.shade500,
        Colors.grey.shade700,
        Colors.grey.shade800,
        Colors.grey.shade600,
        Colors.grey.shade400,
      ],
      stops: const [0, 0.2, 0.4, 0.6, 0.8, 1],
    );

    canvas.drawOval(
      baseRing,
      Paint()..shader = ringGradient.createShader(baseRing),
    );

    // Enhanced outlet valve with 3D details
    final valveCenter = Offset(c.dx + w * 0.36, bottomY + w * 0.03);
    final valveSize = w * 0.045;

    // Multi-layer valve shadow for depth
    canvas.drawCircle(
      Offset(valveCenter.dx + 2, valveCenter.dy + 2),
      valveSize + 1.5,
      Paint()
        ..color = withValues(Colors.black, 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawCircle(
      Offset(valveCenter.dx + 1, valveCenter.dy + 1),
      valveSize + 0.5,
      Paint()..color = withValues(Colors.black, 0.3),
    );

    // Enhanced valve body with metallic finish
    final valveGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Colors.grey.shade400,
        Colors.grey.shade600,
        Colors.grey.shade800,
        Colors.grey.shade900,
      ],
      stops: const [0, 0.3, 0.7, 1],
    );
    canvas.drawCircle(
      valveCenter,
      valveSize,
      Paint()
        ..shader = valveGradient.createShader(
          Rect.fromCircle(center: valveCenter, radius: valveSize),
        ),
    );

    // Valve highlight for 3D effect
    canvas.drawCircle(
      Offset(
        valveCenter.dx - valveSize * 0.4,
        valveCenter.dy - valveSize * 0.4,
      ),
      valveSize * 0.25,
      Paint()
        ..color = withValues(Colors.white, 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    // Enhanced tank bottom border with depth
    canvas.drawOval(
      tankBottom,
      Paint()
        ..color = Colors.grey.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner tank bottom detail
    canvas.drawOval(
      tankBottom.deflate(2),
      Paint()
        ..color = withValues(Colors.grey.shade500, 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Enhanced base ring border
    canvas.drawOval(
      baseRing,
      Paint()
        ..color = Colors.grey.shade900
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Base ring highlight for 3D depth
    canvas.drawOval(
      baseRing.deflate(2),
      Paint()
        ..color = withValues(Colors.grey.shade300, 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Outer glow for professional finish
    canvas.drawOval(
      baseRing.inflate(1),
      Paint()
        ..color = withValues(Colors.white, 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant Professional3DTankPainter oldDelegate) =>
      oldDelegate.waterLevel != waterLevel ||
      oldDelegate.wavePhase != wavePhase;
}
