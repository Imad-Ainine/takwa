import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Totals + history for Sadaqah logged via the daily checklist. See
/// docs/specs/sadaqah-tracker.md — this is a read-only view over
/// `DailyRecords.sadaqah`/`sadaqahAmount`, no new table.
class SadaqahTrackerScreen extends ConsumerWidget {
  const SadaqahTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(sadaqahCurrencyProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context, ref, l10n, currency),
        backgroundColor: context.colors.gold,
        foregroundColor: const Color(0xFF241B05),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.sadaqahLogButton),
      ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CurrencyRow(l10n: l10n),
                        const SizedBox(height: AppSpacing.md),
                        _TotalsRow(l10n: l10n),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.sadaqahHistoryTitle,
                          style: context.typography.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _HistoryList(l10n: l10n),
                        // Extra bottom padding so the FAB doesn't overlap the last row
                        const SizedBox(height: AppSpacing.xxl * 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currency,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) =>
          _LogSadaqahSheet(l10n: l10n, ref: ref, currency: currency),
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
              l10n.sadaqahTrackerAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for logging a Sadaqah entry on an arbitrary date.
class _LogSadaqahSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final WidgetRef ref;
  final String currency;

  const _LogSadaqahSheet({
    required this.l10n,
    required this.ref,
    required this.currency,
  });

  @override
  State<_LogSadaqahSheet> createState() => _LogSadaqahSheetState();
}

class _LogSadaqahSheetState extends State<_LogSadaqahSheet> {
  late DateTime _selectedDate;
  final _amountController = TextEditingController();
  String? _amountError;
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat.yMMMd().format(date);

  /// Returns the parsed amount on success, null when there's a validation error.
  /// Blank input → 0.0 (valid). Otherwise must be in [0.01, 999_999_999.99]
  /// with up to 2 decimal places.
  double? _validateAmount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 0.0;

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < 0.01 || parsed > 999999999.99) return null;

    // Reject more than 2 decimal places
    final parts = trimmed.split('.');
    if (parts.length == 2 && parts[1].length > 2) return null;

    return parsed;
  }

  Future<void> _confirm() async {
    final raw = _amountController.text;
    final amount = _validateAmount(raw);

    if (amount == null) {
      setState(() {
        _amountError = widget.l10n.sadaqahAmountInvalidError;
        _saveError = null;
      });
      return;
    }

    setState(() {
      _amountError = null;
      _saveError = null;
      _saving = true;
    });

    try {
      await widget.ref
          .read(dailyRecordDaoProvider)
          .logSadaqahForDate(_selectedDate, amount);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError = widget.l10n.sadaqahLogErrorText;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sheet handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.sadaqahLogSheetTitle,
            style: context.typography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Date picker row
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.sadaqahLogDateLabel,
                    style: context.typography.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(_selectedDate),
                    style: context.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Amount field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.sadaqahAmountFieldLabel,
              errorText: _amountError,
              // Shows which unit the number is in, so the totals on this
              // screen can't be read as a different currency.
              suffixText: widget.currency.isEmpty ? null : widget.currency,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            onChanged: (_) {
              if (_amountError != null) {
                setState(() => _amountError = null);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Save error
          if (_saveError != null) ...[
            Text(
              _saveError!,
              style: context.typography.caption.copyWith(
                color: context.colors.dangerText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Confirm button
          PrimaryButton(
            label: l10n.sadaqahLogConfirmButton,
            onTap: _saving ? null : _confirm,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends ConsumerWidget {
  final AppLocalizations l10n;
  const _TotalsRow({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(sadaqahTotalsProvider);
    final currency = ref.watch(sadaqahCurrencyProvider);

    return totalsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: TakwaLoadingIndicator()),
      ),
      error: (_, _) => const SizedBox(),
      data: (totals) {
        final (week, month, allTime) = totals;
        return Row(
          children: [
            Expanded(
              child: _totalCard(
                context,
                l10n.sadaqahTotalsWeekLabel,
                week,
                currency,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _totalCard(
                context,
                l10n.sadaqahTotalsMonthLabel,
                month,
                currency,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _totalCard(
                context,
                l10n.sadaqahTotalsAllTimeLabel,
                allTime,
                currency,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _totalCard(
    BuildContext context,
    String label,
    double value,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(
            // Same formatter as the history list: truncating cents here made
            // a 12.50 entry read as "12" in the totals and "12.5" below it.
            value > 0 ? _formatSadaqahAmount(value, currency) : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.labelLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.colors.gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.typography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The tracker's amounts are unitless in the database, so the unit has to be
/// stated once, here, rather than in every row.
class _CurrencyRow extends ConsumerWidget {
  final AppLocalizations l10n;
  const _CurrencyRow({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(sadaqahCurrencyProvider);

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton.icon(
        onPressed: () => _showCurrencyDialog(context, ref, currency),
        icon: Icon(
          Icons.payments_outlined,
          size: 18,
          color: currency.isEmpty
              ? context.colors.textDim
              : context.colors.gold,
        ),
        label: Text(
          currency.isEmpty ? l10n.sadaqahCurrencyNotSet : currency,
          style: context.typography.caption.copyWith(
            color: currency.isEmpty
                ? context.colors.textDim
                : context.colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _showCurrencyDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current);

    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.card,
        title: Text(l10n.sadaqahCurrencyDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: l10n.sadaqahCurrencyFieldHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sadaqahCurrencyNote,
              style: context.typography.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    controller.dispose();
    if (saved == null) return;
    await ref
        .read(settingsDaoProvider)
        .set(kSadaqahCurrencySettingKey, saved);
  }
}

/// Up to two decimals, no trailing `.00`, with the user's currency label
/// appended when one is set. Plain ASCII digits, matching the rest of the
/// app's money display.
String _formatSadaqahAmount(double value, String currency) {
  final text = NumberFormat('#,##0.##', 'en_US').format(value);
  return currency.isEmpty ? text : '$text $currency';
}

class _HistoryList extends ConsumerWidget {
  final AppLocalizations l10n;
  const _HistoryList({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sadaqahHistoryProvider);
    final currency = ref.watch(sadaqahCurrencyProvider);

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: TakwaLoadingIndicator()),
      ),
      error: (_, _) => const SizedBox(),
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                l10n.sadaqahHistoryEmpty,
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          );
        }
        final dateFmt = DateFormat.yMMMd();
        return Column(
          children: records
              .map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFmt.format(r.date),
                        style: context.typography.bodyMedium,
                      ),
                      Text(
                        r.sadaqahAmount > 0
                            ? _formatSadaqahAmount(r.sadaqahAmount, currency)
                            : l10n.sadaqahLoggedNoAmount,
                        style: context.typography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: r.sadaqahAmount > 0
                              ? context.colors.textPrimary
                              : context.colors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
