import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:takwa/app/animated_drawer.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/app/main_shell.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/utils/hijri_display.dart';
import 'package:takwa/core/utils/prayer_display.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/books/data/books_data.dart';
import 'package:takwa/features/books/providers/books_reading_provider.dart';
import 'package:takwa/features/prayer/presentation/screens/prayer_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Kept alive because this is one of six PageView tabs in MainShell: without
  // this, PageView disposes an off-screen tab's State once it scrolls past
  // the cache extent, so switching Home -> Statistics -> Home lost scroll
  // position and re-ran the 1.5s entry-stagger animation on every return.
  @override
  bool get wantKeepAlive => true;
  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;
  final _scrollCtrl = ScrollController();
  // ValueNotifier, not a plain bool behind setState: this flips at most
  // twice per scroll session (crossing the 70px threshold each way), but
  // setState() on _HomeScreenState re-ran the build() that lays out all 11
  // sections below just to update the one AnimatedOpacity that actually
  // depends on it. A ValueListenableBuilder around only that AnimatedOpacity
  // (see the SliverAppBar title below) rebuilds just that subtree instead.
  final _headerCollapsed = ValueNotifier<bool>(false);
  static const _sectionCount = 11;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyRecordDaoProvider).getOrCreateToday();
      _staggerCtrl.forward();
      // Auto-start the background overlay service (adhkar + adhan)
      OverlayBackgroundService.start();
    });
  }

  void _initAnimations() {
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnims = List.generate(_sectionCount, (i) {
      final s = i * 0.08, e = (s + 0.3).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _slideAnims = List.generate(_sectionCount, (i) {
      final s = i * 0.08, e = (s + 0.3).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  void _onScroll() {
    // No setState: ValueNotifier notifies its own listener directly, which
    // is exactly the one small AnimatedOpacity that needs to know.
    _headerCollapsed.value = _scrollCtrl.offset > 70;
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _scrollCtrl.dispose();
    _headerCollapsed.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final todayAsync = ref.watch(todayRecordProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final prayerState = ref.watch(prayerScreenProvider);
    final style = AdaptiveStyle(context, isRamadan);

    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${hijriMonthName(AppLocalizations.of(context)!, hijri.hMonth)} ${hijri.hYear}';
    final languageCode = Localizations.localeOf(context).languageCode;
    final miladi = DateFormat(
      languageCode == 'ar' ? 'EEEE، d MMMM yyyy' : 'EEEE, d MMMM yyyy',
      languageCode,
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: style.bg,
      body: Stack(
        children: [
          // ── Dynamic Background ──
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SliverAppBar ──
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 130,
                collapsedHeight: 64,
                pinned: true,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: DrawerMenuButton(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _anim(
                    0,
                    _HomeHeader(
                      hijriStr: hijriStr,
                      miladiStr: miladi,
                      style: style,
                      isRamadan: isRamadan,
                    ),
                  ),
                  // ValueListenableBuilder instead of reading
                  // _headerCollapsed straight off the State: this way only
                  // this small subtree rebuilds when it flips, not the
                  // whole 11-section build() below.
                  title: ValueListenableBuilder<bool>(
                    valueListenable: _headerCollapsed,
                    // Static — depends on hijriStr/style, not on the
                    // collapsed flag — so it's hoisted out as `child`
                    // rather than rebuilt on every flip.
                    child: Text(
                      hijriStr,
                      // amiri()'s default weight is bold; bodyMedium's
                      // isn't, so it's passed explicitly to preserve the
                      // original rendering.
                      style: style.bodyMedium(
                        color: style.gold,
                        weight: FontWeight.bold,
                      ),
                    ),
                    builder: (context, collapsed, child) => AnimatedOpacity(
                      opacity: collapsed ? 1 : 0,
                      duration: AppMotion.fast,
                      child: child,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.xs),

                    // ① Ramadan Banner
                    if (hijri.hMonth == 9 || isRamadan)
                      _anim(
                        0,
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RamadanBanner(
                            style: style,
                            day: hijri.hDay,
                            isRamadan: isRamadan,
                          ),
                        ),
                      ),

                    // ② Next Prayer Card
                    if (prayerState.next != null)
                      _anim(
                        1,
                        _NextPrayerCardMerged(
                          style: style,
                          prayerState: prayerState,
                        ),
                      ),
                    if (prayerState.next != null) const SizedBox(height: 14),

                    // ③ Prayer Times Mosque Section
                    if (prayerState.prayers.isNotEmpty)
                      _anim(
                        2,
                        _MosquePrayerSection(
                          style: style,
                          prayers: prayerState.prayers,
                          currentKey: prayerState.next?.name ?? '',
                        ),
                      ),
                    if (prayerState.prayers.isNotEmpty)
                      const SizedBox(height: 14),

                    // ④ Taqwa Ring
                    _anim(
                      3,
                      todayAsync.when(
                        loading: () => _Skeleton(style: style, height: 110),
                        error: (_, _) => TakwaErrorState(
                          compact: true,
                          onRetry: () => ref.invalidate(todayRecordProvider),
                        ),
                        data: (r) => _TaqwaSectionMerged(
                          record: r,
                          streakAsync: streakAsync,
                          style: style,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ⑤ Quick Ibadah Grid
                    _anim(
                      4,
                      todayAsync.when(
                        loading: () => _Skeleton(style: style, height: 180),
                        error: (_, _) => TakwaErrorState(
                          compact: true,
                          onRetry: () => ref.invalidate(todayRecordProvider),
                        ),
                        data: (r) =>
                            _QuickIbadahGridMerged(record: r, style: style),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ⑥ Features Row
                    _anim(5, _FeatureRow(style: style)),
                    const SizedBox(height: 14),

                    // ⑦ Books Section
                    _anim(6, _BooksSection(style: style)),
                    const SizedBox(height: 14),

                    // ⑧ Verse Card
                    _anim(
                      7,
                      _VerseCardMerged(style: style, isRamadan: isRamadan),
                    ),
                    const SizedBox(height: 14),

                    // ⑨ Ramadan Iftar
                    if (isRamadan)
                      _anim(8, _RamadanIftar(style: style, hijri: hijri)),

                    // ⑩ Daily Dhikr
                    _anim(9, _DailyDhikrCard(style: style)),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final String hijriStr, miladiStr;
  final AdaptiveStyle style;
  final bool isRamadan;
  const _HomeHeader({
    required this.hijriStr,
    required this.miladiStr,
    required this.style,
    required this.isRamadan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = DateTime.now().hour;
    final g = h < 12
        ? l10n.homeGreetingMorning
        : h < 17
        ? l10n.homeGreetingAfternoon
        : l10n.homeGreetingEvening;

    return Container(
      // Was a hardcoded `47` guessing the status-bar height (audit §M3) —
      // wrong on any device whose status bar isn't ~37dp (punch-hole
      // cameras, tall notches, landscape). This isn't wrapped in a
      // SafeArea, so MediaQuery's own top inset is the correct value.
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 10,
        16,
        10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            style.gold.withValues(alpha: isRamadan ? 0.15 : 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40), // Space for Drawer button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hijriStr, style: style.amiri(19)),
                Text(miladiStr, style: style.naskh(11, color: style.textSec)),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.goldDim,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: style.gold.withValues(alpha: 0.2)),
                ),
                child: Text(g, style: style.naskh(11, color: style.goldLight)),
              ),
              const SizedBox(width: AppSpacing.sm),
              const RamadanToggle(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  RAMADAN BANNER
// ─────────────────────────────────────────
class _RamadanBanner extends StatefulWidget {
  final AdaptiveStyle style;
  final int day;
  final bool isRamadan;
  const _RamadanBanner({
    required this.style,
    required this.day,
    required this.isRamadan,
  });

  @override
  State<_RamadanBanner> createState() => _RamadanBannerState();
}

class _RamadanBannerState extends State<_RamadanBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative banner glow — respects reduce-motion.
    _ctrl.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              s.gold.withValues(alpha: 0.15 + 0.05 * _ctrl.value),
              s.success.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: s.gold.withValues(alpha: 0.25 + 0.15 * _ctrl.value),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: s.gold.withValues(alpha: 0.08 * _ctrl.value),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Text('🌙', style: TextStyle(fontSize: 28, color: s.goldLight)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeRamadanBannerTitle,
                    // headingMedium's default weight is already bold,
                    // matching amiri()'s — no explicit weight needed.
                    style: s.headingMedium(color: s.goldLight),
                  ),
                  Text(
                    l10n.homeRamadanBannerSubtitle(widget.day),
                    style: s.naskh(11, color: s.textSec),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${30 - widget.day}',
                  // headingLarge's default weight is already bold,
                  // matching amiri()'s — no explicit weight needed.
                  style: s.headingLarge(color: s.gold),
                ),
                Text(
                  l10n.homeRamadanDaysRemaining,
                  style: s.caption(color: s.textSec, bodyFont: true),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  NEXT PRAYER CARD MERGED
// ─────────────────────────────────────────
class _NextPrayerCardMerged extends StatefulWidget {
  final AdaptiveStyle style;
  final PrayerScreenState prayerState;
  const _NextPrayerCardMerged({required this.style, required this.prayerState});

  @override
  State<_NextPrayerCardMerged> createState() => _NextPrayerCardMergedState();
}

class _NextPrayerCardMergedState extends State<_NextPrayerCardMerged>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // repeat() is started from didChangeDependencies below, gated on
    // reduce-motion.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Purely decorative breathing pulse — respects reduce-motion.
    _pulse.repeatUnlessReducedMotion(context, reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final l10n = AppLocalizations.of(context)!;
    final next = widget.prayerState.next!;
    final diff = widget.prayerState.remaining ?? const Duration();
    String countdown;
    if (diff.isNegative || diff.inSeconds == 0) {
      countdown = l10n.homeCountdownNow;
    } else {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      countdown = h > 0
          ? l10n.homeCountdownHoursMinutes(h, m)
          : l10n.homeCountdownMinutesOnly(m);
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              s.gold.withValues(alpha: 0.15 + 0.05 * _pulse.value),
              s.teal.withValues(alpha: 0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: s.gold.withValues(alpha: 0.2 + 0.1 * _pulse.value),
          ),
          boxShadow: [
            BoxShadow(
              color: s.gold.withValues(alpha: 0.06 + 0.06 * _pulse.value),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: s.goldDim,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: s.gold.withValues(alpha: 0.2 + 0.15 * _pulse.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: s.gold.withValues(alpha: 0.12 * _pulse.value),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  prayerEmoji(next.name),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNextPrayerLabel,
                    style: s.caption(color: s.textSec, bodyFont: true),
                  ),
                  Text(
                    l10n.checklistPrayerSheetTitle(
                      prayerLocalizedName(l10n, next.name),
                    ),
                    style: s.amiri(19),
                  ),
                  Text(
                    DateFormat('HH:mm').format(next.time),
                    style: s.caption(color: s.textSec, bodyFont: true),
                  ),
                ],
              ),
            ),
            TakwaTappable(
              onTap: () => Navigator.pushNamed(context, '/prayer'),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              // Inline chip alongside the prayer name/time in this Row —
              // 48dp here would blow out the row's height, not the tap
              // target.
              minTapSize: null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: s.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: s.gold.withValues(alpha: 0.25)),
                ),
                child: Text(
                  countdown,
                  style: s.naskh(
                    11,
                    color: widget.prayerState.isIqamaPhase
                        ? Colors.redAccent
                        : s.goldLight,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  MOSQUE PRAYER SECTION (REDESIGNED)
// ─────────────────────────────────────────
class _MosquePrayerSection extends StatelessWidget {
  final List<dynamic> prayers;
  final String currentKey;
  final AdaptiveStyle style;
  const _MosquePrayerSection({
    required this.prayers,
    required this.currentKey,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.homePrayerTimesTitle,
                style: style.headingLarge(
                  color: style.gold,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 1,
                  color: style.gold.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
        ClipPath(
          clipper: MosqueClipper(),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: style.gold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/SL-020520-27660-18.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          style.bg.withValues(alpha: 0.4),
                          style.bg.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pattern Overlay
                const Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPatternBackground(
                      pattern: BackgroundPattern.adhkar,
                    ),
                  ),
                ),
                // Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: prayers.length,
                        separatorBuilder: (_, i) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final prayer = prayers[i];
                          final isActive = prayer.name == currentKey;
                          return _MihrabPrayerChip(
                            prayer: prayer,
                            isActive: isActive,
                            style: style,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MihrabPrayerChip extends StatelessWidget {
  final dynamic prayer;
  final bool isActive;
  final AdaptiveStyle style;
  const _MihrabPrayerChip({
    required this.prayer,
    required this.isActive,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = prayerEmoji(prayer.name);
    final name = prayerLocalizedName(
      AppLocalizations.of(context)!,
      prayer.name,
    );
    final timeStr = DateFormat('HH:mm').format(prayer.time);

    return TakwaTappable(
      onTap: () => Navigator.pushNamed(context, '/prayer'),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(35),
        topRight: Radius.circular(35),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 70,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive
              ? style.gold.withValues(alpha: 0.15)
              : style.card.withValues(alpha: 0.4),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(
            color: isActive
                ? style.gold.withValues(alpha: 0.6)
                : style.border.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: style.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.sm),
            AnimatedScale(
              scale: isActive ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const Spacer(),
            Text(
              name,
              style: style.naskh(
                11,
                color: isActive ? style.gold : style.textSec,
                weight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              // amiri()'s default weight is bold; labelMedium's isn't, so
              // it's passed explicitly to preserve the original rendering.
              style: style.labelMedium(
                color: isActive
                    ? style.goldLight
                    : style.textSec.withValues(alpha: 0.8),
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
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

    path.moveTo(0, h); // Start bottom left
    path.lineTo(0, h * 0.4); // Left wall

    // Left shoulder
    path.quadraticBezierTo(w * 0.05, h * 0.35, w * 0.15, h * 0.35);

    // Left Minaret/Curve
    path.lineTo(w * 0.25, h * 0.35);
    path.quadraticBezierTo(w * 0.3, h * 0.15, w * 0.35, h * 0.15);

    // Main Dome
    path.lineTo(w * 0.4, h * 0.15);
    path.quadraticBezierTo(w * 0.5, 0, w * 0.6, h * 0.15);
    path.lineTo(w * 0.65, h * 0.15);

    // Right Minaret/Curve
    path.quadraticBezierTo(w * 0.7, h * 0.15, w * 0.75, h * 0.35);
    path.lineTo(w * 0.85, h * 0.35);

    // Right shoulder
    path.quadraticBezierTo(w * 0.95, h * 0.35, w, h * 0.4);

    path.lineTo(w, h); // Right wall
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────
//  TAQWA SECTION MERGED
// ─────────────────────────────────────────
class _TaqwaSectionMerged extends ConsumerWidget {
  final DailyRecord? record;
  final AsyncValue<int> streakAsync;
  final AdaptiveStyle style;
  const _TaqwaSectionMerged({
    required this.record,
    required this.streakAsync,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = style;
    final l10n = AppLocalizations.of(context)!;
    final net = record?.netPoints ?? 0;
    final pct = (net / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: s.cardDeco,
      child: Row(
        children: [
          _RingWidget(progress: pct, style: s),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _msg(l10n, pct),
                  // amiri()'s defaults (bold, gold) preserved explicitly —
                  // labelLarge's own defaults differ on both.
                  style: s.labelLarge(color: s.gold, weight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.homeIbadahProgressLabel((pct * 10).round()),
                  style: s.naskh(11, color: s.textSec),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: s.goldDim,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: s.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _level(l10n, net),
                        style: s.naskh(11, color: s.gold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/achievements'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: s.gold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_outlined,
                          size: 16,
                          color: s.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                streakAsync.when(
                  loading: () => const SizedBox(height: 22),
                  error: (_, _) => TakwaInlineError(
                    height: 22,
                    onRetry: () => ref.invalidate(currentStreakProvider),
                  ),
                  data: (n) => n > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: s.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: s.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n.homeStreakDaysLabel(n),
                                style: s.naskh(11, color: s.success),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _level(AppLocalizations l10n, int p) {
    if (p >= 600) return l10n.homeLevelMutaqi;
    if (p >= 300) return l10n.homeLevelMujahid;
    if (p >= 100) return l10n.homeLevelSalik;
    return l10n.homeLevelMubtadi;
  }

  String _msg(AppLocalizations l10n, double p) {
    if (p >= .9) return l10n.homeProgressMsgComplete;
    if (p >= .6) return l10n.homeProgressMsgGreat;
    if (p >= .3) return l10n.homeProgressMsgGood;
    return l10n.homeProgressMsgStart;
  }
}

class _RingWidget extends StatefulWidget {
  final double progress;
  final AdaptiveStyle style;
  const _RingWidget({required this.progress, required this.style});

  @override
  State<_RingWidget> createState() => _RingWidgetState();
}

class _RingWidgetState extends State<_RingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => SizedBox(
        width: 88,
        height: 88,
        child: CustomPaint(
          painter: _RingPainterV2(
            progress: _anim.value,
            gold: widget.style.gold,
            teal: widget.style.teal,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_anim.value * 100).round()}%',
                  style: widget.style
                      .naskh(
                        17,
                        color: widget.style.gold,
                        weight: FontWeight.w700,
                      )
                      .copyWith(height: 1),
                ),
                Text(
                  AppLocalizations.of(context)!.homeRingTodayLabel,
                  style: widget.style.caption(
                    color: widget.style.textSec,
                    bodyFont: true,
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

class _RingPainterV2 extends CustomPainter {
  final double progress;
  final Color gold, teal;
  _RingPainterV2({
    required this.progress,
    required this.gold,
    required this.teal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - 10) / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = gold.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [gold, teal, gold],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    final a = -math.pi / 2 + 2 * math.pi * progress;
    final dx = c.dx + r * math.cos(a), dy = c.dy + r * math.sin(a);
    canvas.drawCircle(
      Offset(dx, dy),
      5,
      Paint()
        ..color = gold
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(Offset(dx, dy), 3, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(_RingPainterV2 o) => o.progress != progress;
}

// ─────────────────────────────────────────
//  QUICK IBADAH GRID MERGED
// ─────────────────────────────────────────
class _QuickIbadahGridMerged extends ConsumerWidget {
  final DailyRecord? record;
  final AdaptiveStyle style;
  const _QuickIbadahGridMerged({required this.record, required this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = style;
    final l10n = AppLocalizations.of(context)!;
    // `id` is a stable routing key, independent of the localized `label` —
    // the onTap logic used to switch on the (Arabic-only) label text
    // directly, which would silently break navigation the moment the UI
    // language changed.
    final items = [
      (
        '🌅',
        'fajr',
        l10n.prayerFajr,
        record?.fajrStatus == PrayerStatus.performed,
      ),
      ('📖', 'quran', l10n.labelQuran, (record?.quranPages ?? 0) > 0),
      (
        '☀️',
        'dhuhr',
        l10n.prayerDhuhr,
        record?.dhuhrStatus == PrayerStatus.performed,
      ),
      (
        '🌤',
        'asr',
        l10n.prayerAsr,
        record?.asrStatus == PrayerStatus.performed,
      ),
      (
        '⭐',
        'adhkar',
        l10n.labelAdhkar,
        (record?.morningAdhkar ?? false) && (record?.eveningAdhkar ?? false),
      ),
      ('🌌', 'qiyam', l10n.ibadahQiyamLabel, record?.nightPrayer ?? false),
    ];
    return Column(
      children: [
        Row(
          children: [
            Text(
              l10n.homeTodayIbadahTitle,
              // amiri()'s defaults (bold, gold) preserved explicitly —
              // labelLarge's own defaults differ on both.
              style: s.headingLarge(color: s.gold, weight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                height: 1,
                color: s.border.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TakwaTappable(
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                ref.read(currentTabProvider.notifier).state = 2;
              },
              borderRadius: BorderRadius.zero,
              minTapSize: null,
              child: Text(
                l10n.homeViewAllLabel,
                style: s.naskh(11, color: s.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: items
              .map(
                (item) => _IbadahChipMerged(
                  emoji: item.$1,
                  id: item.$2,
                  label: item.$3,
                  done: item.$4,
                  style: s,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _IbadahChipMerged extends ConsumerWidget {
  final String emoji, id, label;
  final bool done;
  final AdaptiveStyle style;
  const _IbadahChipMerged({
    required this.emoji,
    required this.id,
    required this.label,
    required this.done,
    required this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = style;
    return TakwaTappable(
      onTap: () {
        switch (id) {
          case 'adhkar':
            Navigator.pushNamed(context, '/adhkar');
          case 'quran':
            Navigator.pushNamed(context, '/quran');
          case 'qiyam':
            HapticFeedback.mediumImpact();
            ref.read(currentTabProvider.notifier).state = 1;
          default:
            HapticFeedback.lightImpact();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: done
              ? LinearGradient(
                  colors: [
                    s.teal.withValues(alpha: 0.12),
                    s.success.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: done ? null : s.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? s.success.withValues(alpha: 0.35) : s.border,
          ),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: s.success.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                if (done)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: style.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: s.card, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: s.caption(
                  bodyFont: true,
                  color: done ? s.success : s.textSec,
                  weight: done ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  FEATURE ROW
// ─────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final AdaptiveStyle style;
  const _FeatureRow({required this.style});

  static List<(String, String, String)> _features(AppLocalizations l10n) => [
    ('🕌', l10n.homeFeaturePrayerTimes, '/prayer'),
    ('📖', l10n.labelQuran, '/quran'),
    ('🧭', l10n.homeFeatureQibla, '/qibla'),
    ('📿', l10n.labelAdhkar, '/adhkar'),
    ('🤲', l10n.homeFeatureDuas, '/duas'),
    ('✨', l10n.homeFeatureMisbaha, '/misbaha'),
    ('🕋', l10n.homeFeatureMosques, '/mosques'),
    ('📊', l10n.homeFeatureStatistics, '/statistics'),
    ('🏆', l10n.homeFeatureAchievements, '/achievements'),
    ('🔔', l10n.homeFeatureReminders, '/reminders'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = style;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.homeFeaturesTitle,
              style: s.headingLarge(color: s.gold, weight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(height: 1, color: s.gold.withValues(alpha: 0.2)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
          children: _features(
            l10n,
          ).map((f) => _FeatureItem(f: f, style: s)).toList(),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final (String, String, String) f;
  final AdaptiveStyle style;
  const _FeatureItem({required this.f, required this.style});

  @override
  Widget build(BuildContext context) {
    final s = style;
    return TakwaTappable(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pushNamed(context, f.$3);
      },
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              s.gold.withValues(alpha: 0.12),
              s.teal.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: s.gold.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: s.gold.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: s.gold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Text(f.$1, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                f.$2,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                // Both 9.0 and 8.5 were below the 12px accessibility
                // floor — caption is the scale's smallest role, at 12.
                style: s
                    .caption(
                      bodyFont: true,
                      color: s.text,
                      weight: FontWeight.w600,
                    )
                    .copyWith(height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  VERSE CARD MERGED
// ─────────────────────────────────────────
class _VerseCardMerged extends StatelessWidget {
  final AdaptiveStyle style;
  final bool isRamadan;
  static const _verses = [
    ('﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا ﴾', 'الطلاق: ٢'),
    ('﴿ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ ﴾', 'البقرة: ١٥٣'),
    ('﴿ فَاذْكُرُونِي أَذْكُرْكُمْ ﴾', 'البقرة: ١٥٢'),
    ('﴿ شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ ﴾', 'البقرة: ١٨٥'),
    ('﴿ إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ ﴾', 'التوبة: ١٢٠'),
    ('﴿ وَبَشِّرِ الصَّابِرِينَ ﴾', 'البقرة: ١٥٥'),
  ];

  const _VerseCardMerged({required this.style, required this.isRamadan});

  @override
  Widget build(BuildContext context) {
    final s = style;
    final idx = DateTime.now().day % _verses.length;
    final verse = _verses[isRamadan ? 3 : idx];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            s.gold.withValues(alpha: isRamadan ? 0.18 : 0.1),
            s.teal.withValues(alpha: isRamadan ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: s.gold.withValues(alpha: isRamadan ? 0.3 : 0.18),
        ),
        boxShadow: isRamadan
            ? [BoxShadow(color: s.gold.withValues(alpha: 0.08), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: s.gold.withValues(alpha: 0.3),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('❁', style: TextStyle(color: s.gold, fontSize: 17)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 24,
                height: 1,
                color: s.gold.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            verse.$1,
            textAlign: TextAlign.center,
            style: s
                .amiri(
                  isRamadan ? 22 : 20,
                  color: s.goldLight,
                  weight: FontWeight.w400,
                )
                .copyWith(height: 2.0),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isRamadan
                ? verse.$2
                : AppLocalizations.of(context)!.homeVerseOfDayLabel(verse.$2),
            style: s.caption(color: s.textSec, bodyFont: true),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  RAMADAN IFTAR COUNTDOWN
// ─────────────────────────────────────────
class _RamadanIftar extends ConsumerStatefulWidget {
  final AdaptiveStyle style;
  final HijriCalendar hijri;
  const _RamadanIftar({required this.style, required this.hijri});

  @override
  ConsumerState<_RamadanIftar> createState() => _RamadanIftarState();
}

class _RamadanIftarState extends ConsumerState<_RamadanIftar> {
  // Kept as raw Durations rather than pre-formatted strings: formatting
  // needs AppLocalizations, and that can't be looked up from initState()
  // (no Localizations ancestor is wired up for dependency tracking yet at
  // that point) — so the l10n-aware text is built once, in build().
  Duration _iftarRemaining = Duration.zero;
  Duration _suhoorRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    // In a real app, use actual prayer times
    final iftar = DateTime(now.year, now.month, now.day, 18, 30);
    final suhoor = DateTime(now.year, now.month, now.day + 1, 4, 15);

    setState(() {
      _iftarRemaining = iftar.difference(now);
      _suhoorRemaining = suhoor.difference(now);
    });
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  String _fmt(AppLocalizations l10n, Duration d) {
    if (d.isNegative) return l10n.homeCountdownPassed;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final l10n = AppLocalizations.of(context)!;
    final iftarCountdown = _fmt(l10n, _iftarRemaining);
    final suhoorCountdown = _fmt(l10n, _suhoorRemaining);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                l10n.homeRamadanTimesTitle,
                style: s.labelLarge(color: s.gold, weight: FontWeight.bold),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 1,
                  color: s.gold.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _IftarCard(
                label: l10n.homeIftarLabel,
                countdown: iftarCountdown,
                icon: '🌙',
                color: s.gold,
                style: s,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _IftarCard(
                label: l10n.homeSuhoorLabel,
                countdown: suhoorCountdown,
                icon: '🌅',
                color: s.success,
                style: s,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _IftarCard extends StatelessWidget {
  final String label, countdown, icon;
  final Color color;
  final AdaptiveStyle style;
  const _IftarCard({
    required this.label,
    required this.countdown,
    required this.icon,
    required this.color,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: AppSpacing.md,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.05)],
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8),
      ],
    ),
    child: Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(label, style: style.naskh(11, color: style.textSec)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          countdown,
          style: style.bodyLarge(
            bodyFont: true,
            color: color,
            weight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
//  DAILY DHIKR CARD
// ─────────────────────────────────────────
class _DailyDhikrCard extends StatelessWidget {
  final AdaptiveStyle style;
  const _DailyDhikrCard({required this.style});

  static const _dhikrs = [
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
  ];

  @override
  Widget build(BuildContext context) {
    final s = style;
    final idx = DateTime.now().hour % _dhikrs.length;
    return TakwaTappable(
      onTap: () => Navigator.pushNamed(context, '/adhkar'),
      borderRadius: AppRadius.card,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: s.cardDeco,
        child: Row(
          children: [
            const Text('📿', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.homeDailyDhikrLabel,
                    style: s.caption(color: s.textSec, bodyFont: true),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _dhikrs[idx],
                    style: s
                        .bodyMedium(color: s.text, weight: FontWeight.w400)
                        .copyWith(height: 1.8),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
              color: s.textSec,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SKELETON
// ─────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  final AdaptiveStyle style;
  final double height;
  const _Skeleton({required this.style, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: style.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: style.border),
    ),
    child: const Center(child: TakwaLoadingIndicator(size: 24)),
  );
}

// ─────────────────────────────────────────
//  BOOKS SECTION (REDESIGNED)
// ─────────────────────────────────────────
class _BooksSection extends ConsumerWidget {
  final AdaptiveStyle style;
  const _BooksSection({required this.style});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksListProvider);
    final s = style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, bottom: 12),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.homeBooksLibraryTitle,
                style: s.headingLarge(color: s.gold, weight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: s.gold.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 10),
              TakwaTappable(
                onTap: () => Navigator.pushNamed(context, '/books'),
                borderRadius: BorderRadius.zero,
                minTapSize: null,
                child: Text(
                  AppLocalizations.of(context)!.homeViewAllLabel,
                  style: s.naskh(11, color: s.goldLight),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: booksAsync.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, __) => _Skeleton(style: s, height: 190),
            ),
            error: (_, __) => TakwaErrorState(
              compact: true,
              onRetry: () => ref.invalidate(booksListProvider),
            ),
            data: (books) => ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _BookCard(book: books[i], style: s),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final IslamicBook book;
  final AdaptiveStyle style;
  const _BookCard({required this.book, required this.style});

  @override
  Widget build(BuildContext context) {
    final s = style;
    final color = Color(int.parse(book.coverColor));

    return TakwaTappable(
      onTap: () =>
          Navigator.pushNamed(context, '/books/chapter', arguments: book),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.8),
                      Color(int.parse(book.coverColor2)).withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (book.coverUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    // Glassmorphism Overlay for Emoji info if no cover
                    if (book.coverUrl == null)
                      Center(
                        child: Text(
                          book.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          book.categoryLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Book Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.titleAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: s.labelMedium(
                        color: s.text,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.authorAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: s.caption(color: s.textSec, bodyFont: true),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 10, color: s.gold),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.homeMinutesLabel(book.estimatedReadingMinutes),
                          // 8px was below the 12px accessibility floor —
                          // caption is the scale's smallest role, at 12.
                          style: s.caption(color: s.textDim, bodyFont: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
