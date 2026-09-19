import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────

/// Theme-aware colour palette for the wake-up overlay.
class _WakePalette {
  final Brightness brightness;
  const _WakePalette._(this.brightness);

  factory _WakePalette.of(Brightness b) => _WakePalette._(b);

  bool get _isDark => brightness == Brightness.dark;

  List<Color> get gradientColors => _isDark
      ? const [
          Color(0xFF02061A),
          Color(0xFF050D2A),
          Color(0xFF0A1540),
          Color(0xFF0E1A50),
        ]
      : const [
          Color(0xFFFFF8E7),
          Color(0xFFFDF3D0),
          Color(0xFFFAE8B0),
          Color(0xFFF5D88A),
        ];

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      );

  /// Warm gold — consistent across modes
  Color get accent => const Color(0xFFD4AF37);

  Color get accentSoft => _isDark
      ? const Color(0xFFD4AF37).withValues(alpha: 0.8)
      : const Color(0xFFA07800);

  Color get textPrimary =>
      _isDark ? Colors.white : const Color(0xFF1A1200);

  Color get textSecondary =>
      _isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF5C4A00);

  Color get cardBg => _isDark
      ? const Color(0xFFD4AF37).withValues(alpha: 0.08)
      : const Color(0xFFD4AF37).withValues(alpha: 0.12);

  Color get cardBorder => _isDark
      ? const Color(0xFFD4AF37).withValues(alpha: 0.22)
      : const Color(0xFFD4AF37).withValues(alpha: 0.35);

  Color get ringColor =>
      _isDark ? const Color(0xFFD4AF37) : const Color(0xFFA07800);

  double get mosqueOpacity => _isDark ? 0.07 : 0.13;
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class WakeUpOverlayScreen extends ConsumerStatefulWidget {
  const WakeUpOverlayScreen({super.key});

  @override
  ConsumerState<WakeUpOverlayScreen> createState() =>
      _WakeUpOverlayScreenState();
}

class _WakeUpOverlayScreenState extends ConsumerState<WakeUpOverlayScreen>
    with TickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _pulseCtrl;
  late final AnimationController _starsCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _ringCtrl;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _audioInitialized = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Alarm ring pulse — faster than pulse for urgency
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _player = AudioPlayer();

    // ⚠️ SOUND FIX: defer audio init until after the first frame so that
    // Riverpod `ref` is fully settled and the widget is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initAudio();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulseCtrl.repeatUnlessReducedMotion(context, reverse: true);
    _starsCtrl.repeatUnlessReducedMotion(context);
    _ringCtrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  // ─── Audio ─────────────────────────────────────────────────────────────────

  Future<void> _initAudio() async {
    if (_audioInitialized || !mounted) return;
    _audioInitialized = true;

    // Read user preferences safely after frame
    UserPreferences? prefs = ref.read(userPreferencesProvider).valueOrNull;
    if (prefs == null) {
      try {
        prefs = await ref.read(userPreferencesProvider.future);
      } catch (_) {}
    }

    if (!mounted) return;

    final volume = (prefs?.adhanVolumeLevel ?? 100) / 100.0;
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}

    // Use preferred adhan/alarm sound, then fallback to existing assets
    final soundFile = prefs?.adhanSound;
    final candidates = <String>[
      if (soundFile != null && soundFile.isNotEmpty) 'assets/sounds/$soundFile',
      'assets/sounds/Adhan-Makkah.mp3',
      'assets/sounds/notification.mp3',
    ];

    for (final asset in candidates) {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          await _player.setAsset(asset);
          _player.setLoopMode(LoopMode.one);
          await _player.play();
          return; // success
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _clockTimer.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    _pulseCtrl.dispose();
    _starsCtrl.dispose();
    _entryCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  String _formattedTime(AppLocalizations l10n) {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final ap = _now.hour < 12 ? l10n.timePeriodAm : l10n.timePeriodPm;
    return '$h:$m $ap';
  }

  void _close() {
    _player.stop();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final palette = _WakePalette.of(brightness);
    final isDark = brightness == Brightness.dark;

    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} ${l10n.hijriEraSuffix}';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _player.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ① Adaptive gradient background
            Container(
              decoration: BoxDecoration(gradient: palette.gradient),
            ),

            // ② Animated stars (dark mode)
            if (isDark)
              AnimatedBuilder(
                animation: _starsCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _WakeStarsPainter(
                    progress: _starsCtrl.value,
                    accent: palette.accent,
                  ),
                  size: Size.infinite,
                ),
              ),

            // ③ Islamic geometric pattern (light mode)
            if (!isDark)
              Positioned.fill(
                child: CustomPaint(
                  painter: _WakeGeometricPainter(
                    color: palette.accent,
                    opacity: 0.06,
                  ),
                ),
              ),

            // ④ Mosque silhouette at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _entryCtrl,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: CustomPaint(
                  painter: _WakeMosquePainter(
                    color: palette.accent,
                    opacity: palette.mosqueOpacity,
                  ),
                  size: Size(MediaQuery.sizeOf(context).width, 220),
                ),
              ),
            ),

            // ⑤ Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Radiant alarm ring ──────────────────────────────────
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final pulse = _pulseCtrl.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Expanding glow rings
                            ...List.generate(3, (i) {
                              final delay = i / 3.0;
                              final wrapped = (pulse + delay) % 1.0;
                              return Container(
                                width: 130 + wrapped * 110,
                                height: 130 + wrapped * 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: palette.ringColor.withValues(
                                      alpha: 0.35 * (1 - wrapped),
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }),

                            // Clock circle
                            AnimatedBuilder(
                              animation: _ringCtrl,
                              builder: (_, child) {
                                final ring = _ringCtrl.value;
                                return Container(
                                  width: 148,
                                  height: 148,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        palette.accent.withValues(
                                          alpha: 0.25 + 0.1 * ring,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: palette.ringColor,
                                      width: 1.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.accent.withValues(
                                          alpha: 0.25 + 0.18 * ring,
                                        ),
                                        blurRadius: 32 + 14 * ring,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.alarm_rounded,
                                    color: palette.accent,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formattedTime(l10n),
                                    style: TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                      height: 1.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Wake-up title ───────────────────────────────────────
                  _buildSlideIn(
                    controller: _entryCtrl,
                    intervalStart: 0.2,
                    intervalEnd: 0.8,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? const [
                                Color(0xFFD4AF37),
                                Color(0xFFF5E070),
                                Color(0xFF2DD4BF),
                              ]
                            : [
                                palette.accentSoft,
                                const Color(0xFFD4AF37),
                                palette.accentSoft,
                              ],
                      ).createShader(bounds),
                      child: Text(
                        l10n.wakeUpOverlayTitle,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // masked by ShaderMask
                          shadows: [
                            Shadow(
                              color: palette.accent.withValues(alpha: 0.35),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Hijri date ──────────────────────────────────────────
                  _buildFadeIn(
                    controller: _entryCtrl,
                    intervalStart: 0.4,
                    intervalEnd: 1.0,
                    child: Text(
                      hijriStr,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 14,
                        color: palette.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Hadith quote card ───────────────────────────────────
                  _buildFadeIn(
                    controller: _entryCtrl,
                    intervalStart: 0.5,
                    intervalEnd: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🌅', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.adhanOverlayDuaSectionLabel,
                                  style: TextStyle(
                                    fontFamily: 'NotoNaskhArabic',
                                    fontSize: 11,
                                    color: palette.accentSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'الصلاة خير من النوم',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                color: isDark
                                    ? palette.accent.withValues(alpha: 0.85)
                                    : palette.accentSoft,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Action buttons ──────────────────────────────────────
                  _buildFadeIn(
                    controller: _entryCtrl,
                    intervalStart: 0.6,
                    intervalEnd: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              onTap: () async {
                                await NotificationsService.scheduleSnooze(
                                  minutes: 10,
                                  l10n: l10n,
                                );
                                _close();
                              },
                              icon: Icons.snooze_rounded,
                              label: l10n.wakeUpSnoozeButton,
                              isOutline: true,
                              baseColor: isDark
                                  ? Colors.white70
                                  : const Color(0xFF5C4A00),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: PrimaryButton(
                              onTap: _close,
                              icon: Icons.stop_circle_outlined,
                              label: l10n.wakeUpStopAlarmButton,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Animation helpers ────────────────────────────────────────────────────

  Widget _buildSlideIn({
    required AnimationController controller,
    required double intervalStart,
    required double intervalEnd,
    required Widget child,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(intervalStart, intervalEnd),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFadeIn({
    required AnimationController controller,
    required double intervalStart,
    required double intervalEnd,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(intervalStart, intervalEnd),
        ),
      ),
      child: child,
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _WakeStarsPainter extends CustomPainter {
  final double progress;
  final Color accent;
  _WakeStarsPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint();

    for (int i = 0; i < 130; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.75;
      final twinkle = math.sin((progress * math.pi * 2) + i * 0.53);
      final opacity = (0.1 + 0.7 * ((twinkle + 1) / 2)).clamp(0.0, 1.0);
      final radius = 0.5 + rng.nextDouble() * 1.6;
      final isGold = i % 8 == 0;

      paint.color = isGold
          ? accent.withValues(alpha: opacity * 0.8)
          : Colors.white.withValues(alpha: opacity * 0.65);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WakeStarsPainter old) =>
      old.progress != progress || old.accent != accent;
}

class _WakeGeometricPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _WakeGeometricPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const tile = 60.0;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * tile + tile / 2;
        final cy = row * tile + tile / 2;
        _drawStar(canvas, paint, Offset(cx, cy), tile * 0.38);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset c, double r) {
    final sq1 = Path()
      ..addRect(Rect.fromCenter(center: c, width: r * 2, height: r * 2));
    final sq2 = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(sq1, paint);
    canvas.drawPath(sq2, paint);
  }

  @override
  bool shouldRepaint(_WakeGeometricPainter old) =>
      old.color != color || old.opacity != opacity;
}

class _WakeMosquePainter extends CustomPainter {
  final Color color;
  final double opacity;
  _WakeMosquePainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      // Right minaret
      ..lineTo(w, h * 0.3)
      ..lineTo(w - w * 0.04, h * 0.3)
      ..lineTo(w - w * 0.04, h * 0.1)
      ..lineTo(w - w * 0.06, h * 0.05)
      ..lineTo(w - w * 0.08, h * 0.1)
      ..lineTo(w - w * 0.08, h * 0.3)
      ..lineTo(w - w * 0.12, h * 0.3)
      ..lineTo(w - w * 0.12, h * 0.5)
      // Main dome
      ..lineTo(w * 0.75, h * 0.5)
      ..quadraticBezierTo(w * 0.5, -h * 0.1, w * 0.25, h * 0.5)
      // Left side
      ..lineTo(w * 0.12, h * 0.5)
      ..lineTo(w * 0.12, h * 0.3)
      ..lineTo(w * 0.08, h * 0.3)
      ..lineTo(w * 0.08, h * 0.1)
      ..lineTo(w * 0.06, h * 0.05)
      ..lineTo(w * 0.04, h * 0.1)
      ..lineTo(w * 0.04, h * 0.3)
      ..lineTo(0, h * 0.3)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path, paint);

    // Crescent finials
    final crescentPaint = Paint()
      ..color = color.withValues(alpha: opacity * 1.4)
      ..style = PaintingStyle.fill;

    _drawCrescent(canvas, crescentPaint, Offset(w * 0.06, h * 0.04), h * 0.025);
    _drawCrescent(canvas, crescentPaint, Offset(w - w * 0.06, h * 0.04), h * 0.025);
  }

  void _drawCrescent(Canvas canvas, Paint paint, Offset centre, double r) {
    final outer = Path()..addOval(Rect.fromCircle(center: centre, radius: r));
    final inner = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(centre.dx + r * 0.35, centre.dy),
          radius: r * 0.75,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
  }

  @override
  bool shouldRepaint(_WakeMosquePainter old) =>
      old.color != color || old.opacity != opacity;
}
