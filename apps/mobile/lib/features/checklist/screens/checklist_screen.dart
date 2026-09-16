import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hijri/hijri_calendar.dart';

import 'package:takwa/l10n/app_localizations.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/app/animated_drawer.dart';
import 'package:takwa/core/widgets/guest_mode_guard.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/features/checklist/widgets/custom_ibadah_group.dart';

const _kArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String _localizedDigits(BuildContext context, int n) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final s = n.toString();
  return isArabic
      ? s.split('').map((c) => _kArabicDigits[int.parse(c)]).join()
      : s;
}

String _signedPoints(BuildContext context, int points) {
  final sign = points < 0 ? '-' : '+';
  return '$sign${_localizedDigits(context, points.abs())}';
}

/// Runs a local database write, then best-effort pushes the result to
/// Supabase — the shared shape behind every prayer/ibadah/prohibition toggle
/// on this screen. Previously each of those ~11 call sites awaited its DAO
/// write and `syncManagerProvider.syncDailyRecord(...)` back to back with no
/// error handling at all: a failed local write (disk full, DB lock) or a
/// failed sync (offline, timeout) threw an unhandled exception out of a bare
/// async tap handler, silently, with nothing shown to the user — and reading
/// the record back for sync with a `!` null-assertion could crash outright
/// on a null.
///
/// [save] performs the local write and returns the record to sync (usually
/// via `getOrCreateToday()`/`getRecordByDate()` again, since the DAO writes
/// here don't return the updated row themselves). A null result — or a
/// failed sync leg — is not re-thrown: the local write already reached the
/// DB, which is what todayRecordProvider and the checkbox above already
/// reflect, so a sync problem is surfaced without being treated as data loss
/// or left to crash the tap handler.
///
/// Returns whether the local save succeeded — most callers ignore it (a
/// failure already got its own SnackBar here), but one (_DayNoteField, which
/// has its own success toast) needs to know not to show "saved" on top of
/// this method's own "couldn't save".
Future<bool> _saveAndSync(
  WidgetRef ref,
  BuildContext context,
  Future<DailyRecord?> Function() save, {
  // For a caller that already applied an optimistic setState before the
  // write (e.g. _ProhibitionRow) — undoes it so the UI stops claiming
  // something was saved that wasn't, instead of drifting out of sync with
  // the DB until the next full reload.
  VoidCallback? onSaveError,
}) async {
  final l10n = AppLocalizations.of(context)!;
  DailyRecord? record;
  try {
    record = await save();
  } catch (_) {
    onSaveError?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.checklistSaveError)));
    }
    return false;
  }
  if (record == null) return true;
  try {
    await ref.read(syncManagerProvider).syncDailyRecord(record);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.checklistSyncError)));
    }
  }
  return true;
}

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // See HomeScreen's _HomeScreenState for why: one of six MainShell tabs.
  // Matters more here than most — without it, in-progress text in
  // _DayNoteField was discarded on every tab switch away and back.
  @override
  bool get wantKeepAlive => true;
  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  final _quranCtrl = TextEditingController();
  static const _groupCount = 5;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnims = List.generate(_groupCount, (i) {
      final s = i * 0.15, e = (s + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _slideAnims = List.generate(_groupCount, (i) {
      final s = i * 0.15, e = (s + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyRecordDaoProvider).getOrCreateToday();
      _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _quranCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final todayAsync = ref.watch(todayRecordProvider);

    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${_hijriMonth(context, hijri.hMonth)} ${hijri.hYear}';

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          todayAsync.when(
            loading: () => Center(
              child: TakwaLoadingIndicator(
                color: context.colors.gold,
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                AppLocalizations.of(
                  context,
                )!.checklistErrorPrefix(e.toString()),
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.danger,
                ),
              ),
            ),
            data: (record) =>
                GuestModeGuard(child: _buildBody(context, record, hijriStr)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DailyRecord? record,
    String hijriStr,
  ) {
    final net = record?.netPoints ?? 0;
    final gross = record?.taqwaPoints ?? 0;
    final deducted = record?.deductedPoints ?? 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          expandedHeight: 110,
          pinned: true,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _TopBar(
              hijriStr: hijriStr,
              netPoints: net,
              grossPoints: gross,
              deducted: deducted,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.sm),

              // ① مؤشر التقدم
              _anim(0, _DayProgressBar(record: record)),
              const SizedBox(height: AppSpacing.lg),

              // ② الصلوات الخمس
              _anim(1, _PrayersGroup(record: record)),
              const SizedBox(height: AppSpacing.md),

              // ③ القرآن + الأذكار + الصيام + الصدقة
              _anim(2, _IbadahGroup(record: record, quranCtrl: _quranCtrl)),
              const SizedBox(height: AppSpacing.md),

              // ④ المحظورات
              _anim(3, _ProhibitionsGroup(record: record)),
              const SizedBox(height: AppSpacing.md),

              // ⑤ عاداتي وإضافاتي (Custom Ibadaat)
              _anim(4, CustomIbadahGroup(record: record)),
              const SizedBox(height: AppSpacing.md),

              // ⑥ ملاحظة اليوم
              _DayNoteField(record: record),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  static String _hijriMonth(BuildContext context, int m) {
    final l10n = AppLocalizations.of(context)!;
    return [
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
  }
}

class _TopBar extends StatelessWidget {
  final String hijriStr;
  final int netPoints, grossPoints, deducted;
  const _TopBar({
    required this.hijriStr,
    required this.netPoints,
    required this.grossPoints,
    required this.deducted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colors.gold.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawerMenuButton(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.checklistTitle,
                  style: context.typography.headingMedium.copyWith(
                    fontSize: 22,
                    color: context.colors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hijriStr,
                  style: context.typography.caption.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _PointsPill(
                label: AppLocalizations.of(context)!.checklistNetPointsLabel,
                value: netPoints,
                color: netPoints >= 0
                    ? context.colors.gold
                    : context.colors.danger,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _PointsPill(
                    label: '+',
                    value: grossPoints,
                    color: context.colors.success,
                    small: true,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _PointsPill(
                    label: '-',
                    value: deducted,
                    color: context.colors.danger,
                    small: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool small;
  const _PointsPill({
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label$value${AppLocalizations.of(context)!.checklistPointsSuffix}',
        style: context.typography.bodySmall.copyWith(
          fontSize: small ? 10 : 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DayProgressBar extends ConsumerWidget {
  final DailyRecord? record;
  const _DayProgressBar({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const totalIbadah = 11;
    int done = 0;
    if (record != null) {
      if (record!.fajrStatus == PrayerStatus.performed) done++;
      if (record!.dhuhrStatus == PrayerStatus.performed) done++;
      if (record!.asrStatus == PrayerStatus.performed) done++;
      if (record!.maghribStatus == PrayerStatus.performed) done++;
      if (record!.ishaStatus == PrayerStatus.performed) done++;
      if (record!.morningAdhkar) done++;
      if (record!.eveningAdhkar) done++;
      if (record!.quranPages > 0) done++;
      if (record!.fastingType != FastingType.none) done++;
      if (record!.nightPrayer) done++;
      if (record!.ghadhBasar) done++;
    }
    final pct = done / totalIbadah;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.checklistTodayProgress,
                style: context.typography.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                '$done / $totalIbadah',
                style: context.typography.bodySmall.copyWith(
                  color: context.colors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnimatedProgressBar(progress: pct),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _motivate(context, pct),
                style: context.typography.caption.copyWith(
                  color: context.colors.textDim,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: context.typography.caption.copyWith(
                  color: pct >= 0.8
                      ? context.colors.success
                      : context.colors.textDim,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _motivate(BuildContext context, double p) {
    final l10n = AppLocalizations.of(context)!;
    if (p >= 1.0) return l10n.checklistMotivationComplete;
    if (p >= 0.7) return l10n.checklistMotivationGreat;
    if (p >= 0.4) return l10n.checklistMotivationKeepGoing;
    return l10n.checklistMotivationStart;
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  const _AnimatedProgressBar({required this.progress});

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(
        begin: old.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, _) => ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Stack(
        children: [
          Container(height: 10, color: context.colors.border),
          FractionallySizedBox(
            widthFactor: _anim.value.clamp(0.0, 1.0),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.gold,
                    _anim.value >= 0.8
                        ? context.colors.success
                        : context.colors.teal,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.gold.withValues(alpha: 0.3),
                    blurRadius: 6,
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

class _PrayersGroup extends ConsumerWidget {
  final DailyRecord? record;
  const _PrayersGroup({required this.record});

  static const _prayerKeys = [
    ('🌅', 'fajr'),
    ('☀️', 'dhuhr'),
    ('🌤', 'asr'),
    ('🌆', 'maghrib'),
    ('🌃', 'isha'),
  ];

  static String _prayerName(AppLocalizations l10n, String key) => switch (key) {
    'fajr' => l10n.prayerFajr,
    'dhuhr' => l10n.prayerDhuhr,
    'asr' => l10n.prayerAsr,
    'maghrib' => l10n.prayerMaghrib,
    _ => l10n.prayerIsha,
  };

  PrayerStatus _statusOf(String key) {
    if (record == null) return PrayerStatus.pending;
    return switch (key) {
      'fajr' => record!.fajrStatus,
      'dhuhr' => record!.dhuhrStatus,
      'asr' => record!.asrStatus,
      'maghrib' => record!.maghribStatus,
      'isha' => record!.ishaStatus,
      _ => PrayerStatus.pending,
    };
  }

  int get _countPerformed => _prayerKeys
      .where((p) => _statusOf(p.$2) == PrayerStatus.performed)
      .length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _GroupCard(
      icon: '🕌',
      title: l10n.checklistFivePrayersTitle,
      trailing:
          '${_localizedDigits(context, _countPerformed)} / ${_localizedDigits(context, 5)}',
      trailingColor: context.colors.gold,
      children: _prayerKeys.map((p) {
        final status = _statusOf(p.$2);
        return _PrayerRow(
          emoji: p.$1,
          name: _prayerName(l10n, p.$2),
          status: status,
          onStatusChange: (newStatus) async {
            HapticFeedback.selectionClick();
            await _saveAndSync(ref, context, () async {
              final dao = ref.read(dailyRecordDaoProvider);
              final rec = await dao.getOrCreateToday();
              await dao.updatePrayerStatus(
                recordId: rec.id,
                prayerName: p.$2,
                status: newStatus,
              );
              return dao.getRecordByDate(DateTime.now());
            });
          },
        );
      }).toList(),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String emoji, name;
  final PrayerStatus status;
  final void Function(PrayerStatus) onStatusChange;

  const _PrayerRow({
    required this.emoji,
    required this.name,
    required this.status,
    required this.onStatusChange,
  });

  Color _rowColor(BuildContext context) => switch (status) {
    PrayerStatus.performed => context.colors.success,
    PrayerStatus.qadaa => context.colors.warning,
    PrayerStatus.missed => context.colors.danger,
    _ => context.colors.textDim,
  };

  String _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      PrayerStatus.performed => l10n.prayerStatusOnTimeShort,
      PrayerStatus.qadaa => l10n.prayerStatusQadaaShort,
      PrayerStatus.missed => l10n.prayerStatusMissedShort,
      PrayerStatus.pending => l10n.prayerStatusPendingShort,
      _ => l10n.prayerStatusNotDueShort,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDone = status == PrayerStatus.performed;
    final isQadaa = status == PrayerStatus.qadaa;
    final isMissed = status == PrayerStatus.missed;

    // One "$name, $status, button" node instead of the checkmark circle,
    // emoji, name, status and points chip each being a separate,
    // uncoordinated stop for a screen reader — see the audit's "i18n &
    // Accessibility" section.
    return Semantics(
      label:
          '$name${AppLocalizations.of(context)!.semanticsSeparator}${_statusLabel(context)}',
      button: true,
      onTap: () => _showStatusPicker(context),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _showStatusPicker(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isDone
                ? context.colors.success.withValues(alpha: 0.08)
                : isQadaa
                ? context.colors.warning.withValues(alpha: 0.07)
                : isMissed
                ? context.colors.danger.withValues(alpha: 0.07)
                : context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDone
                  ? context.colors.success.withValues(alpha: 0.25)
                  : isQadaa
                  ? context.colors.warning.withValues(alpha: 0.22)
                  : isMissed
                  ? context.colors.danger.withValues(alpha: 0.22)
                  : context.colors.border,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? context.colors.success : Colors.transparent,
                  border: Border.all(
                    color: _rowColor(context),
                    width: isDone ? 0 : 1.8,
                  ),
                ),
                child: isDone
                    ? const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: context.typography.bodyMedium.copyWith(
                        fontSize: 13,
                        color: context.colors.textPrimary,
                        fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      _statusLabel(context),
                      style: context.typography.caption.copyWith(
                        fontSize: 10,
                        color: _rowColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                _MiniPts(_signedPoints(context, 10), context.colors.success)
              else if (isMissed)
                _MiniPts(_signedPoints(context, -5), context.colors.danger),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: context.colors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      // _PrayerStatusSheet has no hand-rolled grab handle (unlike most of
      // this app's other sheets), so this one is a safe, isolated place to
      // add the M6 drag handle instead of introducing a visual duplicate.
      showDragHandle: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PrayerStatusSheet(
        prayerName: name,
        currentStatus: status,
        onSelect: onStatusChange,
      ),
    );
  }
}

// ── Bottom sheet for prayer status ──
class _PrayerStatusSheet extends StatelessWidget {
  final String prayerName;
  final PrayerStatus currentStatus;
  final void Function(PrayerStatus) onSelect;

  const _PrayerStatusSheet({
    required this.prayerName,
    required this.currentStatus,
    required this.onSelect,
  });

  List<(PrayerStatus, String, String, Color)> _options(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      (
        PrayerStatus.performed,
        l10n.prayerStatusPerformedFull,
        '✅',
        context.colors.success,
      ),
      (
        PrayerStatus.qadaa,
        l10n.prayerStatusQadaaFull,
        '🔄',
        context.colors.warning,
      ),
      (
        PrayerStatus.missed,
        l10n.prayerStatusMissedFull,
        '❌',
        context.colors.danger,
      ),
      (
        PrayerStatus.pending,
        l10n.prayerStatusPendingShort,
        '⏳',
        context.colors.textDim,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.checklistPrayerSheetTitle(prayerName),
            style: context.typography.headingMedium.copyWith(
              fontSize: 18,
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: 14),
          ..._options(context).map(
            (opt) => _StatusOption(
              status: opt.$1,
              label: opt.$2,
              emoji: opt.$3,
              color: opt.$4,
              isSelected: currentStatus == opt.$1,
              onTap: () {
                onSelect(opt.$1);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final PrayerStatus status;
  final String label, emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isSelected ? color : context.colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _IbadahGroup extends ConsumerWidget {
  final DailyRecord? record;
  final TextEditingController quranCtrl;
  const _IbadahGroup({required this.record, required this.quranCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (quranCtrl.text.isEmpty && (record?.quranPages ?? 0) > 0) {
      quranCtrl.text = record!.quranPages.toString();
    }

    final l10n = AppLocalizations.of(context)!;
    return _GroupCard(
      icon: '📖',
      title: l10n.checklistQuranAdhkarTitle,
      children: [
        _QuranInput(record: record, ctrl: quranCtrl),
        const SizedBox(height: AppSpacing.sm),

        _ToggleRow(
          emoji: '🌅',
          label: l10n.ibadahMorningAdhkarLabel,
          sublabel: l10n.ibadahMorningAdhkarSublabel,
          points: _signedPoints(context, 5),
          value: record?.morningAdhkar ?? false,
          onChanged: (v) async {
            await _saveAndSync(ref, context, () async {
              final dao = ref.read(dailyRecordDaoProvider);
              final rec = await dao.getOrCreateToday();
              await dao.updateAdhkar(recordId: rec.id, morning: v);
              return dao.getOrCreateToday();
            });
          },
        ),

        _ToggleRow(
          emoji: '🌆',
          label: l10n.ibadahEveningAdhkarLabel,
          sublabel: l10n.ibadahEveningAdhkarSublabel,
          points: _signedPoints(context, 5),
          value: record?.eveningAdhkar ?? false,
          onChanged: (v) async {
            await _saveAndSync(ref, context, () async {
              final dao = ref.read(dailyRecordDaoProvider);
              final rec = await dao.getOrCreateToday();
              await dao.updateAdhkar(recordId: rec.id, evening: v);
              return dao.getOrCreateToday();
            });
          },
        ),

        _ToggleRow(
          emoji: '🌌',
          label: l10n.ibadahQiyamLabel,
          sublabel: l10n.ibadahQiyamSublabel,
          points: _signedPoints(context, 15),
          value: record?.nightPrayer ?? false,
          onChanged: (v) async {
            await _saveAndSync(ref, context, () async {
              final dao = ref.read(dailyRecordDaoProvider);
              final rec = await dao.getOrCreateToday();
              await dao.toggleNightPrayer(rec.id, v);
              return dao.getOrCreateToday();
            });
          },
        ),

        _FastingSelector(record: record),

        _ToggleRow(
          emoji: '💧',
          label: l10n.ibadahSadaqahLabel,
          sublabel: l10n.ibadahSadaqahSublabel,
          points: _signedPoints(context, 10),
          value: record?.sadaqah ?? false,
          onChanged: (v) async {
            await _saveAndSync(ref, context, () async {
              final dao = ref.read(dailyRecordDaoProvider);
              final rec = await dao.getOrCreateToday();
              await dao.toggleSadaqah(rec.id, v);
              return dao.getOrCreateToday();
            });
          },
        ),
        _ToggleRow(
          emoji: '👁️',
          label: l10n.ibadahGhadhBasarLabel,
          sublabel: l10n.ibadahGhadhBasarSublabel,
          points: _signedPoints(context, 10),
          value: record?.ghadhBasar ?? false,
          onChanged: (v) async {
            await _saveAndSync(ref, context, () async {
              final dao = ref.read(dailyRecordDaoProvider);
              final rec = await dao.getOrCreateToday();
              await dao.toggleGhadhBasar(rec.id, v);
              return dao.getOrCreateToday();
            });
          },
        ),
      ],
    );
  }
}

// ── حقل القرآن ──
class _QuranInput extends ConsumerWidget {
  final DailyRecord? record;
  final TextEditingController ctrl;
  const _QuranInput({required this.record, required this.ctrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPages = (record?.quranPages ?? 0) > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: hasPages
            ? context.colors.teal.withValues(alpha: 0.07)
            : context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasPages
              ? context.colors.teal.withValues(alpha: 0.3)
              : context.colors.border,
        ),
      ),
      child: Row(
        children: [
          const Text('📖', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.checklistQuranInputLabel,
                  style: context.typography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.checklistQuranPagesHint,
                  style: context.typography.caption.copyWith(
                    fontSize: 10,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: TextFormField(
              controller: ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: context.typography.bodyMedium.copyWith(
                fontSize: 15,
                color: context.colors.teal,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: _localizedDigits(context, 0),
                hintStyle: context.typography.caption.copyWith(
                  fontSize: 13,
                  color: context.colors.textDim,
                ),
                filled: true,
                fillColor: context.colors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: context.colors.teal,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) async {
                final pages = int.tryParse(v) ?? 0;
                await _saveAndSync(ref, context, () async {
                  final dao = ref.read(dailyRecordDaoProvider);
                  final rec = await dao.getOrCreateToday();
                  await dao.updateQuran(recordId: rec.id, pages: pages);
                  return dao.getOrCreateToday();
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _signedPoints(context, 1),
            style: context.typography.caption.copyWith(
              fontSize: 10,
              color: context.colors.teal,
            ),
          ),
          Text(
            AppLocalizations.of(context)!.checklistQuranPageSuffix,
            style: context.typography.caption.copyWith(
              fontSize: 9,
              color: context.colors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle Row ──
class _ToggleRow extends StatelessWidget {
  final String emoji, label, sublabel, points;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleRow({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.points,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // One "$label, on/off" toggle node instead of the checkmark circle,
    // emoji, label, sublabel and points chip each being a separate stop.
    return Semantics(
      label:
          '$label${AppLocalizations.of(context)!.semanticsSeparator}$sublabel',
      toggled: value,
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: value
                ? context.colors.success.withValues(alpha: 0.08)
                : context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: value
                  ? context.colors.success.withValues(alpha: 0.25)
                  : context.colors.border,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? context.colors.success : Colors.transparent,
                  border: Border.all(
                    color: value
                        ? context.colors.success
                        : context.colors.border,
                    width: 1.8,
                  ),
                ),
                child: value
                    ? const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.typography.bodyMedium.copyWith(
                        fontSize: 13,
                        color: context.colors.textPrimary,
                        fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: context.typography.caption.copyWith(
                        fontSize: 10,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (value) _MiniPts(points, context.colors.success),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fasting Selector ──
class _FastingSelector extends ConsumerWidget {
  final DailyRecord? record;
  const _FastingSelector({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = record?.fastingType ?? FastingType.none;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: current != FastingType.none
            ? context.colors.teal.withValues(alpha: 0.07)
            : context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: current != FastingType.none
              ? context.colors.teal.withValues(alpha: 0.25)
              : context.colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.checklistFastingLabel,
                  style: context.typography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              if (current != FastingType.none)
                _MiniPts(
                  _signedPoints(context, current == FastingType.fard ? 20 : 10),
                  context.colors.teal,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _fastChip(
                l10n.fastingTypeFard,
                FastingType.fard,
                current,
                context.colors.gold,
                ref,
                context,
              ),
              const SizedBox(width: 6),
              _fastChip(
                l10n.fastingTypeNafl,
                FastingType.nafl,
                current,
                context.colors.teal,
                ref,
                context,
              ),
              const SizedBox(width: 6),
              _fastChip(
                l10n.fastingTypeNone,
                FastingType.none,
                current,
                context.colors.textDim,
                ref,
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fastChip(
    String label,
    FastingType value,
    FastingType current,
    Color color,
    WidgetRef ref,
    BuildContext context,
  ) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.selectionClick();
          await _saveAndSync(ref, context, () async {
            final dao = ref.read(dailyRecordDaoProvider);
            final rec = await dao.getOrCreateToday();
            await dao.updateFasting(rec.id, value);
            return dao.getOrCreateToday();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.4)
                  : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: context.typography.caption.copyWith(
                fontSize: 11,
                color: selected ? color : context.colors.textDim,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProhibitionsGroup extends ConsumerWidget {
  final DailyRecord? record;
  const _ProhibitionsGroup({required this.record});

  static const _items = [
    (ProhibitionCategory.gheeba, '🗣️'),
    (ProhibitionCategory.nameema, '👂'),
    (ProhibitionCategory.kadhb, '🚫'),
    (ProhibitionCategory.ghaDab, '😠'),
    (ProhibitionCategory.idaatWaqt, '📱'),
  ];

  static (String, String) _text(AppLocalizations l10n, ProhibitionCategory c) {
    switch (c) {
      case ProhibitionCategory.gheeba:
        return (l10n.prohibitionGheebaName, l10n.prohibitionGheebaDesc);
      case ProhibitionCategory.nameema:
        return (l10n.prohibitionNameemaName, l10n.prohibitionNameemaDesc);
      case ProhibitionCategory.kadhb:
        return (l10n.prohibitionKadhbName, l10n.prohibitionKadhbDesc);
      case ProhibitionCategory.ghaDab:
        return (l10n.prohibitionGhadabName, l10n.prohibitionGhadabDesc);
      case ProhibitionCategory.idaatWaqt:
        return (l10n.prohibitionIdaatWaqtName, l10n.prohibitionIdaatWaqtDesc);
      case ProhibitionCategory.ghadhBasar:
      case ProhibitionCategory.custom:
        throw StateError('Not a checklist prohibition category: $c');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _GroupCard(
      icon: '⚠️',
      title: l10n.checklistProhibitionsTitle,
      titleColor: context.colors.danger,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AppSpacing.sm,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: context.colors.danger.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.colors.danger.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.checklistProhibitionsSubtitle,
                  style: context.typography.caption.copyWith(
                    fontSize: 11,
                    color: context.colors.danger.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._items.map((item) {
          final (name, desc) = _text(l10n, item.$1);
          return _ProhibitionRow(
            category: item.$1,
            emoji: item.$2,
            name: name,
            desc: desc,
            recordId: record?.id,
          );
        }),
      ],
    );
  }
}

class _ProhibitionRow extends ConsumerStatefulWidget {
  final ProhibitionCategory category;
  final String emoji, name, desc;
  final int? recordId;

  const _ProhibitionRow({
    required this.category,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.recordId,
  });

  @override
  ConsumerState<_ProhibitionRow> createState() => _ProhibitionRowState();
}

class _ProhibitionRowState extends ConsumerState<_ProhibitionRow> {
  bool _committed = false;
  int _count = 0;

  Future<void> _toggle() async {
    if (widget.recordId == null) return;
    HapticFeedback.selectionClick();
    final newVal = !_committed;
    final prevCount = _count;
    setState(() {
      _committed = newVal;
      if (!newVal) _count = 0;
    });

    await _saveAndSync(
      ref,
      context,
      () async {
        final dao = ref.read(dailyRecordDaoProvider);
        await dao.logProhibition(
          recordId: widget.recordId!,
          category: widget.category,
          committed: newVal,
          timesCount: newVal ? (_count == 0 ? 1 : _count) : 0,
        );
        return dao.getOrCreateToday();
      },
      onSaveError: () {
        if (mounted) {
          setState(() {
            _committed = !newVal;
            _count = prevCount;
          });
        }
      },
    );
  }

  Future<void> _increment() async {
    if (!_committed || widget.recordId == null) return;
    HapticFeedback.selectionClick();
    final prevCount = _count;
    setState(() => _count++);
    await _saveAndSync(
      ref,
      context,
      () async {
        final dao = ref.read(dailyRecordDaoProvider);
        await dao.logProhibition(
          recordId: widget.recordId!,
          category: widget.category,
          committed: true,
          timesCount: _count,
        );
        return dao.getOrCreateToday();
      },
      onSaveError: () {
        if (mounted) setState(() => _count = prevCount);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: _committed
            ? context.colors.danger.withValues(alpha: 0.07)
            : context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _committed
              ? context.colors.danger.withValues(alpha: 0.25)
              : context.colors.border,
        ),
      ),
      child: Row(
        children: [
          // One "$name, committed/not committed" toggle node instead of
          // the checkmark box being an unlabeled stop on its own.
          Semantics(
            label:
                '${widget.name}${AppLocalizations.of(context)!.semanticsSeparator}${widget.desc}',
            toggled: _committed,
            onTap: _toggle,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  color: _committed
                      ? context.colors.danger
                      : Colors.transparent,
                  border: Border.all(
                    color: _committed
                        ? context.colors.danger
                        : context.colors.border,
                    width: 1.8,
                  ),
                ),
                child: _committed
                    ? const Center(
                        child: Text(
                          '✗',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(widget.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: context.typography.bodyMedium.copyWith(
                    fontSize: 13,
                    color: _committed
                        ? context.colors.danger
                        : context.colors.textPrimary,
                    fontWeight: _committed ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Text(
                  widget.desc,
                  style: context.typography.caption.copyWith(
                    fontSize: 10,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_committed) ...[
            Semantics(
              label: AppLocalizations.of(
                context,
              )!.checklistIncrementSemanticLabel(widget.name, _count),
              button: true,
              onTap: _increment,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: _increment,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: context.colors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_count×',
                        style: context.typography.bodySmall.copyWith(
                          fontSize: 12,
                          color: context.colors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: context.colors.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _MiniPts(_signedPoints(context, -10), context.colors.danger),
          ],
        ],
      ),
    );
  }
}

class _DayNoteField extends ConsumerStatefulWidget {
  final DailyRecord? record;
  const _DayNoteField({required this.record});

  @override
  ConsumerState<_DayNoteField> createState() => _DayNoteFieldState();
}

class _DayNoteFieldState extends ConsumerState<_DayNoteField> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.record?.notes ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _GroupCard(
      icon: '📝',
      title: l10n.checklistNoteTitle,
      children: [
        TextFormField(
          controller: _ctrl,
          maxLines: 3,
          maxLength: 300,
          style: context.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: context.colors.textPrimary,
            height: 1.8,
          ),
          decoration: InputDecoration(
            hintText: l10n.checklistNoteHint,
            hintStyle: context.typography.caption.copyWith(
              fontSize: 12,
              color: context.colors.textDim,
            ),
            counterStyle: context.typography.caption.copyWith(
              fontSize: 10,
              color: context.colors.textDim,
            ),
            filled: true,
            fillColor: context.colors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.colors.gold, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          onTap: _saving ? null : () async => _save(),
          label: l10n.checklistNoteSaveButton,
          isLoading: _saving,
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final bool saved;
    try {
      saved = await _saveAndSync(ref, context, () async {
        final rec = await ref.read(dailyRecordDaoProvider).getOrCreateToday();
        final db = ref.read(appDatabaseProvider);
        await (db.update(
          db.dailyRecords,
        )..where((r) => r.id.equals(rec.id))).write(
          DailyRecordsCompanion(
            notes: Value(_ctrl.text.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return ref.read(dailyRecordDaoProvider).getOrCreateToday();
      });
    } finally {
      // In a finally, not right after the await: without it, a save that
      // throws left the button stuck showing its loading state forever —
      // the same defect PrimaryButton itself had before it grew a
      // try/finally around its own tap handler.
      if (mounted) setState(() => _saving = false);
    }
    // _saveAndSync already showed its own SnackBar on failure; only add this
    // one on top when the local write actually succeeded.
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.checklistNoteSaved,
            style: context.typography.bodySmall.copyWith(fontSize: 13),
          ),
          backgroundColor: context.colors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class _GroupCard extends StatelessWidget {
  final String icon, title;
  final Color? titleColor, trailingColor;
  final String? trailing;
  final List<Widget> children;

  const _GroupCard({
    required this.icon,
    required this.title,
    required this.children,
    this.titleColor,
    this.trailingColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: context.typography.headingMedium.copyWith(
                  fontSize: 16,
                  color: titleColor ?? context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: context.typography.bodySmall.copyWith(
                    fontSize: 12,
                    color: trailingColor ?? context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(height: 1, color: context.colors.border),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MiniPts extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniPts(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: context.typography.caption.copyWith(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
