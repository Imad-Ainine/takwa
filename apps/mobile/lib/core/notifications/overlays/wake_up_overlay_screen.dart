import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/l10n/app_localizations.dart';

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

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    // Both repeat()s are started from didChangeDependencies below, gated
    // on reduce-motion.

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _player = AudioPlayer();
    _initAudio();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative pulse/starfield — respects reduce-motion.
    _pulseCtrl.repeatUnlessReducedMotion(context, reverse: true);
    _starsCtrl.repeatUnlessReducedMotion(context);
  }

  Future<void> _initAudio() async {
    // Read user-selected adhan sound from preferences asynchronously
    final prefs = await ref.read(userPreferencesProvider.future);

    final soundFile = prefs.adhanSound;
    final asset = 'assets/sounds/$soundFile';

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await _player.setAsset(asset);
        _player.setLoopMode(
          LoopMode.one,
        ); // Loop the sound until the user turns it off
        await _player.play();
        return; // نجح
      } catch (e) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _player.dispose();
    _pulseCtrl.dispose();
    _starsCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final l10n = AppLocalizations.of(context)!;
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final ap = _now.hour < 12 ? l10n.timePeriodAm : l10n.timePeriodPm;
    return '$h:$m $ap';
  }

  void _close() {
    _player.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} ${l10n.hijriEraSuffix}';

    return PopScope(
      // WillPopScope is deprecated in favor of PopScope. The old
      // onWillPop always returned true — it only existed to stop the
      // player as a side effect of the pop, never to actually block
      // navigation — so canPop: true (always allow) preserves that.
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _player.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ① Deep Night Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF02061A),
                    Color(0xFF050D2A),
                    Color(0xFF0A1540),
                    Color(0xFF0E1A50),
                  ],
                ),
              ),
            ),

            // ② Animated Stars
            AnimatedBuilder(
              animation: _starsCtrl,
              builder: (_, _) => CustomPaint(
                painter: _AdhanStarsPainter(progress: _starsCtrl.value),
                size: Size.infinite,
              ),
            ),

            // ③ Mosque Silhouette
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
                  painter: _MosqueSilhouettePainter(),
                  size: Size(MediaQuery.of(context).size.width, 220),
                ),
              ),
            ),

            // ④ Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Radiant pulse circle
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) {
                        final pulse = _pulseCtrl.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow rings
                            ...List.generate(3, (i) {
                              final delay = i / 3.0;
                              final wrappedPulse = (pulse + delay) % 1.0;
                              return Container(
                                width: 120 + wrappedPulse * 100,
                                height: 120 + wrappedPulse * 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.3 * (1 - wrappedPulse)),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }),
                            // Center clock text
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.3 + 0.2 * pulse),
                                    blurRadius: 30 + 15 * pulse,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _formattedTime,
                                  style: const TextStyle(
                                    fontFamily: 'NotoNaskhArabic',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Title
                  SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entryCtrl,
                            curve: const Interval(
                              0.2,
                              0.8,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _entryCtrl,
                          curve: const Interval(0.2, 0.8),
                        ),
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37),
                            Color(0xFFF5E070),
                            Color(0xFF2DD4BF),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          l10n.wakeUpOverlayTitle,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Color(0xFFD4AF37), blurRadius: 20),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Hijri date
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.4, 1.0),
                      ),
                    ),
                    child: Text(
                      hijriStr,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Hadith quote
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.5, 1.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'الصلاة خير من النوم',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Buttons
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.6, 1.0),
                      ),
                    ),
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
                              icon: Icons.snooze,
                              label: l10n.wakeUpSnoozeButton,
                              isOutline: true,
                              baseColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: PrimaryButton(
                              onTap: () async => _close(),
                              icon: Icons.stop_circle_outlined,
                              label: l10n.wakeUpStopAlarmButton,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _AdhanStarsPainter extends CustomPainter {
  final double progress;
  _AdhanStarsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final paint = Paint();

    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.75;
      final twinkle = math.sin((progress * math.pi * 2) + i * 0.5);
      final opacity = (0.1 + 0.7 * ((twinkle + 1) / 2)).clamp(0.0, 1.0);
      final radius = 0.6 + rng.nextDouble() * 1.6;
      final isGold = i % 9 == 0;

      paint.color = isGold
          ? const Color(0xFFD4AF37).withValues(alpha: opacity * 0.8)
          : Colors.white.withValues(alpha: opacity * 0.7);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_AdhanStarsPainter old) => old.progress != progress;
}

class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    // Ground
    path.moveTo(0, h);
    path.lineTo(w, h);

    // Right minaret
    path.lineTo(w, h * 0.3);
    path.lineTo(w - w * 0.04, h * 0.3);
    path.lineTo(w - w * 0.04, h * 0.1);
    path.lineTo(w - w * 0.06, h * 0.05);
    path.lineTo(w - w * 0.08, h * 0.1);
    path.lineTo(w - w * 0.08, h * 0.3);
    path.lineTo(w - w * 0.12, h * 0.3);
    path.lineTo(w - w * 0.12, h * 0.5);

    // Main dome
    path.lineTo(w * 0.75, h * 0.5);
    path.quadraticBezierTo(w * 0.5, -h * 0.1, w * 0.25, h * 0.5);

    // Left side
    path.lineTo(w * 0.12, h * 0.5);
    path.lineTo(w * 0.12, h * 0.3);
    path.lineTo(w * 0.08, h * 0.3);
    path.lineTo(w * 0.08, h * 0.1);
    path.lineTo(w * 0.06, h * 0.05);
    path.lineTo(w * 0.04, h * 0.1);
    path.lineTo(w * 0.04, h * 0.3);
    path.lineTo(0, h * 0.3);
    path.lineTo(0, h);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MosqueSilhouettePainter old) => false;
}
