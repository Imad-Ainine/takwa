import 'package:flutter/material.dart';
import '../theme/ramadan_theme.dart';
import 'package:takwa/l10n/app_localizations.dart';

class AuthField extends StatefulWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final AdaptiveStyle style;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  /// External focus node, so a screen can chain fields with
  /// `FocusScope.of(context).nextFocus()` from [onSubmit] below. When null,
  /// this widget manages (and disposes) its own.
  final FocusNode? focusNode;

  /// The last field in its group: switches [textInputAction] from `next` to
  /// `done` and routes the keyboard's submit action to [onSubmit] instead of
  /// advancing focus.
  final bool isLast;

  /// Called when the keyboard's "done" action fires on the last field in a
  /// chain (see [isLast]) — wire this to the screen's submit handler.
  final VoidCallback? onSubmit;

  /// Defaults to `[AutofillHints.password]` when [isPassword], otherwise
  /// `[AutofillHints.email]`. Pass e.g. `[AutofillHints.username]` /
  /// `[AutofillHints.newPassword]` explicitly where that's a better fit —
  /// wrap the surrounding fields in an `AutofillGroup` for this to reach a
  /// password manager at all.
  final Iterable<String>? autofillHints;

  final bool autofocus;

  const AuthField({
    super.key,
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.style,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.isLast = false,
    this.onSubmit,
    this.autofillHints,
    this.autofocus = false,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscure = true;
  bool _focused = false;
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    final external = widget.focusNode;
    if (external != null) {
      _focusNode = external;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final l10n = AppLocalizations.of(context)!;

    // A raw TextField wrapped in our own FormField<String> rather than
    // TextFormField: TextFormField hides its FormFieldState from callers, so
    // there was no way to read "is this field currently invalid" back out to
    // drive the AnimatedContainer border below — which is exactly why a
    // failed validator used to have zero visual effect (WCAG 3.3.1/3.3.2).
    // autovalidateMode: onUserInteraction means this works even though none
    // of the three screens that use AuthField wrap it in a Form or ever call
    // formKey.currentState.validate().
    return FormField<String>(
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        final hasError = field.hasError;
        final borderColor = hasError
            ? s.danger
            : (_focused ? s.gold : s.border.withValues(alpha: 0.5));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              onFocusChange: (val) => setState(() => _focused = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: _focused
                      ? s.card.withValues(alpha: 0.6)
                      : s.bg.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: borderColor,
                    width: (_focused || hasError) ? 2 : 1.5,
                  ),
                  boxShadow: _focused
                      ? [
                          BoxShadow(
                            color: (hasError ? s.danger : s.gold).withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: widget.ctrl,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  obscureText: widget.isPassword ? _obscure : false,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.isLast
                      ? TextInputAction.done
                      : TextInputAction.next,
                  autofillHints:
                      widget.autofillHints ??
                      (widget.isPassword
                          ? const [AutofillHints.password]
                          : const [AutofillHints.email]),
                  onChanged: (v) {
                    field.didChange(v);
                    widget.onChanged?.call(v);
                  },
                  onSubmitted: (_) {
                    if (widget.isLast) {
                      widget.onSubmit?.call();
                    } else {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                  style: s.naskh(15, weight: FontWeight.w600),
                  cursorColor: s.gold,
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    // Was hintText only, which — per WCAG 3.3.2 — disappears
                    // the instant the user types, leaving an unlabeled
                    // field. labelText floats above the value once there is
                    // one instead of being replaced by it.
                    labelText: widget.hint,
                    labelStyle: s.naskh(13, color: s.textDim),
                    floatingLabelStyle: s.naskh(
                      12,
                      color: hasError
                          ? s.danger
                          : (_focused ? s.gold : s.textSec),
                    ),
                    prefixIcon: Icon(
                      widget.icon,
                      color: hasError
                          ? s.danger
                          : (_focused ? s.gold : s.textSec),
                      size: 20,
                    ),
                    suffixIcon: widget.isPassword
                        ? IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            tooltip: _obscure
                                ? l10n.authShowPasswordTooltip
                                : l10n.authHidePasswordTooltip,
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: s.textSec,
                              size: 20,
                            ),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
                child: Text(field.errorText!, style: s.naskh(12, color: s.danger)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class PasswordStrengthBar extends StatelessWidget {
  final double strength; // 0..1
  final AdaptiveStyle style;
  const PasswordStrengthBar({
    super.key,
    required this.strength,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = strength < 0.26
        ? l10n.authPasswordStrengthWeak
        : strength < 0.51
        ? l10n.authPasswordStrengthMedium
        : strength < 0.76
        ? l10n.authPasswordStrengthGood
        : l10n.authPasswordStrengthStrong;
    // Audit §M13: these were the raw Material accents at every brightness,
    // and "amber on light is ~1.8:1" as *text* (the bar fill itself doesn't
    // need text-level contrast, but the label painted in the same color
    // does). Dark mode keeps the original vivid accents — nothing flagged
    // those — light mode swaps in darkened versions of the same four hues,
    // each clearing 4.5:1 on a white/near-white surface.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = strength < 0.26
        ? (isDark ? Colors.redAccent : context.colors.dangerText)
        : strength < 0.51
        ? (isDark ? Colors.orange : const Color(0xFF9A3412)) // ~5.8:1 on white
        : strength < 0.76
        ? (isDark ? Colors.amber : context.colors.warningText)
        : (isDark ? Colors.greenAccent : context.colors.successText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 4, color: style.border.withValues(alpha: 0.3)),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                widthFactor: strength.clamp(0.05, 1.0),
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.authPasswordStrengthLabel(label),
          style: style.naskh(11, color: color),
        ),
      ],
    );
  }
}
