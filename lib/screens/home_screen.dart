// home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  /// The water level in the tank (0.0 = empty, 1.0 = full)
  double _waterLevel = 0.4;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Wave animation loops indefinitely.
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// Increases water level by 0.05 (5%)
  void _increaseWaterLevel() {
    setState(() {
      _waterLevel += 0.05;
      if (_waterLevel > 1.0) _waterLevel = 1.0; // Clamp at max (full)
    });
  }

  /// Decreases water level by 0.05 (5%)
  void _decreaseWaterLevel() {
    setState(() {
      _waterLevel -= 0.05;
      if (_waterLevel < 0.0) _waterLevel = 0.0; // Clamp at min (empty)
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, RouteManager.loginRoute);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      // Navigation Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Optional Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: const Text(
                'MyTank Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, RouteManager.homeRoute);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteManager.profileRoute);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            const Text(
              'My Tank Animation',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Animated water tank
            SizedBox(
              width: 120,
              height: 200,
              child: CustomPaint(
                painter: _WaterTankPainter(
                  animation: _waveController,
                  waterLevel: _waterLevel,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Increase / Decrease water level buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _decreaseWaterLevel,
                  child: const Text('Decrease'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _increaseWaterLevel,
                  child: const Text('Increase'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Button to navigate to the Tanks screen
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteManager.tanksRoute);
              },
              child: const Text('Go to Tanks'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the water tank wave animation.
class _WaterTankPainter extends CustomPainter {
  final Animation<double> animation;
  final double waterLevel; // Expected value between 0.0 and 1.0

  _WaterTankPainter({required this.animation, required this.waterLevel})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Draw tank border
    final tankPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tankPaint);

    // 2) Draw animated water wave
    final waterPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Calculate horizontal shift based on animation value.
    final waveShift = animation.value * size.width;
    // Calculate base water line (top when full, bottom when empty).
    final baseHeight = size.height * (1 - waterLevel);

    final wavePath = Path();
    // Start from bottom-left corner.
    wavePath.moveTo(0, size.height);

    final waveHeight = 20.0; // Amplitude of the wave
    for (double x = 0; x <= size.width; x += 10) {
      final rawY = baseHeight + sin((x + waveShift) / size.width * 2 * pi) * waveHeight;
      final clampedY = rawY.clamp(0.0, size.height);
      wavePath.lineTo(x, clampedY);
    }
    // Close path at bottom-right.
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);
  }

  @override
  bool shouldRepaint(_WaterTankPainter oldDelegate) => true;
}
