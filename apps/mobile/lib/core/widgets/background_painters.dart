import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// This file used to hold 41 hand-authored painter variants (1,845 lines) for
// BackgroundPattern's enum — IslamicPattern1-18, IslamicP01-P18Painter,
// GeometricPainter, DuasBgPainter, AsmaBgPainter. Auditing every real call
// site (see BackgroundPattern in custom_pattern_background.dart) found
// exactly three actually reachable from the app: `adhkar` (used on ~45
// screens as the app-wide default), `qibla` (the Qibla compass screen), and
// `twelveFoldStar` (an accent on the Misbaha counter). The other 38 were
// declared, painted, and switched on, but never referenced by any screen —
// design-system bloat the audit called out (§M15) as diluting identity
// rather than reinforcing it, on top of being dead code. Curated down to
// the three below; deleted the rest along with every helper (_starPath,
// _polyPath) and the shared IslamicBasePainter machinery that only those
// deleted classes used — IslamicP01Painter is IslamicBasePainter's one
// remaining user, so that base class stays.

Path _starPath(
  Offset c,
  double outer,
  double inner,
  int n, {
  double rot = 0.0,
}) {
  final p = Path();
  for (int i = 0; i < n * 2; i++) {
    final a = rot + i * math.pi / n;
    final dist = i.isEven ? outer : inner;
    final x = c.dx + dist * math.cos(a);
    final y = c.dy + dist * math.sin(a);
    i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
  }
  return p..close();
}

Path _polyPath(Offset c, double r, int n, {double rot = 0.0}) {
  final p = Path();
  for (int i = 0; i < n; i++) {
    final a = rot + i * 2 * math.pi / n;
    final x = c.dx + r * math.cos(a);
    final y = c.dy + r * math.sin(a);
    i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
  }
  return p..close();
}

// ── Base Islamic Painter for Optimization and Consistency ──
abstract class IslamicBasePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double strokeWidth;
  final double spacing;

  IslamicBasePainter({
    required this.color,
    this.opacity = 0.1,
    this.strokeWidth = 0.7,
    this.spacing = 80.0,
  });

  Picture? _cached;
  Size? _cachedSize;
  Color? _cachedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (_cached == null || _cachedSize != size || _cachedColor != color) {
      _cachedSize = size;
      _cachedColor = color;
      final recorder = PictureRecorder();
      final c = Canvas(recorder);

      final p = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      drawPattern(c, size, p);
      _cached = recorder.endRecording();
    }
    canvas.drawPicture(_cached!);
  }

  void drawPattern(Canvas canvas, Size size, Paint paint);

  @override
  bool shouldRepaint(covariant IslamicBasePainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.strokeWidth != strokeWidth ||
      old.spacing != spacing;
}

// P01 · 12-fold star on hexagonal grid (Moroccan / Andalusian) — the Misbaha
// screen's accent pattern (BackgroundPattern.twelveFoldStar).
class IslamicP01Painter extends IslamicBasePainter {
  IslamicP01Painter({
    required super.color,
    super.opacity,
    super.strokeWidth = 0.7,
    super.spacing = 96.0,
  });

  @override
  void drawPattern(Canvas cv, Size size, Paint p) {
    final s = spacing;
    for (double x = -s; x < size.width + s; x += s) {
      for (double y = -s; y < size.height + s; y += s) {
        final off = ((x / s).round().isOdd) ? s / 2 : 0.0;
        _motif(cv, Offset(x, y + off), s * 0.44, p);
      }
    }
  }

  void _motif(Canvas cv, Offset c, double r, Paint p) {
    cv.drawPath(_starPath(c, r, r * 0.5, 12, rot: -math.pi / 2), p);
    cv.drawPath(_polyPath(c, r * 0.32, 12, rot: -math.pi / 2), p);
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6 - math.pi / 2;
      cv.drawLine(
        Offset(c.dx + r * 0.32 * math.cos(a), c.dy + r * 0.32 * math.sin(a)),
        Offset(c.dx + r * 0.5 * math.cos(a), c.dy + r * 0.5 * math.sin(a)),
        p,
      );
    }
  }
}

// The Qibla compass screen's background — concentric rings, not a tiled
// Islamic-geometric motif like the others, so it stays on plain
// CustomPainter rather than IslamicBasePainter (no tiled `drawPattern` to
// share, and its own `shouldRepaint => false` is simpler than the base
// class's field-comparison version for a painter with only one field).
class QiblaBgPainter extends CustomPainter {
  final Color goldColor;
  QiblaBgPainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = goldColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    final center = Offset(size.width / 2, size.height * 0.45);
    for (int i = 1; i <= 7; i++) {
      final r = i * 48.0;
      canvas.drawCircle(center, r, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

// The app-wide default background (BackgroundPattern.adhkar) — used on
// nearly every screen that renders CustomPatternBackground.
class AdhkarBgPainter extends IslamicBasePainter {
  AdhkarBgPainter({required Color goldColor, required Color nightColor})
    : super(color: goldColor, opacity: 0.06, strokeWidth: 0.75, spacing: 92.0);

  @override
  void drawPattern(Canvas canvas, Size size, Paint paint) {
    final step = spacing;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawInterlacedZellij(canvas, Offset(x, y), step * 0.45, paint);
      }
    }
  }

  void _drawInterlacedZellij(Canvas canvas, Offset c, double r, Paint p) {
    final Path star1 = Path();
    for (int i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final d1 = i.isEven ? r : r * 0.65;
      final px1 = c.dx + d1 * math.cos(a);
      final py1 = c.dy + d1 * math.sin(a);
      if (i == 0) {
        star1.moveTo(px1, py1);
      } else {
        star1.lineTo(px1, py1);
      }
    }
    star1.close();
    canvas.drawPath(star1, p);
  }
}

// RamadanBgPainter moved to ramadan_theme.dart
