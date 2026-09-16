import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'background_painters.dart';

// Was 41 variants (§M15) — GeometricPainter, DuasBgPainter, AsmaBgPainter,
// pattern1-18, and P02-P18 were declared, painted, and switched on below,
// but auditing every CustomPatternBackground(pattern: ...) call site in the
// app found none of them actually used anywhere: every screen reaches for
// `adhkar` except the Qibla screen (`qibla`) and the Misbaha counter's accent
// (`twelveFoldStar`). Curated down to those three real ones; see
// background_painters.dart for where the other 38 painter classes went.
enum BackgroundPattern {
  /// The app-wide default — used on nearly every screen.
  adhkar,

  /// The Qibla compass screen's background.
  qibla,

  /// P01 · 12-fold star on hexagonal grid (Moroccan / Andalusian) — the
  /// Misbaha counter's accent pattern.
  twelveFoldStar,
}

class CustomPatternBackground extends ConsumerStatefulWidget {
  final BackgroundPattern pattern;
  final Color? color;
  final double? opacity;

  const CustomPatternBackground({
    super.key,
    this.pattern = BackgroundPattern.adhkar,
    this.color,
    this.opacity,
  });

  @override
  ConsumerState<CustomPatternBackground> createState() =>
      _CustomPatternBackgroundState();
}

class _CustomPatternBackgroundState
    extends ConsumerState<CustomPatternBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // Actual start/stop is decided in didChangeDependencies below (it needs
    // MediaQuery, which isn't available this early) and the `ref.listen` in
    // build — not here unconditionally.
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Used to be decided inline in build() (audit §M16: a side effect there
    // makes build() non-idempotent — Flutter is free to call it more than
    // once for the same frame, so _ctrl.stop()/.repeat() could fire
    // redundantly on every rebuild for no reason). MediaQuery's reduce-motion
    // flag can change mid-session, and didChangeDependencies is exactly the
    // lifecycle hook Flutter re-runs when a dependency like that changes; the
    // Ramadan-mode half of this same decision is handled by the ref.listen
    // registered in build below.
    _syncAnimation(ref.read(ramadanModeProvider).value ?? false);
  }

  // This drives a purely decorative starfield twinkle + lantern flicker
  // (see RamadanBgPainter) — exactly the ambient motion the platform's
  // reduce-motion setting exists to suppress. The painter still renders its
  // static content at whatever frame the controller is parked on; only the
  // animation itself stops. Stays off entirely outside Ramadan mode.
  void _syncAnimation(bool isRamadan) {
    final shouldRun = isRamadan && !prefersReducedMotion(context);
    if (shouldRun && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!shouldRun && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    // Registered on every build, but Riverpod only invokes the callback when
    // the provider's value actually changes, and always after this build
    // finishes — the sanctioned way to run a side effect off a watched
    // provider instead of mutating _ctrl inline above.
    ref.listen<AsyncValue<bool>>(ramadanModeProvider, (_, next) {
      _syncAnimation(next.value ?? false);
    });

    if (isRamadan) {
      final brightness = Theme.of(context).brightness;
      // No AnimatedBuilder here on purpose: RamadanBgPainter is constructed
      // with `repaint: _ctrl` (see its constructor), so the render object
      // calls paint() again on this SAME painter instance every animation
      // tick without rebuilding this subtree or constructing a new painter.
      // That's what lets the painter's internal Picture/star caches (see
      // that class) actually get reused instead of being rebuilt from
      // scratch ~15 times a second.
      return SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: RamadanBgPainter(
                    animation: _ctrl,
                    brightness: brightness,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    CustomPainter painter;
    final baseColor = widget.color ?? colors.gold;
    // In light mode, use a lower default opacity so the pattern stays subtle.
    final baseOpacity = widget.opacity ?? (isDark ? 0.08 : 0.04);

    switch (widget.pattern) {
      case BackgroundPattern.twelveFoldStar:
        painter = IslamicP01Painter(color: baseColor, opacity: baseOpacity);
      case BackgroundPattern.adhkar:
        painter = AdhkarBgPainter(
          goldColor: baseColor,
          nightColor: colors.background,
        );
      case BackgroundPattern.qibla:
        painter = QiblaBgPainter(goldColor: baseColor);
    }

    return SizedBox.expand(
      child: RepaintBoundary(child: CustomPaint(painter: painter)),
    );
  }
}
