import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import '../../data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/l10n/app_localizations.dart';

// Styles are managed via AdaptiveStyle

enum _SortBy { date, name, duration, progress }

class KhatmaHistoryScreen extends ConsumerStatefulWidget {
  const KhatmaHistoryScreen({super.key});
  @override
  ConsumerState<KhatmaHistoryScreen> createState() =>
      _KhatmaHistoryScreenState();
}

class _KhatmaHistoryScreenState extends ConsumerState<KhatmaHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _toastMsg;
  _SortBy _sortBy = _SortBy.date;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<KhatmaSessionEx> _sorted(List<KhatmaSessionEx> list) {
    final sorted = [...list];
    switch (_sortBy) {
      case _SortBy.date:
        sorted.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case _SortBy.name:
        sorted.sort((a, b) => a.label.compareTo(b.label));
        break;
      case _SortBy.duration:
        sorted.sort((a, b) => _daysOf(b).compareTo(_daysOf(a)));
        break;
      case _SortBy.progress:
        sorted.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }
    return sorted;
  }

  int _daysOf(KhatmaSessionEx s) =>
      (s.completedDate ?? s.cancelledDate ?? DateTime.now())
          .difference(s.startDate)
          .inDays +
      1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);

    final completed = ref.watch(khatmaCompletedProvider);
    final cancelled = ref.watch(khatmaCancelledProvider);

    final completedCount = completed.value?.length ?? 0;
    final cancelledCount = cancelled.value?.length ?? 0;

    return Scaffold(
      backgroundColor: style.bg,
      bottomSheet: _toastMsg != null ? _buildToast(style) : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(style, l10n, completed.value, cancelled.value),
            _buildTabBar(style, l10n, completedCount, cancelledCount),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildCompletedList(style, l10n, completed),
                  _buildCancelledList(style, l10n, cancelled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AdaptiveStyle style,
    AppLocalizations l10n,
    List<KhatmaSessionEx>? completed,
    List<KhatmaSessionEx>? cancelled,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          const CustomLeadingButton(),
          const Spacer(),
          Text(
            l10n.khatmaHistoryTitle,
            style: style.amiri(22, color: style.text, weight: FontWeight.bold),
          ),
          const Spacer(),
          PopupMenuButton<Object>(
            tooltip: l10n.khatmaHistorySortMenuTooltip,
            icon: Icon(Icons.sort_rounded, color: style.text),
            color: style.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: style.border),
            ),
            onSelected: (v) {
              if (v is _SortBy) {
                setState(() => _sortBy = v);
              } else if (v == 'stats') {
                _showStats(style, l10n, completed ?? [], cancelled ?? []);
              }
            },
            itemBuilder: (_) => [
              _sortMenuItem(style, _SortBy.date, l10n.khatmaHistorySortByDate),
              _sortMenuItem(style, _SortBy.name, l10n.khatmaHistorySortByName),
              _sortMenuItem(
                style,
                _SortBy.duration,
                l10n.khatmaHistorySortByDuration,
              ),
              _sortMenuItem(
                style,
                _SortBy.progress,
                l10n.khatmaHistorySortByProgress,
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 18, color: style.gold),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.khatmaHistoryShowStats,
                      style: style.naskh(14, color: style.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<Object> _sortMenuItem(
    AdaptiveStyle style,
    _SortBy value,
    String label,
  ) {
    final selected = _sortBy == value;
    return PopupMenuItem<Object>(
      value: value,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 16,
            color: selected ? style.gold : style.textDim,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: style.naskh(
              14,
              color: selected ? style.gold : style.text,
              weight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
    AdaptiveStyle style,
    AppLocalizations l10n,
    int completedCount,
    int cancelledCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: style.border)),
      ),
      child: TabBar(
        controller: _tab,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicatorColor: style.gold,
        indicatorWeight: 2,
        labelColor: style.gold,
        unselectedLabelColor: style.textDim,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.khatmaHistoryCompletedTab(completedCount.toString()),
                  style: style.naskh(13, weight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.archive_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.khatmaHistoryCancelledTab(cancelledCount.toString()),
                  style: style.naskh(13, weight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedList(
    AdaptiveStyle style,
    AppLocalizations l10n,
    AsyncValue<List<KhatmaSessionEx>> async,
  ) {
    return async.when(
      loading: () => const Center(child: TakwaLoadingIndicator()),
      error: (_, __) => Center(
        child: Text(l10n.khatmaHistoryError, style: style.naskh(14, color: style.text)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _buildEmpty(
            style: style,
            icon: Icons.history_rounded,
            title: l10n.khatmaHistoryEmptyCompletedTitle,
            subtitle: l10n.khatmaHistoryEmptyCompletedSubtitle,
          );
        }
        final sorted = _sorted(list);
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: sorted.length,
          itemBuilder: (_, i) => _KhatmaCard(
            session: sorted[i],
            onDelete: () => _showDeleteConfirm(
              style,
              sorted[i],
              khatmaCompletedProvider,
            ),
            onDetails: () => _showDetails(style, l10n, sorted[i]),
            style: style,
          ),
        );
      },
    );
  }

  Widget _buildCancelledList(
    AdaptiveStyle style,
    AppLocalizations l10n,
    AsyncValue<List<KhatmaSessionEx>> async,
  ) {
    return async.when(
      loading: () => const Center(child: TakwaLoadingIndicator()),
      error: (_, __) => Center(
        child: Text(l10n.khatmaHistoryError, style: style.naskh(14, color: style.text)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _buildEmpty(
            style: style,
            icon: Icons.archive_outlined,
            title: l10n.khatmaHistoryEmptyCancelledTitle,
            subtitle: l10n.khatmaHistoryEmptyCancelledSubtitle,
          );
        }
        final sorted = _sorted(list);
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: sorted.length,
          itemBuilder: (_, i) => _KhatmaCard(
            session: sorted[i],
            onDelete: () => _showDeleteConfirm(
              style,
              sorted[i],
              khatmaCancelledProvider,
            ),
            onDetails: () => _showDetails(style, l10n, sorted[i]),
            style: style,
          ),
        );
      },
    );
  }

  Widget _buildEmpty({
    required AdaptiveStyle style,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: style.textDim.withValues(alpha: 0.15)),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: style.naskh(18, color: style.textDim),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: style.naskh(13, color: style.textSec.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    AdaptiveStyle style,
    KhatmaSessionEx session,
    // The provider whose list [session] belongs to, so we invalidate the
    // right one after deleting (completed vs. cancelled history).
    FutureProvider<List<KhatmaSessionEx>> ownerProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: style.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: style.border),
        ),
        title: Text(
          l10n.khatmaHistoryDeleteTitle,
          textAlign: TextAlign.start,
          style: style.amiri(20, color: style.text, weight: FontWeight.bold),
        ),
        content: Text(
          l10n.khatmaHistoryDeleteConfirm,
          textAlign: TextAlign.start,
          style: style.naskh(14, color: style.textSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.adhkarCancelButton,
              style: style.naskh(14, color: style.textDim),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(khatmaDeleteHistoryProvider)(session.id);
              ref.invalidate(ownerProvider);
              _showToast(l10n.khatmaHistoryDeletedToast);
            },
            child: Text(
              l10n.adhkarDeleteTooltip,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(
    AdaptiveStyle style,
    AppLocalizations l10n,
    KhatmaSessionEx session,
  ) {
    final fmt = DateFormat('d/M/yyyy');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: style.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: style.border),
        ),
        title: Text(
          l10n.khatmaHistoryDetailsTitle,
          textAlign: TextAlign.right,
          style: style.amiri(20, color: style.text, weight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _detailRow(style, l10n.khatmaInfoNameLabel, session.label),
            _detailRow(
              style,
              l10n.khatmaInfoTypeLabel,
              session.type == KhatmaType.muyassara
                  ? l10n.khatmaTypeMuyassaraLabel
                  : l10n.khatmaTypeMultazimaLabel,
            ),
            _detailRow(
              style,
              l10n.khatmaInfoStartDateLabel,
              fmt.format(session.startDate),
            ),
            if (session.completedDate != null)
              _detailRow(
                style,
                l10n.khatmaHistoryStatusCompleted,
                fmt.format(session.completedDate!),
              ),
            if (session.cancelledDate != null)
              _detailRow(
                style,
                l10n.khatmaHistoryStatusCancelled,
                fmt.format(session.cancelledDate!),
              ),
            _detailRow(
              style,
              l10n.khatmaHistoryPagesProgress(
                localizedNumeral(context, session.pagesRead),
                localizedNumeral(context, KhatmaSessionEx.totalPages),
              ),
              '${(session.progress * 100).toStringAsFixed(1)}%',
            ),
            _detailRow(
              style,
              l10n.khatmaEstimatedHasanatLabel,
              localizedNumeral(context, session.estimatedHasanat),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.khatmaHistoryCloseButton,
              style: style.naskh(14, color: style.gold, weight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(AdaptiveStyle style, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: style.naskh(13, color: style.text, weight: FontWeight.w600)),
          Text(label, style: style.naskh(13, color: style.textSec)),
        ],
      ),
    );
  }

  void _showStats(
    AdaptiveStyle style,
    AppLocalizations l10n,
    List<KhatmaSessionEx> completed,
    List<KhatmaSessionEx> cancelled,
  ) {
    final totalPages = [...completed, ...cancelled]
        .fold<int>(0, (sum, s) => sum + s.pagesRead);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: style.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: style.border),
        ),
        title: Text(
          l10n.khatmaHistoryStatsTitle,
          textAlign: TextAlign.right,
          style: style.amiri(20, color: style.text, weight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _detailRow(
              style,
              l10n.khatmaHistoryStatsTotal,
              localizedNumeral(context, completed.length + cancelled.length),
            ),
            _detailRow(
              style,
              l10n.khatmaHistoryStatsCompleted,
              localizedNumeral(context, completed.length),
            ),
            _detailRow(
              style,
              l10n.khatmaHistoryStatsCancelled,
              localizedNumeral(context, cancelled.length),
            ),
            _detailRow(
              style,
              l10n.khatmaHistoryStatsTotalPages,
              localizedNumeral(context, totalPages),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.khatmaHistoryCloseButton,
              style: style.naskh(14, color: style.gold, weight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    setState(() => _toastMsg = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

  Widget _buildToast(AdaptiveStyle style) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 14,
      ),
      color: style.gold.withValues(alpha: 0.9),
      child: Text(
        _toastMsg ?? '',
        textAlign: TextAlign.start,
        style: style.naskh(14, color: Colors.white, weight: FontWeight.bold),
      ),
    );
  }
}

class _KhatmaCard extends StatelessWidget {
  final KhatmaSessionEx session;
  final VoidCallback? onDelete;
  final VoidCallback? onDetails;
  final AdaptiveStyle style;
  const _KhatmaCard({
    required this.session,
    required this.onDelete,
    required this.onDetails,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('d/M/yyyy');
    final days =
        (session.completedDate ?? session.cancelledDate ?? DateTime.now())
            .difference(session.startDate)
            .inDays +
        1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (onDelete != null)
                TakwaTappable(
                  onTap: onDelete,
                  semanticLabel: l10n.commonDelete,
                  // Sits inline in the card's header row.
                  minTapSize: null,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: session.isCompleted
                      ? style.gold.withValues(alpha: 0.18)
                      : Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  session.isCompleted
                      ? l10n.khatmaHistoryStatusCompleted
                      : l10n.khatmaHistoryStatusCancelled,
                  style: style.naskh(
                    12,
                    color: session.isCompleted ? style.gold : Colors.redAccent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                session.label,
                style: style.amiri(
                  18,
                  color: style.text,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: session.progress,
              // Was Colors.white — the unfilled track all but vanished on
              // this card's light-mode `style.card` background.
              backgroundColor: style.text.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                session.isCompleted ? style.gold : style.textDim,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfo(
                style,
                Icons.timer_rounded,
                l10n.khatmaHistoryDaysLabel(localizedNumeral(context, days)),
              ),
              _buildInfo(
                style,
                Icons.auto_stories_rounded,
                l10n.khatmaHistoryPagesProgress(
                  localizedNumeral(context, session.pagesRead),
                  localizedNumeral(context, KhatmaSessionEx.totalPages),
                ),
              ),
              _buildInfo(
                style,
                Icons.calendar_today_rounded,
                fmt.format(session.startDate),
              ),
            ],
          ),
          if (onDetails != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onDetails,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.visibility_outlined, size: 15, color: style.gold),
                label: Text(
                  l10n.khatmaHistoryViewDetails,
                  style: style.naskh(12, color: style.gold, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfo(AdaptiveStyle style, IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: style.textDim),
      const SizedBox(width: AppSpacing.xs),
      Text(text, style: style.naskh(11, color: style.textSec)),
    ],
  );
}
