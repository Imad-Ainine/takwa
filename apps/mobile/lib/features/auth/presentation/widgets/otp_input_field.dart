import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Six-box numeric verification code entry: a single invisible input drives a
/// row of digit tiles, the next empty tile wears the gold focus ring, and a
/// failed check shakes the row red. Paste and SMS/email autofill work because
/// the real TextField keeps the value.
class OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final bool autofocus;
  final bool hasError;

  /// Fires as soon as [length] digits are present — wire this to verify.
  final VoidCallback? onCompleted;
  final ValueChanged<String>? onChanged;

  const OtpInputField({
    super.key,
    required this.controller,
    this.length = 6,
    this.autofocus = true,
    this.hasError = false,
    this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _focusNode.addListener(() => setState(() {}));
    if (widget.hasError) _shakeCtrl.value = 1;
  }

  @override
  void didUpdateWidget(OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void requestFocus() => _focusNode.requestFocus();

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final reduced = prefersReducedMotion(context);
    final text = widget.controller.text;
    final activeIndex = text.length < widget.length ? text.length : -1;
    final focused = _focusNode.hasFocus;

    return Semantics(
      textField: true,
      label: l10n.forgotPasswordOtpHint,
      value: text.isEmpty ? l10n.otpNoneEntered : text.split('').join(' '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: AnimatedBuilder(
          animation: Listenable.merge([_shakeCtrl, widget.controller]),
          builder: (context, child) {
            // Damped sideways shake on error — skipped under reduce-motion.
            final v = _shakeCtrl.value;
            final shake = reduced || !widget.hasError
                ? 0.0
                : 6 * (1 - v) * math.sin(v * math.pi * 4);
            return Transform.translate(offset: Offset(shake, 0), child: child);
          },
          child: Stack(
            children: [
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _handleChanged,
                  onSubmitted: (_) => _handleChanged(widget.controller.text),
                  style: const TextStyle(fontSize: 1),
                ),
              ),
              IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = AppSpacing.sm;
                    final tileWidth = math.min(
                      46.0,
                      (constraints.maxWidth - gap * (widget.length - 1)) /
                          widget.length,
                    );
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < widget.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          _OtpTile(
                            width: tileWidth,
                            digit: i < text.length ? text[i] : '',
                            isActive: focused && i == activeIndex,
                            isFilled: i < text.length,
                            hasError: widget.hasError,
                            reducedMotion: reduced,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpTile extends StatelessWidget {
  final double width;
  final String digit;
  final bool isActive;
  final bool isFilled;
  final bool hasError;
  final bool reducedMotion;
  const _OtpTile({
    required this.width,
    required this.digit,
    required this.isActive,
    required this.isFilled,
    required this.hasError,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = hasError
        ? colors.dangerText
        : isActive
        ? colors.gold
        : isFilled
        ? colors.gold.withValues(alpha: 0.45)
        : colors.borderSubdued;
    return AnimatedContainer(
      duration: reducedMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.standard,
      width: 46,
      height: 54,
      decoration: BoxDecoration(
        color: isFilled || isActive
            ? colors.card.withValues(alpha: 0.65)
            : colors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1.4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.focusRing.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: reducedMotion ? Duration.zero : AppMotion.fast,
        child: Text(
          digit,
          key: ValueKey(digit),
          style: context.typography.headingMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
