import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';

import '../../providers/adhkar_providers.dart';
import 'package:takwa/features/duas/data/duas_data.dart';
import 'package:takwa/l10n/app_localizations.dart';

// This overlay runs in the separate isolate spawned for the system overlay
// window (see main.dart's overlayMain()), so a fixed-locale lookup is used
// here rather than trying to follow the main isolate's live app locale —
// same rationale as overlay_background_service.dart.
final AppLocalizations _l10n = lookupAppLocalizations(const Locale('ar'));

class _IGold {
  // static const deep = Color(0xFF0B0F1C); // خلفية عميقة
  // static const card = Color(0xFF111827); // بطاقة
  // static const border = Color(0xFF12192E); // حدود داخلية
  static const gold1 = Color(0xFFF0C040); // ذهبي فاتح
  static const gold2 = Color(0xFFC8960C); // ذهبي وسط
  static const gold3 = Color(0xFF7A5500); // ذهبي غامق
  static const teal = Color(0xFF3ABFA8); // فيروزي
  static const white80 = Color(0xCCF5F0E8); // أبيض دافئ
  static const white50 = Color(0x80F5F0E8);
  // static const white30 = Color(0x4DF5F0E8);
  // static const glow = Color(0x33F0C040); // هالة ذهبية
}

class _PopupItem {
  final String arabic;
  final String? meaning;
  final String? fadl;
  final String? source;
  final String emoji;
  final String categoryName;
  final bool isDua;

  const _PopupItem({
    required this.arabic,
    required this.emoji,
    required this.categoryName,
    required this.isDua,
    this.meaning,
    this.fadl,
    this.source,
  });
}

List<_PopupItem> _buildAllItems() {
  final items = <_PopupItem>[];

  final catNames = {
    AdhkarCategory.morning: ('🌅', _l10n.overlayAdhkarMorning),
    AdhkarCategory.evening: ('🌆', _l10n.overlayAdhkarEvening),
    AdhkarCategory.afterPrayer: ('🕌', _l10n.overlayAdhkarAfterPrayer),
    AdhkarCategory.sleep: ('🌙', _l10n.overlayAdhkarSleep),
    AdhkarCategory.misc: ('📿', _l10n.overlayAdhkarMisc),
    AdhkarCategory.wakingUp: ('📿', _l10n.overlayAdhkarWakingUp),
    AdhkarCategory.food: ('📿', _l10n.overlayAdhkarFood),
  };

  for (final entry in kAdhkarData.entries) {
    final meta = catNames[entry.key]!;
    for (final d in entry.value) {
      items.add(
        _PopupItem(
          arabic: d.arabic,
          fadl: d.fadl,
          source: d.source,
          emoji: meta.$1,
          categoryName: meta.$2,
          isDua: false,
        ),
      );
    }
  }

  final duaCatNames = {
    DuaCategory.morning: ('🌅', _l10n.overlayDuaMorning),
    DuaCategory.distress: ('🌊', _l10n.overlayDuaDistress),
    DuaCategory.guidance: ('🌟', _l10n.overlayDuaGuidance),
    DuaCategory.forgiveness: ('🌿', _l10n.overlayDuaForgiveness),
    DuaCategory.rizq: ('🌾', _l10n.overlayDuaRizq),
    DuaCategory.health: ('🫀', _l10n.overlayDuaHealth),
    DuaCategory.parents: ('❤️', _l10n.overlayDuaParents),
    DuaCategory.travel: ('✈️', _l10n.overlayDuaTravel),
    DuaCategory.rain: ('🌧️', _l10n.overlayDuaRain),
    DuaCategory.general: ('🤲', _l10n.overlayDuaGeneral),
  };
  for (final entry in kDuasData.entries) {
    final meta = duaCatNames[entry.key];
    if (meta == null) continue;
    for (final d in entry.value) {
      items.add(
        _PopupItem(
          arabic: d.arabic,
          meaning: d.meaning,
          source: d.source,
          emoji: d.emoji,
          categoryName: meta.$2,
          isDua: true,
        ),
      );
    }
  }
  return items;
}

class _IslamicPatternPainter extends CustomPainter {
  final double opacity;
  const _IslamicPatternPainter({this.opacity = 0.07});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _IGold.gold1.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const step = 28.0;
    // نجمة إسلامية ثمانية الأضلاع مكررة
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawStar8(canvas, Offset(x, y), step * 0.42, paint);
      }
    }
    // خطوط الشبكة الهندسية
    final gridPaint = Paint()
      ..color = _IGold.gold1.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawStar8(Canvas canvas, Offset center, double r, Paint paint) {
    const sides = 8;
    const innerRatio = 0.38;
    final path = Path();
    for (int i = 0; i < sides * 2; i++) {
      final angle = (i * math.pi / sides) - math.pi / 2;
      final radius = i.isEven ? r : r * innerRatio;
      final pt = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_IslamicPatternPainter old) => old.opacity != opacity;
}

class _CornerOrnamentPainter extends CustomPainter {
  const _CornerOrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [_IGold.gold1, _IGold.gold2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const len = 18.0;
    const r = 6.0;

    // ── أعلى يمين ──
    canvas.drawLine(
      Offset(size.width - len, 0),
      Offset(size.width - r, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, r), Offset(size.width, len), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );

    // ── أعلى يسار ──
    canvas.drawLine(const Offset(len, 0), const Offset(r, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, len), paint);
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, r * 2, r * 2),
      math.pi,
      math.pi / 2,
      false,
      paint,
    );

    // ── أسفل يمين ──
    canvas.drawLine(
      Offset(size.width - len, size.height),
      Offset(size.width - r, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - r),
      Offset(size.width, size.height - len),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
      0,
      math.pi / 2,
      false,
      paint,
    );

    // ── أسفل يسار ──
    canvas.drawLine(Offset(len, size.height), Offset(r, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height - r),
      Offset(0, size.height - len),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
      math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _IGold.gold2, Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '✦',
            style: TextStyle(
              color: _IGold.gold1.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _IGold.gold2, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldProgressBar extends StatefulWidget {
  final Duration duration;
  final Key barKey;
  const _GoldProgressBar({required this.duration, required this.barKey})
    : super(key: barKey);
  @override
  State<_GoldProgressBar> createState() => _GoldProgressBarState();
}

class _GoldProgressBarState extends State<_GoldProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion. The actual progress is the TweenAnimationBuilder
    // below, driven by widget.duration — this is a decorative sheen
    // layered on top of it, so gating it loses no information.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shimmer.repeatUnlessReducedMotion(context);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: widget.barKey,
      tween: Tween(begin: 1.0, end: 0.0),
      duration: widget.duration,
      builder: (ctx, value, _) {
        return AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) {
            return Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [_IGold.gold3, _IGold.gold1, _IGold.gold3],
                  stops: [
                    (_shimmer.value - 0.3).clamp(0.0, 1.0),
                    _shimmer.value.clamp(0.0, 1.0),
                    (_shimmer.value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_IGold.gold3, _IGold.gold1],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UnifiedOverlayWindow extends StatefulWidget {
  const UnifiedOverlayWindow({super.key});
  @override
  State<UnifiedOverlayWindow> createState() => _UnifiedOverlayWindowState();
}

class _UnifiedOverlayWindowState extends State<UnifiedOverlayWindow>
    with TickerProviderStateMixin {
  final _allItems = _buildAllItems();
  final _random = math.Random();
  _PopupItem? _current;
  Timer? _autoRefreshTimer;
  Timer? _closeTimer;
  String? _filter;
  final Duration _displayDuration = const Duration(seconds: 15);

  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // ── Slide Animation ──
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1.6, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideCtrl,
            curve: Curves.elasticOut,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);

    // ── Glow Pulse ──
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _pickRandom();
    _slideCtrl.forward();

    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _pickRandom(animate: true);
    });
    _startCloseTimer();

    FlutterOverlayWindow.overlayListener.listen((data) {
      // OverlayBackgroundService._checkAndTriggerAdhan used to also pop a
      // 'type: prayer' card here on this same system overlay — a second,
      // separate popup for "prayer time reached" with no audio and no
      // flip-to-silence of its own, competing with the real Adhan screen.
      // Removed: the real AdhanOverlayScreen (sound + flip-to-silence) is
      // now the only surface for prayer time, opened directly via
      // sendDataToMain when the app is alive, and via the already-scheduled
      // full-screen-intent notification when it isn't. This overlay is
      // back to only ever showing the routine adhkar/dua popups below.
      if (data is Map && data.containsKey('type')) {
        setState(() {
          _filter = data['type'];
        });
        _pickRandom(animate: true);
      } else if (data is int && data >= 0 && data < _allItems.length) {
        setState(() {
          _current = _allItems[data];
        });
        _slideCtrl.forward(from: 0);
        _startCloseTimer();
      } else {
        _pickRandom(animate: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative glow pulse — respects reduce-motion.
    _glowCtrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(_displayDuration, () {
      if (mounted) _closeOverlay();
    });
  }

  void _closeOverlay() {
    _slideCtrl.reverse().then((_) {
      FlutterOverlayWindow.closeOverlay();
    });
  }

  void _pickRandom({bool animate = false}) {
    if (_allItems.isEmpty) return;
    List<_PopupItem> pool = _allItems;
    if (_filter == 'adhkar') {
      pool = _allItems.where((i) => !i.isDua).toList();
    } else if (_filter == 'dua') {
      pool = _allItems.where((i) => i.isDua).toList();
    }
    if (pool.isEmpty) pool = _allItems;

    final next = pool[_random.nextInt(pool.length)];
    if (animate) {
      _slideCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _current = next);
        _slideCtrl.forward();
        _startCloseTimer();
      });
    } else {
      setState(() => _current = next);
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _closeTimer?.cancel();
    _slideCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_current == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // ── Dismiss Area ──
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),

            // ── Card: center right ──
            Positioned(
              top: 220,
              left: 12,
              right: 12,
              child: Padding(
                padding: const EdgeInsets.only(right: 10, left: 30),
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: GestureDetector(onTap: () {}, child: _buildCard()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  CARD
  // ═══════════════════════════════════════
  Widget _buildCard() {
    final item = _current!;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // ── Multi-layer glow ──
          boxShadow: [
            BoxShadow(
              color: _IGold.gold2.withValues(alpha: _glowAnim.value * 0.2),
              blurRadius: 15,
              spreadRadius: 0.5,
              offset: const Offset(-3, 0),
            ),
            BoxShadow(
              color: _IGold.gold1.withValues(alpha: _glowAnim.value * 0.05),
              blurRadius: 25,
              spreadRadius: 1,
              offset: const Offset(-6, 0),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(2, 6),
            ),
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF141C2E), // أزرق داكن عميق
                Color(0xFF0D1220), // أعمق
                Color(0xFF0A0F1A), // أسود إسلامي
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Islamic Pattern Background ──
              const Positioned.fill(
                child: CustomPaint(
                  painter: _IslamicPatternPainter(opacity: 0.055),
                ),
              ),

              // ── Top gold gradient wash ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _IGold.gold3.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Outer gold border ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _IGold.gold2.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
              ),

              // ── Inner thin border ──
              Positioned(
                top: 3,
                left: 3,
                right: 3,
                bottom: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _IGold.gold1.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                ),
              ),

              // ── Corner ornaments ──
              const Positioned.fill(
                child: CustomPaint(painter: _CornerOrnamentPainter()),
              ),

              // ── Shimmer progress bar at bottom ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  child: _GoldProgressBar(
                    duration: _displayDuration,
                    barKey: ValueKey('progress_${item.arabic.hashCode}'),
                  ),
                ),
              ),

              // ── Main Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(item),
                    const SizedBox(height: 10),
                    const _GoldDivider(),
                    const SizedBox(height: AppSpacing.md),
                    _buildArabicText(item),
                    if (item.source != null || item.fadl != null) ...[
                      const SizedBox(height: 10),
                      const _GoldDivider(),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSource(item),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  //  HEADER ROW
  // ─────────────────────────────
  Widget _buildHeader(_PopupItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emoji في دائرة ذهبية
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF2A1F00), Color(0xFF0D1220)],
            ),
            border: Border.all(
              color: _IGold.gold2.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _IGold.gold2.withValues(alpha: 0.15),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(item.emoji, style: const TextStyle(fontSize: 19)),
        ),

        const SizedBox(width: 10),

        // اسم التصنيف
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_IGold.gold1, _IGold.gold2, _IGold.gold1],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
                  item.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white, // يُطغى عليه بـ ShaderMask
                    height: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    item.isDua ? _l10n.overlayTypeDua : _l10n.overlayTypeDhikr,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 10,
                      color: _IGold.teal.withValues(alpha: 0.85),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    '•',
                    style: TextStyle(color: _IGold.gold3, fontSize: 8),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _l10n.overlayTapOutsideToClose,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 10,
                      color: _IGold.white50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // زر الإغلاق الذهبي
        TakwaTappable(
          onTap: _closeOverlay,
          // Inline in the header row alongside the category name.
          minTapSize: null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _IGold.gold3.withValues(alpha: 0.25),
              border: Border.all(
                color: _IGold.gold2.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.close_rounded,
              color: _IGold.gold1.withValues(alpha: 0.8),
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────
  //  ARABIC TEXT
  // ─────────────────────────────
  Widget _buildArabicText(_PopupItem item) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 210),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // زخرفة بسملة صغيرة
              Text(
                '﷽',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  color: _IGold.gold2.withValues(alpha: 0.55),
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.arabic,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 21,
                  color: _IGold.white80,
                  height: 1.85,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  //  SOURCE BADGE
  // ─────────────────────────────
  Widget _buildSource(_PopupItem item) {
    final text = item.source ?? item.fadl ?? '';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: LinearGradient(
            colors: [
              _IGold.gold3.withValues(alpha: 0.3),
              _IGold.gold3.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(color: _IGold.gold2.withValues(alpha: 0.35), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, color: _IGold.gold2, size: 12),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 11,
                  color: _IGold.gold1.withValues(alpha: 0.85),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
