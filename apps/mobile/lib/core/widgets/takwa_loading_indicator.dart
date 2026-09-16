import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// A premium Takwa-branded loading indicator.
///
/// Renders the Takwa logo at the center with a gentle pulse animation,
/// surrounded by a sweeping golden arc for a premium look.
class TakwaLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const TakwaLoadingIndicator({
    super.key,
    this.size = 56.0,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  State<TakwaLoadingIndicator> createState() => _TakwaLoadingIndicatorState();
}

class _TakwaLoadingIndicatorState extends State<TakwaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;
  late final Animation<double> _arc;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Gentle scale pulse: 0.88 → 1.0 → 0.88
    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.88,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.88,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_ctrl);

    // Fade: fades slightly on the "inhale"
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_ctrl);

    // Arc sweep angle: drives the rotating arc painter
    _arc = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = widget.color ?? context.colors.gold;
    final logoSize = widget.size * 0.60;

    // This spinner is embedded all over the app — cards, buttons, list
    // items — and animates continuously while visible. RepaintBoundary
    // isolates its per-tick repaints to its own compositing layer instead
    // of forcing whatever it's embedded in to repaint alongside it.
    return RepaintBoundary(
      child: Center(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // ── Outer glow halo ──────────────────────────────
                  Opacity(
                    opacity: _fade.value * 0.35,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: gold,
                            blurRadius: widget.size * 0.45,
                            spreadRadius: widget.size * 0.05,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Sweeping arc ring ───────────────────────────────
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _SweepArcPainter(
                      rotation: _arc.value,
                      color: gold,
                      strokeWidth: widget.strokeWidth,
                    ),
                  ),

                  // ── Logo (pulsing) ──────────────────────────────────
                  Transform.scale(
                    scale: _pulse.value,
                    child: Opacity(
                      opacity: (_fade.value * 0.5 + 0.5).clamp(0.0, 1.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                        color: gold,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Arc painter ──────────────────────────────────────────────────────────────

class _SweepArcPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final double strokeWidth;

  const _SweepArcPainter({
    required this.rotation,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - strokeWidth / 2,
    );

    // Dim track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color.withValues(alpha: 0.10)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    // Gradient sweep arc (270° sweep, rotating)
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: rotation,
        endAngle: rotation + 1.5 * math.pi,
        colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.6), color],
      ).createShader(rect);

    canvas.drawArc(rect, rotation, 1.5 * math.pi, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepArcPainter old) =>
      old.rotation != rotation || old.color != color;
}
