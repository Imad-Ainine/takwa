import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'app_theme.dart';

class RamadanColors {
  // Deep lapis + gold + emerald — ألوان الفسيفساء الإسلامية
  static const deepLapis = Color(0xFF0A1628);
  static const lapis = Color(0xFF0F2044);
  static const lapisLight = Color(0xFF0C1B3C);
  static const lapisCard = Color(0xBD101A32);

  static const goldenAura = Color(0xFFD4A843);
  static const goldenLight = Color(0xFFEDD278);
  static const goldenDeep = Color(0xFFA07820);
  static const goldenDim = Color(0x30D4A843);

  static const emerald = Color(0xFF1B6B4E);
  static const emeraldLight = Color(0xFF2A9E73);
  static const emeraldDim = Color(0x20278055);

  static const ruby = Color(0xFF8B2635);
  static const rubyLight = Color(0xFFB03040);

  static const ivory = Color(0xFFF5ECD7);
  static const ivoryLight = Color(0xFFFCF9F2);
  static const ivoryDim = Color(0xFFD4C4A0);
  static const ivoryGhost = Color(0x15F5ECD7);

  static const border = Color(0x40D4A843);
  static const borderLight = Color(0x60EDD278);

  // Gradients
  static const LinearGradient nightSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF050D1A), Color(0xFF0A1628), Color(0xFF0F2044)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient daySky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCF9F2), Color(0xFFF5ECD7), Color(0xFFE8DDC3)],
  );

  static const LinearGradient goldenGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x28D4A843), Color(0x121B6B4E)],
  );

  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2044), Color.fromARGB(255, 3, 18, 52)],
  );

  static const LinearGradient cardGlowLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFCF9F2)],
  );
}

class RamadanTheme {
  static ThemeData theme(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final locale = Localizations.localeOf(context);
    return brightness == Brightness.dark ? dark(locale) : light(locale);
  }

  /// [locale] defaults to Arabic, matching this app's default UI language.
  static ThemeData dark([Locale locale = const Locale('ar')]) {
    final colors = AppColorsExtension(
      background: RamadanColors.deepLapis,
      deep: RamadanColors.lapis,
      card: RamadanColors.lapisCard,
      card2: RamadanColors.lapisCard,
      border: RamadanColors.border,
      night: RamadanColors.deepLapis,
      gold: RamadanColors.goldenAura,
      goldLight: RamadanColors.goldenLight,
      goldDark: RamadanColors.goldenDeep,
      goldDim: RamadanColors.goldenDim,
      teal: RamadanColors.emeraldLight,
      tealDim: RamadanColors.emeraldDim,
      success: RamadanColors.emeraldLight,
      successDim: RamadanColors.emeraldDim,
      danger: RamadanColors.rubyLight,
      dangerDim: RamadanColors.rubyLight.withValues(alpha: 0.1),
      warning: RamadanColors.goldenAura,
      // On-surface accent ramp — see AppColorsExtension. On deep lapis the
      // gold/emerald fills already clear AA as foregrounds; rubyLight does
      // not (2.89:1), so error text gets a lifted tint.
      goldText: RamadanColors.goldenAura,
      tealText: RamadanColors.emeraldLight,
      successText: RamadanColors.emeraldLight,
      warningText: RamadanColors.goldenAura,
      dangerText: const Color(0xFFE0808C), // 6.59:1 on deepLapis
      textPrimary: RamadanColors.ivory,
      textSecondary: RamadanColors.ivoryDim,
      // 0.5 opacity landed at 3.49:1 on deepLapis; 0.72 clears AA.
      textDim: RamadanColors.ivoryDim.withValues(alpha: 0.72),
      backgroundGradient: RamadanColors.nightSky,
      cardGradient: RamadanColors.cardGlow,
      goldGradient: AppColorsExtension.dark.goldGradient,
      tealGoldGradient: AppColorsExtension.dark.tealGoldGradient,
    );

    // Delegates to the shared builder behind AppTheme.dark/light instead of
    // hand-rolling a second ThemeData here. That used to mean this theme
    // only got 6 of the 17 component themes AppTheme builds (no
    // navigationBarTheme, inputDecorationTheme, chipTheme, dialogTheme,
    // snackBarTheme, sliderTheme, tabBarTheme, checkbox/switch themes, ...),
    // a hand-built ColorScheme with ~11 roles instead of the ~20 AppTheme
    // fills out (so e.g. NavigationBar/SearchBar/Badge fell back to the
    // stock purple-tinted M3 defaults), and its own type scale that
    // disagreed with AppTheme's on every role's size by 2-6px. The one
    // deliberate divergence — a transparent app bar so RamadanBgPainter
    // shows through behind it, instead of the base theme's opaque
    // `colors.deep` — is preserved via `appBarBackground`.
    //
    // Visible side effect: card corner radius moves from this theme's
    // previous 24px to AppTheme's 16px (`AppRadius.card`) — the two had
    // silently diverged and there was no reason for Ramadan cards alone to
    // be rounder.
    return AppTheme.fromColors(
      colors,
      Brightness.dark,
      locale,
      Colors.transparent,
    );
  }

  static ThemeData light([Locale locale = const Locale('ar')]) {
    final colors = AppColorsExtension(
      background: RamadanColors.ivoryLight,
      deep: RamadanColors.ivory,
      card: Colors.white,
      card2: RamadanColors.ivoryLight,
      border: RamadanColors.border,
      night: RamadanColors.deepLapis,
      gold: RamadanColors.goldenAura,
      goldLight: RamadanColors.goldenLight,
      goldDark: RamadanColors.goldenDeep,
      goldDim: RamadanColors.goldenDim,
      teal: RamadanColors.emerald,
      tealDim: RamadanColors.emeraldDim,
      success: RamadanColors.emerald,
      successDim: RamadanColors.emeraldDim,
      danger: RamadanColors.ruby,
      dangerDim: RamadanColors.ruby.withValues(alpha: 0.1),
      warning: RamadanColors.goldenAura,
      // goldenDeep (#A07820) is only 3.84:1 on the ivory ground, so the
      // on-surface gold is darkened further; emerald and ruby already pass.
      goldText: const Color(0xFF6E5110), // 7.01:1 on ivoryLight
      tealText: RamadanColors.emerald,
      successText: RamadanColors.emerald,
      warningText: const Color(0xFF6E5110),
      dangerText: RamadanColors.ruby,
      textPrimary: RamadanColors.deepLapis,
      textSecondary: RamadanColors.deepLapis.withValues(alpha: 0.7),
      // 0.4 opacity landed at 2.56:1 on the ivory ground; 0.65 clears AA.
      textDim: RamadanColors.deepLapis.withValues(alpha: 0.65),
      backgroundGradient: RamadanColors.daySky,
      cardGradient: RamadanColors.cardGlowLight,
      goldGradient: AppColorsExtension.light.goldGradient,
      tealGoldGradient: AppColorsExtension.light.tealGoldGradient,
    );

    // See the comment in dark() above — same collapse, same caveats.
    return AppTheme.fromColors(
      colors,
      Brightness.light,
      locale,
      Colors.transparent,
    );
  }
}

class RamadanDecorations {
  static BoxDecoration get card => BoxDecoration(
    gradient: RamadanColors.cardGlow,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: RamadanColors.border),
    boxShadow: [
      BoxShadow(
        color: RamadanColors.goldenAura.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get heroCard => BoxDecoration(
    gradient: RamadanColors.goldenGlow,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: RamadanColors.borderLight),
    boxShadow: [
      BoxShadow(
        color: RamadanColors.goldenAura.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get pill => BoxDecoration(
    color: RamadanColors.goldenDim,
    borderRadius: BorderRadius.circular(100),
    border: Border.all(color: RamadanColors.border),
  );

  static BoxDecoration get page =>
      const BoxDecoration(gradient: RamadanColors.nightSky);
}

class RamadanBgPainter extends CustomPainter {
  // Was a plain `final double animT` set from a caller-read `_ctrl.value`,
  // with CustomPatternBackground rebuilding via AnimatedBuilder and
  // constructing a BRAND NEW RamadanBgPainter every animation tick (~15/s).
  // That made every field below pointless as a cache: a fresh instance
  // starts with everything null, so the whole arabesque tiling — nested
  // loops over the viewport, a 20-segment star plus 10 béziers per cell —
  // was re-recorded from scratch on every frame, and being `static` on top
  // of that meant every differently-sized CustomPatternBackground on
  // screen (there are dozens, including one inside every PrimaryButton)
  // stomped on the one shared cache.
  //
  // Passing `animation` straight to `super(repaint: animation)` fixes the
  // root cause: the render object now calls paint() again on this SAME
  // painter instance whenever the controller ticks, without rebuilding the
  // widget tree or constructing a new painter — see
  // CustomPatternBackground's Ramadan branch, which no longer wraps this in
  // AnimatedBuilder. That makes the caches below instance fields that
  // actually get reused, keyed by (size, brightness) as before.
  final Animation<double> animation;
  final Brightness brightness;
  RamadanBgPainter({required this.animation, this.brightness = Brightness.dark})
    : super(repaint: animation);

  double get animT => animation.value;

  final math.Random _rng = math.Random(7);
  List<Offset>? _stars;
  Size? _starsSize;
  Picture? _cachedArabesque;
  Size? _cachedArabesqueSize;
  Brightness? _cachedBrightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final isDark = brightness == Brightness.dark;

    // Background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = (isDark ? RamadanColors.nightSky : RamadanColors.daySky)
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    if (isDark) {
      _drawNightElements(canvas, size);
    } else {
      _drawDayElements(canvas, size);
    }

    // Pattern - Caching expensive arabesque
    if (_cachedArabesque == null ||
        _cachedArabesqueSize != size ||
        _cachedBrightness != brightness) {
      // Dispose the outgoing recording before replacing it — a Picture
      // holds a native (Skia) resource that isn't freed just because the
      // Dart reference is overwritten.
      _cachedArabesque?.dispose();
      _cachedArabesqueSize = size;
      _cachedBrightness = brightness;
      final recorder = PictureRecorder();
      final c = Canvas(recorder);
      _drawArabesque(c, size, isDark);
      _cachedArabesque = recorder.endRecording();
    }
    canvas.drawPicture(_cachedArabesque!);

    // Lanterns (Fanoos)
    _drawLantern(canvas, Offset(size.width * 0.15, 60), 1.0, isDark);
    _drawLantern(canvas, Offset(size.width * 0.85, 40), 0.8, isDark);
  }

  void _drawNightElements(Canvas canvas, Size size) {
    // Also now keyed by size, not just "has this ever run": the old
    // `_stars ??= ...` generated the field once for whatever size happened
    // to paint first and never regenerated it, so a later resize (rotation,
    // a different screen) left stars scattered to fit stale dimensions.
    if (_stars == null || _starsSize != size) {
      _starsSize = size;
      _stars = List.generate(
        120,
        (_) => Offset(
          _rng.nextDouble() * size.width,
          _rng.nextDouble() * size.height * 0.7,
        ),
      );
    }
    for (int i = 0; i < _stars!.length; i++) {
      final t = (math.sin(animT * 2 * math.pi + i * 0.4) + 1) / 2;
      final r = 0.5 + _rng.nextDouble() * 1.2;
      canvas.drawCircle(
        _stars![i],
        r,
        Paint()..color = RamadanColors.ivory.withValues(alpha: 0.1 + 0.5 * t),
      );
    }
    _drawCrescent(canvas, Offset(size.width * 0.82, size.height * 0.09), true);
  }

  void _drawDayElements(Canvas canvas, Size size) {
    // Subtle sun glow
    final sunCenter = Offset(size.width * 0.82, size.height * 0.12);
    canvas.drawCircle(
      sunCenter,
      40,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RamadanColors.goldenAura.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: 40)),
    );
  }

  void _drawLantern(Canvas canvas, Offset pos, double scale, bool isDark) {
    final flicker = (math.sin(animT * 2 * math.pi * 1.5) + 1) / 2;
    final p = Paint()
      ..color = RamadanColors.goldenAura.withValues(alpha: isDark ? 0.8 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final glowP = Paint()
      ..color = RamadanColors.goldenLight.withValues(alpha: isDark ? 0.3 * flicker : 0.15 * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(pos + const Offset(0, 15), 15 * scale, glowP);

    final path = Path();
    final w = 12.0 * scale;
    final h = 25.0 * scale;

    // Top
    path.moveTo(pos.dx - w * 0.5, pos.dy);
    path.lineTo(pos.dx + w * 0.5, pos.dy);
    path.lineTo(pos.dx + w * 0.2, pos.dy - 8 * scale);
    path.lineTo(pos.dx - w * 0.2, pos.dy - 8 * scale);
    path.close();

    // Body
    path.moveTo(pos.dx - w * 0.5, pos.dy);
    path.lineTo(pos.dx - w, pos.dy + h * 0.4);
    path.lineTo(pos.dx - w * 0.6, pos.dy + h);
    path.lineTo(pos.dx + w * 0.6, pos.dy + h);
    path.lineTo(pos.dx + w, pos.dy + h * 0.4);
    path.lineTo(pos.dx + w * 0.5, pos.dy);

    // Bottom
    path.moveTo(pos.dx - w * 0.6, pos.dy + h);
    path.lineTo(pos.dx + w * 0.6, pos.dy + h);
    path.lineTo(pos.dx + w * 0.3, pos.dy + h + 6 * scale);
    path.lineTo(pos.dx - w * 0.3, pos.dy + h + 6 * scale);
    path.close();

    canvas.drawPath(path, p);

    // Inner light
    final innerP = Paint()
      ..color = RamadanColors.goldenLight.withValues(alpha: isDark ? 0.5 * flicker : 0.3 * flicker)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(
        center: pos + Offset(0, h * 0.5),
        width: w * 0.6,
        height: h * 0.4,
      ),
      innerP,
    );
  }

  void _drawCrescent(Canvas canvas, Offset center, bool isDark) {
    const r = 20.0;
    canvas.drawCircle(
      center,
      r + 8,
      Paint()
        ..color = RamadanColors.goldenAura.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFFF0B3));
    canvas.drawCircle(
      Offset(center.dx + r * 0.55, center.dy - r * 0.05),
      r * 0.88,
      Paint()..color = const Color(0xFF040C1E),
    );
  }

  void _drawArabesque(Canvas canvas, Size size, bool isDark) {
    final p = Paint()
      ..color = RamadanColors.goldenAura.withValues(alpha: isDark ? 0.07 : 0.05)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    const s = 100.0;
    for (double x = 0; x < size.width + s; x += s) {
      for (double y = 0; y < size.height + s; y += s) {
        final isOdd = (x / s).round().isOdd;
        final py = isOdd ? y + s / 2 : y;
        _drawTenFoldArabesque(canvas, Offset(x, py), s * 0.45, p);
      }
    }
  }

  void _drawTenFoldArabesque(Canvas canvas, Offset c, double r, Paint p) {
    // 10-point star base
    final Path star = Path();
    for (int i = 0; i < 20; i++) {
      final a = i * math.pi / 10;
      final dist = i.isEven ? r : r * 0.7;
      final px = c.dx + dist * math.cos(a);
      final py = c.dy + dist * math.sin(a);
      if (i == 0) {
        star.moveTo(px, py);
      } else {
        star.lineTo(px, py);
      }
    }
    star.close();
    canvas.drawPath(star, p);

    // Interlacing "vine" paths
    final Path vines = Path();
    for (int i = 0; i < 10; i++) {
      final a1 = i * math.pi / 5;
      final a2 = (i + 1) * math.pi / 5;

      final p1 = Offset(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1));
      final p2 = Offset(c.dx + r * math.cos(a2), c.dy + r * math.sin(a2));
      final cp = Offset(
        c.dx + r * 1.4 * math.cos((a1 + a2) / 2),
        c.dy + r * 1.4 * math.sin((a1 + a2) / 2),
      );

      vines.moveTo(p1.dx, p1.dy);
      vines.quadraticBezierTo(cp.dx, cp.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(vines, p);

    // Core detail
    canvas.drawCircle(c, r * 0.3, p);
    _drawSmallStar(canvas, c, r * 0.15, p);
  }

  void _drawSmallStar(Canvas canvas, Offset c, double r, Paint p) {
    final Path s = Path();
    for (int i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final dist = i.isEven ? r : r * 0.5;
      final px = c.dx + dist * math.cos(a);
      final py = c.dy + dist * math.sin(a);
      if (i == 0) {
        s.moveTo(px, py);
      } else {
        s.lineTo(px, py);
      }
    }
    s.close();
    canvas.drawPath(s, p);
  }

  @override
  bool shouldRepaint(covariant RamadanBgPainter old) =>
      // Per-frame repaints are driven by `repaint: animation` above, not by
      // this — Flutter calls paint() again on tick regardless of what this
      // returns. This only matters on the rarer occasion a NEW painter
      // instance replaces this one (e.g. a brightness flip rebuilds
      // CustomPatternBackground), where a differing controller identity or
      // brightness is the real signal to repaint.
      old.animation != animation || old.brightness != brightness;
}

/// Theme-aware style helper used across screens that need to react to
/// Ramadan mode (`AdaptiveStyle(context, isRamadan)`), reading whichever
/// theme extensions are currently active on [context] — the caller (app
/// layer) is responsible for actually setting `theme:`/`darkTheme:` to
/// [AppTheme] or [RamadanTheme] based on its own Ramadan-mode state.
class AdaptiveStyle {
  final BuildContext context;
  final bool isRamadan;
  const AdaptiveStyle(this.context, this.isRamadan);

  AppColorsExtension get _colors =>
      Theme.of(context).extension<AppColorsExtension>()!;
  AppDecorationsExtension get _decorations =>
      Theme.of(context).extension<AppDecorationsExtension>()!;

  Color get gold => _colors.gold;
  Color get goldLight => _colors.goldLight;
  Color get goldDark => _colors.goldDark;
  Color get goldDim => _colors.goldDim;
  Color get teal => _colors.teal;
  Color get success => _colors.success;
  Color get danger => _colors.danger;
  Color get bg => _colors.background;
  Color get deep => _colors.deep;
  Color get card => _colors.card;
  Color get border => _colors.border;
  Color get text => _colors.textPrimary;
  Color get textSec => _colors.textSecondary;
  Color get textDim => _colors.textDim;

  BoxDecoration get cardDeco => _decorations.card;
  BoxDecoration get heroDeco => _decorations.goldCard;

  /// Display/heading style — Amiri for Arabic (unchanged), Poppins for
  /// every other locale, with Tajawal fallback for Arabic glyphs.
  TextStyle amiri(
    double size, {
    Color? color,
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontFamily: appFontFamily(Localizations.localeOf(context)),
    fontFamilyFallback: appFontFamilyFallback(Localizations.localeOf(context)),
    fontSize: size,
    color: color ?? gold,
    fontWeight: weight ?? FontWeight.w700,
    height: height,
    shadows: isRamadan
        ? [
            Shadow(
              color: gold.withValues(alpha: size > 20 ? 0.4 : 0.2),
              blurRadius: size > 20 ? 12 : 8,
            ),
          ]
        : null,
  );

  /// Body style — NotoNaskhArabic for Arabic (unchanged), Poppins for
  /// every other locale, with Tajawal fallback for Arabic glyphs.
  TextStyle naskh(
    double size, {
    Color? color,
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontFamily: appBodyFontFamily(Localizations.localeOf(context)),
    fontFamilyFallback: appFontFamilyFallback(Localizations.localeOf(context)),
    fontSize: size,
    color: color ?? (size < 12 ? textSec : text),
    fontWeight: weight ?? FontWeight.w400,
    height: height,
  );

  /// Clean modern Arabic style using Tajawal.
  TextStyle tajawal(
    double size, {
    Color? color,
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontFamily: 'Tajawal',
    fontFamilyFallback: appFontFamilyFallback(Localizations.localeOf(context)),
    fontSize: size,
    color: color ?? (size < 12 ? textSec : text),
    fontWeight: weight ?? FontWeight.w400,
    height: height,
  );

  // ── Role-based styles ─────────────────────────────────────────────
  //
  // The three methods above take a raw pixel `size` — which is exactly how
  // this class ended up behind 266 call sites passing 19 different literal
  // values (down to 8px), because reaching for a number was always easier
  // than fighting a type scale that didn't fit real usage (see the "display
  // sizes masquerading as body sizes" note on AppTypographyExtension's own
  // fromColors). These return the SAME TextStyle Theme.of(context) already
  // carries on AppTypographyExtension, one role at a time, instead of
  // resolving a font/size themselves — and since RamadanTheme now shares
  // AppTheme's builder rather than hand-rolling its own type scale, that
  // resolved style is already correct for whichever of the four themes
  // (base/Ramadan × dark/light) is active, with no extra logic needed here.
  //
  // Not a mechanical migration of the 266 existing call sites: this adds
  // the accessors the fix calls for and moves this file itself, but sweeping
  // every call site means picking, for each one, which of these 12 roles
  // its current raw size was *supposed* to mean — a judgment call per site
  // that needs a visual pass this environment (no Flutter SDK) can't do
  // safely. New call sites, and any call site touched for other reasons,
  // should reach for one of these instead of `.naskh(11)`.
  AppTypographyExtension get _type =>
      Theme.of(context).extension<AppTypographyExtension>()!;

  // The old amiri()'s Ramadan-only glow, ported by role instead of by a
  // `size > 20` threshold: displayLarge/displayMedium/headingLarge are the
  // roles that used to sit above that threshold.
  TextStyle _withRamadanGlow(TextStyle style, {required bool strong}) {
    if (!isRamadan) return style;
    return style.copyWith(
      shadows: [
        Shadow(
          color: gold.withValues(alpha: strong ? 0.4 : 0.2),
          blurRadius: strong ? 12 : 8,
        ),
      ],
    );
  }

  TextStyle _override(
    TextStyle style, {
    Color? color,
    FontWeight? weight,
    double? height,
    bool bodyFont = false,
  }) {
    final withColor = style.copyWith(color: color, fontWeight: weight, height: height);
    if (!bodyFont) return withColor;
    // AppTypographyExtension.fromColors bakes appFontFamily (the display/
    // heading face — Amiri for Arabic) into every role, since that's what
    // amiri() always used. naskh() call sites are body text in a
    // DIFFERENT face (NotoNaskhArabic for Arabic) — swapping those to a
    // role without this would silently change their rendered font, not
    // just their size. bodyFont: true swaps back to the body face while
    // keeping the role's size/weight/line-height.
    final locale = Localizations.localeOf(context);
    return withColor.copyWith(
      fontFamily: appBodyFontFamily(locale),
      fontFamilyFallback: appFontFamilyFallback(locale),
    );
  }

  TextStyle displayLarge({Color? color, FontWeight? weight, double? height}) =>
      _override(_withRamadanGlow(_type.displayLarge, strong: true), color: color, weight: weight, height: height);

  TextStyle displayMedium({Color? color, FontWeight? weight, double? height}) =>
      _override(_withRamadanGlow(_type.displayMedium, strong: true), color: color, weight: weight, height: height);

  TextStyle headingLarge({Color? color, FontWeight? weight, double? height}) =>
      _override(_withRamadanGlow(_type.headingLarge, strong: true), color: color, weight: weight, height: height);

  TextStyle headingMedium({Color? color, FontWeight? weight, double? height}) =>
      _override(_withRamadanGlow(_type.headingMedium, strong: false), color: color, weight: weight, height: height);

  /// [bodyFont]: use the body face (NotoNaskhArabic for Arabic) instead of
  /// this role's baked-in display face — pass this when migrating a
  /// `naskh(N)` call site, so the rendered font doesn't change along with
  /// the size. Leave it false when migrating an `amiri(N)` call site,
  /// which already used the display face this role defaults to.
  TextStyle bodyLarge({Color? color, FontWeight? weight, double? height, bool bodyFont = false}) =>
      _override(_type.bodyLarge, color: color, weight: weight, height: height, bodyFont: bodyFont);

  TextStyle bodyMedium({Color? color, FontWeight? weight, double? height, bool bodyFont = false}) =>
      _override(_type.bodyMedium, color: color, weight: weight, height: height, bodyFont: bodyFont);

  TextStyle bodySmall({Color? color, FontWeight? weight, double? height, bool bodyFont = false}) =>
      _override(_type.bodySmall, color: color, weight: weight, height: height, bodyFont: bodyFont);

  TextStyle labelLarge({Color? color, FontWeight? weight, double? height, bool bodyFont = false}) =>
      _override(_type.labelLarge, color: color, weight: weight, height: height, bodyFont: bodyFont);

  TextStyle labelMedium({Color? color, FontWeight? weight, double? height, bool bodyFont = false}) =>
      _override(_type.labelMedium, color: color, weight: weight, height: height, bodyFont: bodyFont);

  TextStyle caption({Color? color, FontWeight? weight, double? height, bool bodyFont = false}) =>
      _override(_type.caption, color: color, weight: weight, height: height, bodyFont: bodyFont);

  TextStyle quranicVerse({Color? color, FontWeight? weight, double? height}) =>
      _override(_type.quranicVerse, color: color, weight: weight, height: height);

  TextStyle taqwaScore({Color? color, FontWeight? weight, double? height}) =>
      _override(_type.taqwaScore, color: color, weight: weight, height: height);
}
