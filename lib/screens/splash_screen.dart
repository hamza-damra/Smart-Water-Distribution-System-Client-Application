import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/auth_provider.dart';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) =>
    Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), opacity);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waterLevelAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Preload resources and initialize auth
  Future<void> _preloadResources() async {
    // Ensure the splash screen is shown immediately by precaching the app icon
    // and setting the system UI overlay style
    try {
      // Set system UI overlay style for a more immersive experience
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF1E3A8A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // Force immediate rendering of the splash screen
      await Future.microtask(() {});

      // Precache the app icon to ensure it's loaded immediately
      if (mounted) {
        await precacheImage(const AssetImage('assets/icon.png'), context);
      }
    } catch (e) {
      // Ignore any errors during precaching to ensure splash screen still works
      debugPrint('Error precaching resources: $e');
    }

    return;
  }

  @override
  void initState() {
    super.initState();

    // Initialize animations synchronously to ensure immediate display
    _initializeAnimations();

    // Start animations immediately to ensure splash screen appears right away
    _animationController.forward();
    _pulseController.forward();

    // Preload resources immediately without waiting for post-frame callback
    // This helps ensure the splash screen appears without delay
    _preloadResources();

    // Navigate to next screen after animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });
  }

  // Separate method to initialize animations for better organization
  void _initializeAnimations() {
    // Initialize main animation controller with slightly faster duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200), // Even faster animation
    );

    // Initialize pulse animation controller for continuous effects
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Faster pulse
    )..repeat(reverse: true);

    // Fade in animation - faster and smoother
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0,
          0.25, // Faster fade in
          curve: Curves.easeOut,
        ),
      ),
    );

    // Scale animation with improved bounce effect
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    // Water level rising animation - smoother curve
    _waterLevelAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeInOut),
      ),
    );

    // Wave movement animation - more dynamic
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 1.0, curve: Curves.linear),
      ),
    );

    // Enhanced pulsing animation for the logo
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Subtle rotation animation for the logo
    _rotationAnimation = Tween<double>(begin: -0.01, end: 0.01).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth provider to check for existing token
    await authProvider.initialize();

    // Add a small delay to ensure animation is fully visible
    await Future.delayed(const Duration(milliseconds: 500));

    if (authProvider.isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteManager.homeRoute);
      }
    } else {
      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteManager.loginRoute);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Ensure the splash screen is rendered immediately
    return Scaffold(
      // Set the background color to match the gradient start color
      // to avoid the gray flash
      backgroundColor: const Color(
        0xFF2196F3,
      ), // Modern blue for immediate display
      body: AnimatedBuilder(
        animation: Listenable.merge([_animationController, _pulseController]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand, // Ensure stack fills the entire screen
            children: [
              // Background gradient with enhanced colors - more modern gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2196F3), // Modern blue
                      const Color(0xFF03A9F4), // Light blue
                      const Color(0xFF00BCD4), // Cyan
                      const Color(0xFF009688), // Teal
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),

              // Modern animated background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05 + (0.03 * _pulseAnimation.value),
                  child: CustomPaint(
                    painter: GridPatternPainter(
                      color: Colors.white,
                      pulseValue: _pulseAnimation.value,
                    ),
                  ),
                ),
              ),

              // Enhanced animated background particles with modern look
              ...List.generate(40, (index) {
                // More particles for richer effect
                final random = math.Random(index);
                final particleSize =
                    random.nextDouble() * 8 +
                    2; // Smaller particles for modern look
                final initialX =
                    random.nextDouble() * MediaQuery.of(context).size.width;
                final initialY =
                    random.nextDouble() * MediaQuery.of(context).size.height;
                final speed = random.nextDouble() * 0.7 + 0.3;

                // Different particle colors for more visual interest - modern color palette
                final particleColor =
                    index % 5 == 0
                        ? Colors.white
                        : index % 5 == 1
                        ? const Color(0xFF80DEEA) // Cyan light
                        : index % 5 == 2
                        ? const Color(0xFF4DD0E1) // Cyan
                        : index % 5 == 3
                        ? const Color(0xFF80CBC4) // Teal light
                        : const Color(0xFF4DB6AC); // Teal

                return Positioned(
                  left:
                      initialX +
                      math.sin((_pulseController.value + index) * math.pi * 2) *
                          12,
                  top:
                      initialY -
                      _animationController.value *
                          MediaQuery.of(context).size.height *
                          speed,
                  child: Opacity(
                    opacity:
                        0.2 + random.nextDouble() * 0.3, // More subtle opacity
                    child: Container(
                      width: particleSize,
                      height: particleSize,
                      decoration: BoxDecoration(
                        color: particleColor,
                        borderRadius: BorderRadius.circular(particleSize),
                        boxShadow: [
                          BoxShadow(
                            color: withValues(particleColor, 0.3),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Main content
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with water animation - enhanced with modern design
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Container(
                              width: size.width * 0.45,
                              height: size.width * 0.45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: withValues(
                                      const Color(0xFF01579B),
                                      0.25,
                                    ), // Deep blue shadow
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: withValues(
                                      const Color(0xFF42A5F5), // Modern blue
                                      0.2,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Water level animation - enhanced colors with modern gradient
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      height:
                                          (size.width * 0.45) *
                                          _waterLevelAnimation.value,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(30),
                                          bottomRight: Radius.circular(30),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Base water color - more vibrant with modern gradient
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    withValues(
                                                      const Color(0xFF81D4FA),
                                                      0.7,
                                                    ), // Light blue
                                                    withValues(
                                                      const Color(0xFF4FC3F7),
                                                      0.8,
                                                    ), // Medium blue
                                                    withValues(
                                                      const Color(0xFF29B6F6),
                                                      0.9,
                                                    ), // Darker blue
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Wave animation - enhanced with modern look
                                            CustomPaint(
                                              painter: WavePainter(
                                                waveAnimation:
                                                    _waveAnimation.value,
                                                color: withValues(
                                                  const Color(
                                                    0xFF2196F3,
                                                  ), // Modern blue
                                                  0.8,
                                                ),
                                              ),
                                              size: Size(
                                                size.width * 0.45,
                                                (size.width * 0.45) *
                                                    _waterLevelAnimation.value,
                                              ),
                                            ),
                                            // Enhanced shimmering effect with modern look
                                            Positioned.fill(
                                              child: Opacity(
                                                opacity:
                                                    0.4 * _pulseAnimation.value,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        withValues(
                                                          Colors.white,
                                                          0.1,
                                                        ),
                                                        withValues(
                                                          Colors.white,
                                                          0.4,
                                                        ),
                                                        withValues(
                                                          Colors.white,
                                                          0.1,
                                                        ),
                                                      ],
                                                      stops: const [
                                                        0.2,
                                                        0.5,
                                                        0.8,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Logo with pulse animation - enhanced with modern look
                                    ScaleTransition(
                                      scale: _pulseAnimation,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Image.asset(
                                          'assets/icon.png',
                                          width: size.width * 0.25,
                                          height: size.width * 0.25,
                                          color: const Color(
                                            0xFF00838F,
                                          ), // Cyan dark
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      // App name with enhanced animated shadow and modern typography
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(
                                0.2,
                                0.5,
                                curve: Curves.elasticOut,
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Enhanced shadow text with modern look
                              Text(
                                'Smart Tank',
                                style: TextStyle(
                                  fontSize: 38, // Larger text for modern look
                                  fontWeight: FontWeight.bold,
                                  foreground:
                                      Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth =
                                            8 // Thicker stroke
                                        ..color = withValues(
                                          const Color(0xFF006064), // Cyan dark
                                          0.25,
                                        ),
                                ),
                              ),
                              // Enhanced main text with more vibrant gradient - modern color palette
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      Colors.white,
                                      const Color(0xFFE1F5FE), // Light blue
                                      const Color(
                                        0xFFB3E5FC,
                                      ), // Very light blue
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Smart Tank',
                                  style: TextStyle(
                                    fontSize: 38, // Larger text for modern look
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing:
                                        1.2, // Added letter spacing for modern typography
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Enhanced tagline with animated typing effect and modern typography
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final text = 'Smart Water Management Platform';
                            final visibleText =
                                _animationController.value >
                                        0.4 // Start earlier
                                    ? text.substring(
                                      0,
                                      (text.length *
                                              ((_animationController.value -
                                                      0.4) *
                                                  1.7)) // Faster typing
                                          .round()
                                          .clamp(0, text.length),
                                    )
                                    : '';

                            return Text(
                              visibleText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing:
                                    0.7, // Increased letter spacing for modern look
                                shadows: const [
                                  Shadow(
                                    color: Color(
                                      0x4D006064,
                                    ), // Cyan dark with 30% opacity
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 50),
                      // Modern loading animation (replacing circular progress with shimmer effect)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: withValues(
                              Colors.white,
                              0.08,
                            ), // More subtle background
                            borderRadius: BorderRadius.circular(
                              24,
                            ), // Larger radius for modern look
                            border: Border.all(
                              color: withValues(Colors.white, 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: withValues(
                                  const Color(0xFF006064),
                                  0.15,
                                ), // Cyan dark
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(15),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Modern loading animation with shimmer effect
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: ModernLoaderPainter(
                                      progress: _animationController.value,
                                      pulseValue: _pulseAnimation.value,
                                      waveValue: _waveAnimation.value,
                                    ),
                                    size: const Size(50, 50),
                                  );
                                },
                              ),

                              // Center dot with modern glow effect
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: withValues(Colors.white, 0.7),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom painter for wave animation
class WavePainter extends CustomPainter {
  final double waveAnimation;
  final Color color;

  WavePainter({required this.waveAnimation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Start at bottom-left
    path.moveTo(0, height);

    // Create wave pattern
    for (int i = 0; i < width.toInt(); i++) {
      // Create two waves with different frequencies
      final wave1 =
          10 * math.sin((i / width * 2 * math.pi) + (waveAnimation * 10));
      final wave2 =
          5 * math.sin((i / width * 4 * math.pi) + (waveAnimation * 15));

      // Combine waves
      final y = height - 20 + wave1 + wave2;
      path.lineTo(i.toDouble(), y);
    }

    // Complete the path
    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for modern grid pattern
class GridPatternPainter extends CustomPainter {
  final Color color;
  final double pulseValue;

  GridPatternPainter({required this.color, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 0.5;

    final cellSize = 30.0;
    final xCount = (size.width / cellSize).ceil() + 1;
    final yCount = (size.height / cellSize).ceil() + 1;

    // Draw vertical lines
    for (int i = 0; i < xCount; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i < yCount; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw accent dots at intersections
    final dotPaint =
        Paint()
          ..color = withValues(color, 0.7 + (pulseValue - 0.97) * 2)
          ..style = PaintingStyle.fill;

    for (int x = 0; x < xCount; x++) {
      for (int y = 0; y < yCount; y++) {
        // Only draw some dots for a more subtle effect
        if ((x + y) % 3 == 0) {
          canvas.drawCircle(
            Offset(x * cellSize, y * cellSize),
            1.0 + (pulseValue - 0.97) * 3,
            dotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPatternPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue;
}

// Custom painter for modern loading animation
class ModernLoaderPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final double waveValue;

  ModernLoaderPainter({
    required this.progress,
    required this.pulseValue,
    required this.waveValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer ring with gradient
    final outerRingPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..shader = SweepGradient(
            colors: [
              withValues(Colors.white, 0.1),
              withValues(Colors.white, 0.8),
              withValues(Colors.white, 0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
            startAngle: 0,
            endAngle: 2 * math.pi,
            transform: GradientRotation(waveValue * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw progress arc
    final progressPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white;

    // Draw multiple arcs for a more interesting effect
    for (int i = 0; i < 3; i++) {
      final startAngle =
          -math.pi / 2 + (i * 2 * math.pi / 3) + (waveValue * math.pi);
      final sweepAngle = progress * 2 * math.pi / 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - i * 4),
        startAngle,
        sweepAngle,
        false,
        progressPaint..color = withValues(Colors.white, 1.0 - i * 0.2),
      );
    }

    // Draw pulsing inner circle
    final innerCirclePaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = withValues(Colors.white, 0.3 + (pulseValue - 0.97) * 2);

    canvas.drawCircle(center, radius * 0.3 * pulseValue, innerCirclePaint);

    // Draw outer ring
    canvas.drawCircle(center, radius, outerRingPaint);

    // Draw shimmer effect
    final shimmerPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..shader = LinearGradient(
            colors: [
              withValues(Colors.white, 0.0),
              withValues(Colors.white, 0.5),
              withValues(Colors.white, 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Rotate the canvas for the shimmer effect
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(waveValue * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawCircle(center, radius * 0.8, shimmerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ModernLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.waveValue != waveValue;
}
