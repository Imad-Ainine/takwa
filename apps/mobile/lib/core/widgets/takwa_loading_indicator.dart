import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// Half-width of the shimmer band in alignment units, where 1.0 is the distance
/// from the centre of the mark to its right edge.
const double _band = 0.45;

/// The Takwa wordmark, breathing.
///
/// No ring, no arc, nothing that spins: the brand mark is the whole indicator.
/// A band of light sweeps across it on a loop while a soft gold halo swells
/// underneath, which reads as "working" without borrowing Material's spinner
/// silhouette.
///
/// [size] is the height of the square the indicator occupies — the wordmark is
/// wide, so it is letterboxed inside that square rather than filling it. Every
/// call site relies on that footprint staying stable, since the loader swaps in
/// and out of buttons, pills and list tiles.
class TakwaLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const TakwaLoadingIndicator({super.key, this.size = 56.0, this.color});

  @override
  State<TakwaLoadingIndicator> createState() => _TakwaLoadingIndicatorState();
}

class _TakwaLoadingIndicatorState extends State<TakwaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  /// Width of the wordmark relative to its height (assets/images/logo.png is
  /// 1492x678).
  static const double _logoAspect = 1492 / 678;

  late final AnimationController _ctrl;

  /// The sweep runs over the first three quarters of the cycle and then rests,
  /// so the mark is plainly gold for a beat before the next pass.
  late final Animation<double> _sweep;

  /// Halo swell, one full breath per cycle.
  late final Animation<double> _halo;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _sweep = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.08, 0.78, curve: Curves.easeInOutSine),
    );

    _halo = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.35,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_ctrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mid-sweep is the most legible resting frame: the band sits over the
    // centre of the mark rather than off-screen.
    _ctrl.repeatUnlessReducedMotion(context, restingValue: 0.5);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = widget.color ?? context.colors.gold;
    final logoWidth = widget.size * 0.94;
    final logoHeight = logoWidth / _logoAspect;

    // This indicator is embedded all over the app — cards, buttons, list
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
                  // ── Halo, swelling under the mark ─────────────────
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          gold.withValues(alpha: 0.30 * _halo.value),
                          gold.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.75],
                      ),
                    ),
                  ),

                  // ── Wordmark, lit by a travelling band ────────────
                  Transform.scale(
                    scale: 0.985 + 0.03 * _halo.value,
                    child: _ShimmeredLogo(
                      width: logoWidth,
                      height: logoHeight,
                      base: gold,
                      // t runs -1.45 → 1.45 so the band enters and leaves the
                      // mark fully off its own edges.
                      center: -1 - _band + _sweep.value * (2 + 2 * _band),
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

class _ShimmeredLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color base;
  final double center;

  const _ShimmeredLogo({
    required this.width,
    required this.height,
    required this.base,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    final lit = Color.lerp(base, Colors.white, 0.72)!;

    return ShaderMask(
      // The logo is painted flat white so that its alpha (including the
      // distressed texture) becomes the mask, and this gradient becomes the
      // only source of colour.
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(center - _band, -0.35),
          end: Alignment(center + _band, 0.35),
          colors: [base, base, lit, base, base],
          stops: const [0.0, 0.32, 0.5, 0.68, 1.0],
        ).createShader(bounds);
      },
      child: Image.asset(
        'assets/images/logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        color: Colors.white,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, _, _) => Icon(
          Icons.brightness_2_rounded,
          size: height,
          color: base,
        ),
      ),
    );
  }
}
