import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const gold1 = Color(0xFFF0C040); // ذهبي فاتح
  static const gold2 = Color(0xFFC8960C); // ذهبي وسط
  static const gold3 = Color(0xFF7A5500); // ذهبي غامق
  static const goldDeep = Color(0xFF5E4000); // برونزي غامق للوضع الفاتح
  static const teal = Color(0xFF3ABFA8); // فيروزي
  static const tealDark = Color(0xFF1B8A78); // فيروزي داكن للوضع الفاتح
  static const white80 = Color(0xCCF5F0E8); // أبيض دافئ
  static const white50 = Color(0x80F5F0E8);
}

class _OverlayPalette {
  final bool isDark;
  final Color bgStart;
  final Color bgMid;
  final Color bgEnd;
  final Color outerBorder;
  final Color innerBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMeaning;
  final Color meaningBg;
  final Color meaningBorder;
  final Color headerTitle;
  final Color badgeBgStart;
  final Color badgeBgEnd;
  final Color btnBg;
  final Color patternColor;
  final List<BoxShadow> shadows;

  const _OverlayPalette({
    required this.isDark,
    required this.bgStart,
    required this.bgMid,
    required this.bgEnd,
    required this.outerBorder,
    required this.innerBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMeaning,
    required this.meaningBg,
    required this.meaningBorder,
    required this.headerTitle,
    required this.badgeBgStart,
    required this.badgeBgEnd,
    required this.btnBg,
    required this.patternColor,
    required this.shadows,
  });

  factory _OverlayPalette.of(BuildContext context) {
    final isDark =
        (MediaQuery.maybePlatformBrightnessOf(context) ??
            Theme.of(context).brightness) ==
        Brightness.dark;

    if (isDark) {
      return _OverlayPalette(
        isDark: true,
        bgStart: const Color(0xFF141C2E),
        bgMid: const Color(0xFF0D1220),
        bgEnd: const Color(0xFF0A0F1A),
        outerBorder: _IGold.gold2.withValues(alpha: 0.5),
        innerBorder: _IGold.gold1.withValues(alpha: 0.08),
        textPrimary: _IGold.white80,
        textSecondary: _IGold.white50,
        textMeaning: const Color(0xFFCBD5E1),
        meaningBg: const Color(0xFF131A2B).withValues(alpha: 0.7),
        meaningBorder: _IGold.gold2.withValues(alpha: 0.2),
        headerTitle: Colors.white,
        badgeBgStart: const Color(0xFF2A1F00),
        badgeBgEnd: const Color(0xFF0D1220),
        btnBg: _IGold.gold3.withValues(alpha: 0.25),
        patternColor: _IGold.gold1,
        shadows: [
          BoxShadow(
            color: _IGold.gold2.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 0.5,
            offset: const Offset(-3, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(2, 8),
          ),
        ],
      );
    } else {
      return _OverlayPalette(
        isDark: false,
        bgStart: const Color(0xFFFFFDF9),
        bgMid: const Color(0xFFFAF5EB),
        bgEnd: const Color(0xFFF3ECE0),
        outerBorder: _IGold.gold2.withValues(alpha: 0.65),
        innerBorder: _IGold.gold2.withValues(alpha: 0.15),
        textPrimary: const Color(0xFF1E2530),
        textSecondary: const Color(0xFF5E6778),
        textMeaning: const Color(0xFF334155),
        meaningBg: const Color(0xFFEDE5D5).withValues(alpha: 0.65),
        meaningBorder: _IGold.gold2.withValues(alpha: 0.35),
        headerTitle: const Color(0xFF2C2416),
        badgeBgStart: const Color(0xFFFFF7DC),
        badgeBgEnd: const Color(0xFFF3E2B8),
        btnBg: _IGold.gold2.withValues(alpha: 0.15),
        patternColor: _IGold.gold2,
        shadows: [
          BoxShadow(
            color: const Color(0xFF8C6D23).withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }
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

/// The popup pool is built straight from the two data files and their category
/// extensions, so a new category is included automatically. It used to be two
/// literal maps keyed by category: the adhkar one read values with `!` (a new
/// category crashed the overlay), and the dua one skipped missing keys (a new
/// category's duas silently never appeared).
List<_PopupItem> _buildAllItems() {
  final items = <_PopupItem>[];

  for (final entry in kAdhkarData.entries) {
    for (final d in entry.value) {
      items.add(
        _PopupItem(
          arabic: d.arabic,
          fadl: d.fadl,
          source: d.source,
          emoji: entry.key.emoji,
          categoryName: entry.key.arabicLabel,
          isDua: false,
        ),
      );
    }
  }

  for (final entry in kDuasData.entries) {
    for (final d in entry.value) {
      items.add(
        _PopupItem(
          arabic: d.arabic,
          meaning: d.meaning,
          source: d.source,
          emoji: d.emoji,
          categoryName: entry.key.arabicLabel,
          isDua: true,
        ),
      );
    }
  }
  return items;
}

class _IslamicPatternPainter extends CustomPainter {
  final double opacity;
  final Color color;
  const _IslamicPatternPainter({
    this.opacity = 0.07,
    this.color = _IGold.gold1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
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
      ..color = color.withValues(alpha: opacity * 0.5)
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
  bool shouldRepaint(_IslamicPatternPainter old) =>
      old.opacity != opacity || old.color != color;
}

class _CornerOrnamentPainter extends CustomPainter {
  final bool isDark;
  const _CornerOrnamentPainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? const [_IGold.gold1, _IGold.gold2]
            : const [_IGold.gold2, _IGold.goldDeep],
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
  bool shouldRepaint(_CornerOrnamentPainter old) => old.isDark != isDark;
}

class _GoldDivider extends StatelessWidget {
  final bool isDark;
  const _GoldDivider({this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark ? _IGold.gold2 : _IGold.gold2.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '✦',
            style: TextStyle(
              color: isDark
                  ? _IGold.gold1.withValues(alpha: 0.8)
                  : _IGold.goldDeep.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark ? _IGold.gold2 : _IGold.gold2.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
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
  final bool isDark;
  const _GoldProgressBar({
    required this.duration,
    required this.barKey,
    this.isDark = true,
  }) : super(key: barKey);

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
    final colors = widget.isDark
        ? const [_IGold.gold3, _IGold.gold1, _IGold.gold3]
        : const [_IGold.gold2, _IGold.gold1, _IGold.gold2];

    return TweenAnimationBuilder<double>(
      key: widget.barKey,
      tween: Tween(begin: 1.0, end: 0.0),
      duration: widget.duration,
      builder: (ctx, value, _) {
        return AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) {
            return Container(
              height: 3.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isDark
                          ? const [_IGold.gold3, _IGold.gold1]
                          : const [_IGold.goldDeep, _IGold.gold2],
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
  bool _copied = false;

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
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideCtrl,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);

    // ── Glow Pulse ──
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
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
    setState(() => _copied = false);
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

  void _copyToClipboard() {
    if (_current == null) return;
    final buffer = StringBuffer()..writeln(_current!.arabic);
    if (_current!.meaning != null && _current!.meaning!.trim().isNotEmpty) {
      buffer.writeln(_current!.meaning!.trim());
    }
    final source = _current!.source ?? _current!.fadl;
    if (source != null && source.trim().isNotEmpty) {
      buffer.writeln(source.trim());
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
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
    final palette = _OverlayPalette.of(context);

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
              top: 210,
              left: 12,
              right: 12,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, left: 24),
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: GestureDetector(
                      onTap: () {},
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity!.abs() > 80) {
                          _pickRandom(animate: true);
                        }
                      },
                      child: _buildCard(palette),
                    ),
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
  Widget _buildCard(_OverlayPalette palette) {
    final item = _current!;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _IGold.gold2.withValues(
                alpha: _glowAnim.value * (palette.isDark ? 0.2 : 0.15),
              ),
              blurRadius: 16,
              spreadRadius: 0.5,
              offset: const Offset(-3, 0),
            ),
            ...palette.shadows,
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [palette.bgStart, palette.bgMid, palette.bgEnd],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Islamic Pattern Background ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _IslamicPatternPainter(
                    opacity: palette.isDark ? 0.055 : 0.04,
                    color: palette.patternColor,
                  ),
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
                        _IGold.gold3.withValues(
                          alpha: palette.isDark ? 0.18 : 0.08,
                        ),
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.outerBorder, width: 1.0),
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
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: palette.innerBorder, width: 0.8),
                  ),
                ),
              ),

              // ── Corner ornaments ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _CornerOrnamentPainter(isDark: palette.isDark),
                ),
              ),

              // ── Shimmer progress bar at bottom ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: _GoldProgressBar(
                    duration: _displayDuration,
                    isDark: palette.isDark,
                    barKey: ValueKey('progress_${item.arabic.hashCode}'),
                  ),
                ),
              ),

              // ── Main Content ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(item, palette),
                    const SizedBox(height: 10),
                    _GoldDivider(isDark: palette.isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildArabicText(item, palette),
                    const SizedBox(height: 10),
                    _GoldDivider(isDark: palette.isDark),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFooter(item, palette),
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
  Widget _buildHeader(_PopupItem item, _OverlayPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emoji في دائرة مزخرفة
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [palette.badgeBgStart, palette.badgeBgEnd],
            ),
            border: Border.all(
              color: _IGold.gold2.withValues(alpha: 0.65),
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

        // اسم التصنيف + نوع الذكر
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: palette.isDark
                      ? const [_IGold.gold1, _IGold.gold2, _IGold.gold1]
                      : const [_IGold.goldDeep, _IGold.gold2, _IGold.goldDeep],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
                  item.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.headerTitle,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: (palette.isDark ? _IGold.teal : _IGold.tealDark)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isDua
                          ? _l10n.overlayTypeDua
                          : _l10n.overlayTypeDhikr,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.isDark ? _IGold.teal : _IGold.tealDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '•',
                    style: TextStyle(
                      color: palette.isDark ? _IGold.gold3 : _IGold.gold2,
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _l10n.overlayTapOutsideToClose,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 10,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // زر تحديث / ذكر آخر
        TakwaTappable(
          onTap: () => _pickRandom(animate: true),
          minTapSize: null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.btnBg,
              border: Border.all(
                color: _IGold.gold2.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.refresh_rounded,
              color: palette.isDark
                  ? _IGold.gold1.withValues(alpha: 0.85)
                  : _IGold.goldDeep,
              size: 15,
            ),
          ),
        ),

        // زر الإغلاق
        TakwaTappable(
          onTap: _closeOverlay,
          minTapSize: null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.btnBg,
              border: Border.all(
                color: _IGold.gold2.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.close_rounded,
              color: palette.isDark
                  ? _IGold.gold1.withValues(alpha: 0.8)
                  : _IGold.goldDeep,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────
  //  ARABIC TEXT & MEANING
  // ─────────────────────────────
  Widget _buildArabicText(_PopupItem item, _OverlayPalette palette) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
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
                  fontSize: 14,
                  color: _IGold.gold2.withValues(
                    alpha: palette.isDark ? 0.65 : 0.85,
                  ),
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // النص العربي الرئيسي
              SelectableText(
                item.arabic,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 23,
                  color: palette.textPrimary,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              // المعنى أو الترجمة إن وجد
              if (item.meaning != null && item.meaning!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.meaningBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.meaningBorder,
                      width: 0.7,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 6),
                        child: Icon(
                          Icons.translate_rounded,
                          size: 13,
                          color: palette.isDark
                              ? _IGold.teal.withValues(alpha: 0.9)
                              : _IGold.tealDark,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.meaning!.trim(),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            color: palette.textMeaning,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────
  //  FOOTER / SOURCE BADGE & ACTIONS
  // ─────────────────────────────
  Widget _buildFooter(_PopupItem item, _OverlayPalette palette) {
    final text = item.source ?? item.fadl ?? '';

    return Row(
      children: [
        // زر النسخ السريع
        TakwaTappable(
          onTap: _copyToClipboard,
          minTapSize: null,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _copied
                  ? (palette.isDark ? _IGold.teal : _IGold.tealDark).withValues(
                      alpha: 0.2,
                    )
                  : palette.btnBg,
              border: Border.all(
                color: _copied
                    ? (palette.isDark ? _IGold.teal : _IGold.tealDark)
                    : _IGold.gold2.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 12,
                  color: _copied
                      ? (palette.isDark ? _IGold.teal : _IGold.tealDark)
                      : (palette.isDark ? _IGold.gold1 : _IGold.goldDeep),
                ),
                const SizedBox(width: 4),
                Text(
                  _copied ? 'تم النسخ' : 'نسخ',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _copied
                        ? (palette.isDark ? _IGold.teal : _IGold.tealDark)
                        : (palette.isDark ? _IGold.gold1 : _IGold.goldDeep),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // المصدر / الفضل
        if (text.trim().isNotEmpty)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                color: palette.isDark
                    ? _IGold.gold3.withValues(alpha: 0.2)
                    : _IGold.gold2.withValues(alpha: 0.1),
                border: Border.all(
                  color: _IGold.gold2.withValues(
                    alpha: palette.isDark ? 0.3 : 0.4,
                  ),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: palette.isDark ? _IGold.gold2 : _IGold.goldDeep,
                    size: 11,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      text.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 11,
                        color: palette.isDark ? _IGold.gold1 : _IGold.goldDeep,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Spacer(),

        const SizedBox(width: 8),

        // تلميح السحب
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swipe_rounded,
              size: 12,
              color: palette.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 3),
            Text(
              'اسحب للتالي',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 10,
                color: palette.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
