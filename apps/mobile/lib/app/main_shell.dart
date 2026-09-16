import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/features/checklist/screens/checklist_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/takwa_error_state.dart';
import '../core/providers/database_providers.dart';
import '../core/notifications/notifications_service.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/qiyam/presentation/screens/qiyam_dashboard_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../app/animated_drawer.dart';
import '../core/providers/auth_providers.dart';
import '../features/auth/presentation/pages/auth_choice_screen.dart';
import '../core/widgets/custom_pattern_background.dart';
import '../core/notifications/overlay_background_service.dart';

// ─────────────────────────────────────────
//  CURRENT TAB PROVIDER
// ─────────────────────────────────────────
final currentTabProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────
//  APP SHELL
// ─────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late List<AnimationController> _tabAnims;

  // Was 6 destinations (audit §C10: "exceeds Material's 3-5 destination
  // guidance; at 375pt that's 62pt per tab"). Names of Allah moved to the
  // drawer (_DrawerNav in animated_drawer.dart) — a reference/browse screen
  // fits better as an occasional lookup than a persistent bottom-nav slot,
  // unlike Qiyam which is a daily-tracked habit like the other four.
  // Emoji → real icons (audit §H2): emoji can't be tinted
  // (`Text('🌙', style: TextStyle(color: ...))` was a no-op — see the old
  // shadow-only "selected" hack this replaced) and render differently per
  // platform/OS version. Outlined for unselected, filled for selected —
  // the standard Material way to show selection without relying on color
  // in the (rare but real) case an icon renders in grayscale.
  static List<_TabInfo> _getTabs(AppLocalizations l10n) => [
    _TabInfo(Icons.home_outlined, Icons.home_rounded, l10n.bottomNavHome, 0),
    _TabInfo(
      Icons.nightlight_outlined,
      Icons.nightlight_rounded,
      l10n.bottomNavQiyam,
      1,
    ),
    _TabInfo(
      Icons.checklist_outlined,
      Icons.checklist_rounded,
      l10n.bottomNavMuhasaba,
      2,
    ),
    _TabInfo(
      Icons.bar_chart_outlined,
      Icons.bar_chart_rounded,
      l10n.bottomNavStatistics,
      3,
    ),
    _TabInfo(
      Icons.settings_outlined,
      Icons.settings_rounded,
      l10n.bottomNavSettings,
      4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.initialIndex);

    _tabAnims = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    // تفعيل التبويب الأول
    _tabAnims[widget.initialIndex].forward();

    // جدولة الإشعارات عند أول تشغيل (بعد استكمال التهيئة فقط)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // The PageController starts on initialIndex, but currentTabProvider
      // defaulted to 0 — so entering via e.g. Routes.settings showed the
      // Settings page with Home highlighted in the bottom nav, and the
      // ref.listen below never fired to correct it.
      if (ref.read(currentTabProvider) != widget.initialIndex) {
        ref.read(currentTabProvider.notifier).state = widget.initialIndex;
      }

      final done = await ref.read(onboardingDoneProvider.future);
      if (done) {
        _initializePostOnboardingServices();
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final a in _tabAnims) {
      a.dispose();
    }
    super.dispose();
  }

  void _switchTab(int idx, {bool updateProvider = true}) {
    final current = ref.read(currentTabProvider);
    // Use closer comparison for double values check from PageController if needed,
    // but round() is usually fine for discrete tab indexes.
    if (current == idx &&
        _pageCtrl.hasClients &&
        _pageCtrl.page?.round() == idx) {
      return;
    }

    HapticFeedback.selectionClick();

    // Animate out current, animate in new
    if (current != idx) {
      _tabAnims[current].reverse();
      _tabAnims[idx].forward();
    }

    if (updateProvider) {
      ref.read(currentTabProvider.notifier).state = idx;
    }

    if (_pageCtrl.hasClients && _pageCtrl.page?.round() != idx) {
      _pageCtrl.animateToPage(
        idx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _initializePostOnboardingServices() {
    ref.read(notificationsManagerProvider).scheduleAll();
    OverlayBackgroundService.start();
  }

  @override
  Widget build(BuildContext context) {
    // تشغيل الخدمات فور اكتمال التهيئة
    ref.listen(onboardingDoneProvider, (prev, next) {
      if (next.value == true && prev?.value != true) {
        _initializePostOnboardingServices();
      }
    });

    // Listen for external tab changes (e.g. from Home screen)
    ref.listen(currentTabProvider, (prev, next) {
      if (_pageCtrl.hasClients && _pageCtrl.page?.round() != next) {
        _switchTab(next, updateProvider: false);
      }
    });

    // Avoid rebuilding unnecessarily on each new frame
    final onboardAsync = ref.watch(onboardingDoneProvider);

    return onboardAsync.when(
      loading: () => const _SplashScreen(),
      // Was const _SplashScreen() — onboardingDoneProvider reads the local
      // DB, so a failure here (corrupt/unreadable database) used to strand
      // the user on a permanently-spinning splash with no way out. Now it
      // surfaces the failure with a way to retry the read.
      error: (_, _) => _SplashErrorScreen(
        onRetry: () => ref.invalidate(onboardingDoneProvider),
      ),
      data: (done) {
        if (!done) {
          return const OnboardingScreen();
        }

        // Check Auth Status
        final authStatus = ref.watch(authStatusProvider);
        if (authStatus == AuthStatus.unauthenticated) {
          return const AuthChoiceScreen();
        }

        return _buildShell();
      },
    );
  }

  Widget _buildShell() {
    // Robustness check: If tabs were added/removed during hot reload, re-initialize controllers
    const tabCount = 5;
    if (_tabAnims.length != tabCount) {
      for (final a in _tabAnims) {
        a.dispose();
      }
      _tabAnims = List.generate(
        tabCount,
        (i) => AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      );
      // Ensure current index is still valid
      final currentIdx = ref.read(currentTabProvider);
      if (currentIdx >= tabCount) {
        ref.read(currentTabProvider.notifier).state = 0;
      }
      _tabAnims[ref.read(currentTabProvider)].forward();
    }

    final currentIdx = ref.watch(currentTabProvider);

    return DrawerScaffold(
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(), // manual nav only
          children: const [
            HomeScreen(),
            QiyamDashboardScreen(),
            ChecklistScreen(),
            StatisticsScreen(),
            SettingsScreen(),
          ],
          onPageChanged: (idx) {
            // If swiped
            if (ref.read(currentTabProvider) != idx) {
              _tabAnims[ref.read(currentTabProvider)].reverse();
              _tabAnims[idx].forward();
              ref.read(currentTabProvider.notifier).state = idx;
            }
          },
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: currentIdx,
          tabs: _getTabs(AppLocalizations.of(context)!),
          onTap: _switchTab,
          tabAnims: _tabAnims,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  CUSTOM BOTTOM NAV
// ─────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_TabInfo> tabs;
  final void Function(int) onTap;
  final List<AnimationController> tabAnims;

  const _BottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
    required this.tabAnims,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: context.colors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle pattern background for BottomNav
          const Positioned.fill(
            child: ClipRect(
              child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final tab = tabs[i];
                  final isActive = currentIndex == i;
                  return Expanded(
                    // One coherent "button, label, selected" stop for a
                    // screen reader instead of the animated indicator,
                    // emoji, and label each being a separate stop.
                    child: Semantics(
                      label: tab.label,
                      button: true,
                      selected: isActive,
                      onTap: () => onTap(i),
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: AnimatedBuilder(
                          animation: tabAnims[i],
                          builder: (_, _) {
                            final t = tabAnims[i].value;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Improved Active indicator with glow
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: isActive ? 24 : 0,
                                  height: 3,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        context.colors.gold,
                                        context.colors.teal,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(1.5),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: context.colors.gold
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),

                                // Icon with scale bounce
                                Transform.scale(
                                  scale: isActive ? 1.0 + 0.15 * t : 1.0,
                                  child: Icon(
                                    isActive ? tab.activeIcon : tab.icon,
                                    size: 22,
                                    color: isActive
                                        ? context.colors.gold
                                        : context.colors.textDim,
                                    shadows: isActive
                                        ? [
                                            Shadow(
                                              color: context.colors.gold
                                                  .withValues(alpha: 0.6 * t),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Label
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: context.typography.caption.copyWith(
                                    // 11 is Material's smallest label size /
                                    // the iOS HIG floor — this used to be
                                    // 9.5, below both platforms' minimums.
                                    fontSize: 11,
                                    color: isActive
                                        ? context.colors.gold
                                        : context.colors.textDim,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    letterSpacing: isActive ? 0.2 : 0,
                                  ),
                                  child: Text(
                                    tab.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────
//  SPLASH ERROR SCREEN
// ─────────────────────────────────────────
/// Shown in place of [_SplashScreen] when onboardingDoneProvider — the very
/// first read this app does — fails. Without this the user was stuck on a
/// spinning splash forever with no signal anything was wrong and no way
/// back in.
class _SplashErrorScreen extends StatelessWidget {
  const _SplashErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: TakwaErrorState(onRetry: onRetry),
    );
  }
}

// ─────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(
                        3,
                        (i) => Container(
                          width: 100 - i * 20.0,
                          height: 100 - i * 20.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.gold.withValues(alpha: 0.3 - i * 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const Text('🌙', style: TextStyle(fontSize: 32)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l10n.authChoiceAppName,
                  style: context.typography.displayMedium.copyWith(
                    fontSize: 32,
                    color: context.colors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.splashQuote,
                  style: context.typography.quranicVerse.copyWith(
                    fontSize: 14,
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
//  DATA CLASSES
// ─────────────────────────────────────────
class _TabInfo {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _TabInfo(this.icon, this.activeIcon, this.label, this.index);
}
