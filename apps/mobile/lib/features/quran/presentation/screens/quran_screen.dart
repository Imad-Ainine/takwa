import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import '../../data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import 'create_khatma_screen.dart';
import 'khatma_history_screen.dart';
import 'khatma_progress_screen.dart';
// import 'khatma_settings_screen.dart';
import 'ai_memorize_screen.dart';
import 'quran_reader_screen.dart';
import 'free_reading_screen.dart';
import 'package:takwa/l10n/app_localizations.dart';

// Styles are handled by AdaptiveStyle

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});
  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final khatma = ref.watch(khatmaExProvider);
    final dailyVerse = ref.watch(dailyVerseProvider);

    return Scaffold(
      backgroundColor: style.bg,
      body: Stack(
        children: [
          const CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          FadeTransition(
            opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar(style)),
                SliverToBoxAdapter(child: _buildDatePill(style)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverToBoxAdapter(child: _buildVerseCard(dailyVerse, style)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(child: _buildKhatmaButton(khatma, style)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(child: _buildFreeReadingButton(style)),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(child: _buildGrid(style)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AdaptiveStyle style) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Row(
          children: [
            // History icon
            const CustomLeadingButton(),
            const Spacer(),
            // Center: title
            Column(
              children: [
                Text(
                  l10n.quranScreenKhatmaLabel,
                  style: style.amiri(28, color: style.text),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: style.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: style.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    l10n.quranScreenTitle,
                    style: style.amiri(13, color: style.gold),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Quran icon button — jumps straight to the last reading
            // checkpoint (quranLastReadProvider), same position the "last
            // read" banner on the Free Reading screen opens. Previously
            // just a decorative Container with no GestureDetector at all —
            // tapping it did nothing.
            TakwaTappable(
              onTap: () => _goToLastRead(l10n),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: style.gold.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: style.gold,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, AdaptiveStyle style) =>
      TakwaTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: style.text.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: style.border),
          ),
          child: Icon(icon, color: style.textSec, size: 22),
        ),
      );

  Widget _buildDatePill(AdaptiveStyle style) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: style.text.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: style.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, color: style.textDim, size: 14),
            const SizedBox(width: AppSpacing.sm),
            Text(
              hijriDateString(),
              style: style.naskh(13, color: style.textSec),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseCard(Map<String, dynamic> verse, AdaptiveStyle style) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                _surahChip(verse['surahName'] as String, style),
                const Spacer(),
                _tinyBtn(Icons.share_rounded, () => _shareVerse(verse), style),
                const SizedBox(width: 6),
                _tinyBtn(
                  Icons.refresh_rounded,
                  () => ref.read(dailyVerseRefreshProvider.notifier).state++,
                  style,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: AppSpacing.md,
            ),
            child: Text(
              verse['text'] as String,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: style.amiri(20, color: style.text, height: 2.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(
              children: [
                TakwaTappable(
                  onTap: () => _push(
                    QuranReaderScreen(
                      initialPage: verse['page'] as int,
                      initialAyahUQNumber: verse['ayahUQNumber'] as int,
                    ),
                  ),
                  // Inline alongside the Spacer()+badge below.
                  minTapSize: null,
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    color: style.textDim,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: style.text.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.quranScreenAyahLabel(
                          localizedNumeral(context, verse['ayahNumber'] as int),
                        ),
                        style: style.amiri(13, color: style.textSec),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '»»',
                        style: TextStyle(color: style.textDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surahChip(String name, AdaptiveStyle style) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 5),
    decoration: BoxDecoration(
      color: style.gold.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: style.gold.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, color: style.gold, size: 12),
        const SizedBox(width: 5),
        Text(
          name,
          style: style.amiri(14, color: style.gold, weight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _tinyBtn(IconData icon, VoidCallback onTap, AdaptiveStyle style) =>
      TakwaTappable(
        onTap: onTap,
        minTapSize: null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: style.text.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: style.textSec, size: 16),
        ),
      );

  Widget _buildKhatmaButton(KhatmaSessionEx? khatma, AdaptiveStyle style) {
    final l10n = AppLocalizations.of(context)!;
    final hasActive = khatma != null && khatma.isActive;
    // The margin sits on this outer Padding, not the Container below — see
    // quran_widgets.dart's KhatmaActionCard for why: TakwaTappable's
    // ClipRRect needs to clip the *decorated* box, not one that still
    // carries the margin's transparent inset.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TakwaTappable(
        onTap: () {
          if (hasActive) {
            _push(
              QuranReaderScreen(
                startFromKhatma: true,
                initialPage: khatma.currentPage,
              ),
            );
          } else {
            _push(const CreateKhatmaScreen());
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: style.isRamadan
                ? style.gold.withValues(alpha: 0.9)
                : style.teal,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: (style.isRamadan ? style.gold : style.teal).withValues(
                  alpha: 0.4,
                ),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
          children: [
            _circleBtn(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              style.text.withValues(alpha: 0.15),
              Colors.white,
              () => _push(const KhatmaHistoryScreen()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  Text(
                    hasActive
                        ? l10n.quranScreenContinueKhatma
                        : l10n.quranScreenStartNewKhatma,
                    style: style.amiri(
                      19,
                      color: Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasActive
                        ? l10n.quranScreenContinueFromPage(
                            localizedNumeral(context, khatma.currentPage),
                          )
                        : l10n.quranScreenChooseKhatmaOptions,
                    style: style.naskh(
                      12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _circleBtn(
              hasActive ? Icons.play_arrow_rounded : Icons.add,
              style.text.withValues(alpha: 0.2),
              Colors.white,
              () => hasActive
                  ? _push(
                      QuranReaderScreen(
                        startFromKhatma: true,
                        initialPage: khatma.currentPage,
                      ),
                    )
                  : _push(const CreateKhatmaScreen()),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreeReadingButton(AdaptiveStyle style) {
    final l10n = AppLocalizations.of(context)!;
    // Margin moved to this outer Padding — see _buildKhatmaButton above.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TakwaTappable(
        onTap: () => _push(const FreeReadingScreen()),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: style.isRamadan
                ? style.goldDim
                : style.success.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: (style.isRamadan ? style.goldDim : style.success)
                    .withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
          children: [
            _circleBtn(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              style.text.withValues(alpha: 0.15),
              Colors.white,
              () => _push(const FreeReadingScreen()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  Text(
                    l10n.quranScreenFreeReadingTitle,
                    style: style.amiri(
                      19,
                      color: Colors.white,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.quranScreenFreeReadingSubtitle,
                    style: style.naskh(
                      12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _circleBtn(
              Icons.menu_book_rounded,
              style.text.withValues(alpha: 0.2),
              Colors.white,
              () => _push(const FreeReadingScreen()),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // Callers resolve the correct chevron direction themselves (Icon has no
  // matchTextDirection param) before passing `icon` in — this helper just
  // paints whatever IconData it's given, directional or not (the other two
  // callers pass play_arrow_rounded/add, which should never flip).
  Widget _circleBtn(IconData icon, Color bg, Color fg, VoidCallback f) =>
      TakwaTappable(
        onTap: f,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: fg, size: 22),
        ),
      );

  Widget _buildGrid(AdaptiveStyle style) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _GridItem(
        icon: Icons.history_rounded,
        title: l10n.khatmaHistoryTitle,
        subtitle: l10n.quranScreenHistoryGridSubtitle,
        color: style.isRamadan
            ? style.gold.withValues(alpha: 0.7)
            : const Color(0xFF7A6833),
        onTap: () => _push(const KhatmaHistoryScreen()),
      ),
      _GridItem(
        icon: Icons.bar_chart_rounded,
        title: l10n.khatmaProgressScreenTitle,
        subtitle: l10n.quranScreenProgressGridSubtitle,
        color: style.isRamadan
            ? style.goldDark.withValues(alpha: 0.7)
            : const Color(0xFF1A5C3A),
        onTap: () => _push(const KhatmaProgressScreen()),
      ),
      // _GridItem(
      //   icon: Icons.settings_rounded,
      //   title: l10n.settingsScreenTitle,
      //   subtitle: l10n.quranScreenSettingsGridSubtitle,
      //   color: style.isRamadan
      //       ? style.gold.withValues(alpha: 0.7)
      //       : const Color(0xFF7A6833),
      //   onTap: () => _push(const KhatmaSettingsScreen()),
      // ),
      _GridItem(
        isAi: true,
        title: l10n.quranScreenAiMemorizeTitle,
        subtitle: l10n.quranScreenAiMemorizeSubtitle,
        color: style.isRamadan
            ? style.teal.withValues(alpha: 0.7)
            : const Color(0xFF1A4060),
        onTap: () => _push(const AiMemorizeScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: items.map((item) => _buildGridItem(item, style)).toList(),
      ),
    );
  }

  Widget _buildGridItem(_GridItem item, AdaptiveStyle style) {
    return TakwaTappable(
      onTap: item.onTap,
      // No semanticLabel: the visible title/subtitle Text below already
      // carries this into the semantics tree.
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50, maxHeight: 60),
        decoration: BoxDecoration(
          color: style.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: style.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(50),
              ),
              child: item.isAi
                  ? Center(
                      child: Text(
                        'AI',
                        style: style.naskh(
                          18,
                          color: Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Icon(item.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: style.amiri(
                15,
                color: style.text,
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              style: style.naskh(10, color: style.textSec),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _goToLastRead(AppLocalizations l10n) {
    final lastRead = ref.read(quranLastReadProvider);
    if (lastRead == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.freeReadingLastReadNone),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _push(QuranReaderScreen(initialPage: lastRead.page));
  }

  void _shareVerse(Map<String, dynamic> verse) {
    final l10n = AppLocalizations.of(context)!;
    final surahNum = verse['surahNumber'] as int;
    final ayahNum = verse['ayahNumber'] as int;
    final reference = l10n.quranReaderAyahRefLabel(
      localizedNumeral(context, ayahNum),
      verse['surahName'] as String,
    );
    final link = 'https://takwa.app/quran?surah=$surahNum&ayah=$ayahNum';
    final shareText = [
      '"${verse['text'] as String}"',
      reference,
      link,
    ].join('\n\n');
    SharePlus.instance.share(ShareParams(text: shareText));
  }
}

class _GridItem {
  final IconData? icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isAi;
  const _GridItem({
    this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isAi = false,
  });
}
