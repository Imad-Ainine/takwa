import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/notifications/location_prayer_update.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/core/utils/prayer_display.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'package:takwa/features/settings/presentation/widgets/location_picker_sheet.dart';

// ─────────────────────────────────────────
//  IQAMA OFFSETS (minutes after adhan)
// ─────────────────────────────────────────
const Map<String, int> _kIqamaOffsets = {
  'fajr': 20,
  'dhuhr': 15,
  'asr': 15,
  'maghrib': 5,
  'isha': 15,
};

// ─────────────────────────────────────────
//  PRAYER VISUAL DATA
// ─────────────────────────────────────────
class _PrayerVisual {
  final String key, emoji;
  final Color primaryColor, secondaryColor;
  final String skyPhase; // dawn/morning/noon/afternoon/sunset/night
  const _PrayerVisual({
    required this.key,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.skyPhase,
  });
}

const _kPrayerVisuals = {
  'fajr': _PrayerVisual(
    key: 'fajr',
    emoji: '🌙',
    primaryColor: Color(0xFF4A5568),
    secondaryColor: Color(0xFF7B8FA6),
    skyPhase: 'dawn',
  ),
  'sunrise': _PrayerVisual(
    key: 'sunrise',
    emoji: '🌅',
    primaryColor: Color(0xFFE8945A),
    secondaryColor: Color(0xFFF6AD55),
    skyPhase: 'morning',
  ),
  'dhuhr': _PrayerVisual(
    key: 'dhuhr',
    emoji: '☀️',
    primaryColor: Color(0xFF1A6B8A),
    secondaryColor: Color(0xFF2E9CC4),
    skyPhase: 'noon',
  ),
  'asr': _PrayerVisual(
    key: 'asr',
    emoji: '🌤',
    primaryColor: Color(0xFF8B5E3C),
    secondaryColor: Color(0xFFE8945A),
    skyPhase: 'afternoon',
  ),
  'maghrib': _PrayerVisual(
    key: 'maghrib',
    emoji: '🌆',
    primaryColor: Color(0xFF7B3F6E),
    secondaryColor: Color(0xFFE87B5A),
    skyPhase: 'sunset',
  ),
  'isha': _PrayerVisual(
    key: 'isha',
    emoji: '🌃',
    primaryColor: Color(0xFF0D1117),
    secondaryColor: Color(0xFF1A2332),
    skyPhase: 'night',
  ),
};

// ─────────────────────────────────────────
//  STATE MODEL
// ─────────────────────────────────────────
class PrayerScreenState {
  final List<PrayerTimeInfo> prayers;
  final PrayerTimeInfo? next;
  final Duration? remaining;
  final DateTime? iqamaTime;
  final Duration? remainingIqama;
  final bool isIqamaPhase;
  final String cityName;
  final bool loading;
  final bool isUpdatingLocation;
  final String? error;

  const PrayerScreenState({
    this.prayers = const [],
    this.next,
    this.remaining,
    this.iqamaTime,
    this.remainingIqama,
    this.isIqamaPhase = false,
    this.cityName = '',
    this.loading = true,
    this.isUpdatingLocation = false,
    this.error,
  });

  PrayerScreenState copyWith({
    List<PrayerTimeInfo>? prayers,
    PrayerTimeInfo? next,
    Duration? remaining,
    DateTime? iqamaTime,
    Duration? remainingIqama,
    bool? isIqamaPhase,
    String? cityName,
    bool? loading,
    bool? isUpdatingLocation,
    String? error,
  }) => PrayerScreenState(
    prayers: prayers ?? this.prayers,
    next: next ?? this.next,
    remaining: remaining ?? this.remaining,
    iqamaTime: iqamaTime ?? this.iqamaTime,
    remainingIqama: remainingIqama ?? this.remainingIqama,
    isIqamaPhase: isIqamaPhase ?? this.isIqamaPhase,
    cityName: cityName ?? this.cityName,
    loading: loading ?? this.loading,
    isUpdatingLocation: isUpdatingLocation ?? this.isUpdatingLocation,
    error: error,
  );
}

// ─────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────
class PrayerNotifier extends StateNotifier<PrayerScreenState> {
  PrayerNotifier(this._ref) : super(const PrayerScreenState()) {
    _init();
  }

  final Ref _ref;
  Timer? _ticker;

  Future<void> _init() async {
    _listenToPrayers();
    state = state.copyWith(loading: true);
    try {
      final settings = _ref.read(settingsDaoProvider);

      // جلب الموقع المحفوظ أو تحديثه
      final unknownCity = lookupAppLocalizations(
        const Locale('ar'),
      ).overlayServiceUnknownCity;
      final savedLat = await settings.get('latitude');
      final savedLng = await settings.get('longitude');
      String city = await settings.get('cityName') ?? unknownCity;

      if (savedLat == null || savedLng == null || city == unknownCity) {
        final result = await LocationPrayerManager.refreshLocation(_ref);
        if (result == LocationResult.success) {
          city = await settings.get('cityName') ?? city;
        }
        // If refresh failed but we already have cached coordinates, keep
        // going with what's stored — prayerTimesProvider will use them.
        // Only surface an error if we have *nothing* at all.
        if (!result.isSuccess && savedLat == null && savedLng == null) {
          // No cached coords and no fresh fix — still try the provider
          // (it falls back to a default location) but mark as recoverable.
          // Do NOT call state.copyWith(error: ...) here because the full
          // _ErrorView obscures the entire screen; a SnackBar from
          // requestAndUpdateLocation is enough user feedback.
        }
      }

      // حساب أوقات الصلاة باستخدام الـ provider لإبقاء البيانات متزامنة
      final prayers = await _ref.read(prayerTimesProvider.future);

      state = state.copyWith(
        prayers: prayers,
        cityName: city,
        loading: false,
        error: null, // clear any previous error so the screen shows content
      );

      _startTicker();
    } catch (e) {
      // Only show _ErrorView for a hard failure that prevented prayer times
      // from loading at all (e.g., database initialisation error).
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _listenToPrayers() {
    _ref.listen<AsyncValue<List<PrayerTimeInfo>>>(prayerTimesProvider, (
      prev,
      next,
    ) {
      next.whenData((prayers) {
        state = state.copyWith(prayers: prayers);
        _tick(); // تحديث فوري للحسابات عند تغير الأوقات
      });
    }, fireImmediately: false);

    // Also listen to cityName changes in the DAO so that background-service
    // location updates (which write to SettingsDao via _syncLocationFromBackground
    // in main.dart) are reflected in the header without a full screen rebuild.
    _ref.listen<AsyncValue<String?>>(settingStreamProvider('cityName'), (
      prev,
      next,
    ) {
      final city = next.valueOrNull;
      if (city != null && city.isNotEmpty && city != state.cityName) {
        state = state.copyWith(cityName: city);
      }
    }, fireImmediately: false);
  }

  Future<void> refresh({BuildContext? context}) async {
    if (context != null && context.mounted) {
      state = state.copyWith(isUpdatingLocation: true);
      try {
        final result = await LocationPrayerManager.requestAndUpdateLocation(
          context,
          _ref,
        );
        if (result.isSuccess) {
          final settings = _ref.read(settingsDaoProvider);
          final city = await settings.get('cityName') ?? state.cityName;
          _ref.invalidate(prayerTimesProvider);
          final prayers = await _ref.read(prayerTimesProvider.future);
          state = state.copyWith(
            prayers: prayers,
            cityName: city,
            isUpdatingLocation: false,
            error: null,
          );
          _tick();
        } else {
          // requestAndUpdateLocation already showed a coloured SnackBar with
          // the specific failure reason and a "Retry" action. Just reset the
          // spinner and clear any full-screen error that was showing so the
          // user can see the (possibly stale) prayer times while they retry.
          state = state.copyWith(isUpdatingLocation: false, error: null);
        }
      } catch (e) {
        state = state.copyWith(isUpdatingLocation: false, error: null);
      }
    } else {
      state = state.copyWith(loading: true);
      await LocationPrayerManager.refreshLocation(_ref);
      await _init();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    if (state.prayers.isEmpty) return;
    final now = DateTime.now();
    final next = PrayerTimesService.nextPrayer(state.prayers);
    if (next == null) return;

    final iqamaOffset = _kIqamaOffsets[next.name] ?? 15;
    final iqamaTime = next.time.add(Duration(minutes: iqamaOffset));
    final isIqamaPhase = now.isAfter(next.time) && now.isBefore(iqamaTime);

    final remaining = isIqamaPhase
        ? iqamaTime.difference(now)
        : next.time.difference(now);

    state = state.copyWith(
      next: next,
      remaining: remaining,
      iqamaTime: iqamaTime,
      remainingIqama: iqamaTime.difference(now),
      isIqamaPhase: isIqamaPhase,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final prayerScreenProvider =
    StateNotifierProvider<PrayerNotifier, PrayerScreenState>(
      (ref) => PrayerNotifier(ref),
    );

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _skyCtrl; // تغيير لون السماء
  late final AnimationController _pulseCtrl; // نبض الدائرة
  late final AnimationController _entryCtrl; // دخول العناصر

  late Animation<double> _pulse;

  String _lastPrayerKey = '';

  @override
  void initState() {
    super.initState();

    _skyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
    _pulse = Tween<double>(
      begin: 0.85,
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
    _skyCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _animateSkyIfNeeded(String prayerKey) {
    if (prayerKey != _lastPrayerKey) {
      _lastPrayerKey = prayerKey;
      _skyCtrl.forward(from: 0);
      _entryCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerScreenProvider);

    final style = AdaptiveStyle(
      context,
      ref.watch(ramadanModeProvider).value ?? false,
    );
    final prayerKey = state.next?.name ?? 'isha';
    final visual = _kPrayerVisuals[prayerKey]!;
    _animateSkyIfNeeded(prayerKey);

    return Scaffold(
      backgroundColor: style.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    style.bg.withValues(alpha: 0.3),
                    style.bg.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          // ── Floating Particles ──
          Positioned.fill(child: _FloatingParticles(visual: visual)),

          // ── Content ──
          state.loading
              ? _LoadingOverlay(style: style)
              : state.error != null
              ? _ErrorView(
                  onRetry: () => ref
                      .read(prayerScreenProvider.notifier)
                      .refresh(context: context),
                )
              : _buildContent(context, state, visual, style),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PrayerScreenState state,
    _PrayerVisual visual,
    AdaptiveStyle style,
  ) {
    return SafeArea(
      child: Column(
        children: [
          // ── Prayer Header ──
          _PrayerHeader(
            cityName: state.cityName,
            onRefresh: () => ref
                .read(prayerScreenProvider.notifier)
                .refresh(context: context),
            isUpdating: state.isUpdatingLocation,
            entryCtrl: _entryCtrl,
            style: style,
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // ── ساعة حية ──
                  _LiveClockBanner(style: style, entryCtrl: _entryCtrl),
                  const SizedBox(height: AppSpacing.md),

                  // ── البطاقة الرئيسية ──
                  _MainPrayerCard(
                    state: state,
                    visual: visual,
                    pulseAnim: _pulse,
                    entryCtrl: _entryCtrl,
                    style: style,
                  ),
                  const SizedBox(height: 14),

                  // ── مراحل الشمس ──
                  _SunPhaseRow(prayers: state.prayers, style: style),
                  const SizedBox(height: AppSpacing.lg),

                  // ── جدول الصلوات اليومي ──
                  _DailyPrayersTable(
                    prayers: state.prayers,
                    currentKey: state.next?.name ?? '',
                    iqamaOffsets: _kIqamaOffsets,
                    entryCtrl: _entryCtrl,
                    style: style,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MosqueClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h);
    path.lineTo(0, h * 0.4);

    path.quadraticBezierTo(w * 0.05, h * 0.35, w * 0.15, h * 0.35);
    path.lineTo(w * 0.25, h * 0.35);
    path.quadraticBezierTo(w * 0.3, h * 0.15, w * 0.35, h * 0.15);

    path.lineTo(w * 0.4, h * 0.15);
    path.quadraticBezierTo(w * 0.5, 0, w * 0.6, h * 0.15);
    path.lineTo(w * 0.65, h * 0.15);

    path.quadraticBezierTo(w * 0.7, h * 0.15, w * 0.75, h * 0.35);
    path.lineTo(w * 0.85, h * 0.35);

    path.quadraticBezierTo(w * 0.95, h * 0.35, w, h * 0.4);

    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _FloatingParticles extends StatefulWidget {
  final _PrayerVisual visual;
  const _FloatingParticles({required this.visual});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static final _rng = math.Random(99);
  static final _particles = List.generate(
    18,
    (i) => _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      size: 1.0 + _rng.nextDouble() * 2.5,
      speed: 0.0002 + _rng.nextDouble() * 0.0004,
      phase: _rng.nextDouble() * 2 * math.pi,
    ),
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative floating particles — respects reduce-motion.
    _ctrl.repeatUnlessReducedMotion(context);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          t: _ctrl.value,
          color: widget.visual.secondaryColor,
        ),
        // We remove size: Size.infinite because it causes offsets to be Infinity.
        // Being inside a Positioned.fill already provides the correct layout constraints.
        size: Size.copy(MediaQuery.sizeOf(context)),
      ),
    );
  }
}

class _Particle {
  final double x, y, size, speed, phase;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final p in particles) {
      final dx = math.sin(t * 2 * math.pi + p.phase) * 20;
      final dy = -(t * size.height * 0.3 + p.y * size.height) % size.height;
      final opacity = (0.1 + 0.15 * math.sin(t * 2 * math.pi + p.phase + 1))
          .clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(p.x * size.width + dx, dy),
        p.size,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _PrayerHeader extends StatelessWidget {
  final String cityName;
  final VoidCallback onRefresh;
  final bool isUpdating;
  final AnimationController entryCtrl;
  final AdaptiveStyle style;

  const _PrayerHeader({
    required this.cityName,
    required this.onRefresh,
    this.isUpdating = false,
    required this.entryCtrl,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: entryCtrl, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: entryCtrl,
        child: ClipPath(
          clipper: HeaderCurveClipper(),
          child: Container(
            height: 90, // Increased slightly from 60 to accommodate the curve
            width: double.infinity,
            color: style.bg,
            child: Stack(
              children: [
                // ── Mosque Silhouette Background ──
                Positioned.fill(
                  child: ClipPath(
                    clipper: MosqueClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            style.gold.withValues(alpha: 0.3),
                            style.gold.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: const Opacity(
                        opacity: 0.1,
                        child: CustomPatternBackground(
                          pattern: BackgroundPattern.adhkar,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Top Bar Content (Positioned) ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const CustomLeadingButton(),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.prayerScreenTitle,
                                style: style.amiri(26, color: style.gold),
                              ),
                              TakwaTappable(
                                onTap: () => LocationPickerSheet.show(context),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 12,
                                        color: style.gold,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        cityName,
                                        style: style.naskh(
                                          12,
                                          color: style.textDim,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TakwaTappable(
                          onTap: isUpdating ? null : onRefresh,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: style.card.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: style.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isUpdating
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: TakwaLoadingIndicator(
                                        color: style.gold,
                                        strokeWidth: 2,
                                        size: 18,
                                      ),
                                    )
                                  : Icon(
                                      Icons.refresh_rounded,
                                      size: 20,
                                      color: style.gold,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  HEADER CURVE CLIPPER
// ─────────────────────────────────────────
class HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 15);
    final controlPoint = Offset(size.width / 2, size.height);
    final endPoint = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MainPrayerCard extends StatelessWidget {
  final PrayerScreenState state;
  final _PrayerVisual visual;
  final Animation<double> pulseAnim;
  final AnimationController entryCtrl;
  final AdaptiveStyle style;

  const _MainPrayerCard({
    required this.state,
    required this.visual,
    required this.pulseAnim,
    required this.entryCtrl,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final next = state.next;
    if (next == null) return const SizedBox();

    final remaining = state.remaining ?? Duration.zero;
    final iqamaTime = state.iqamaTime;
    final isIqama = state.isIqamaPhase;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: entryCtrl,
        curve: const Interval(0.1, 0.7),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: entryCtrl,
                curve: const Interval(0.6, 1, curve: Curves.decelerate),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: style.bg),
              boxShadow: [
                BoxShadow(
                  color: style.bg.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Prayer Name Badge ──
                _PrayerNameBadge(
                  visual: visual,
                  isIqama: isIqama,
                  style: style,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Countdown Ring ──
                _CountdownRing(
                  remaining: remaining,
                  visual: visual,
                  isIqama: isIqama,
                  pulseAnim: pulseAnim,
                  style: style,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Adhan & Iqama Info ──
                _AdhanIqamaRow(
                  adhanTime: next.time,
                  iqamaTime: iqamaTime,
                  iqamaOffset: _kIqamaOffsets[next.name] ?? 15,
                  isIqamaPhase: isIqama,
                  style: style,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── شارة اسم الصلاة ──
class _PrayerNameBadge extends StatelessWidget {
  final _PrayerVisual visual;
  final bool isIqama;
  final AdaptiveStyle style;

  const _PrayerNameBadge({
    required this.visual,
    required this.isIqama,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = prayerLocalizedName(l10n, visual.key);
    return Column(
      children: [
        ScaleTransition(
          scale: const AlwaysStoppedAnimation(1.1),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.gold.withValues(alpha: 0.1),
              border: Border.all(color: style.gold.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: style.gold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(visual.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isIqama
              ? l10n.prayerScreenIqamaTimeFor(name)
              : l10n.prayerScreenPrayerFor(name),
          style: style.amiri(28, color: style.text, weight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isIqama
              ? l10n.prayerScreenEstablishPrayer
              : l10n.prayerScreenNextPrayerLabel,
          style: style.naskh(13, color: style.textDim),
        ),
      ],
    );
  }
}

// ── دائرة العداد المتناقص ──
class _CountdownRing extends StatelessWidget {
  final Duration remaining;
  final _PrayerVisual visual;
  final bool isIqama;
  final Animation<double> pulseAnim;
  final AdaptiveStyle style;

  const _CountdownRing({
    required this.remaining,
    required this.visual,
    required this.isIqama,
    required this.pulseAnim,
    required this.style,
  });

  String get _timeStr {
    if (remaining.isNegative) return '00:00:00';
    final h = remaining.inHours;
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  double get _progress {
    // نسبة الوقت المتبقي من الوقت الكامل بين صلاتين (~4-6 ساعات)
    final maxSecs = isIqama ? 1200.0 : 21600.0; // 20 دقيقة أو 6 ساعات
    return (remaining.inSeconds / maxSecs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaleTransition(
      scale: pulseAnim,
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // حلقات خارجية (halo)
            ...List.generate(
              3,
              (i) => Container(
                width: 220 - i * 28.0,
                height: 220 - i * 28.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: visual.secondaryColor.withValues(
                      alpha: 0.06 + i * 0.04,
                    ),
                    width: 1,
                  ),
                ),
              ),
            ),

            // الحلقة الرئيسية
            CustomPaint(
              size: const Size(200, 200),
              painter: _CountdownArcPainter(
                progress: _progress,
                primaryColor: visual.secondaryColor,
                successColor: context.colors.success,
                tealColor: context.colors.teal,
                isIqama: isIqama,
                // The track/end-dot sit on this card's own `style.bg`
                // background (not the fixed-color inner disc below), so —
                // like everything else in this file — a hardcoded white was
                // nearly invisible in light mode.
                onSurfaceColor: style.text,
              ),
            ),

            // المحتوى الداخلي
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    visual.primaryColor.withValues(alpha: 0.8),
                    visual.primaryColor.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(
                  color: visual.secondaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isIqama
                        ? l10n.prayerScreenIqamaCountdownLabel
                        : l10n.prayerScreenAdhanCountdownLabel,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _timeStr,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: remaining.inHours > 0 ? 26 : 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: visual.secondaryColor.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      isIqama
                          ? '🕌 ${l10n.prayerScreenEstablishPrayer}'
                          : '🔔 ${l10n.prayerScreenGetReady}',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownArcPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color successColor;
  final Color tealColor;
  final bool isIqama;
  final Color onSurfaceColor;

  _CountdownArcPainter({
    required this.progress,
    required this.primaryColor,
    required this.successColor,
    required this.tealColor,
    required this.isIqama,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - 14) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Track
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = onSurfaceColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    if (progress <= 0) return;

    // Outer glow
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: isIqama
              ? [successColor, tealColor, successColor]
              : [
                  primaryColor,
                  Colors.white.withValues(alpha: 0.9),
                  primaryColor,
                ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Solid arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: isIqama
              ? [successColor, tealColor, successColor]
              : [primaryColor, Colors.white, primaryColor],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // End dot
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final dx = c.dx + r * math.cos(angle);
    final dy = c.dy + r * math.sin(angle);
    canvas.drawCircle(
      Offset(dx, dy),
      8,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(dx, dy),
      5,
      Paint()..color = isIqama ? successColor : primaryColor,
    );
  }

  @override
  bool shouldRepaint(_CountdownArcPainter old) =>
      old.progress != progress ||
      old.isIqama != isIqama ||
      old.onSurfaceColor != onSurfaceColor;
}

// ── صف الأذان والإقامة ──
class _AdhanIqamaRow extends StatelessWidget {
  final DateTime adhanTime;
  final DateTime? iqamaTime;
  final int iqamaOffset;
  final bool isIqamaPhase;
  final AdaptiveStyle style;

  const _AdhanIqamaRow({
    required this.adhanTime,
    required this.iqamaTime,
    required this.iqamaOffset,
    required this.isIqamaPhase,
    required this.style,
  });

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _TimeCard(
            label: l10n.prayerScreenAdhanTimeLabel,
            time: _fmt(adhanTime),
            icon: '📢',
            color: style.gold,
            isActive: !isIqamaPhase,
            subtitle: l10n.prayerScreenSalvationSlogan,
            style: style,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TimeCard(
            label: l10n.prayerScreenIqamaTimeLabel,
            time: iqamaTime != null
                ? _fmt(iqamaTime!)
                : l10n.prayerScreenIqamaOffsetShort(iqamaOffset),
            icon: '🕌',
            color: context.colors.success,
            isActive: isIqamaPhase,
            subtitle: l10n.prayerScreenIqamaAfterMinutes(iqamaOffset),
            style: style,
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label, time, icon;
  final Color color;
  final bool isActive;
  final String? subtitle;
  final AdaptiveStyle style;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.isActive,
    this.subtitle,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.15)
            : style.text.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : style.text.withValues(alpha: 0.1),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12)]
            : null,
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 10,
              color: style.textSec,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: time.contains(' ') ? time.split(' ').first : time,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isActive ? color : style.text,
                  ),
                ),
                TextSpan(
                  text: time.contains(' ') ? ' ${time.split(' ').last}' : '',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? color.withValues(alpha: 0.85)
                        : style.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 9,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyPrayersTable extends StatelessWidget {
  final List<PrayerTimeInfo> prayers;
  final String currentKey;
  final Map<String, int> iqamaOffsets;
  final AnimationController entryCtrl;
  final AdaptiveStyle style;

  const _DailyPrayersTable({
    required this.prayers,
    required this.currentKey,
    required this.iqamaOffsets,
    required this.entryCtrl,
    required this.style,
  });

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _dateHeaderLabel(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final pattern = code == 'ar' ? 'EEE، d MMM' : 'EEE, d MMM';
    return DateFormat(pattern, code).format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: entryCtrl,
        curve: const Interval(0.4, 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: style.bg),
            boxShadow: [
              BoxShadow(color: style.bg.withValues(alpha: 0.3), blurRadius: 20),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: context.colors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.prayerScreenTodaysPrayers,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colors.gold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.textPrimary.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: context.colors.textPrimary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Text(
                        _dateHeaderLabel(context),
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 10,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: context.colors.textPrimary.withValues(alpha: 0.06),
              ),

              ...prayers.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final isNext = p.name == currentKey;
                final isPast = DateTime.now().isAfter(p.time);
                final iqama = p.time.add(
                  Duration(minutes: _kIqamaOffsets[p.name] ?? 15),
                );

                return _PrayerTableRow(
                  prayer: p,
                  iqamaTime: iqama,
                  isNext: isNext,
                  isPast: isPast,
                  isLast: i == prayers.length - 1,
                  formatTime: _fmt,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerTableRow extends StatelessWidget {
  final PrayerTimeInfo prayer;
  final DateTime iqamaTime;
  final bool isNext, isPast, isLast;
  final String Function(DateTime) formatTime;

  const _PrayerTableRow({
    required this.prayer,
    required this.iqamaTime,
    required this.isNext,
    required this.isPast,
    required this.isLast,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = _kPrayerVisuals[prayer.name]!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isNext
            ? visual.secondaryColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
        border: isNext
            ? BorderDirectional(
                end: BorderSide(color: visual.secondaryColor, width: 3),
              )
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // أيقونة + اسم
                Text(prayer.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayerLocalizedName(l10n, prayer.name),
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 13,
                          color: isNext
                              ? context.colors.textPrimary
                              : isPast
                              ? context.colors.textDim
                              : context.colors.textSecondary,
                          fontWeight: isNext
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (isNext)
                        Text(
                          l10n.prayerScreenAdhanNowBadge,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 9,
                            color: visual.secondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),

                // وقت الأذان
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formatTime(prayer.time),
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 14,
                        color: isNext
                            ? context.colors.textPrimary
                            : isPast
                            ? context.colors.textDim
                            : context.colors.textSecondary,
                        fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    _MihrabPrayerChip(
                      label: prayer.name == 'sunrise'
                          ? l10n.prayerScreenSunriseBadge
                          : l10n.prayerScreenAdhanBadge,
                      color: isNext
                          ? visual.secondaryColor
                          : context.colors.textDim,
                      isActive: isNext,
                    ),
                  ],
                ),

                if (prayer.name != 'sunrise') ...[
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    color: context.colors.textPrimary.withValues(alpha: 0.08),
                  ),

                  // وقت الإقامة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        formatTime(iqamaTime),
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 14,
                          color: isNext
                              ? context.colors.success
                              : isPast
                              ? context.colors.textDim.withValues(alpha: 0.6)
                              : context.colors.textDim,
                          fontWeight: isNext
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      _MihrabPrayerChip(
                        label: l10n.prayerScreenIqamaBadge,
                        color: isNext
                            ? context.colors.success
                            : context.colors.textDim,
                        isActive: isNext,
                      ),
                    ],
                  ),
                ],

                // علامة ✓ للماضي
                if (isPast && !isNext && prayer.name != 'sunrise') ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: context.colors.success.withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ),
          if (!isLast)
            Container(
              height: 1,
              color: context.colors.textPrimary.withValues(alpha: 0.04),
            ),
        ],
      ),
    );
  }
}

// ── شريحة على شكل محراب ──
class _MihrabPrayerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _MihrabPrayerChip({
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.15 : 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.3 : 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 9,
          color: color.withValues(alpha: isActive ? 1.0 : 0.6),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _LiveClockBanner extends StatefulWidget {
  final AdaptiveStyle style;
  final AnimationController entryCtrl;
  const _LiveClockBanner({required this.style, required this.entryCtrl});

  @override
  State<_LiveClockBanner> createState() => _LiveClockBannerState();
}

class _LiveClockBannerState extends State<_LiveClockBanner> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final ampm = _now.hour < 12 ? 'AM' : 'PM';
    final weekday = DateFormat('EEEE', 'ar').format(_now);
    final date = DateFormat('d MMMM yyyy', 'ar').format(_now);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: widget.entryCtrl,
        curve: const Interval(0.0, 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: widget.style.text.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.style.text.withValues(alpha: 0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Clock ──
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$h:$m',
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: widget.style.text,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: ' $ampm',
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: widget.style.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  ':$s',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: widget.style.textDim,
                  ),
                ),
              ),
              const Spacer(),
              // ── Date ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.style.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 11,
                      color: widget.style.textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SUN PHASE ROW
// ─────────────────────────────────────────
class _SunPhaseRow extends StatelessWidget {
  final List<PrayerTimeInfo> prayers;
  final AdaptiveStyle style;
  const _SunPhaseRow({required this.prayers, required this.style});

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    PrayerTimeInfo? fajrP, sunriseP, maghribP;
    for (final p in prayers) {
      if (p.name == 'fajr') fajrP = p;
      if (p.name == 'sunrise') sunriseP = p;
      if (p.name == 'maghrib') maghribP = p;
    }
    if (fajrP == null && sunriseP == null && maghribP == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          if (fajrP != null)
            Expanded(
              child: _SunChip(
                icon: '🌙',
                label: prayerLocalizedName(l10n, 'fajr'),
                time: _fmt(fajrP.time),
                color: const Color(0xFF7B8FA6),
              ),
            ),
          if (fajrP != null && sunriseP != null)
            const SizedBox(width: AppSpacing.sm),
          if (sunriseP != null)
            Expanded(
              child: _SunChip(
                icon: '🌅',
                label: prayerLocalizedName(l10n, 'sunrise'),
                time: _fmt(sunriseP.time),
                color: const Color(0xFFE8945A),
              ),
            ),
          if (sunriseP != null && maghribP != null)
            const SizedBox(width: AppSpacing.sm),
          if (maghribP != null)
            Expanded(
              child: _SunChip(
                icon: '🌆',
                label: prayerLocalizedName(l10n, 'maghrib'),
                time: _fmt(maghribP.time),
                color: const Color(0xFF7B3F6E),
              ),
            ),
        ],
      ),
    );
  }
}

class _SunChip extends StatelessWidget {
  final String icon, label, time;
  final Color color;
  const _SunChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 10,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: time.contains(' ') ? time.split(' ').first : time,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: time.contains(' ') ? ' ${time.split(' ').last}' : '',
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.7),
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

/// Shape-matched skeleton for the prayer screen's loading state — mirrors
/// _MainPrayerCard (badge + countdown ring + adhan/iqama row),
/// _SunPhaseRow (3 chips) and _DailyPrayersTable (header + 5 rows) so the
/// layout doesn't visibly jump once real data arrives. Previously this
/// was a bare spinner + "جارٍ تحديد موقعك..." text — see the audit's
/// "UI/UX Polish" section.
class _LoadingOverlay extends StatefulWidget {
  final AdaptiveStyle style;
  const _LoadingOverlay({required this.style});

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion. The skeleton *shapes* already convey the loading
    // state on their own, so the shimmer pulse on top is decorative.
    _pulse = Tween<double>(
      begin: 0.35,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bone({double? width, required double height, double radius = 12}) {
    final style = widget.style;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: style.gold.withValues(alpha: _pulse.value * 0.12),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: style.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            // ── Header placeholder ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _bone(width: 40, height: 40, radius: 20),
                  const SizedBox(width: AppSpacing.md),
                  _bone(width: 120, height: 16),
                  const Spacer(),
                  _bone(width: 40, height: 40, radius: 20),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Main card placeholder (badge + ring + adhan/iqama row) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    _bone(width: 140, height: 28, radius: 14),
                    const SizedBox(height: AppSpacing.xxxl),
                    Center(child: _bone(width: 200, height: 200, radius: 100)),
                    const SizedBox(height: AppSpacing.xxxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _bone(width: 90, height: 44),
                        _bone(width: 90, height: 44),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Sun phase row placeholder ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: _bone(height: 77, radius: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _bone(height: 77, radius: 18)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _bone(height: 77, radius: 18)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Daily prayers table placeholder ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _bone(width: 3, height: 16, radius: 2),
                        const SizedBox(width: 10),
                        _bone(width: 100, height: 14),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (int i = 0; i < 5; i++) ...[
                      Row(
                        children: [
                          _bone(width: 28, height: 28, radius: 14),
                          const SizedBox(width: AppSpacing.md),
                          _bone(width: 70, height: 14),
                          const Spacer(),
                          _bone(width: 60, height: 14),
                        ],
                      ),
                      if (i < 4) const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.prayerScreenLocationErrorTitle,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.prayerScreenLocationErrorSubtitle,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 12,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 200,
            child: PrimaryButton(
              onTap: () async => onRetry(),
              label: l10n.prayerScreenRetryButton,
            ),
          ),
        ],
      ),
    );
  }
}
