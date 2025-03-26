// tank_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tank_model.dart';

class TankCard extends StatefulWidget {
  final Tank tank;
  final VoidCallback onReadMore;

  const TankCard({
    Key? key,
    required this.tank,
    required this.onReadMore,
  }) : super(key: key);

  @override
  State<TankCard> createState() => _TankCardState();
}

class _TankCardState extends State<TankCard> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

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

  @override
  Widget build(BuildContext context) {
    final waterLevelFraction = widget.tank.currentLevel / widget.tank.maxCapacity;
    final waterLevel = waterLevelFraction.clamp(0.0, 1.0);
    final fillPercentage = (waterLevel * 100).toStringAsFixed(1);

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 140,
              child: CustomPaint(
                painter: _WaterTankPainter(
                  animation: _waveController,
                  waterLevel: waterLevel,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current Level: ${widget.tank.currentLevel}L / ${widget.tank.maxCapacity}L',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            Text(
              '(${fillPercentage}%)',
              style: TextStyle(color: Colors.blue[300]),
            ),
            const SizedBox(height: 6),
            Text(
              'Monthly credit: ${widget.tank.monthlyCapacity.toStringAsFixed(0)}L / Month',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: widget.onReadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('Read More'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterTankPainter extends CustomPainter {
  final Animation<double> animation;
  final double waterLevel;

  _WaterTankPainter({
    required this.animation,
    required this.waterLevel,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final tankPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tankPaint);

    final waterPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final waveShift = animation.value * size.width;
    final baseHeight = size.height * (1 - waterLevel);

    final wavePath = Path();
    wavePath.moveTo(0, size.height);

    const waveHeight = 8.0;
    for (double x = 0; x <= size.width; x += 5) {
      final rawY = baseHeight + sin((x + waveShift) / size.width * 2 * pi) * waveHeight;
      final clampedY = rawY.clamp(0.0, size.height);
      wavePath.lineTo(x, clampedY);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, waterPaint);
  }

  @override
  bool shouldRepaint(_WaterTankPainter oldDelegate) => true;
}
