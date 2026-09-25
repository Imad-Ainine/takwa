import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/features/occasions/domain/islamic_occasions.dart';
import 'package:takwa/features/reminders/presentation/widgets/add_reminder_bottom_sheet.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Read-only Islamic occasions + White Days screen. See
/// docs/specs/islamic-occasions.md. No notification scheduling here — an
/// "add reminder" shortcut deep-links into the existing Reminders feature
/// instead of building a second, date-aware scheduler (see the spec's
/// Non-goals).
class IslamicOccasionsScreen extends StatelessWidget {
  const IslamicOccasionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final occasions = resolveAllOccasions();
    final whiteDays = resolveWhiteDays();

    // Sort by daysUntil ascending; tie-break alphabetically by localized name
    // (R11.2 — occasions with equal daysUntil must be sorted alphabetically).
    occasions.sort((a, b) {
      final byDays = a.daysUntil.compareTo(b.daysUntil);
      if (byDays != 0) return byDays;
      return _occasionName(l10n, a.kind).compareTo(_occasionName(l10n, b.kind));
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, l10n),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    children: [
                      _WhiteDaysCard(whiteDays: whiteDays, l10n: l10n),
                      const SizedBox(height: AppSpacing.xl),
                      ...occasions.map(
                        (o) => _OccasionTile(occasion: o, l10n: l10n),
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

  Widget _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          CustomLeadingButton(onPressed: () => Navigator.pop(context)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.occasionsAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
        ],
      ),
    );
  }
}

String _occasionName(AppLocalizations l10n, IslamicOccasionKind kind) =>
    switch (kind) {
      IslamicOccasionKind.ashura => l10n.occasionAshura,
      IslamicOccasionKind.isra1Miraj => l10n.occasionIsraMiraj,
      IslamicOccasionKind.ramadanStart => l10n.occasionRamadanStart,
      IslamicOccasionKind.eidAlFitr => l10n.occasionEidAlFitr,
      IslamicOccasionKind.mawlid => l10n.occasionMawlid,
      IslamicOccasionKind.eidAlAdha => l10n.occasionEidAlAdha,
      IslamicOccasionKind.islamicNewYear => l10n.occasionIslamicNewYear,
      IslamicOccasionKind.laylatAlQadr => l10n.occasionLaylatAlQadr,
      IslamicOccasionKind.dayOfArafah => l10n.occasionDayOfArafah,
    };

String _daysUntilLabel(AppLocalizations l10n, int daysUntil) =>
    daysUntil == 0 ? l10n.occasionsDaysUntilToday : l10n.occasionsDaysUntil(daysUntil);

void _openAddReminder(BuildContext context, String title) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddReminderBottomSheet(initialTitle: title),
  );
}

// ---------------------------------------------------------------------------
// Fasting chip — shown on occasions and White Days where fasting is recommended.
// ---------------------------------------------------------------------------

/// Small chip displayed next to an occasion or White Day title when voluntary
/// fasting is specifically recommended on that day (R12.1–12.4).
class _FastingChip extends StatelessWidget {
  final AppLocalizations l10n;
  const _FastingChip({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.goldDim,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
      ),
      child: Text(
        l10n.occasionsFastingRecommended,
        style: context.typography.caption.copyWith(
          color: context.colors.goldText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// White Days card
// ---------------------------------------------------------------------------

class _WhiteDaysCard extends StatelessWidget {
  final List<WhiteDay> whiteDays;
  final AppLocalizations l10n;
  const _WhiteDaysCard({required this.whiteDays, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.MMMd();

    // R10.3 — highlight the White Day with the smallest non-negative daysUntil.
    // Fall back to smallest absolute value only if all have passed (should not
    // happen after the R10 domain fix, but kept for safety).
    final upcoming = whiteDays.where((d) => d.daysUntil >= 0);
    final soonest = upcoming.isNotEmpty
        ? upcoming.reduce((a, b) => a.daysUntil < b.daysUntil ? a : b)
        : whiteDays.reduce(
            (a, b) => a.daysUntil.abs() < b.daysUntil.abs() ? a : b,
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.goldDim,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.occasionsWhiteDaysTitle,
                  style: context.typography.labelLarge.copyWith(
                    color: context.colors.goldText,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: context.colors.gold,
                ),
                tooltip: l10n.occasionsAddReminderTooltip,
                onPressed: () =>
                    _openAddReminder(context, l10n.occasionsWhiteDaysTitle),
              ),
            ],
          ),
          Text(l10n.occasionsWhiteDaysSubtitle, style: context.typography.caption),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: whiteDays
                .map(
                  (d) => Column(
                    children: [
                      Text(
                        dateFmt.format(d.gregorianDate),
                        style: context.typography.bodyMedium.copyWith(
                          fontWeight:
                              d == soonest ? FontWeight.w800 : FontWeight.w400,
                          color: d == soonest
                              ? context.colors.gold
                              : context.colors.textPrimary,
                        ),
                      ),
                      Text(
                        _daysUntilLabel(l10n, d.daysUntil),
                        style: context.typography.caption,
                      ),
                      const SizedBox(height: 4),
                      // White Days always have isFastingRecommended = true (R12.1, 12.3)
                      _FastingChip(l10n: l10n),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Occasion tile
// ---------------------------------------------------------------------------

class _OccasionTile extends StatelessWidget {
  final ResolvedOccasion occasion;
  final AppLocalizations l10n;
  const _OccasionTile({required this.occasion, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final name = _occasionName(l10n, occasion.kind);
    // Spec R3 is "when the user taps an occasion" — the bell icon alone was a
    // small affordance most users never find, so the whole card is the action.
    return Semantics(
      button: true,
      label: l10n.occasionsAddReminderTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openAddReminder(context, name),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // R12.3 — fasting chip has the same visual form and position
                    // on every annotated occasion.
                    if (occasion.isFastingRecommended) ...[
                      _FastingChip(l10n: l10n),
                      const SizedBox(height: 4),
                    ],
                    Text(name, style: context.typography.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFmt.format(occasion.gregorianDate)} · ${_daysUntilLabel(l10n, occasion.daysUntil)}',
                      style: context.typography.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: context.colors.textDim,
                ),
                tooltip: l10n.occasionsAddReminderTooltip,
                onPressed: () => _openAddReminder(context, name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
