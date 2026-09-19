import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:takwa/core/notifications/adhan_auto_trigger.dart';
import 'package:takwa/core/notifications/adhan_foreground_service.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────

/// Theme- and prayer-aware colour palette for the adhan overlay screen.
///
/// Use [_AdhanPalette.of] to resolve the palette from the current [Brightness]
/// and the Arabic prayer name supplied to the screen.
class _AdhanPalette {
  final Brightness brightness;
  final String prayerName;

  const _AdhanPalette._(this.brightness, this.prayerName);

  factory _AdhanPalette.of(Brightness brightness, String? prayerName) {
    return _AdhanPalette._(brightness, (prayerName ?? '').toLowerCase());
  }

  bool get _isDark => brightness == Brightness.dark;

  // ── Gradient ──────────────────────────────────────────────────────────────

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
          Color(0xFFF5D78A),
        ];

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      );

  // ── Accent (prayer-specific) ───────────────────────────────────────────────

  Color get accent {
    if (prayerName.contains('فجر') || prayerName.contains('fajr')) {
      return const Color(0xFF6BA3BE); // dawn blue
    } else if (prayerName.contains('ظهر') || prayerName.contains('dhuhr')) {
      return const Color(0xFFE8A838); // warm amber
    } else if (prayerName.contains('عصر') || prayerName.contains('asr')) {
      return const Color(0xFFD4AF37); // golden yellow
    } else if (prayerName.contains('مغرب') || prayerName.contains('maghrib')) {
      return const Color(0xFFD4602A); // deep orange-crimson
    } else if (prayerName.contains('عشاء') || prayerName.contains('isha')) {
      return const Color(0xFF4A3F8C); // deep indigo
    }
    return const Color(0xFFD4AF37); // default gold
  }

  // ── Text / opacity helpers ────────────────────────────────────────────────

  Color get textColor =>
      _isDark ? Colors.white : const Color(0xFF1A1A2E);

  double get mosqueOpacity => _isDark ? 0.6 : 0.45;

  double get geometricOpacity => _isDark ? 0.05 : 0.07;
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class AdhanOverlayScreen extends ConsumerStatefulWidget {
  /// Null when the route was opened without a prayer argument — the screen
  /// then falls back to a localized generic label.
  final String? prayerName;
  final bool autoPlay;

  const AdhanOverlayScreen({
    super.key,
    this.prayerName,
    this.autoPlay = true,
  });

  @override
  ConsumerState<AdhanOverlayScreen> createState() => _AdhanOverlayScreenState();
}

class _AdhanOverlayScreenState extends ConsumerState<AdhanOverlayScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _starsCtrl;
  late final AnimationController _entryCtrl;

  Timer? _vibrationTimer;
  Timer? _restoreRingerTimer;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Prevents repeated silence calls while the phone stays face-down.
  bool _silenced = false;
  bool _flipArmed = false;

  // Face-down detection thresholds (tuned for real devices)
  static const double _zFaceDownThreshold = -8.0;
  static const double _xyStillThreshold = 4.0;
  static const Duration _faceDownConfirm = Duration(milliseconds: 280);

  DateTime? _faceDownSince;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _initializePreferences();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decorative animations respect reduce-motion.
    _pulseCtrl.repeatUnlessReducedMotion(context, reverse: true);
    _starsCtrl.repeatUnlessReducedMotion(context);
  }

  Future<void> _initializePreferences() async {
    final UserPreferences prefs =
        ref.read(userPreferencesProvider).valueOrNull ??
            await ref.read(userPreferencesProvider.future);
    if (!mounted) return;

    if (prefs.wakeScreenEnabled) {
      WakelockPlus.enable();
    }

    // Mirror player silence state into local UI.
    AdhanAudioPlayer.silenced.addListener(_onPlayerSilencedChanged);
    _onPlayerSilencedChanged();

    _initVibration(prefs);

    if (widget.autoPlay) {
      await _initAudio(prefs);

      // Arm the player's own flip logic (keeps compatibility).
      AdhanAudioPlayer.ensureFlipArmed(
        prefs.flipToSilenceEnabled,
        flipSilencePhone: prefs.autoSilentAfterAdhan,
      );

      // Also arm our own reliable detector.
      if (prefs.flipToSilenceEnabled) {
        _armFlipToSilence(prefs.autoSilentAfterAdhan);
      }
    }
  }

  void _onPlayerSilencedChanged() {
    if (!AdhanAudioPlayer.silenced.value || _silenced) return;
    _vibrationTimer?.cancel();
    if (mounted) {
      setState(() => _silenced = true);
    } else {
      _silenced = true;
    }
  }

  // ─── Flip-to-Silence (self-contained, reliable) ───────────────────────────

  void _armFlipToSilence(bool alsoSilentPhone) {
    if (_flipArmed) return;
    _flipArmed = true;

    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (event) => _onAccelerometer(event, alsoSilentPhone),
      onError: (e) => debugPrint('Accelerometer error: $e'),
      cancelOnError: false,
    );
  }

  void _onAccelerometer(AccelerometerEvent event, bool alsoSilentPhone) {
    if (_silenced || !mounted) return;

    final z = event.z;
    final xy = math.sqrt(event.x * event.x + event.y * event.y);

    final isFaceDown = z <= _zFaceDownThreshold && xy <= _xyStillThreshold;

    if (isFaceDown) {
      _faceDownSince ??= DateTime.now();
      if (DateTime.now().difference(_faceDownSince!) >= _faceDownConfirm) {
        _silenceAdhan(alsoSilentPhone: alsoSilentPhone);
      }
    } else {
      _faceDownSince = null;
    }
  }

  // ─── Vibration ───────────────────────────────────────────────────────────

  void _initVibration(UserPreferences prefs) {
    final mode = prefs.adhanMode;

    if (mode == 'vibrate' || (mode == 'sound' && prefs.vibrateWithAdhan)) {
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (AdhanAudioPlayer.isPlaying || mode == 'vibrate') {
          HapticFeedback.vibrate();
        }
      });

      if (mode == 'vibrate') {
        Future.delayed(const Duration(minutes: 3), () {
          _vibrationTimer?.cancel();
        });
      }
    }
  }

  // ─── Silence / Audio ─────────────────────────────────────────────────────

  Future<void> _silenceAdhan({bool alsoSilentPhone = false}) async {
    if (_silenced) return;

    if (mounted) {
      setState(() => _silenced = true);
    } else {
      _silenced = true;
    }

    _vibrationTimer?.cancel();
    await AdhanAudioPlayer.stop();
    AdhanAudioPlayer.silenced.value = true;

    if (mounted) HapticFeedback.mediumImpact();

    // Optional: put the whole phone into silent mode after flip.
    if (alsoSilentPhone) {
      try {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
      } catch (_) {}
    }
  }

  Future<void> _initAudio(UserPreferences prefs) async {
    final mode = prefs.adhanMode;

    if (mode == 'silent' || mode == 'vibrate') {
      if (mounted) {
        setState(() => _silenced = true);
      } else {
        _silenced = true;
      }
      return;
    }

    final soundFile = prefs.adhanSound;
    final asset = 'assets/sounds/$soundFile';
    final volume = prefs.adhanVolumeLevel;

    if (!AdhanAudioPlayer.isPlaying) {
      await AdhanAudioPlayer.play(
        asset: asset,
        volume: volume,
        flipToSilenceEnabled: prefs.flipToSilenceEnabled,
        flipSilencePhone: prefs.autoSilentAfterAdhan,
      );
    } else {
      await AdhanAudioPlayer.setVolume(volume);
    }

    if (mounted) setState(() => _silenced = false);
  }

  // ─── Navigation helpers ──────────────────────────────────────────────────

  void _close() {
    _cleanup();
    _applyAutoSilent();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    }
  }

  void _goToPrayer() {
    _cleanup();
    _applyAutoSilent();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      Navigator.of(context).pushNamed(Routes.prayer);
    } else {
      Navigator.of(context).pushReplacementNamed(Routes.prayer);
    }
  }

  void _cleanup() {
    AdhanAudioPlayer.stop();
    _vibrationTimer?.cancel();
    _accelSub?.cancel();
    AdhanForegroundService.stopAdhanService();
  }

  // ─── Subtask 3.6: Fixed _applyAutoSilent ─────────────────────────────────

  Future<void> _applyAutoSilent() async {
    final prefs = ref.read(userPreferencesProvider).valueOrNull;
    if (prefs == null || !prefs.autoSilentAfterAdhan) return;

    final style = prefs.silentModeAlertStyle;
    final RingerModeStatus targetMode;
    switch (style) {
      case 'vibrate':
        targetMode = RingerModeStatus.vibrate;
        break;
      case 'tone':
      case 'toneVibrate':
        targetMode = RingerModeStatus.normal;
        break;
      case 'silent':
      case 'none':
      default:
        targetMode = RingerModeStatus.silent;
        break;
    }

    try {
      await SoundMode.setSoundMode(targetMode);
    } catch (e) {
      debugPrint('Auto-silent error: $e');
    }

    if (targetMode != RingerModeStatus.normal) {
      _restoreRingerTimer?.cancel();
      _restoreRingerTimer = Timer(Duration(minutes: prefs.silentDurationMins), () async {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.normal);
        } catch (e) {
          debugPrint('Auto-silent restore error: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    AdhanAudioPlayer.silenced.removeListener(_onPlayerSilencedChanged);
    _vibrationTimer?.cancel();
    _restoreRingerTimer?.cancel();
    _accelSub?.cancel();
    AdhanAudioPlayer.stop();
    AdhanForegroundService.stopAdhanService();
    _pulseCtrl.dispose();
    _starsCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Subtask 3.1: resolve palette
    final palette = _AdhanPalette.of(theme.brightness, widget.prayerName);

    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} ${l10n.hijriEraSuffix}';

    // Derive secondary colours from palette
    final gold = palette.accent;
    final goldSoft = gold.withValues(alpha: isDark ? 0.8 : 0.9);
    final textSecondary =
        isDark ? Colors.white.withValues(alpha: 0.65) : colorScheme.onSurfaceVariant;
    final muteChipBg = _silenced
        ? (isDark ? Colors.white.withValues(alpha: 0.1) : colorScheme.surfaceContainerHighest)
        : gold.withValues(alpha: isDark ? 0.2 : 0.15);
    final muteChipBorder = _silenced
        ? (isDark ? Colors.white24 : colorScheme.outline.withValues(alpha: 0.4))
        : gold.withValues(alpha: 0.6);

    return PopScope(
      canPop: true,
      // Subtask 3.5: call _applyAutoSilent on system back-button dismissal
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cleanup();
          unawaited(_applyAutoSilent());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ① Adaptive background — Subtask 3.1: uses palette.gradient
            Container(
              decoration: BoxDecoration(
                gradient: palette.gradient,
              ),
            ),

            // ② Islamic geometric pattern — Subtask 3.3
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicGeometricPainter(
                  color: palette.textColor,
                  opacity: palette.geometricOpacity,
                ),
              ),
            ),

            // ③ Animated stars (dark mode only – subtle in light)
            if (isDark)
              AnimatedBuilder(
                animation: _starsCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _AdhanStarsPainter(progress: _starsCtrl.value),
                  size: Size.infinite,
                ),
              ),

            // ④ Mosque silhouette — Subtask 3.2: enhanced painter
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
                  painter: _MosqueSilhouettePainter(
                    color: gold.withValues(alpha: isDark ? 0.07 : 0.12),
                    accentColor: palette.accent,
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
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _close,
                          icon: Icon(
                            Icons.close_rounded,
                            color: textSecondary,
                            size: 26,
                          ),
                          tooltip: l10n.adhanOverlayCloseButton,
                        ),
                        InkWell(
                          onTap: () => _silenceAdhan(),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: muteChipBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: muteChipBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _silenced
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  color: _silenced ? textSecondary : gold,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _silenced
                                      ? (Localizations.localeOf(context)
                                                  .languageCode ==
                                              'ar'
                                          ? 'الصوت متوقف'
                                          : 'Muted')
                                      : (Localizations.localeOf(context)
                                                  .languageCode ==
                                              'ar'
                                          ? 'إيقاف الصوت'
                                          : 'Stop Audio'),
                                  style: TextStyle(
                                    fontFamily: 'NotoNaskhArabic',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _silenced ? textSecondary : gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Radiant pulse + crescent
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
                            ...List.generate(3, (i) {
                              final delay = i / 3.0;
                              final wrapped = (pulse + delay) % 1.0;
                              return Container(
                                width: 120 + wrapped * 100,
                                height: 120 + wrapped * 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: gold.withValues(
                                      alpha: 0.3 * (1 - wrapped),
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    gold.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                                border: Border.all(color: gold, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withValues(
                                      alpha: 0.25 + 0.2 * pulse,
                                    ),
                                    blurRadius: 30 + 15 * pulse,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '☪',
                                  style: TextStyle(
                                    fontSize: 42,
                                    color: gold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Subtask 3.4: Calligraphic Bismillah header above prayer name
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entryCtrl,
                      curve: const Interval(0.1, 0.7),
                    ),
                    child: Text(
                      '\uFDFD', // ﷽ Bismillah
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        color: palette.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Prayer name
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
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
                        shaderCallback: (bounds) => LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFFD4AF37),
                                  const Color(0xFFF5E070),
                                  const Color(0xFF2DD4BF),
                                ]
                              : [
                                  gold,
                                  colorScheme.primary,
                                  colorScheme.tertiary,
                                ],
                        ).createShader(bounds),
                        child: Text(
                          l10n.adhanOverlayPrayerTimeTitle(
                            widget.prayerName ?? l10n.prayerGenericLabel,
                          ),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white, // masked
                            shadows: [
                              Shadow(
                                color: gold.withValues(alpha: 0.4),
                                blurRadius: 18,
                              ),
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
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Hadith
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
                        _prayerHadith(widget.prayerName ?? ''),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: goldSoft,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Action buttons
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
                              onTap: () async => _close(),
                              icon: Icons.close_rounded,
                              label: l10n.adhanOverlayCloseButton,
                              isOutline: true,
                              baseColor: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: PrimaryButton(
                              onTap: () async => _goToPrayer(),
                              icon: Icons.mosque_rounded,
                              label: l10n.adhanOverlayGoToPrayerButton,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Dua after Adhan
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _entryCtrl,
                        curve: const Interval(0.7, 1.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: isDark ? 0.08 : 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: gold.withValues(alpha: isDark ? 0.2 : 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🤲', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.adhanOverlayDuaSectionLabel,
                                  style: TextStyle(
                                    fontFamily: 'NotoNaskhArabic',
                                    fontSize: 12,
                                    color: gold.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'اللَّهُمَّ رَبَّ هَٰذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 15,
                                color: palette.textColor,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prayerHadith(String prayer) {
    if (prayer.contains('فجر') || prayer.contains('Fajr')) {
      return 'الصلاة خير من النوم';
    } else if (prayer.contains('ظهر') || prayer.contains('Dhuhr')) {
      return 'حافظوا على الصلوات والصلاة الوسطى';
    } else if (prayer.contains('عصر') || prayer.contains('Asr')) {
      return 'من فاتته صلاة العصر فكأنما وُتر أهله وماله';
    } else if (prayer.contains('مغرب') || prayer.contains('Maghrib')) {
      return 'بادروا بالصلاة قبل الفوات';
    } else if (prayer.contains('عشاء') || prayer.contains('Isha')) {
      return 'لو يعلم الناس ما في الصلاة في الظلمة لأتوها ولو حبواً';
    }
    return 'الصلوات الخمس كفارة لما بينهن';
  }
}

// ─── Painters ──────────────────────────────────────────────────────────────

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

// ─── Subtask 3.2: Enhanced _MosqueSilhouettePainter ──────────────────────────

class _MosqueSilhouettePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final double opacity;

  _MosqueSilhouettePainter({
    required this.color,
    required this.accentColor,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Main body (dome + minarets) ──────────────────────────────────────────
    final bodyPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      // Right minaret body
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

    canvas.drawPath(path, bodyPaint);

    // ── Arched windows along dome base ───────────────────────────────────────
    // Cut out 4 small arched openings evenly spaced across the dome base
    final windowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    const windowCount = 4;
    final windowWidth = w * 0.055;
    final windowHeight = h * 0.08;
    final baselineY = h * 0.52; // just above the dome base edge
    final startX = w * 0.32;
    final gap = (w * 0.36) / (windowCount - 1);

    for (int i = 0; i < windowCount; i++) {
      final cx = startX + i * gap;
      final top = baselineY - windowHeight;
      final rect = Rect.fromLTWH(
        cx - windowWidth / 2,
        top,
        windowWidth,
        windowHeight,
      );
      final windowPath = Path()
        // flat bottom
        ..moveTo(cx - windowWidth / 2, baselineY)
        ..lineTo(cx + windowWidth / 2, baselineY)
        ..lineTo(cx + windowWidth / 2, top + windowHeight * 0.45)
        // arched top
        ..arcToPoint(
          Offset(cx - windowWidth / 2, top + windowHeight * 0.45),
          radius: Radius.elliptical(windowWidth / 2, windowHeight * 0.55),
          clockwise: false,
        )
        ..close();
      canvas.drawPath(windowPath, windowPaint);
      // prevent unused variable warning
      rect.toString();
    }

    // ── Crescent finials on minaret tips ─────────────────────────────────────
    final crescentPaint = Paint()
      ..color = accentColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Left minaret crescent (tip at w*0.06, h*0.05)
    _drawCrescent(canvas, crescentPaint, Offset(w * 0.06, h * 0.04), h * 0.025);
    // Right minaret crescent (tip at w-w*0.06, h*0.05)
    _drawCrescent(canvas, crescentPaint, Offset(w - w * 0.06, h * 0.04), h * 0.025);
  }

  /// Draws a small crescent moon centred at [centre] with outer radius [r].
  void _drawCrescent(Canvas canvas, Paint paint, Offset centre, double r) {
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: r));

    // Offset inner circle to create the crescent cutout shape
    final innerOffset = Offset(centre.dx + r * 0.35, centre.dy);
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerOffset, radius: r * 0.75));

    final crescent = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );
    canvas.drawPath(crescent, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_MosqueSilhouettePainter old) =>
      old.color != color ||
      old.accentColor != accentColor ||
      old.opacity != opacity;
}

// ─── Subtask 3.3: Islamic geometric pattern overlay ──────────────────────────

class _IslamicGeometricPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _IslamicGeometricPainter({
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const tileSize = 60.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * tileSize + tileSize / 2;
        final cy = row * tileSize + tileSize / 2;
        _drawEightPointedStar(canvas, paint, Offset(cx, cy), tileSize * 0.38);
      }
    }
  }

  /// Draws an eight-pointed star centred at [centre] with outer radius [r]
  /// by overlaying two squares — one axis-aligned and one rotated 45°.
  void _drawEightPointedStar(Canvas canvas, Paint paint, Offset centre, double r) {
    // Square 1: axis-aligned
    final sq1 = Path();
    final half = r;
    sq1.addRect(Rect.fromCenter(center: centre, width: half * 2, height: half * 2));

    // Square 2: rotated 45°
    final sq2 = Path();
    final pts = <Offset>[
      Offset(centre.dx, centre.dy - r),
      Offset(centre.dx + r, centre.dy),
      Offset(centre.dx, centre.dy + r),
      Offset(centre.dx - r, centre.dy),
    ];
    sq2.moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      sq2.lineTo(p.dx, p.dy);
    }
    sq2.close();

    canvas.drawPath(sq1, paint);
    canvas.drawPath(sq2, paint);
  }

  @override
  bool shouldRepaint(_IslamicGeometricPainter old) =>
      old.color != color || old.opacity != opacity;
}
