import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'quran_reader_colors.dart';

class QuranReaderBgDecor extends StatelessWidget {
  const QuranReaderBgDecor({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _QuranBgPainter(), size: Size.infinite);
  }
}

class _QuranBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0B1E2D), Color(0xFF0A1A28), Color(0xFF0D1F2E)],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // Subtle gold geometric pattern
    final p = Paint()
      ..color = const Color.fromARGB(6, 255, 166, 0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 80.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawStar(canvas, Offset(x, y), step * 0.35, p);
      }
    }

    // Top glow
    final topGlow = RadialGradient(
      colors: [kReaderTeal.withValues(alpha: 0.18), Colors.transparent],
    );
    canvas.drawCircle(
      Offset(size.width / 2, 0),
      size.width * 0.7,
      Paint()
        ..shader = topGlow.createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, 0),
            radius: size.width * 0.7,
          ),
        ),
    );
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    const n = 8;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = i * 3.14159 / n;
      final dist = i.isEven ? r : r * 0.45;
      final pt = Offset(c.dx + dist * _cos(angle), c.dy + dist * _sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_) => false;
}
