import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/providers/adhkar_providers.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/adhkar/providers/misbaha_provider.dart';
import 'package:takwa/features/quran/utils/quran_helpers.dart'
    show localizedNumeral;
import 'package:takwa/l10n/app_localizations.dart';

class MisbahaScreen extends ConsumerStatefulWidget {
  const MisbahaScreen({super.key});

  @override
  ConsumerState<MisbahaScreen> createState() => _MisbahaScreenState();
}

class _MisbahaScreenState extends ConsumerState<MisbahaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    ref.read(misbahaProvider.notifier).increment();
    _pulseCtrl.forward(from: 0);
  }

  void _onLongPressStart(LongPressStartDetails _) {
    HapticFeedback.heavyImpact();
    ref.read(misbahaProvider.notifier).listen(true);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    ref.read(misbahaProvider.notifier).listen(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final state = ref.watch(misbahaProvider);

    return Scaffold(
      backgroundColor: style.bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),

          // Decorative Glows
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlow(style.gold.withValues(alpha: 0.15), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGlow(style.teal.withValues(alpha: 0.1), 250),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                // Adjusted scale factor to maintain aesthetics on smaller screens
                final scale = (availableHeight / 780).clamp(0.7, 1.0);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(style, context),
                          const Spacer(),
                          _buildDhikrSelector(l10n, state, style, context),
                          SizedBox(height: 32 * scale),
                          _buildCounterDisplay(context, state, style, scale),
                          const Spacer(),
                          _buildMainBead(l10n, state, style, scale),
                          const Spacer(),
                          _buildBottomControls(l10n, state, style),
                          SizedBox(height: 32 * scale),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: size, spreadRadius: size / 2),
        ],
      ),
    );
  }

  Widget _buildHeader(AdaptiveStyle style, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CustomLeadingButton(),
          Column(
            children: [
              Text(
                l10n.misbahaScreenTitle,
                style: style.amiri(22, color: style.gold),
              ),
              Text(
                'ألا بذكر الله تطمئن القلوب',
                style: style.naskh(11, color: style.textSec),
              ),
            ],
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDhikrSelector(
    AppLocalizations l10n,
    MisbahaState state,
    AdaptiveStyle style,
    BuildContext context,
  ) {
    final hasDhikr = state.selectedDhikr != null;
    return Semantics(
      label: hasDhikr
          ? l10n.misbahaSelectedDhikrLabel
          : l10n.misbahaChooseDhikrPrompt,
      button: true,
      onTap: () => _showDhikrListModal(l10n, style, context),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _showDhikrListModal(l10n, style, context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: hasDhikr
                  ? style.gold.withValues(alpha: 0.6)
                  : style.border,
              width: hasDhikr ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hasDhikr
                    ? style.gold.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle Pattern Overlay
              if (hasDhikr)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPatternBackground(
                      pattern: BackgroundPattern.twelveFoldStar,
                      color: style.gold,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: style.gold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasDhikr
                                ? Icons.auto_awesome_rounded
                                : Icons.menu_book_rounded,
                            color: style.gold,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          hasDhikr
                              ? l10n.misbahaSelectedDhikrLabel
                              : l10n.misbahaChooseDhikrPrompt,
                          style: style.naskh(
                            13,
                            color: style.gold,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (hasDhikr)
                          TakwaTappable(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(misbahaProvider.notifier).clearDhikr();
                            },
                            // Inline next to the label above via Spacer().
                            minTapSize: null,
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: style.textDim.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: style.textSec,
                                size: 18,
                              ),
                            ),
                          )
                        else
                          // Was chevron_left — every other "tap to pick/drill
                          // in" trailing chevron in the app (settings rows,
                          // home cards, checklist) uses chevron_right, so this
                          // was the one inconsistent one (audit §H5).
                          Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            color: style.gold,
                            size: 20,
                          ),
                      ],
                    ),
                    if (hasDhikr) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.15,
                                child: Icon(
                                  Icons.format_quote_rounded,
                                  color: style.gold,
                                  size: 32,
                                ),
                              ),
                              Text(
                                state.selectedDhikr!.arabic,
                                textAlign: TextAlign.center,
                                style: style.amiri(
                                  20,
                                  color: style.text,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (state.selectedDhikr!.arabic.length > 50)
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: style.gold.withValues(alpha: 0.3),
                          size: 20,
                        ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          l10n.misbahaTapToChooseHint,
                          style: style.naskh(12, color: style.textDim),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterDisplay(
    BuildContext context,
    MisbahaState state,
    AdaptiveStyle style,
    double scale,
  ) {
    final size = 180.0 * scale;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress indicator around the number
            if (state.selectedDhikr != null)
              SizedBox(
                width: size,
                height: size,
                child: TakwaLoadingIndicator(
                  size: size,
                  strokeWidth: 4 * scale,
                  color: style.gold.withValues(alpha: 0.6),
                ),
              ),
            Column(
              children: [
                Text(
                  localizedNumeral(context, state.count),
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 90 * scale,
                    fontWeight: FontWeight.bold,
                    color: style.text,
                    height: 1.0,
                  ),
                ),
                if (state.selectedDhikr != null)
                  Text(
                    '/ ${localizedNumeral(context, state.selectedDhikr!.count)}',
                    style: style.naskh(
                      16 * scale,
                      color: style.gold.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainBead(
    AppLocalizations l10n,
    MisbahaState state,
    AdaptiveStyle style,
    double scale,
  ) {
    final size = 220.0 * scale;
    final innerSize = 190.0 * scale;

    return Column(
      children: [
        ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.92).animate(
            CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOutBack),
          ),
          child: Semantics(
            label: state.selectedDhikr != null
                ? l10n.misbahaCounterWithTargetSemanticLabel(
                    state.count,
                    state.selectedDhikr!.count,
                  )
                : l10n.misbahaCounterSemanticLabel(state.count),
            button: true,
            liveRegion: true,
            onTap: _onTap,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _onTap,
              onLongPressStart: _onLongPressStart,
              onLongPressEnd: _onLongPressEnd,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse Animation Background
                  if (state.isListening)
                    _ListeningRipple(color: style.teal, size: size),

                  // The Main Bead
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: state.isListening
                            ? [style.teal, style.teal.withValues(alpha: 0.7)]
                            : [style.gold, style.goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (state.isListening ? style.teal : style.gold)
                              .withValues(alpha: 0.4),
                          blurRadius: 30 * scale,
                          spreadRadius: 5 * scale,
                          offset: Offset(0, 10 * scale),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: innerSize,
                        height: innerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              state.isListening
                                  ? Icons.mic_rounded
                                  : Icons.fingerprint_rounded,
                              size: 64 * scale,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              state.isListening
                                  ? l10n.misbahaListeningLabel
                                  : l10n.misbahaTapOrHoldHint,
                              style: style.naskh(
                                12 * scale,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(
    AppLocalizations l10n,
    MisbahaState state,
    AdaptiveStyle style,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Reset Button
          _buildActionButton(
            icon: Icons.refresh_rounded,
            label: l10n.misbahaResetButton,
            color: style.textSec,
            onTap: () => ref.read(misbahaProvider.notifier).reset(),
          ),

          // Sound Toggle? (Optional extra)
          _buildActionButton(
            icon: state.isSpeaking
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: l10n.misbahaSoundButton,
            color: state.selectedDhikr == null ? style.textDim : style.gold,
            onTap: state.selectedDhikr == null
                ? null
                : () => ref.read(misbahaProvider.notifier).speakDhikr(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDhikrListModal(
    AppLocalizations l10n,
    AdaptiveStyle style,
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder: (_, controller) {
              final allItems = kAdhkarData.values
                  .expand((list) => list)
                  .toList();
              return Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: style.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.misbahaChooseDhikrTitle,
                    style: style.amiri(24, color: style.gold),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: 10,
                      ),
                      itemCount: allItems.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (ctx, i) {
                        final dhikr = allItems[i];
                        return _buildDhikrItem(dhikr, style, ctx);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDhikrItem(
    DhikrItem dhikr,
    AdaptiveStyle style,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    void select() {
      HapticFeedback.selectionClick();
      ref.read(misbahaProvider.notifier).selectDhikr(dhikr);
      Navigator.pop(context);
    }

    return Semantics(
      label: l10n.misbahaDhikrItemSemanticLabel(dhikr.arabic, dhikr.count),
      button: true,
      onTap: select,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: select,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: style.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: style.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dhikr.arabic,
                  style: style.amiri(18, color: style.text, height: 1.4),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  localizedNumeral(context, dhikr.count),
                  style: style.naskh(
                    14,
                    color: style.gold,
                    weight: FontWeight.bold,
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

class _ListeningRipple extends StatefulWidget {
  final Color color;
  final double size;
  const _ListeningRipple({required this.color, required this.size});

  @override
  State<_ListeningRipple> createState() => _ListeningRippleState();
}

class _ListeningRippleState extends State<_ListeningRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Transform.scale(
                scale: 1.0 + (_ctrl.value + i / 3) % 1.0 * 1.5,
                child: Opacity(
                  opacity: (1.0 - (_ctrl.value + i / 3) % 1.0).clamp(0.0, 1.0),
                  child: Container(
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
