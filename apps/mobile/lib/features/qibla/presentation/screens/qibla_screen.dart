import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan/adhan.dart' as adhan;

import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ─────────────────────────────────────────
//  QIBLA CALCULATION PROVIDER
// ─────────────────────────────────────────
final qiblaProvider = FutureProvider<double>((ref) async {
  final settings = ref.watch(settingsDaoProvider);
  final lat = double.tryParse(await settings.get('latitude') ?? '') ?? 36.7;
  final lng = double.tryParse(await settings.get('longitude') ?? '') ?? 3.0;
  final coords = adhan.Coordinates(lat, lng);
  return adhan.Qibla(coords).direction; // degrees from true North
});

final compassProvider = StreamProvider<double>((ref) {
  return FlutterCompass.events!
      .where((e) => e.heading != null)
      .map((e) => e.heading!);
});

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});
  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _pulse;
  double _smoothHeading = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative breathing pulse — respects reduce-motion.
    _pulseCtrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final qiblaAsync = ref.watch(qiblaProvider);
    final compassAsync = ref.watch(compassProvider);

    return Scaffold(
      backgroundColor: style.bg,
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.qibla),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                _QiblaTopBar(style: style),

                Expanded(
                  child: qiblaAsync.when(
                    loading: () => const _QiblaLoading(),
                    error: (_, _) => _QiblaLocationError(style: style),
                    data: (qiblaDir) => compassAsync.when(
                      loading: () => const _QiblaLoading(),
                      error: (e, _) =>
                          _QiblaCompassError(style: style, error: e),
                      data: (heading) {
                        // Smooth heading
                        double diff = heading - _smoothHeading;
                        while (diff > 180) {
                          diff -= 360;
                        }
                        while (diff < -180) {
                          diff += 360;
                        }
                        _smoothHeading += diff * 0.2;

                        final needleAngle =
                            (qiblaDir - _smoothHeading) * math.pi / 180;
                        final isAligned = (diff.abs() % 360) < 5;

                        return _QiblaContent(
                          style: style,
                          qiblaDir: qiblaDir,
                          heading: _smoothHeading,
                          needleAngle: needleAngle,
                          isAligned: isAligned,
                          pulseAnim: _pulse,
                          entryCtrl: _entryCtrl,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaTopBar extends StatelessWidget {
  final AdaptiveStyle style;
  const _QiblaTopBar({required this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          const CustomLeadingButton(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.qiblaScreenTitle, style: style.amiri(22)),
                Text(
                  l10n.qiblaScreenSubtitle,
                  style: style.naskh(11, color: style.textSec),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── المحتوى الرئيسي ──
class _QiblaContent extends StatelessWidget {
  final AdaptiveStyle style;
  final double qiblaDir, heading, needleAngle;
  final bool isAligned;
  final Animation<double> pulseAnim;
  final AnimationController entryCtrl;

  const _QiblaContent({
    required this.style,
    required this.qiblaDir,
    required this.heading,
    required this.needleAngle,
    required this.isAligned,
    required this.pulseAnim,
    required this.entryCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Matches _QiblaInfoRow's own dir/deg math so the semantic label says
    // the same thing the visible info cards do.
    final diff = ((qiblaDir - heading) % 360 + 360) % 360;
    final turnDir = diff < 180 ? l10n.qiblaDirRight : l10n.qiblaDirLeft;
    final turnDeg = (diff < 180 ? diff : 360 - diff).round();
    final compassLabel = isAligned
        ? l10n.qiblaCompassLabelAligned
        : l10n.qiblaCompassLabelUnaligned(turnDeg.toString(), turnDir);

    return FadeTransition(
      opacity: CurvedAnimation(parent: entryCtrl, curve: Curves.easeOut),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ── الدائرة الرئيسية ──
          ScaleTransition(
            scale: isAligned ? pulseAnim : const AlwaysStoppedAnimation(1.0),
            // One clear "compass, currently pointing X" node instead of a
            // silent CustomPaint plus the center's emoji/degree text read
            // as disconnected fragments — see the audit's "i18n &
            // Accessibility" section. No liveRegion: the heading changes
            // continuously from the compass sensor, and re-announcing on
            // every micro-degree update would be unusable; a screen
            // reader user re-focuses this node to get a fresh reading,
            // same as the visible _QiblaInfoRow cards below it.
            child: Semantics(
              label: compassLabel,
              excludeSemantics: true,
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  painter: _QiblaCompassPainter(
                    needleAngle: needleAngle,
                    heading: heading,
                    isAligned: isAligned,
                    primaryColor: style.gold,
                    tealColor: style.teal,
                    isRamadan: style.isRamadan,
                    north: l10n.qiblaCompassNorth,
                    east: l10n.qiblaCompassEast,
                    south: l10n.qiblaCompassSouth,
                    west: l10n.qiblaCompassWest,
                  ),
                  child: Center(
                    child: _CompassCenter(
                      style: style,
                      isAligned: isAligned,
                      qiblaDir: qiblaDir,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── معلومات القبلة ──
          _QiblaInfoRow(
            style: style,
            heading: heading,
            qiblaDir: qiblaDir,
            isAligned: isAligned,
          ),

          // ── تعليمات ──
          _QiblaHint(style: style, isAligned: isAligned),
        ],
      ),
    );
  }
}

// ── الكومباس (CustomPainter) ──
class _QiblaCompassPainter extends CustomPainter {
  final double needleAngle, heading;
  final bool isAligned;
  final Color primaryColor, tealColor;
  final bool isRamadan;
  final String north, east, south, west;

  _QiblaCompassPainter({
    required this.needleAngle,
    required this.heading,
    required this.isAligned,
    required this.primaryColor,
    required this.tealColor,
    required this.isRamadan,
    required this.north,
    required this.east,
    required this.south,
    required this.west,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;

    // ── حلقات خارجية ──
    for (int i = 3; i >= 0; i--) {
      canvas.drawCircle(
        c,
        r - i * 18,
        Paint()
          ..color = (isAligned ? primaryColor : tealColor).withValues(alpha: 0.03 + i * 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // ── دائرة البوصلة ──
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = isRamadan
            ? primaryColor.withValues(alpha: 0.05)
            : tealColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = primaryColor.withValues(alpha: isAligned ? 0.5 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── علامات الدرجات ──
    for (int deg = 0; deg < 360; deg += 5) {
      final a = (deg - heading) * math.pi / 180;
      final isMajor = deg % 90 == 0;
      final isMed = deg % 45 == 0;
      final lineLen = isMajor
          ? 14.0
          : isMed
          ? 9.0
          : 4.0;
      final p1 = Offset(
        c.dx + (r - 2) * math.sin(a),
        c.dy - (r - 2) * math.cos(a),
      );
      final p2 = Offset(
        c.dx + (r - 2 - lineLen) * math.sin(a),
        c.dy - (r - 2 - lineLen) * math.cos(a),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isMajor
              ? primaryColor.withValues(alpha: isAligned ? 0.9 : 0.6)
              : primaryColor.withValues(alpha: 0.3)
          ..strokeWidth = isMajor ? 2 : 0.8,
      );
    }

    // ── حرف N,S,E,W ──
    final dirs = [(north, 0.0), (east, 90.0), (south, 180.0), (west, 270.0)];
    final tp = TextPainter(textDirection: TextDirection.rtl);
    for (final d in dirs) {
      final a = (d.$2 - heading) * math.pi / 180;
      final textR = r - 24;
      final x = c.dx + textR * math.sin(a);
      final y = c.dy - textR * math.cos(a);
      tp.text = TextSpan(
        text: d.$1,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 13,
          color: d.$1 == north ? primaryColor : primaryColor.withValues(alpha: 0.4),
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // ── خط القبلة (glow) ──
    if (isAligned) {
      canvas.drawLine(
        Offset(c.dx, c.dy),
        Offset(
          c.dx + (r - 30) * math.sin(needleAngle),
          c.dy - (r - 30) * math.cos(needleAngle),
        ),
        Paint()
          ..color = primaryColor.withValues(alpha: 0.3)
          ..strokeWidth = 30
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // ── سهم القبلة ──
    final arrowTip = Offset(
      c.dx + (r - 30) * math.sin(needleAngle),
      c.dy - (r - 30) * math.cos(needleAngle),
    );
    final arrowBase = Offset(
      c.dx - 35 * math.sin(needleAngle),
      c.dy + 35 * math.cos(needleAngle),
    );

    // Arrow shaft
    canvas.drawLine(
      arrowBase,
      arrowTip,
      Paint()
        ..color = isAligned ? primaryColor : tealColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead
    final arrowColor = isAligned ? primaryColor : tealColor;
    const headLen = 18.0;
    const headAng = 0.4;
    for (final side in [-1, 1]) {
      final hx = arrowTip.dx - headLen * math.sin(needleAngle + side * headAng);
      final hy = arrowTip.dy + headLen * math.cos(needleAngle + side * headAng);
      canvas.drawLine(
        arrowTip,
        Offset(hx, hy),
        Paint()
          ..color = arrowColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dot at tip
    canvas.drawCircle(
      arrowTip,
      6,
      Paint()
        ..color = arrowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(arrowTip, 4, Paint()..color = arrowColor);
  }

  @override
  bool shouldRepaint(_QiblaCompassPainter old) =>
      old.needleAngle != needleAngle ||
      old.isAligned != isAligned ||
      old.north != north;
}

// ── مركز الكومباس ──
class _CompassCenter extends StatelessWidget {
  final AdaptiveStyle style;
  final bool isAligned;
  final double qiblaDir;
  const _CompassCenter({
    required this.style,
    required this.isAligned,
    required this.qiblaDir,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            style.gold.withValues(alpha: isAligned ? 0.25 : 0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: style.gold.withValues(alpha: isAligned ? 0.5 : 0.2),
          width: isAligned ? 2 : 1,
        ),
        boxShadow: isAligned
            ? [
                BoxShadow(
                  color: style.gold.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isAligned ? '🕋' : '🧭',
            style: TextStyle(fontSize: isAligned ? 26 : 22),
          ),
          Text(
            '${qiblaDir.round()}°',
            style: style.naskh(11, color: style.gold, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── صف المعلومات ──
class _QiblaInfoRow extends StatelessWidget {
  final AdaptiveStyle style;
  final double heading, qiblaDir;
  final bool isAligned;
  const _QiblaInfoRow({
    required this.style,
    required this.heading,
    required this.qiblaDir,
    required this.isAligned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = ((qiblaDir - heading) % 360 + 360) % 360;
    final dir = diff < 180 ? l10n.qiblaTurnRightShort : l10n.qiblaTurnLeftShort;
    final deg = diff < 180 ? diff.round() : (360 - diff).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              label: l10n.qiblaScreenTitle,
              value: '${qiblaDir.round()}°',
              icon: '🕋',
              style: style,
              isActive: isAligned,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _InfoCard(
              label: l10n.qiblaCurrentDirectionLabel,
              value: '${heading.round() % 360}°',
              icon: '🧭',
              style: style,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _InfoCard(
              label: isAligned
                  ? l10n.qiblaAlignedLabel
                  : l10n.qiblaTurnLabel(dir),
              value: isAligned ? l10n.qiblaCorrectValue : '$deg°',
              icon: isAligned ? '✅' : '↩️',
              style: style,
              isActive: isAligned,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value, icon;
  final AdaptiveStyle style;
  final bool isActive;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.style,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.md,
      horizontal: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: isActive ? style.gold.withValues(alpha: 0.12) : style.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isActive ? style.gold.withValues(alpha: 0.4) : style.border,
      ),
    ),
    child: Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: style.naskh(
            14,
            color: isActive ? style.gold : style.text,
            weight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: style.naskh(9, color: style.textSec),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ── تعليمات ──
class _QiblaHint extends StatelessWidget {
  final AdaptiveStyle style;
  final bool isAligned;
  const _QiblaHint({required this.style, required this.isAligned});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: isAligned
              ? LinearGradient(
                  colors: [
                    style.teal.withValues(alpha: 0.15),
                    style.gold.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isAligned ? null : style.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAligned ? style.teal.withValues(alpha: 0.4) : style.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isAligned ? '✅' : '📱', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              isAligned ? l10n.qiblaFacingNowHint : l10n.qiblaHoldPhoneHint,
              style: style.naskh(
                12,
                color: isAligned ? style.teal : style.textSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error / Loading states ──
class _QiblaLoading extends ConsumerWidget {
  const _QiblaLoading();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    return const Center(child: TakwaLoadingIndicator(size: 32));
  }
}

class _QiblaLocationError extends StatelessWidget {
  final AdaptiveStyle style;
  const _QiblaLocationError({required this.style});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.qiblaLocationRequiredTitle, style: style.amiri(16)),
          const SizedBox(height: 6),
          Text(
            l10n.qiblaLocationRequiredSubtitle,
            style: style.naskh(12, color: style.textSec),
          ),
        ],
      ),
    );
  }
}

class _QiblaCompassError extends StatelessWidget {
  final AdaptiveStyle style;
  final Object error;
  const _QiblaCompassError({required this.style, required this.error});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.qiblaCompassUnavailableTitle, style: style.amiri(16)),
          const SizedBox(height: 6),
          Text(
            l10n.qiblaCompassUnavailableSubtitle,
            style: style.naskh(12, color: style.textSec),
          ),
        ],
      ),
    );
  }
}
