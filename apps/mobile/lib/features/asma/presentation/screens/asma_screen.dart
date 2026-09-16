import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/features/asma/data/asma_data.dart';

import '../../../../core/theme/ramadan_theme.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AsmaScreen extends ConsumerStatefulWidget {
  const AsmaScreen({super.key});
  @override
  ConsumerState<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends ConsumerState<AsmaScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // See HomeScreen's _HomeScreenState for why: one of six MainShell tabs.
  // Matters more here than most — without it, the search query and expanded
  // name were both reset on every tab switch away and back.
  @override
  bool get wantKeepAlive => true;
  late final AnimationController _entryCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _expandedIdx;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AsmaItem> get _filtered => kAsmaData
      .where(
        (a) =>
            _query.isEmpty ||
            a.name.contains(_query) ||
            a.meaning.contains(_query) ||
            a.explanation.contains(_query) ||
            a.number.toString() == _query,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final s = AdaptiveStyle(context, isRamadan);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: s.bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          Column(
            children: [
              _AsmaTopBar(
                style: s,
                query: _query,
                searchCtrl: _searchCtrl,
                onSearch: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: _AsmaList(
                  items: filtered,
                  style: s,
                  entryCtrl: _entryCtrl,
                  expanded: _expandedIdx,
                  onExpand: (i) => setState(
                    () => _expandedIdx = _expandedIdx == i ? null : i,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AsmaTopBar extends StatelessWidget {
  final AdaptiveStyle style;
  final String query;
  final Function(String) onSearch;
  final TextEditingController searchCtrl;

  const _AsmaTopBar({
    required this.style,
    required this.query,
    required this.onSearch,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = style;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            Row(
              children: [
                const CustomLeadingButton(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.asmaScreenTitle,
                        style: s.amiri(22, color: s.gold),
                      ),
                      Text(
                        l10n.asmaScreenSubtitle,
                        style: s.naskh(11, color: s.textSec),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Search
            Container(
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: s.border),
              ),
              child: TextField(
                controller: searchCtrl,
                textDirection: TextDirection.rtl,
                style: s.naskh(13),
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: l10n.asmaSearchHint,
                  hintStyle: s.naskh(12, color: s.textSec),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: s.textSec,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: AppSpacing.md,
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

class _AsmaList extends StatelessWidget {
  final List<AsmaItem> items;
  final AdaptiveStyle style;
  final AnimationController entryCtrl;
  final int? expanded;
  final Function(int) onExpand;

  const _AsmaList({
    required this.items,
    required this.style,
    required this.entryCtrl,
    this.expanded,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(l10n.asmaNoResultsLabel, style: style.amiri(16)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final d = i * 0.03;
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: entryCtrl,
              curve: Interval(
                d.clamp(0, 0.8),
                (d + 0.4).clamp(0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: _AsmaCard(
            item: items[i],
            style: style,
            isExpanded: expanded == i,
            onTap: () => onExpand(i),
          ),
        );
      },
    );
  }
}

class _AsmaCard extends StatelessWidget {
  final AsmaItem item;
  final AdaptiveStyle style;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AsmaCard({
    required this.item,
    required this.style,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = style;

    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: isExpanded
              ? LinearGradient(
                  colors: [s.gold.withValues(alpha: 0.12), s.teal.withValues(alpha: 0.06)],
                )
              : null,
          color: isExpanded ? null : s.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded ? s.gold.withValues(alpha: 0.4) : s.border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [BoxShadow(color: s.gold.withValues(alpha: 0.1), blurRadius: 12)]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  _NumberBadge(num: item.number, style: s, mini: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.meaning,
                      style: s.naskh(12, color: s.textSec),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.name));
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.favoriteAdhkarCopiedToast,
                            style: const TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: s.teal,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_rounded, size: 16, color: s.textSec),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Name
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: s
                    .amiri(24, color: s.gold, weight: FontWeight.w700)
                    .copyWith(height: 1.5),
              ),

              // Transliteration
              Text(
                item.transliteration,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 10,
                  color: s.textSec.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),

              // Explanation (collapsed)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Container(height: 1, color: s.border),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.explanation,
                      textAlign: TextAlign.center,
                      style: s
                          .naskh(13, color: s.textSec)
                          .copyWith(height: 1.8),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: s.goldDim,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: s.gold.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              '${l10n.asmaDuaLabel}: ${item.dua}',
                              style: s.naskh(
                                11,
                                color: s.gold,
                                weight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),
              Align(
                alignment: Alignment.center,
                child: AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: s.textSec,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int num;
  final AdaptiveStyle style;
  final bool mini;
  const _NumberBadge({
    required this.num,
    required this.style,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mini ? 24 : 36,
      height: mini ? 24 : 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [style.gold, style.teal]),
        boxShadow: [
          BoxShadow(color: style.gold.withValues(alpha: 0.3), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text(
          num.toString(),
          style: TextStyle(
            fontFamily: 'Amiri',
            color: style.bg,
            fontWeight: FontWeight.w700,
            fontSize: mini ? 10 : 13,
          ),
        ),
      ),
    );
  }
}

// ── Detail Sheet (Kept for completeness, though mostly using list expansion now) ──
class _AsmaDetailSheet extends StatelessWidget {
  final AsmaItem item;
  final AdaptiveStyle style;
  const _AsmaDetailSheet({required this.item, required this.style});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = style;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: s.gold, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: s.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              item.name,
              style: s.amiri(42, weight: FontWeight.w700, color: s.gold),
            ),
            Text(item.meaning, style: s.naskh(16, color: s.textDim)),
            const SizedBox(height: AppSpacing.xxxl),
            _DetailSection(
              title: l10n.asmaDetailExplanationTitle,
              content: item.explanation,
              style: s,
            ),
            const SizedBox(height: AppSpacing.xl),
            _DetailSection(
              title: l10n.asmaDetailQuranTitle,
              content: item.quranRef,
              style: s,
              isVerse: true,
            ),
            const SizedBox(height: AppSpacing.xl),
            _DetailSection(
              title: l10n.asmaDetailDuaTitle,
              content: item.dua,
              style: s,
              isDua: true,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            PrimaryButton(
              onTap: () async => Navigator.pop(context),
              label: l10n.adhanOverlayCloseButton,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title, content;
  final AdaptiveStyle style;
  final bool isVerse, isDua;
  const _DetailSection({
    required this.title,
    required this.content,
    required this.style,
    this.isVerse = false,
    this.isDua = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: style.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: style.naskh(
                12,
                weight: FontWeight.w700,
                color: style.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: style.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: style.border),
          ),
          child: Text(
            content,
            style: isVerse
                ? style.amiri(16, height: 1.8)
                : style.naskh(14, height: 1.8),
            textAlign: isVerse ? TextAlign.center : TextAlign.start,
          ),
        ),
      ],
    );
  }
}
