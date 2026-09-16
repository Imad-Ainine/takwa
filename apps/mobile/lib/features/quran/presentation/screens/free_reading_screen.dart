import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_library/quran_library.dart' as ql;
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/quran/data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import '../../data/quran_data.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/l10n/app_localizations.dart';
import 'quran_reader_screen.dart';

// Styles are managed via AdaptiveStyle

class FreeReadingScreen extends ConsumerStatefulWidget {
  const FreeReadingScreen({super.key});
  @override
  ConsumerState<FreeReadingScreen> createState() => _FreeReadingScreenState();
}

class _FreeReadingScreenState extends ConsumerState<FreeReadingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _search = TextEditingController();
  String _query = '';

  // Tab count only — display titles come from _tabTitles(l10n) below, in
  // the same RTL order (displayed right-to-left).
  static const _tabs = [0, 1, 2, 3, 4];

  static List<String> _tabTitles(AppLocalizations l10n) => [
    l10n.freeReadingTabSurah,
    l10n.freeReadingTabReview,
    l10n.freeReadingTabIndex,
    l10n.freeReadingTabJuz,
    l10n.freeReadingTabRub,
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);

    return Scaffold(
      backgroundColor: style.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n, style),
            _buildTabBar(l10n, style),
            if (_tab.index == 0 || _tab.index == 2) _buildSearchBar(l10n, style),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _SurahTab(query: _query, onTap: _goToSurah, style: style),
                  _ReviewTab(onTap: _goToSurah, style: style),
                  _IndexTab(
                    query: _query,
                    lastRead: ref.watch(quranLastReadProvider),
                    onTap: _goToPage,
                    style: style,
                  ),
                  _JuzTab(onTap: _goToJuz, style: style),
                  _RubTab(onTap: _goToPage, style: style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, AdaptiveStyle style) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          const CustomLeadingButton(),
          const Spacer(),
          Text(
            l10n.freeReadingScreenTitle,
            style: style.amiri(22, color: style.text, weight: FontWeight.bold),
          ),
          const Spacer(),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n, AdaptiveStyle style) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: style.border)),
      ),
      child: TabBar(
        controller: _tab,
        isScrollable: false,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicatorColor: style.gold,
        indicatorWeight: 2,
        labelColor: style.gold,
        unselectedLabelColor: style.textDim,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
        ),
        tabs: _tabTitles(l10n).map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, AdaptiveStyle style) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border),
      ),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        textDirection: TextDirection.rtl,
        style: style.naskh(15, color: style.text),
        decoration: InputDecoration(
          hintText: _tab.index == 0
              ? l10n.freeReadingSearchHintSurah
              : l10n.freeReadingSearchHintOther,
          hintStyle: style.naskh(13, color: style.textDim),
          prefixIcon: Icon(Icons.search, color: style.textDim, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  void _goToSurah(int surahNum) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(initialSurah: surahNum),
      ),
    );
  }

  void _goToPage(int page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuranReaderScreen(initialPage: page)),
    );
  }

  void _goToJuz(int juzNum) {
    final start = juzStarts[juzNum - 1];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(initialSurah: start.$1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SURAH TAB
// ─────────────────────────────────────────────────────────────
class _SurahTab extends StatelessWidget {
  final String query;
  final void Function(int) onTap;
  final AdaptiveStyle style;
  const _SurahTab({
    required this.query,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final surahs = ql.QuranLibrary.quranCtrl.surahsList;
    final filtered = query.isEmpty
        ? surahs
        : surahs
              .where(
                (s) =>
                    s.name.contains(query) ||
                    s.englishName.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final s = filtered[i];
        return _SurahRow(s: s, onTap: () => onTap(s.number), style: style);
      },
    );
  }
}

class _SurahRow extends StatelessWidget {
  final dynamic s;
  final VoidCallback onTap;
  final AdaptiveStyle style;
  const _SurahRow({required this.s, required this.onTap, required this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahNum = s.number as int;
    final colors = [
      style.gold,
      const Color(0xFF3AAFA9),
      const Color(0xFF4CAF7D),
      const Color(0xFF9B59B6),
    ];
    final c = colors[(surahNum - 1) % colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: style.border.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          children: [
            // Arrow
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: style.textDim,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Arabic calligraphic name (left side)
            Expanded(
              child: Text(
                s.name as String,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  color: c,
                  fontWeight: FontWeight.w400,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 14),
            // Surah info (right side)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.englishName as String,
                  style: style.amiri(
                    17,
                    color: style.text,
                    weight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.quranReaderAyahCountBadge(s.ayahsNumber as int),
                  style: style.naskh(12, color: style.textSec),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.12),
                border: Border.all(color: c.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  localizedNumeral(context, surahNum),
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: c,
                    fontWeight: FontWeight.bold,
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

// ─────────────────────────────────────────────────────────────
// REVIEW TAB (مراجعة)
// ─────────────────────────────────────────────────────────────
class _ReviewTab extends StatelessWidget {
  final void Function(int) onTap;
  final AdaptiveStyle style;
  const _ReviewTab({required this.onTap, required this.style});

  @override
  Widget build(BuildContext context) {
    // Show Juz list with beginning ayah text for review
    final surahs = ql.QuranLibrary.quranCtrl.surahs;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: kJuzData.length,
      itemBuilder: (_, i) {
        final juz = kJuzData[i];
        final surahIdx = juz.startSurah - 1;
        if (surahIdx >= surahs.length) return const SizedBox();
        final surah = surahs[surahIdx];
        final ayahIdx = (juz.startAyah - 1).clamp(0, surah.ayahs.length - 1);
        final ayah = surah.ayahs[ayahIdx];
        final previewText = ayah.text.length > 80
            ? '${ayah.text.substring(0, 80)}...'
            : ayah.text;

        return GestureDetector(
          onTap: () => onTap(juz.startSurah),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: style.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: style.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: style.textDim,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        surah.arabicName,
                        style: style.amiri(
                          18,
                          color: style.text,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        previewText,
                        textDirection: TextDirection.rtl,
                        style: style.amiri(14, color: style.textSec),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: style.gold.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      localizedNumeral(context, i + 1),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 11,
                        color: style.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INDEX / FIHRIS TAB (فهرس)
// ─────────────────────────────────────────────────────────────
class _IndexTab extends StatelessWidget {
  final String query;
  final QuranBookmark? lastRead;
  final void Function(int) onTap;
  final AdaptiveStyle style;
  const _IndexTab({
    required this.query,
    required this.lastRead,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Last read banner
        // The margin moved to this outer Padding, off the Container below —
        // see quran_widgets.dart's KhatmaActionCard for why: TakwaTappable's
        // ClipRRect needs to clip the *decorated* box, not a box that still
        // carries the margin's transparent inset.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TakwaTappable(
            onTap: lastRead != null ? () => onTap(lastRead!.page) : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: style.isRamadan ? style.gold : const Color(0xFFD07010),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  lastRead != null
                      ? l10n.freeReadingLastReadLabel(
                          lastRead!.surahName,
                          localizedNumeral(context, lastRead!.page),
                        )
                      : l10n.freeReadingLastReadNone,
                  style: style.naskh(
                    15,
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 604,
            itemBuilder: (_, i) {
              final page = i + 1;
              if (query.isNotEmpty &&
                  !ar(page).contains(query) &&
                  !'$page'.contains(query)) {
                return const SizedBox();
              }
              return TakwaTappable(
                onTap: () => onTap(page),
                // No semanticLabel: the visible page-number Text below
                // already carries this into the semantics tree.
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: style.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: style.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizedNumeral(context, page),
                        style: style.amiri(
                          20,
                          color: style.gold,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.bookReaderPageLabel,
                        style: style.naskh(10, color: style.textDim),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// JUZ TAB (جزء)
// ─────────────────────────────────────────────────────────────
class _JuzTab extends StatelessWidget {
  final void Function(int) onTap;
  final AdaptiveStyle style;
  const _JuzTab({required this.onTap, required this.style});

  @override
  Widget build(BuildContext context) {
    final surahs = ql.QuranLibrary.quranCtrl.surahs;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: kJuzData.length,
      itemBuilder: (_, i) {
        final juz = kJuzData[i];
        final surahIdx = juz.startSurah - 1;
        if (surahIdx >= surahs.length) return const SizedBox();
        final surah = surahs[surahIdx];
        final ayahIdx = (juz.startAyah - 1).clamp(0, surah.ayahs.length - 1);
        final ayah = surah.ayahs[ayahIdx];
        final preview = ayah.text.length > 90
            ? '${ayah.text.substring(0, 90)}...'
            : ayah.text;

        return GestureDetector(
          onTap: () => onTap(i + 1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: style.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: style.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: Colors.white30,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        surah.arabicName,
                        style: style.amiri(
                          18,
                          color: style.text,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        preview,
                        textDirection: TextDirection.rtl,
                        style: style.amiri(14, color: style.textSec),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: style.gold.withValues(alpha: 0.2),
                    border: Border.all(color: style.gold.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      localizedNumeral(context, i + 1),
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        color: style.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RUB / HIZB TAB (ربع)
// ─────────────────────────────────────────────────────────────
class _RubTab extends StatelessWidget {
  final void Function(int) onTap;
  final AdaptiveStyle style;
  const _RubTab({required this.onTap, required this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahs = ql.QuranLibrary.quranCtrl.surahs;

    // Build hizb groups (60 hizbs, each with 4 quarters)
    final hizbGroups = <int, List<Map<String, dynamic>>>{};
    for (int h = 1; h <= 30; h++) {
      final juzIdx = h - 1;
      if (juzIdx >= kJuzData.length) continue;
      final juz = kJuzData[juzIdx];
      final surahIdx = juz.startSurah - 1;
      if (surahIdx >= surahs.length) continue;
      final surah = surahs[surahIdx];

      hizbGroups[h] = [];
      for (int q = 1; q <= 4; q++) {
        final ayahIdx = ((surah.ayahs.length / 4) * (q - 1)).toInt().clamp(
          0,
          surah.ayahs.length - 1,
        );
        final ayah = surah.ayahs[ayahIdx];
        final preview = ayah.text.length > 50
            ? '${ayah.text.substring(0, 50)}...'
            : ayah.text;
        hizbGroups[h]!.add({
          'surahName': surah.arabicName,
          'preview': preview,
          'page': kSurahData[surahIdx].startPage,
          'quarter': q,
        });
      }
    }

    final keys = hizbGroups.keys.toList()..sort();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final hizb = keys[i];
        final quarters = hizbGroups[hizb]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.freeReadingHizbLabel(localizedNumeral(context, hizb)),
                style: style.amiri(
                  16,
                  color: style.textSec,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            ...quarters.asMap().entries.map((e) {
              final q = e.value;
              final idx = e.key;
              final progress = (idx + 1) / 4;
              return GestureDetector(
                onTap: () => onTap(q['page'] as int),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: style.card,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: style.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Progress circle
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TakwaLoadingIndicator(
                              size: 36,
                              strokeWidth: 2.5,
                              color: idx == 0
                                  ? style.textDim
                                  : idx == 1
                                  ? style.gold
                                  : idx == 2
                                  ? style.textSec
                                  : style.text,
                            ),
                            Text(
                              idx == 0
                                  ? '¼'
                                  : idx == 1
                                  ? '½'
                                  : idx == 2
                                  ? '¾'
                                  : '1',
                              style: TextStyle(
                                fontSize: 10,
                                color: idx == 3 ? style.text : style.textDim,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              q['surahName'] as String,
                              style: style.amiri(
                                16,
                                color: style.text,
                                weight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              q['preview'] as String,
                              textDirection: TextDirection.rtl,
                              style: style.amiri(13, color: style.textSec),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
