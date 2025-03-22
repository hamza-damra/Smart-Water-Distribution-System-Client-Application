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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  /// The water level in the tank (0.0 = empty, 1.0 = full)
  double _waterLevel = 0.4;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // wave animation loops
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
      if (_waterLevel > 1.0) _waterLevel = 1.0; // clamp at max (full)
    });
  }

  /// Decreases water level by 0.05 (5%)
  void _decreaseWaterLevel() {
    setState(() {
      _waterLevel -= 0.05;
      if (_waterLevel < 0.0) _waterLevel = 0.0; // clamp at min (empty)
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
            // Water tank title
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

            // Increase / Decrease water level
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

            // Bills list
            const Text(
              'Bills',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBillsList(),
          ],
        ),
      ),
    );
  }

  /// A dummy list of bills
  Widget _buildBillsList() {
    final bills = [
      'Water Bill - Due 5/Apr',
      'Electricity Bill - Due 10/Apr',
      'Maintenance Fee - Due 15/Apr',
      'Sewerage Fee - Due 20/Apr',
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text(bills[index]),
            subtitle: const Text('Tap for details'),
            onTap: () {
              // TODO: Implement further navigation if needed
            },
          ),
        );
      },
    );
  }
}

/// Custom painter for the water tank
class _WaterTankPainter extends CustomPainter {
  final Animation<double> animation;
  final double waterLevel; // 0.0 to 1.0

  _WaterTankPainter({required this.animation, required this.waterLevel})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Draw tank border
    final tankPaint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tankPaint);

    // 2) Animate wave horizontally
    final waterPaint =
        Paint()
          ..color = Colors.blueAccent.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    // Horizontal shift in wave
    final waveShift = animation.value * size.width;

    // Base water line: 1.0 => top, 0.0 => bottom
    // e.g. waterLevel=1 => baseHeight=0 => wave at top
    // waterLevel=0 => baseHeight=size.height => wave at bottom
    final baseHeight = size.height * (1 - waterLevel);

    final wavePath = Path();
    // Start from bottom-left corner
    wavePath.moveTo(0, size.height);

    final waveHeight = 20.0; // amplitude
    for (double x = 0; x <= size.width; x += 10) {
      // Original wave formula
      final rawY =
          baseHeight + sin((x + waveShift) / size.width * 2 * pi) * waveHeight;
      // Ensure wave stays within the tank (0..size.height)
      final clampedY = rawY.clamp(0.0, size.height);
      wavePath.lineTo(x, clampedY);
    }

    // Close path at bottom-right
    wavePath.lineTo(size.width, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, waterPaint);
  }

  @override
  bool shouldRepaint(_WaterTankPainter oldDelegate) => true;
}
