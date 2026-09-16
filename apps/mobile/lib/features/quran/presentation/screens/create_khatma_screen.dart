import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/database_providers.dart';
import '../../data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import 'package:takwa/l10n/app_localizations.dart';

// Styles are managed via AdaptiveStyle for consistent theming (including Ramadan mode).

class CreateKhatmaScreen extends ConsumerStatefulWidget {
  const CreateKhatmaScreen({super.key});
  @override
  ConsumerState<CreateKhatmaScreen> createState() => _CreateKhatmaScreenState();
}

class _CreateKhatmaScreenState extends ConsumerState<CreateKhatmaScreen> {
  int _step = 0; // 0, 1, 2

  // Step 0 state
  final _nameCtrl = TextEditingController();
  KhatmaType _type = KhatmaType.muyassara;

  // Step 1 state
  DateTime _startDate = DateTime.now();
  int _startPage = 1;
  bool _notificationsEnabled = false;

  bool _defaultNameSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default name — set once, so it doesn't clobber what the user typed.
    if (!_defaultNameSet) {
      _defaultNameSet = true;
      _nameCtrl.text = AppLocalizations.of(
        context,
      )!.createKhatmaDefaultNamePrefix(hijriMonthYearLabel());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final khatma = ref.watch(khatmaExProvider);

    return Scaffold(
      backgroundColor: style.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(style, l10n),
            _buildStepIndicator(style),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 0
                      ? _buildStep0(style, l10n)
                      : _step == 1
                      ? _buildStep1(style, l10n)
                      : _buildStep2(style, l10n),
                ),
              ),
            ),
            _buildBottomBar(style, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AdaptiveStyle style, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          const CustomLeadingButton(),
          const Spacer(),
          Text(
            l10n.createKhatmaTitle,
            style: style.amiri(22, color: style.text, weight: FontWeight.bold),
          ),
          const Spacer(),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(AdaptiveStyle style) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
      child: Row(
        children: [
          _stepDot(0, style),
          Expanded(child: _stepLine(0, style)),
          _stepDot(1, style),
          Expanded(child: _stepLine(1, style)),
          _stepDot(2, style),
        ],
      ),
    );
  }

  Widget _stepDot(int s, AdaptiveStyle style) {
    final active = s == _step;
    final done = s < _step;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? (style.isRamadan ? style.gold : style.teal)
            : done
            ? (style.isRamadan ? style.gold : style.teal).withValues(alpha: 0.7)
            : style.card,
        border: Border.all(
          color: active || done
              ? (style.isRamadan ? style.gold : style.teal)
              : style.border,
          width: active ? 2 : 1,
        ),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '${s + 1}',
                style: style.amiri(
                  13,
                  color: active || done ? Colors.white : style.textDim,
                  weight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _stepLine(int s, AdaptiveStyle style) => Container(
    height: 2,
    color: s < _step
        ? (style.isRamadan ? style.gold : style.teal).withValues(alpha: 0.6)
        : style.border,
  );

  // ──────────────────── STEP 0: Name & Type ────────────────────
  Widget _buildStep0(AdaptiveStyle style, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _card(
            style,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TakwaTappable(
                      onTap: () {
                        // edit name
                      },
                      // Inline with the label text via spaceBetween.
                      minTapSize: null,
                      child: Icon(
                        Icons.edit_rounded,
                        color: style.gold,
                        size: 18,
                      ),
                    ),
                    Text(
                      l10n.createKhatmaNameLabel,
                      style: style.amiri(
                        18,
                        color: style.text,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameCtrl,
                  textAlign: TextAlign.start,
                  textDirection: Directionality.of(context),
                  style: style.naskh(15, color: style.text),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: style.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: style.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: style.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: style.isRamadan ? style.gold : style.teal,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            style,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.createKhatmaTypeLabel,
                      style: style.amiri(
                        18,
                        color: style.text,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.account_tree_rounded,
                      color: style.gold,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.createKhatmaTypeSubtitle,
                    style: style.naskh(12, color: style.textDim),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Radio(groupValue:, onChanged:) is deprecated in favor of a
                // RadioGroup ancestor managing the group value — wrap both
                // options so their Radio children can drop those params.
                RadioGroup<KhatmaType>(
                  groupValue: _type,
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                  child: Column(
                    children: [
                      _typeOption(
                        KhatmaType.muyassara,
                        l10n.createKhatmaTypeMuyassaraTitle,
                        l10n.createKhatmaTypeMuyassaraDesc,
                        style,
                      ),
                      const SizedBox(height: 10),
                      _typeOption(
                        KhatmaType.multazima,
                        l10n.createKhatmaTypeMultazimaTitle,
                        l10n.createKhatmaTypeMultazimaDesc,
                        style,
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

  Widget _typeOption(
    KhatmaType type,
    String title,
    String desc,
    AdaptiveStyle style,
  ) {
    final selected = _type == type;
    return TakwaTappable(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _type = type);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<KhatmaType>(
            value: type,
            activeColor: style.isRamadan ? style.gold : style.teal,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: style.amiri(
                    16,
                    color: selected ? style.text : style.textSec,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: style.naskh(12, color: style.textDim),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── STEP 1: Settings ────────────────────
  Widget _buildStep1(AdaptiveStyle style, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Start Date
          _card(
            style,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.createKhatmaStartDateLabel,
                      style: style.amiri(
                        18,
                        color: style.text,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.calendar_month_rounded,
                      color: style.gold,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TakwaTappable(
                  onTap: () => _pickDate(style),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: style.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: style.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                          style: style.naskh(15, color: style.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Start Page
          _card(
            style,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.createKhatmaStartPageLabel,
                      style: style.amiri(
                        18,
                        color: style.text,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.auto_stories_rounded,
                      color: style.gold,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: style.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _startPage,
                      isExpanded: true,
                      dropdownColor: style.card,
                      style: style.naskh(15, color: style.text),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: style.textDim,
                      ),
                      items: List.generate(
                        604,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            l10n.createKhatmaPageOption(
                              localizedNumeral(context, i + 1),
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _startPage = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Notifications
          _card(
            style,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: style.isRamadan ? style.gold : style.teal,
                      activeTrackColor:
                          (style.isRamadan ? style.gold : style.teal)
                              .withValues(alpha: 0.3),
                      inactiveTrackColor: style.border,
                      inactiveThumbColor: style.textDim,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          l10n.createKhatmaEnableNotifications,
                          style: style.amiri(
                            18,
                            color: style.text,
                            weight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.notifications_rounded,
                          color: style.gold,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_notificationsEnabled) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: style.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: style.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.createKhatmaNotificationsDisabledWarning,
                            textAlign: TextAlign.start,
                            style: style.naskh(12, color: style.danger),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.info_outline_rounded,
                          color: style.danger,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(AdaptiveStyle style) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Was `Theme(data: ThemeData.dark().copyWith(...))` (audit §M11): a
      // brand-new ThemeData carries none of the app's ThemeExtensions, so
      // any context.colors/AdaptiveStyle read inside the picker's subtree
      // hit `extension<...>()!` on null and crashed — and it forced a dark
      // picker even in light mode. Copying the *ambient* theme instead
      // keeps every extension intact and only tints the accent/surface.
      builder: (ctx, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: style.isRamadan ? style.gold : style.teal,
              surface: style.card,
              onSurface: style.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  // ──────────────────── STEP 2: Summary ────────────────────
  Widget _buildStep2(AdaptiveStyle style, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: _card(
        style,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: style.gold.withValues(alpha: 0.2),
                  ),
                  child: Icon(Icons.check_rounded, color: style.gold, size: 16),
                ),
                Text(
                  l10n.createKhatmaSummaryTitle,
                  style: style.amiri(
                    18,
                    color: style.text,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Type pill
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: style.isRamadan
                    ? style.gold.withValues(alpha: 0.1)
                    : style.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: (style.isRamadan ? style.gold : style.teal)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _type == KhatmaType.muyassara
                            ? l10n.createKhatmaTypeMuyassaraTitle
                            : l10n.createKhatmaTypeMultazimaTitle,
                        style: style.amiri(
                          15,
                          color: style.isRamadan ? style.gold : style.teal,
                          weight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.account_tree_rounded,
                        color: style.isRamadan ? style.gold : style.teal,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.createKhatmaTypeFieldLabel,
                        style: style.naskh(
                          12,
                          color: style.isRamadan ? style.gold : style.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _type == KhatmaType.muyassara
                        ? l10n.createKhatmaTypeMuyassaraDesc
                        : l10n.createKhatmaTypeMultazimaDesc,
                    textAlign: TextAlign.start,
                    style: style.naskh(
                      11,
                      color: (style.isRamadan ? style.gold : style.teal)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _summaryRow(l10n.createKhatmaNameFieldLabel, _nameCtrl.text, style),
            _summaryRow(
              l10n.createKhatmaStartDateFieldLabel,
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              style,
            ),
            _summaryRow(
              l10n.createKhatmaFirstPageFieldLabel,
              l10n.createKhatmaPageOption(
                localizedNumeral(context, _startPage),
              ),
              style,
            ),
            _summaryRow(
              l10n.createKhatmaNotificationsFieldLabel,
              _notificationsEnabled
                  ? l10n.createKhatmaNotificationsEnabledValue
                  : l10n.createKhatmaNotificationsDisabledValue,
              style,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (style.isRamadan ? style.gold : style.teal).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (style.isRamadan ? style.gold : style.teal)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      l10n.createKhatmaStartReadingHint,
                      textAlign: TextAlign.start,
                      style: style.naskh(
                        12,
                        color: style.isRamadan ? style.gold : style.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.info_outline_rounded,
                    color: style.isRamadan ? style.gold : style.teal,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, AdaptiveStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: style.naskh(13, color: style.textSec)),
          Text(label, style: style.naskh(13, color: style.textDim)),
        ],
      ),
    );
  }

  // ──────────────────── Bottom Bar ────────────────────
  Widget _buildBottomBar(AdaptiveStyle style, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: BoxDecoration(
        color: style.bg,
        border: Border(top: BorderSide(color: style.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: TakwaTappable(
                onTap: () => setState(() => _step--),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: style.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      l10n.createKhatmaPreviousButton,
                      style: style.amiri(16, color: style.textSec),
                    ),
                  ),
                ),
              ),
            ),
          if (_step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TakwaTappable(
              onTap: _onNextTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: style.isRamadan ? style.gold : style.teal,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (style.isRamadan ? style.gold : style.teal)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _step == 2
                        ? l10n.createKhatmaCreateButton
                        : l10n.createKhatmaNextButton,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNextTap() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _createKhatma();
    }
  }

  Future<void> _createKhatma() async {
    final isRamadan = ref.read(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final l10n = AppLocalizations.of(context)!;

    await ref
        .read(khatmaExProvider.notifier)
        .createNew(
          label: _nameCtrl.text.trim().isEmpty
              ? l10n.createKhatmaDefaultLabelFallback
              : _nameCtrl.text.trim(),
          type: _type,
          startPage: _startPage,
          notificationsEnabled: _notificationsEnabled,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.createKhatmaSuccessMessage,
            style: const TextStyle(fontFamily: 'NotoNaskhArabic'),
          ),
          backgroundColor: style.isRamadan ? style.gold : style.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }
  }

  Widget _card(AdaptiveStyle style, {required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: style.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: style.border),
    ),
    child: child,
  );
}
