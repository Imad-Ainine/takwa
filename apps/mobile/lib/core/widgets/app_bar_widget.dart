import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/curved_edges.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool isCurved;
  final bool showBackground;
  final Widget? child;
  final Color? firstShade;
  final Color? secondShade;

  /// Drives a scroll-linked "quiet down" as the attached scroll view moves:
  /// the decorative circles fade toward the background and the title
  /// shrinks slightly, over the first [collapseDistance] logical pixels of
  /// scroll. Pass the same controller used by the screen's own scroll view
  /// (e.g. a `CustomScrollView`'s `controller:`).
  ///
  /// This does NOT shrink the reserved app-bar height itself — this widget
  /// is a plain `PreferredSizeWidget` (used via `Scaffold.appBar:`, not a
  /// sliver), and [preferredSize] is a property of the immutable widget
  /// that `Scaffold` reads independently of this internal, scroll-driven
  /// state. A true collapsing-toolbar effect (the reserved space itself
  /// shrinking) needs a `SliverPersistentHeader`/`SliverAppBar`-based
  /// rewrite and each call site's body converted to a `CustomScrollView`
  /// with this in its `slivers:` — a larger, separate change from the
  /// visual-only collapse here.
  final ScrollController? scrollController;

  /// Scroll distance, in logical pixels, over which the collapse in
  /// [scrollController] fully applies.
  final double collapseDistance;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    // Was 160 — oversized for a bar whose content is just a title row plus
    // three decorative circles that read fine at a more ordinary height;
    // the two screens that actually need more (a hero image, an
    // in-app-bar search field) already override this via `height:`.
    this.height = 120,
    this.isCurved = true,
    this.showBackground = true,
    this.child,
    this.firstShade,
    this.secondShade,
    this.scrollController,
    this.collapseDistance = 60,
  });

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();

  @override
  Size get preferredSize => Size.fromHeight(height);

  /// Adaptive foreground color for content sitting directly on this bar's
  /// background — same computation the built-in title uses internally (see
  /// the comment in `_AppBarWidgetState.build`). Callers that pass their own
  /// `actions:` icons/buttons (or a custom `child:`, when it isn't sitting on
  /// its own fixed-color surface — a per-item brand gradient, say) should use
  /// this instead of hardcoding `Colors.white`: the built-in title already
  /// avoided that exact bug, but a caller-supplied action icon still can — a
  /// hardcoded white read fine on the dark-mode gradient and disappeared on
  /// light mode's near-white one.
  static Color foregroundColorFor(
    BuildContext context, {
    bool showBackground = true,
    Color? firstShade,
    Color? secondShade,
  }) {
    final colors = context.colors;
    if (!showBackground) return colors.textPrimary;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCustomGradient = firstShade != null && secondShade != null;
    final gradientColors = hasCustomGradient
        ? [firstShade, secondShade]
        : (isDark
              ? [
                  colors.gold.withValues(alpha: 0.75),
                  colors.background.withValues(alpha: 0.85),
                ]
              : [
                  colors.background.withValues(alpha: 0.65),
                  colors.gold.withValues(alpha: 0.80),
                ]);
    final gradientMid = Color.alphaBlend(
      Color.lerp(gradientColors.first, gradientColors.last, 0.5)!,
      colors.background,
    );
    return ThemeData.estimateBrightnessForColor(gradientMid) == Brightness.dark
        ? Colors.white
        : colors.textPrimary;
  }
}

class _AppBarWidgetState extends State<AppBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _floatingAnimation;

  // 0.0 = fully expanded, 1.0 = fully collapsed. Self-contained: updated
  // from widget.scrollController's own listener and only ever setState's
  // this State, never the screen that owns the ScrollController — a plain
  // scroll-position listener is far cheaper than rebuilding the whole
  // screen on every frame the user scrolls.
  double _collapseFraction = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // repeat() is started from didChangeDependencies below, not here — that
    // is where the reduce-motion check happens, gated on a BuildContext
    // that isn't meaningfully available yet at this point in initState.

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    _floatingAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant AppBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (controller == null || !controller.hasClients) return;
    final distance = widget.collapseDistance <= 0
        ? 1.0
        : widget.collapseDistance;
    final next = (controller.offset / distance).clamp(0.0, 1.0);
    if (next != _collapseFraction) setState(() => _collapseFraction = next);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative — three drifting circles behind the title — so it
    // respects reduce-motion. Checked here rather than initState so a
    // setting flipped mid-session is picked up on the next dependency
    // change instead of only at first build.
    _animationController.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Whether a caller-supplied gradient is active.
    final hasCustomGradient =
        widget.firstShade != null && widget.secondShade != null;

    // Use caller gradient, or pick a theme-appropriate default.
    final gradient = hasCustomGradient
        ? LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [widget.firstShade!, widget.secondShade!],
          )
        : (isDark
              ? LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    colors.gold.withValues(alpha: 0.75),
                    colors.background.withValues(alpha: 0.85),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    colors.background.withValues(alpha: 0.65),
                    colors.gold.withValues(alpha: 0.80),
                  ],
                ));

    // Pick the title color from the gradient it actually sits on. It used to
    // be hardcoded white whenever showBackground was true, which in light mode
    // put white text over the near-white end of the default gradient (~1.05:1)
    // and leaned on a drop shadow to stay readable.
    final titleColor = AppBarWidget.foregroundColorFor(
      context,
      showBackground: widget.showBackground,
      firstShade: widget.firstShade,
      secondShade: widget.secondShade,
    );

    // Decorative circle opacities adapt to brightness so they stay subtle in
    // light mode and properly atmospheric in dark mode.
    final circleAlphaA = isDark ? 0.05 : 0.15;
    final circleAlphaB = isDark ? 0.20 : 0.22;
    final circleAlphaC = isDark ? 0.10 : 0.18;

    final circleColorA = Colors.white.withValues(alpha: circleAlphaA);
    final circleColorB = (widget.secondShade ?? colors.gold).withValues(alpha: circleAlphaB);
    final circleColorC = Colors.white.withValues(alpha: circleAlphaC);

    return TCurvedEdgeWidget(
      isCurved: widget.isCurved,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            if (widget.showBackground)
              Container(
                decoration: BoxDecoration(gradient: gradient),
                child: CustomPatternBackground(
                  pattern: BackgroundPattern.adhkar,
                  // Slightly lower opacity in light mode so the pattern stays subtle.
                  opacity: isDark ? 0.08 : 0.05,
                ),
              ),

            // ── Animated Decorative Circles ──────────────────────────
            // Each circle gets its own AnimatedBuilder with the static
            // TCirculerContainer passed in as `child` instead of one builder
            // reconstructing all three Positioned/Transform/Container
            // subtrees from scratch on every tick — the builder callback now
            // only rebuilds the cheap Positioned+Transform.scale wrapper
            // around a child it doesn't otherwise touch. Wrapped in one
            // RepaintBoundary so this continuous 4s animation repaints its
            // own compositing layer instead of forcing a repaint of the
            // CustomPatternBackground and AppBar title/actions painted in
            // the same Stack.
            //
            // Fades toward the background as widget.scrollController
            // reports scroll — see _collapseFraction. Never fully to 0: a
            // trace of the atmosphere stays even fully "collapsed".
            Opacity(
              opacity: 1 - _collapseFraction * 0.7,
              child: RepaintBoundary(
                child: Stack(
                  children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    child: TCirculerContainer(
                      width: 150,
                      height: 150,
                      backgroundColor: circleColorA,
                    ),
                    builder: (context, child) => Positioned(
                      bottom: -20 + _floatingAnimation.value,
                      left: -40,
                      child: Transform.scale(
                        scale: _breathingAnimation.value,
                        child: child,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animationController,
                    child: TCirculerContainer(
                      width: 100,
                      height: 100,
                      backgroundColor: circleColorB,
                    ),
                    builder: (context, child) => Positioned(
                      top: 40 - _floatingAnimation.value,
                      right: -30,
                      child: Transform.scale(
                        scale: 2.0 - _breathingAnimation.value,
                        child: child,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animationController,
                    child: TCirculerContainer(
                      width: 140,
                      height: 140,
                      backgroundColor: circleColorC,
                    ),
                    builder: (context, child) => Positioned(
                      top: -80 + _floatingAnimation.value * 0.5,
                      right: 110,
                      child: Transform.scale(
                        scale: _breathingAnimation.value,
                        child: child,
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ),

            // ── AppBar Content ───────────────────────────────────────
            SafeArea(
              child:
                  widget.child ??
                  Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        title: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.headingMedium.copyWith(
                            color: titleColor,
                            // 22 expanded, shrinking to 18 as the attached
                            // scroll view (if any) moves — see
                            // _collapseFraction.
                            fontSize: 22 - _collapseFraction * 4,
                            letterSpacing: 0.5,
                            // Shadow only where it is a legibility aid (light
                            // text on a busy gradient), never as a substitute
                            // for contrast.
                            shadows: widget.showBackground &&
                                    titleColor == Colors.white
                                ? [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.20),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        centerTitle: true,
                        leading: widget.leading,
                        actions: widget.actions,
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
