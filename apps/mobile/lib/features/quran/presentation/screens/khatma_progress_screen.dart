import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/quran_models.dart';
import '../../providers/quran_providers.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import '../../utils/quran_helpers.dart';
import '../widgets/quran_widgets.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

enum _DayState { future, missed, partial, complete }

class KhatmaProgressScreen extends ConsumerWidget {
  const KhatmaProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);

    final khatma = ref.watch(khatmaExProvider);
    // Only needed once there's an active Khatma to show stats for — avoids
    // an unnecessary DB read (and its async loading flicker) on the empty
    // state.
    final readingStatsAsync = khatma != null
        ? ref.watch(khatmaReadingStatsProvider)
        : const AsyncValue<KhatmaReadingStats>.loading();

    return Scaffold(
      backgroundColor: style.bg,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29). As a plain
      // Scaffold.appBar (not inside the scroll view) it's always visible
      // regardless of scroll, matching this SliverAppBar's pinned: true.
      appBar: AppBarWidget(
        title: l.khatmaScreenTitle,
        leading: const CustomLeadingButton(),
        actions: [
          if (khatma != null && khatma.isActive)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: style.text),
              color: style.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: style.border),
              ),
              onSelected: (v) {
                if (v == 'finish') {
                  _confirmMarkFinished(context, ref, style, l);
                } else if (v == 'cancel') {
                  _confirmCancel(context, ref, style, l);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'finish',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: style.gold,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l.khatmaMenuMarkFinished,
                        style: style.naskh(14, color: style.text),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l.khatmaMenuCancelKhatma,
                        style: style.naskh(14, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (khatma == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(style, l),
            )
          else
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  KhatmaProgressRing(
                    progress: khatma.progress,
                    pagesRead: khatma.pagesRead,
                    totalPages: KhatmaSessionEx.totalPages,
                    style: style,
                    color: style.gold,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l.khatmaProgressPercent(
                      (khatma.progress * 100).toStringAsFixed(1),
                    ),
                    style: style.naskh(
                      16,
                      color: style.gold,
                      weight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        _InfoCard(khatma: khatma, style: style, l: l),
                        const SizedBox(height: AppSpacing.lg),
                        _ProgressCard(khatma: khatma, style: style, l: l),
                        const SizedBox(height: AppSpacing.lg),
                        _StatusCard(khatma: khatma, style: style, l: l),
                        const SizedBox(height: AppSpacing.lg),
                        readingStatsAsync.when(
                          loading: () => const SizedBox(
                            height: 80,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (stats) => _ExtraStatsCard(
                            khatma: khatma,
                            stats: stats,
                            style: style,
                            l: l,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        readingStatsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (stats) => _ReadingDaysCalendar(
                            khatma: khatma,
                            stats: stats,
                            style: style,
                            l: l,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdaptiveStyle style, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 72,
              color: style.textDim.withValues(alpha: 0.15),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l.khatmaProgressEmptyTitle,
              style: style.naskh(18, color: style.textDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.khatmaProgressEmptySubtitle,
              style: style.naskh(13, color: style.textSec.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmMarkFinished(
    BuildContext context,
    WidgetRef ref,
    AdaptiveStyle style,
    AppLocalizations l,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: style.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: style.border),
        ),
        title: Text(
          l.khatmaMarkFinishedDialogTitle,
          textAlign: TextAlign.right,
          style: style.amiri(20, color: style.text, weight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l.khatmaMarkFinishedDialogBody,
              textAlign: TextAlign.right,
              style: style.naskh(14, color: style.textSec),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.khatmaMarkFinishedDialogNote,
              textAlign: TextAlign.right,
              style: style.naskh(12, color: style.textDim),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l.khatmaDialogGoBack,
              style: style.naskh(14, color: style.textDim),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(khatmaExProvider.notifier).markAsFinished();
              ref.invalidate(khatmaCompletedProvider);
            },
            child: Text(
              l.khatmaMarkFinishedConfirm,
              style: style.naskh(
                14,
                color: style.gold,
                weight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    AdaptiveStyle style,
    AppLocalizations l,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: style.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: style.border),
        ),
        title: Text(
          l.khatmaCancelDialogTitle,
          textAlign: TextAlign.right,
          style: style.amiri(20, color: style.text, weight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l.khatmaCancelDialogBody,
              textAlign: TextAlign.right,
              style: style.naskh(14, color: style.textSec),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.khatmaCancelDialogWarning,
              textAlign: TextAlign.right,
              style: style.naskh(12, color: Colors.redAccent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l.khatmaDialogGoBack,
              style: style.naskh(14, color: style.textDim),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(khatmaExProvider.notifier).cancel();
              ref.invalidate(khatmaCancelledProvider);
            },
            child: Text(
              l.khatmaCancelConfirmFinal,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared card chrome
// ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final AdaptiveStyle style;
  final List<Widget> children;
  const _Card({
    required this.title,
    required this.style,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: style.amiri(16, color: style.text, weight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final AdaptiveStyle style;
  final Color? valueColor;
  const _KvRow({
    required this.label,
    required this.value,
    required this.style,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: style.naskh(13, color: valueColor ?? style.text, weight: FontWeight.w600)),
          Text(label, style: style.naskh(13, color: style.textSec)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// معلومات الختمة
// ─────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final KhatmaSessionEx khatma;
  final AdaptiveStyle style;
  final AppLocalizations l;
  const _InfoCard({required this.khatma, required this.style, required this.l});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d/M/yyyy');
    final completedDays =
        DateTime.now().difference(khatma.startDate).inDays + 1;
    return _Card(
      title: l.khatmaInfoSectionTitle,
      style: style,
      children: [
        _KvRow(label: l.khatmaInfoNameLabel, value: khatma.label, style: style),
        _KvRow(
          label: l.khatmaInfoTypeLabel,
          value: khatma.type == KhatmaType.muyassara
              ? l.khatmaTypeMuyassaraLabel
              : l.khatmaTypeMultazimaLabel,
          style: style,
        ),
        _KvRow(
          label: l.khatmaInfoStartDateLabel,
          value: fmt.format(khatma.startDate),
          style: style,
        ),
        _KvRow(
          label: l.khatmaInfoCompletedDaysLabel,
          value: l.khatmaInfoCompletedDaysValue(
            localizedNumeral(context, completedDays),
          ),
          style: style,
        ),
        _KvRow(
          label: l.khatmaInfoEndTypeLabel,
          value: khatma.endDate != null
              ? l.khatmaInfoEndTypeTarget(fmt.format(khatma.endDate!))
              : l.khatmaInfoEndTypeNoLimit,
          style: style,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// التقدم الإجمالي
// ─────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final KhatmaSessionEx khatma;
  final AdaptiveStyle style;
  final AppLocalizations l;
  const _ProgressCard({
    required this.khatma,
    required this.style,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = KhatmaSessionEx.totalPages - khatma.pagesRead;
    return _Card(
      title: l.khatmaOverallProgressTitle,
      style: style,
      children: [
        _KvRow(
          label: l.khatmaReachedPageLabel,
          value: l.khatmaReachedPageValue(
            localizedNumeral(context, khatma.pagesRead),
            localizedNumeral(context, KhatmaSessionEx.totalPages),
          ),
          style: style,
        ),
        _KvRow(
          label: l.khatmaCurrentPageLabel,
          value: l.khatmaCurrentPageValue(
            localizedNumeral(context, khatma.currentPage),
          ),
          style: style,
        ),
        _KvRow(
          label: l.khatmaRemainingPagesLabel,
          value: l.khatmaRemainingPagesValue(
            localizedNumeral(context, remaining < 0 ? 0 : remaining),
          ),
          style: style,
        ),
        _KvRow(
          label: l.khatmaEstimatedHasanatLabel,
          value: l.khatmaEstimatedHasanatValue(
            localizedNumeral(context, khatma.estimatedHasanat),
          ),
          style: style,
          valueColor: style.gold,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// حالة الختمة (ميسرة/ملتزمة)
// ─────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final KhatmaSessionEx khatma;
  final AdaptiveStyle style;
  final AppLocalizations l;
  const _StatusCard({
    required this.khatma,
    required this.style,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final daysSinceStart = DateTime.now().difference(khatma.startDate).inDays + 1;
    final avgPerDay = daysSinceStart > 0 ? khatma.pagesRead / daysSinceStart : 0.0;
    final isMuyassara = khatma.type == KhatmaType.muyassara;

    return _Card(
      title: isMuyassara
          ? l.khatmaStatusMuyassaraBadge
          : l.khatmaStatusMultazimaBadge(
              localizedNumeral(context, khatma.dailyPages ?? 0),
            ),
      style: style,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: style.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isMuyassara
                  ? l.khatmaStatusMuyassaraBadge
                  : l.khatmaStatusMultazimaBadge(
                      localizedNumeral(context, khatma.dailyPages ?? 0),
                    ),
              style: style.naskh(12, color: style.gold, weight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _KvRow(
          label: l.khatmaAvgPagesPerDayLabel,
          value: avgPerDay.toStringAsFixed(1),
          style: style,
        ),
        _KvRow(
          label: l.khatmaTypeDescriptionLabel,
          value: isMuyassara
              ? l.khatmaTypeDescriptionFree
              : l.khatmaTypeDescriptionTarget(
                  localizedNumeral(context, khatma.dailyPages ?? 0),
                ),
          style: style,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// إحصائيات إضافية
// ─────────────────────────────────────────────────────────────
class _ExtraStatsCard extends StatelessWidget {
  final KhatmaSessionEx khatma;
  final KhatmaReadingStats stats;
  final AdaptiveStyle style;
  final AppLocalizations l;
  const _ExtraStatsCard({
    required this.khatma,
    required this.stats,
    required this.style,
    required this.l,
  });

  String _duration(BuildContext context, int totalSeconds) {
    if (totalSeconds <= 0) return l.khatmaNoDataValue;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return l.khatmaDurationHoursMinutes(
        localizedNumeral(context, hours),
        localizedNumeral(context, minutes),
      );
    }
    if (minutes > 0) {
      return l.khatmaDurationMinutesSeconds(
        localizedNumeral(context, minutes),
        localizedNumeral(context, seconds),
      );
    }
    return l.khatmaDurationSecondsOnly(localizedNumeral(context, seconds));
  }

  @override
  Widget build(BuildContext context) {
    final avgSeconds = khatma.readingSessionsCount > 0
        ? khatma.totalReadingSeconds ~/ khatma.readingSessionsCount
        : 0;
    final fmt = DateFormat('d/M/yyyy');

    return _Card(
      title: l.khatmaExtraStatsTitle,
      style: style,
      children: [
        _KvRow(
          label: l.khatmaTotalReadingTimeLabel,
          value: _duration(context, khatma.totalReadingSeconds),
          style: style,
        ),
        _KvRow(
          label: l.khatmaAvgReadingTimeLabel,
          value: _duration(context, avgSeconds),
          style: style,
        ),
        _KvRow(
          label: l.khatmaCurrentStreakLabel,
          value: l.khatmaStreakDaysValue(
            localizedNumeral(context, stats.currentStreak),
          ),
          style: style,
          valueColor: stats.currentStreak > 0 ? Colors.orangeAccent : null,
        ),
        _KvRow(
          label: l.khatmaLongestStreakLabel,
          value: l.khatmaStreakDaysValue(
            localizedNumeral(context, stats.longestStreak),
          ),
          style: style,
        ),
        _KvRow(
          label: l.khatmaLastReadLabel,
          value: stats.lastReadDate != null
              ? fmt.format(stats.lastReadDate!)
              : l.khatmaNoDataValue,
          style: style,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// أيام القراءة (calendar grid)
// ─────────────────────────────────────────────────────────────
class _ReadingDaysCalendar extends StatelessWidget {
  final KhatmaSessionEx khatma;
  final KhatmaReadingStats stats;
  final AdaptiveStyle style;
  final AppLocalizations l;
  const _ReadingDaysCalendar({
    required this.khatma,
    required this.stats,
    required this.style,
    required this.l,
  });

  /// Classifies [day] using the real page count logged for it (via
  /// [stats.pagesByDay]) against this Khatma's daily target — when a
  /// Khatma has no explicit target (muyassara), any pages read at all
  /// counts as "complete" for that day, since there's no partial quota
  /// to fall short of.
  _DayState _stateFor(DateTime day, DateTime today) {
    if (day.isAfter(today)) return _DayState.future;
    final pages = stats.pagesByDay[day] ?? 0;
    final target = khatma.dailyPages;
    if (pages <= 0) return _DayState.missed;
    if (target != null && target > 0 && pages < target) return _DayState.partial;
    return _DayState.complete;
  }

  Color _colorFor(_DayState s) {
    switch (s) {
      case _DayState.future:
        return style.border.withValues(alpha: 0.4);
      case _DayState.missed:
        return Colors.redAccent.withValues(alpha: 0.35);
      case _DayState.partial:
        return Colors.orangeAccent.withValues(alpha: 0.55);
      case _DayState.complete:
        return style.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = KhatmaReadingStats.dayOnly(now);
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Sunday-first grid, matching the weekday labels below.
    final leadingBlanks = firstOfMonth.weekday % 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.khatmaReadingDaysTitle,
            textAlign: TextAlign.right,
            style: style.amiri(16, color: style.text, weight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.khatmaReadingDaysSubtitle,
            textAlign: TextAlign.right,
            style: style.naskh(12, color: style.textSec),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (_, i) {
              if (i < leadingBlanks) return const SizedBox.shrink();
              final dayNum = i - leadingBlanks + 1;
              final day = DateTime(now.year, now.month, dayNum);
              final s = _stateFor(day, today);
              final isToday = day == today;
              return Container(
                decoration: BoxDecoration(
                  color: _colorFor(s),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: isToday
                      ? Border.all(color: style.gold, width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  localizedNumeral(context, dayNum),
                  style: style.naskh(
                    10,
                    color: s == _DayState.complete
                        ? Colors.black.withValues(alpha: 0.75)
                        : style.text,
                    weight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendDot(color: _colorFor(_DayState.complete), label: l.khatmaLegendComplete, style: style),
              _LegendDot(color: _colorFor(_DayState.partial), label: l.khatmaLegendPartial, style: style),
              _LegendDot(color: _colorFor(_DayState.missed), label: l.khatmaLegendMissed, style: style),
              _LegendDot(color: _colorFor(_DayState.future), label: l.khatmaLegendFuture, style: style),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final AdaptiveStyle style;
  const _LegendDot({required this.color, required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: style.naskh(11, color: style.textSec)),
      ],
    );
  }
}
