import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hijri/hijri_calendar.dart';

import '../core/theme/app_theme.dart';
import '../core/providers/database_providers.dart';
import '../core/database/daos.dart';
import '../core/supabase/sync_manager.dart';
import '../core/supabase/supabase_providers.dart';
import '../core/widgets/custom_pattern_background.dart';
import '../core/supabase/supabase_config.dart';
import '../core/providers/auth_providers.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/taqwa_level_display.dart';
import '../core/providers/app_info_provider.dart';
import 'main_shell.dart' show currentTabProvider;
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ─────────────────────────────────────────
//  DRAWER STATE PROVIDER
// ─────────────────────────────────────────
final drawerOpenProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────
//  DRAWER SCAFFOLD WRAPPER
//  يُغلّف الـ AppShell بالكامل
// ─────────────────────────────────────────
class DrawerScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const DrawerScaffold({super.key, required this.child});

  @override
  ConsumerState<DrawerScaffold> createState() => _DrawerScaffoldState();
}

class _DrawerScaffoldState extends ConsumerState<DrawerScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _rotate;
  late final Animation<BorderRadius?> _radius;

  static const _drawerWidth = 280.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slide = Tween<double>(
      begin: 0,
      end: _drawerWidth,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(
      begin: 0.0,
      end: 0.65,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _rotate = Tween<double>(
      begin: 0.0,
      end: -0.05,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _radius = BorderRadiusTween(
      begin: BorderRadius.zero,
      end: BorderRadius.circular(28),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.mediumImpact();
    ref.read(drawerOpenProvider.notifier).state = true;
    _ctrl.forward();
    ref.read(syncManagerProvider).fullSync(); // Trigger sync when opening
  }

  void _close() {
    HapticFeedback.lightImpact();
    ref.read(drawerOpenProvider.notifier).state = false;
    _ctrl.reverse();
  }

  void _toggle() {
    if (_ctrl.isAnimating) return;
    ref.read(drawerOpenProvider) ? _close() : _open();
  }

  @override
  Widget build(BuildContext context) {
    // Was hardcoded to the left edge regardless of locale (audit §H5): in
    // Arabic (RTL, this app's default) Material's convention puts the nav
    // drawer on the *start* edge — the right — so a fixed-left drawer opened
    // from the wrong side for the app's primary language.
    // PositionedDirectional resolves `start` per Directionality.of(context)
    // for the drawer's own position; the slide distance the main content
    // translates by needs its sign flipped by hand for the same reason
    // (Transform has no directional "translate", only a raw Offset), and
    // the scale/rotate pivot moves from centerLeft to centerStart so the
    // "push back" hinges on the same edge the drawer actually opens from.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isOpen = ref.watch(drawerOpenProvider);
    // Was no back-button handling at all (audit §M8): with the drawer open,
    // Android back popped the whole screen behind it instead of just
    // closing the drawer — the platform-standard drawer behavior.
    return PopScope(
      canPop: !isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Stack(
          children: [
            // ── الـ Drawer (خلف الشاشة) ──
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: 0,
              width: _drawerWidth,
              child: _DrawerContent(onClose: _close),
            ),

            // ── الشاشة الرئيسية (فوق الـ Drawer) ──
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Transform(
                // translate()/scale() are deprecated in this Flutter version's
                // vector_math in favor of the ByDouble/Values variants —
                // multiply() by an explicit translation/scale matrix is the
                // non-deprecated equivalent (same right-multiply semantics
                // the old cascade had).
                transform: Matrix4.identity()
                  ..multiply(
                    Matrix4.translationValues(
                      isRtl ? -_slide.value : _slide.value,
                      0.0,
                      0.0,
                    ),
                  )
                  ..multiply(
                    Matrix4.diagonal3Values(_scale.value, _scale.value, 1.0),
                  )
                  ..rotateZ(isRtl ? -_rotate.value : _rotate.value),
                alignment: AlignmentDirectional.centerStart,
                child: ClipRRect(
                  borderRadius: _radius.value ?? BorderRadius.zero,
                  child: child,
                ),
              ),
              child: Stack(
                children: [
                  widget.child,

                  // overlay عند فتح الـ Drawer
                  AnimatedBuilder(
                    animation: _fade,
                    builder: (_, _) => _fade.value > 0
                        ? GestureDetector(
                            onTap: _close,
                            child: Container(
                              color: Colors.black.withValues(
                                alpha: _fade.value,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // expose toggle للخارج
  static _DrawerScaffoldState of(BuildContext context) =>
      context.findAncestorStateOfType<_DrawerScaffoldState>()!;
}

// ─────────────────────────────────────────
//  DRAWER CONTENT
// ─────────────────────────────────────────
class _DrawerContent extends ConsumerWidget {
  final VoidCallback onClose;
  const _DrawerContent({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(monthStatsProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final hijri = HijriCalendar.now();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.deep, context.colors.deep],
        ),
      ),
      child: Stack(
        children: [
          // نمط خلفية عصري
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── رأس الـ Drawer ──
                _DrawerHeader(
                  hijri: hijri,
                  statsAsync: statsAsync,
                  streakAsync: streakAsync,
                  onClose: onClose,
                ),

                const SizedBox(height: AppSpacing.sm),
                Container(height: 1, color: context.colors.border),
                const SizedBox(height: AppSpacing.sm),

                // ── قائمة التنقل ──
                Expanded(child: _DrawerNav(onClose: onClose)),

                // ── حالة الاتصال والمزامنة ──
                // Was surfaced nowhere except a buried Settings row (and only
                // ever as "syncing"/"synced", never "offline" —
                // connectivityProvider itself was read in exactly one place
                // in the whole app, favorites_providers.dart). The drawer is
                // reachable from every tab, so it's the one place this is
                // guaranteed visible without adding a chip to all ~50
                // screens' app bars.
                if (ref.watch(authStatusProvider) == AuthStatus.authenticated)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: AppSpacing.xs,
                    ),
                    child: _ConnectivityStatusRow(),
                  ),

                // ── تسجيل الخروج ──
                if (ref.watch(authStatusProvider) == AuthStatus.authenticated)
                  _LogoutButton(onClose: onClose),

                // ── تذييل ──
                const _DrawerFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── رأس الـ Drawer ──
class _DrawerHeader extends ConsumerWidget {
  final HijriCalendar hijri;
  final AsyncValue<MonthStats> statsAsync;
  final AsyncValue<int> streakAsync;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.hijri,
    required this.statsAsync,
    required this.streakAsync,
    required this.onClose,
  });

  static String _hijriMonth(AppLocalizations l10n, int m) => [
    l10n.hijriMuharram,
    l10n.hijriSafar,
    l10n.hijriRabiAlAwwal,
    l10n.hijriRabiAlThani,
    l10n.hijriJumadaAlAwwal,
    l10n.hijriJumadaAlThani,
    l10n.hijriRajab,
    l10n.hijriShaban,
    l10n.hijriRamadan,
    l10n.hijriShawwal,
    l10n.hijriDhulQadah,
    l10n.hijriDhulHijjah,
  ][m - 1];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRamadan = hijri.hMonth == 9;
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section in header
          profileAsync.when(
            data: (profile) {
              final l = AppLocalizations.of(context)!;
              final username = profile?['username'] ?? l.drawerDefaultUsername;
              final avatar = profile?['avatar_emoji'] ?? '🌙';
              return GestureDetector(
                onTap: () {
                  // Was Navigator.pop(context) — this drawer is a Stack
                  // layer (DrawerScaffold), not a pushed route, so that
                  // popped the actual page underneath instead of closing
                  // the drawer. onClose() is the drawer's own animation.
                  onClose();
                  Navigator.of(context).pushNamed(Routes.profile);
                },
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.goldDim,
                        border: Border.all(
                          color: context.colors.gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.gold.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  username,
                                  style: context.typography.headingLarge
                                      .copyWith(
                                        fontSize: 18,
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (profile?['gender'] != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.gold.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: context.colors.gold.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    profile!['gender'] == 'male'
                                        ? l.drawerGenderMale
                                        : l.drawerGenderFemale,
                                    style: context.typography.caption.copyWith(
                                      color: context.colors.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (ref.watch(authStatusProvider) ==
                              AuthStatus.authenticated)
                            Row(
                              children: [
                                Text(
                                  l.drawerViewProfile,
                                  style: context.typography.caption.copyWith(
                                    fontSize: 11,
                                    color: context.colors.gold,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  // Was 8px, under audit §M5's 12dp
                                  // decorative floor — sub-legible next to
                                  // an 11px label.
                                  size: 12,
                                  color: context.colors.gold,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 52),
            error: (_, _) => SizedBox(
              height: 52,
              child: TakwaInlineError(
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // التاريخ الهجري
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: context.colors.goldDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.colors.gold.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${hijri.hDay} ${_hijriMonth(l10n, hijri.hMonth)} ${hijri.hYear}',
                  style: context.typography.headingMedium.copyWith(
                    fontSize: 14,
                    color: context.colors.goldLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Stats row
          Row(
            children: [
              Expanded(
                child: statsAsync.when(
                  loading: () => const SizedBox(height: 48),
                  error: (_, _) => TakwaInlineError(
                    height: 48,
                    onRetry: () => ref.invalidate(monthStatsProvider),
                  ),
                  data: (s) => _MiniStatCard(
                    value: '${s.totalPoints}',
                    label: AppLocalizations.of(context)!.drawerStatTaqwaPoints,
                    icon: '🌟',
                    color: context.colors.gold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: streakAsync.when(
                  loading: () => const SizedBox(height: 48),
                  error: (_, _) => TakwaInlineError(
                    height: 48,
                    onRetry: () => ref.invalidate(currentStreakProvider),
                  ),
                  data: (s) => _MiniStatCard(
                    value: '$s',
                    label: AppLocalizations.of(context)!.drawerStatStreakDays,
                    icon: '🔥',
                    color: context.colors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Level & Progress
          statsAsync.when(
            loading: () => const SizedBox(),
            error: (_, _) => TakwaErrorState(
              compact: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              onRetry: () => ref.invalidate(monthStatsProvider),
            ),
            data: (s) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.drawerLevelLabel(
                        taqwaLevelLabel(AppLocalizations.of(context)!, s.level),
                      ),
                      style: context.typography.caption.copyWith(
                        color: context.colors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${s.totalPoints} / 600',
                      style: context.typography.caption.copyWith(
                        fontSize: 9,
                        color: context.colors.textDim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (s.totalPoints / 600).clamp(0, 1),
                    backgroundColor: context.colors.gold.withValues(alpha: 0.1),
                    color: context.colors.gold,
                    minHeight: 4,
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

class _MiniStatCard extends StatelessWidget {
  final String value, label, icon;
  final Color color;
  const _MiniStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.sm,
      horizontal: 10,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: context.typography.bodyLarge.copyWith(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: context.typography.caption.copyWith(
                fontSize: 9,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── قائمة التنقل ──
class _DrawerNav extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const _DrawerNav({required this.onClose});

  @override
  ConsumerState<_DrawerNav> createState() => _DrawerNavState();
}

class _DrawerNavState extends ConsumerState<_DrawerNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  // Emoji → real icons (audit §H2) — same motivation as main_shell.dart's
  // bottom nav: these render as fixed-color glyphs on the app's own gold
  // accent (see _NavRowState below), not the un-tintable Text-emoji this
  // replaced.
  static List<_NavItem> _buildItems(AppLocalizations l) => [
    _NavItem(Icons.home_rounded, l.drawerNavHome, '/home', 0),
    _NavItem(Icons.checklist_rounded, l.drawerNavChecklist, '/checklist', 1),
    _NavItem(Icons.mosque_rounded, l.drawerNavPrayer, '/prayer', 2),
    _NavItem(Icons.menu_book_rounded, l.drawerNavBooks, '/books', 3),
    _NavItem(Icons.bar_chart_rounded, l.drawerNavStatistics, '/statistics', 4),
    // Moved out of the bottom nav (main_shell.dart §C10: 6 destinations was
    // one over Material's guidance) — a reference/browse screen fits an
    // occasional-lookup drawer entry better than a persistent tab. '/asma'
    // isn't in shellRouteToTab below, so this pushes AsmaScreen as its own
    // route rather than switching a shell tab.
    _NavItem(Icons.auto_awesome_rounded, l.drawerNavAsma, '/asma', 5),
    _NavItem(
      Icons.emoji_events_rounded,
      l.drawerNavAchievements,
      '/achievements',
      6,
    ),
    _NavItem(Icons.person_rounded, l.drawerNavProfile, '/profile', 7),
    _NavItem(Icons.settings_rounded, l.drawerNavSettings, '/settings', 8),
  ];

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Animations are now computed dynamically in build to handle filtered items
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    final authStatus = ref.watch(authStatusProvider);
    final visibleItems = _buildItems(l).where((item) {
      if (item.route == '/profile') {
        return authStatus == AuthStatus.authenticated;
      }
      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      itemCount: visibleItems.length,
      itemBuilder: (_, i) {
        final item = visibleItems[i];

        // Dynamic animation for the current index
        final stagger = CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(
            (i * 0.1).clamp(0.0, 1.0),
            (i * 0.1 + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(stagger),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(-0.2, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _staggerCtrl,
                    curve: Interval(
                      (i * 0.1).clamp(0.0, 1.0),
                      (i * 0.1 + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            child: _NavRow(
              item: item,
              isActive: currentRoute == item.route,
              onTap: () {
                widget.onClose();
                // Routes embedded in the PageView shell → switch tab. '/asma'
                // deliberately isn't here — it moved out of the shell (see
                // _buildItems above) and falls through to the pushNamed
                // branch below like '/prayer'/'/books'/etc already did.
                const shellRouteToTab = <String, int>{
                  '/home': 0,
                  '/checklist': 2,
                  '/statistics': 3,
                  '/settings': 4,
                };
                final tabIdx = shellRouteToTab[item.route];
                if (tabIdx != null) {
                  Future.delayed(const Duration(milliseconds: 320), () {
                    ref.read(currentTabProvider.notifier).state = tabIdx;
                  });
                } else {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) {
                      Navigator.pushNamed(context, item.route);
                    }
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _NavRow extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavRow({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> with SingleTickerProviderStateMixin {
  late final AnimationController _hover;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _hover.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        _hover.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hover.reverse(),
      child: AnimatedBuilder(
        animation: _hover,
        builder: (_, _) => Transform.scale(
          scale: 1.0 - 0.02 * _hover.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              gradient: widget.isActive
                  ? LinearGradient(
                      colors: [
                        context.colors.gold.withValues(alpha: 0.15),
                        context.colors.teal.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: widget.isActive ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isActive
                    ? context.colors.gold.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: widget.isActive ? 22 : 0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [context.colors.gold, context.colors.teal],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: widget.isActive ? 8 : 0),

                Icon(
                  widget.item.icon,
                  size: 20,
                  color: widget.isActive
                      ? context.colors.gold
                      : context.colors.textPrimary.withValues(alpha: 0.75),
                  shadows: widget.isActive
                      ? [
                          Shadow(
                            color: context.colors.gold.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: context.typography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: widget.isActive
                          ? context.colors.gold
                          : context.colors.textPrimary.withValues(alpha: 0.75),
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),

                if (widget.isActive)
                  Icon(Icons.circle, size: 6, color: context.colors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── تذييل الـ Drawer ──
class _DrawerFooter extends ConsumerWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(height: 1, color: context.colors.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '❁',
                style: TextStyle(color: context.colors.gold, fontSize: 12),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.drawerFooterQuote,
                  style: context.typography.bodySmall.copyWith(
                    fontSize: 11,
                    color: context.colors.textDim,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '❁',
                style: TextStyle(color: context.colors.gold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            appInfo.formattedVersion,
            style: context.typography.caption.copyWith(
              fontSize: 10,
              color: context.colors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Menu Button (للـ AppBar) ──
class DrawerMenuButton extends ConsumerWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(drawerOpenProvider);

    return GestureDetector(
      onTap: () => _DrawerScaffoldState.of(context)._toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOpen
              ? context.colors.goldDim
              : context.colors.textPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isOpen
                ? context.colors.gold.withValues(alpha: 0.3)
                : context.colors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isOpen
                ? Icon(
                    Icons.close_rounded,
                    key: const ValueKey('close'),
                    size: 18,
                    color: context.colors.gold,
                  )
                : _HamburgerIcon(
                    key: const ValueKey('menu'),
                    color: context.colors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── أيقونة الـ Hamburger المتحركة ──
class _HamburgerIcon extends StatelessWidget {
  final Color color;
  const _HamburgerIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HLine(color: color, width: 16),
        const SizedBox(height: AppSpacing.xs),
        _HLine(color: color, width: 11),
        const SizedBox(height: AppSpacing.xs),
        _HLine(color: color, width: 14),
      ],
    );
  }
}

class _HLine extends StatelessWidget {
  final Color color;
  final double width;
  const _HLine({required this.color, required this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 1.8,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

// ─────────────────────────────────────────
//  BACKGROUND PAINTER
// ─────────────────────────────────────────
class _DrawerBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // نقاط هندسية
    final p = Paint()..color = const Color(0x0AC8A96E);
    for (double x = 16; x < size.width; x += 24) {
      for (double y = 16; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
    // خطوط مائلة
    final lp = Paint()
      ..color = const Color(0x06C8A96E)
      ..strokeWidth = 0.5;
    for (double x = -size.height; x < size.width + size.height; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
    }
    // glow أسفل يسار
    canvas.drawCircle(
      Offset(0, size.height),
      160,
      Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0x14C8A96E), Colors.transparent],
            ).createShader(
              Rect.fromCircle(center: Offset(0, size.height), radius: 160),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────
//  DATA CLASS
// ─────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label, route;
  final int index;
  const _NavItem(this.icon, this.label, this.route, this.index);
}

// ── حالة الاتصال والمزامنة ──
/// Connectivity + sync state, compact enough for one drawer row. Three
/// states only — offline always wins the display regardless of whether a
/// sync happens to be mid-flight, since it's the more actionable thing for
/// the user to know.
class _ConnectivityStatusRow extends ConsumerWidget {
  const _ConnectivityStatusRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Defaults to true before the stream's first emission so the row doesn't
    // flash "offline" on every cold start while connectivity_plus is still
    // reporting its initial status.
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final isSyncing = ref.watch(isSyncingProvider);

    final IconData icon;
    final Color color;
    final String label;
    if (!isOnline) {
      icon = Icons.cloud_off_rounded;
      color = context.colors.dangerText;
      label = l10n.drawerSyncOffline;
    } else if (isSyncing) {
      icon = Icons.sync_rounded;
      color = context.colors.tealText;
      label = l10n.syncStatusSyncing;
    } else {
      icon = Icons.cloud_done_rounded;
      color = context.colors.successText;
      label = l10n.drawerSyncSynced;
    }

    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.typography.caption.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  final VoidCallback onClose;
  const _LogoutButton({required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: () => _handleLogout(context, ref, onClose),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: context.colors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: context.colors.danger.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Text(
                '🚪',
                style: TextStyle(fontSize: 18, color: context.colors.danger),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                AppLocalizations.of(context)!.drawerLogoutButton,
                style: context.typography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: context.colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onClose,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: dCtx.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: dCtx.colors.border),
        ),
        title: Text(
          AppLocalizations.of(dCtx)!.drawerLogoutDialogTitle,
          style: dCtx.typography.headingMedium.copyWith(
            fontSize: 18,
            color: dCtx.colors.danger,
          ),
        ),
        content: Text(
          AppLocalizations.of(dCtx)!.drawerLogoutDialogBody,
          style: dCtx.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: dCtx.colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(
              AppLocalizations.of(dCtx)!.drawerLogoutDialogCancel,
              style: dCtx.typography.labelMedium.copyWith(
                fontSize: 13,
                color: dCtx.colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(
              AppLocalizations.of(dCtx)!.drawerLogoutDialogConfirm,
              style: dCtx.typography.labelMedium.copyWith(
                fontSize: 13,
                color: dCtx.colors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onClose(); // Close drawer
      ref.read(guestModeProvider.notifier).state = false;
      await ref.read(supabaseServiceProvider).signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }
}
