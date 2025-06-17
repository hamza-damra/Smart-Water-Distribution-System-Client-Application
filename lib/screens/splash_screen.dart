import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper method for color opacity
Color withValues(Color color, double opacity) =>
    color.withValues(alpha: opacity);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _waveController;
  late AnimationController _particleController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _waterLevelAnimation;
  late Animation<double> _backgroundFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setSystemUIStyle();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Main animation controller for overall sequence
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Wave animation controller for continuous water effects
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Particle animation controller for floating effects
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Background fade animation
    _backgroundFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Water level animation
    _waterLevelAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Text animations
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutQuart),
      ),
    );
  }

  void _setSystemUIStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Constants.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _startAnimations() {
    _mainController.forward();

    // Navigate after animation completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 500), () {
          _checkServerConfigAndNavigate();
        });
      }
    });
  }

  Future<void> _checkServerConfigAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasServerConfig = prefs.containsKey('server_url');

    if (mounted) {
      if (!hasServerConfig) {
        Navigator.pushReplacementNamed(context, RouteManager.serverConfigRoute);
      } else {
        _checkAuthAndNavigate();
      }
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (mounted) {
      if (authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, RouteManager.homeRoute);
      } else {
        Navigator.pushReplacementNamed(context, RouteManager.loginRoute);
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Constants.primaryColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _backgroundFadeAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Constants.primaryColor,
                      Constants.secondaryColor,
                      Constants.accentColor.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Opacity(
                  opacity: _backgroundFadeAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          withValues(Constants.accentColor, 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated water particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Stack(
                children: List.generate(15, (index) {
                  final random = math.Random(index);
                  final startX = random.nextDouble() * size.width;
                  final speed = random.nextDouble() * 0.5 + 0.3;
                  final particleSize = random.nextDouble() * 6 + 2;

                  return Positioned(
                    left:
                        startX +
                        math.sin(
                              (_particleController.value + index) * math.pi * 2,
                            ) *
                            30,
                    top:
                        size.height -
                        (size.height * _particleController.value * speed) %
                            (size.height + 100),
                    child: Opacity(
                      opacity: 0.4 + random.nextDouble() * 0.3,
                      child: Container(
                        width: particleSize,
                        height: particleSize,
                        decoration: BoxDecoration(
                          color: Constants.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: withValues(Constants.accentColor, 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with water effect
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoFadeAnimation,
                      _logoScaleAnimation,
                      _waterLevelAnimation,
                      _waveController,
                    ]),
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            width: size.width * 0.4,
                            height: size.width * 0.4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: withValues(
                                    Constants.primaryColor,
                                    0.3,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: withValues(Constants.accentColor, 0.5),
                                  blurRadius: 25,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Water level indicator
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: AnimatedBuilder(
                                      animation: _waterLevelAnimation,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: _WaterPainter(
                                            waveOffset:
                                                _waveController.value *
                                                2 *
                                                math.pi,
                                            fillLevel:
                                                _waterLevelAnimation.value,
                                            color: Constants.accentColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Water drop icon
                                Center(
                                  child: Icon(
                                    Icons.water_drop,
                                    size: size.width * 0.2,
                                    color: Constants.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // App name with slide animation
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _textFadeAnimation,
                      _textSlideAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Column(
                            children: [
                              // Main title
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Constants.accentColor,
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Smart Tank',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Smart Water Management',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Professional branding footer
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _textFadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Center(
                    child: Text(
                      'Powered by Smart Technology',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: withValues(Colors.white, 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double waveOffset;
  final double fillLevel;
  final Color color;

  _WaterPainter({
    required this.waveOffset,
    required this.fillLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final height = size.height * (1 - fillLevel);

    path.moveTo(0, height);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, height + math.sin((i / 30) + waveOffset) * 8);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaterPainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset ||
        oldDelegate.fillLevel != fillLevel ||
        oldDelegate.color != color;
  }
}
