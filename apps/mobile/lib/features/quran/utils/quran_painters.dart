import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'quran_helpers.dart';

class QuranBgPainter extends CustomPainter {
  final double t;
  QuranBgPainter(this.t);
  static final _r = math.Random(19);
  static List<Offset>? _s;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = kNight,
    );
    _s ??= List.generate(
      50,
      (_) => Offset(
        _r.nextDouble() * size.width,
        _r.nextDouble() * size.height * 0.5,
      ),
    );
    for (int i = 0; i < _s!.length; i++) {
      final op = 0.03 + 0.1 * ((math.sin(t * 2 * math.pi + i) + 1) / 2);
      canvas.drawCircle(_s![i], 0.9, Paint()..color = kGold.withValues(alpha: op));
    }
    canvas.drawCircle(
      Offset(size.width / 2, -40),
      180,
      Paint()
        ..shader =
            RadialGradient(
              colors: [kGold.withValues(alpha: 0.05), Colors.transparent],
            ).createShader(
              Rect.fromCircle(center: Offset(size.width / 2, -40), radius: 180),
            ),
    );
    final p = Paint()
      ..color = kGold.withValues(alpha: 0.035)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width + 50; x += 50) {
      for (double y = 60; y < size.height + 50; y += 50) {
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4 - math.pi / 8;
          final r = i.isEven ? 14.0 : 6.0;
          final pt = Offset(x + r * math.cos(a), y + r * math.sin(a));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(QuranBgPainter o) => o.t != t;
}

class SurahBadgePainter extends CustomPainter {
  final int n;
  final Color c;
  SurahBadgePainter(this.n, this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = Offset(size.width / 2, size.height / 2), r = size.width / 2 - 1;
    canvas.drawCircle(cx, r, Paint()..color = c.withValues(alpha: 0.08));
    canvas.drawCircle(
      cx,
      r,
      Paint()
        ..color = c.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        Offset(cx.dx + (r - 3) * math.cos(a), cx.dy + (r - 3) * math.sin(a)),
        1.1,
        Paint()..color = c.withValues(alpha: 0.35),
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: ar(n),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: n > 99 ? 8 : 11,
          color: c,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset(cx.dx - tp.width / 2, cx.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(SurahBadgePainter o) => false;
}

class JuzRingPainter extends CustomPainter {
  final double progress;
  final Color c;
  JuzRingPainter(this.progress, this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = Offset(size.width / 2, size.height / 2), r = size.width / 2 - 3;
    canvas.drawCircle(
      cx,
      r,
      Paint()
        ..color = kBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: cx, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(JuzRingPainter o) => o.progress != progress;
}

class VerseMarkerPaint extends CustomPainter {
  final int n;
  final Color c;
  VerseMarkerPaint(this.n, this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = Offset(size.width / 2, size.height / 2), r = size.width / 2 - 1;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 8;
      final rr = i.isEven ? r : r * 0.62;
      final pt = Offset(cx.dx + rr * math.cos(a), cx.dy + rr * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c.withValues(alpha: 0.08));
    canvas.drawPath(
      path,
      Paint()
        ..color = c.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: ar(n),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: n > 9 ? 7 : 9,
          color: c,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset(cx.dx - tp.width / 2, cx.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(VerseMarkerPaint o) => o.n != n;
}

class CornerDeco extends CustomPainter {
  final Color c;
  const CornerDeco(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = c.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), p);
    canvas.drawLine(Offset.zero, Offset(0, size.height), p);
    canvas.drawCircle(
      const Offset(3, 3),
      1.5,
      Paint()..color = c.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CornerDeco o) => false;
}
