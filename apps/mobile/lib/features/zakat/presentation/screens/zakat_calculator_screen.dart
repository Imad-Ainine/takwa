import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/database/app_database.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/primary_switch.dart';
import 'package:takwa/features/reminders/presentation/widgets/add_reminder_bottom_sheet.dart';
import 'package:takwa/features/zakat/domain/zakat_calculator.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Zakat al-Mal calculator. See docs/specs/zakat-calculator.md.
///
/// Deliberately never asserts a "current" gold/silver price itself — the
/// user supplies today's price per gram, since a bundled or fetched number
/// would go stale between app releases for a calculation that matters.
class ZakatCalculatorScreen extends ConsumerStatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  ConsumerState<ZakatCalculatorScreen> createState() =>
      _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState
    extends ConsumerState<ZakatCalculatorScreen> {
  final _cashCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _goldGramsCtrl = TextEditingController();
  final _goldPriceCtrl = TextEditingController();
  final _silverGramsCtrl = TextEditingController();
  final _silverPriceCtrl = TextEditingController();
  final _tradeGoodsCtrl = TextEditingController();
  final _debtCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();

  ZakatNisabBasis _nisabBasis = ZakatNisabBasis.silver;
  bool _hawlConfirmed = false;
  ZakatResult? _result;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    final latest = await ref.read(zakatDaoProvider).getLatest();
    if (latest == null || !mounted) return;
    setState(() {
      _cashCtrl.text = _fmtInput(latest.cashAmount);
      _bankCtrl.text = _fmtInput(latest.bankAmount);
      _goldGramsCtrl.text = _fmtInput(latest.goldGrams);
      _goldPriceCtrl.text = _fmtInput(latest.goldPricePerGram);
      _silverGramsCtrl.text = _fmtInput(latest.silverGrams);
      _silverPriceCtrl.text = _fmtInput(latest.silverPricePerGram);
      _tradeGoodsCtrl.text = _fmtInput(latest.tradeGoodsValue);
      _debtCtrl.text = _fmtInput(latest.debtAmount);
      _currencyCtrl.text = latest.currencyLabel;
      _nisabBasis = latest.nisabStandard == NisabStandard.gold
          ? ZakatNisabBasis.gold
          : ZakatNisabBasis.silver;
      _hawlConfirmed = latest.hawlConfirmed;
    });
  }

  static String _fmtInput(double v) => v == 0 ? '' : _trimZeros(v);

  static String _trimZeros(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  ZakatInputs get _inputs => ZakatInputs(
    cashAmount: _num(_cashCtrl),
    bankAmount: _num(_bankCtrl),
    goldGrams: _num(_goldGramsCtrl),
    goldPricePerGram: _num(_goldPriceCtrl),
    silverGrams: _num(_silverGramsCtrl),
    silverPricePerGram: _num(_silverPriceCtrl),
    tradeGoodsValue: _num(_tradeGoodsCtrl),
    debtAmount: _num(_debtCtrl),
    nisabBasis: _nisabBasis,
    hawlConfirmed: _hawlConfirmed,
  );

  void _calculate() {
    setState(() => _result = computeZakat(_inputs));
  }

  Future<void> _save() async {
    final inputs = _inputs;
    final result = _result ?? computeZakat(inputs);
    await ref.read(zakatDaoProvider).save(
      ZakatCalculationsCompanion.insert(
        cashAmount: Value(inputs.cashAmount),
        bankAmount: Value(inputs.bankAmount),
        goldGrams: Value(inputs.goldGrams),
        goldPricePerGram: Value(inputs.goldPricePerGram),
        silverGrams: Value(inputs.silverGrams),
        silverPricePerGram: Value(inputs.silverPricePerGram),
        tradeGoodsValue: Value(inputs.tradeGoodsValue),
        debtAmount: Value(inputs.debtAmount),
        nisabStandard: Value(
          _nisabBasis == ZakatNisabBasis.gold
              ? NisabStandard.gold
              : NisabStandard.silver,
        ),
        currencyLabel: Value(_currencyCtrl.text.trim()),
        hawlConfirmed: Value(inputs.hawlConfirmed),
        resultDue: Value(result.amountDue),
      ),
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.zakatSavedMessage)));
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _bankCtrl.dispose();
    _goldGramsCtrl.dispose();
    _goldPriceCtrl.dispose();
    _silverGramsCtrl.dispose();
    _silverPriceCtrl.dispose();
    _tradeGoodsCtrl.dispose();
    _debtCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DisclaimerBanner(text: l10n.zakatDisclaimer),
                        const SizedBox(height: AppSpacing.lg),
                        _sectionTitle(context, l10n.zakatAssetsSectionTitle),
                        const SizedBox(height: AppSpacing.sm),
                        _numberField(l10n.zakatCashLabel, _cashCtrl),
                        _numberField(l10n.zakatBankLabel, _bankCtrl),
                        _numberField(l10n.zakatGoldGramsLabel, _goldGramsCtrl),
                        _numberField(l10n.zakatGoldPriceLabel, _goldPriceCtrl),
                        _numberField(
                          l10n.zakatSilverGramsLabel,
                          _silverGramsCtrl,
                        ),
                        _numberField(
                          l10n.zakatSilverPriceLabel,
                          _silverPriceCtrl,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.md,
                          ),
                          child: Text(
                            l10n.zakatPriceHelperText,
                            style: context.typography.caption,
                          ),
                        ),
                        _numberField(
                          l10n.zakatTradeGoodsLabel,
                          _tradeGoodsCtrl,
                        ),
                        _numberField(l10n.zakatDebtLabel, _debtCtrl),
                        TextFormField(
                          controller: _currencyCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.zakatCurrencyLabel,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _sectionTitle(context, l10n.zakatNisabSectionTitle),
                        const SizedBox(height: AppSpacing.sm),
                        _NisabPicker(
                          value: _nisabBasis,
                          onChanged: (v) => setState(() => _nisabBasis = v),
                          l10n: l10n,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _HawlToggle(
                          value: _hawlConfirmed,
                          onChanged: (v) =>
                              setState(() => _hawlConfirmed = v),
                          l10n: l10n,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: l10n.zakatCalculateButton,
                          onTap: _calculate,
                        ),
                        if (_result != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _ResultCard(
                            result: _result!,
                            currency: _currencyCtrl.text.trim(),
                            l10n: l10n,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: l10n.zakatSaveButton,
                            isOutline: true,
                            onTap: _save,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => AddReminderBottomSheet(
                                initialTitle: l10n.zakatReminderDefaultTitle,
                              ),
                            ),
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: Text(l10n.zakatSetReminderButton),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),
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
              l10n.zakatCalculatorAppBarTitle,
              style: context.typography.headingMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text, style: context.typography.headingMedium);
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  final String text;
  const _DisclaimerBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.goldDim,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: context.typography.caption.copyWith(
          color: context.colors.goldText,
        ),
      ),
    );
  }
}

class _NisabPicker extends StatelessWidget {
  final ZakatNisabBasis value;
  final ValueChanged<ZakatNisabBasis> onChanged;
  final AppLocalizations l10n;
  const _NisabPicker({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _option(
            context,
            l10n.zakatNisabGoldOption,
            ZakatNisabBasis.gold,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _option(
            context,
            l10n.zakatNisabSilverOption,
            ZakatNisabBasis.silver,
          ),
        ),
      ],
    );
  }

  Widget _option(BuildContext context, String label, ZakatNisabBasis basis) {
    final selected = value == basis;
    return GestureDetector(
      onTap: () => onChanged(basis),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.colors.goldDim : context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? context.colors.gold
                : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: context.typography.labelLarge.copyWith(
            color: selected ? context.colors.goldText : context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _HawlToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppLocalizations l10n;
  const _HawlToggle({
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.zakatHawlLabel, style: context.typography.labelLarge),
                const SizedBox(height: 2),
                Text(l10n.zakatHawlSublabel, style: context.typography.caption),
              ],
            ),
          ),
          PrimarySwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ZakatResult result;
  final String currency;
  final AppLocalizations l10n;
  const _ResultCard({
    required this.result,
    required this.currency,
    required this.l10n,
  });

  String _fmt(double v) {
    final suffix = currency.isEmpty ? '' : ' $currency';
    return '${v.toStringAsFixed(2)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.zakatResultTitle, style: context.typography.headingMedium),
          const SizedBox(height: AppSpacing.md),
          _row(context, l10n.zakatResultWealthLabel, _fmt(result.netWealth)),
          _row(
            context,
            l10n.zakatResultNisabLabel,
            result.nisabThreshold > 0
                ? _fmt(result.nisabThreshold)
                : l10n.zakatMissingPriceMessage,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_message(), style: context.typography.bodyLarge.copyWith(
            color: result.zakatDue ? context.colors.success : context.colors.textSecondary,
            fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }

  String _message() {
    if (result.zakatDue) {
      return l10n.zakatResultDueMessage(_fmt(result.amountDue));
    }
    if (result.meetsNisab) {
      return l10n.zakatResultHawlPendingMessage;
    }
    if (result.nisabThreshold > 0) {
      return '${l10n.zakatResultNotDueMessage}\n'
          '${l10n.zakatResultShortfallMessage(_fmt(result.shortfallToNisab))}';
    }
    return l10n.zakatResultNotDueMessage;
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.typography.bodyMedium),
          Text(
            value,
            style: context.typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
