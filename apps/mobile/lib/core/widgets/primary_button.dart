import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'takwa_loading_indicator.dart';
import 'custom_pattern_background.dart';

/// A premium, animated primary button unified across the application.
class PrimaryButton extends StatefulWidget {
  final String label;
  final FutureOr<void> Function()? onTap;
  final IconData? icon;
  final Color? baseColor;
  final Widget? customContent;
  final bool isOutline;
  final bool isLoading;
  final bool isBg;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.baseColor,
    this.customContent,
    this.isOutline = false,
    this.isLoading = false,
    this.isBg = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onTap!();
    } finally {
      // Without the finally a throwing handler left the spinner up forever
      // and the button permanently disabled.
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = widget.onTap == null || widget.isLoading || _loading;
    final primaryColor = widget.baseColor ?? colors.gold;

    // Slightly darken the caller color (or gold default) for the gradient end.
    final endColor = widget.baseColor != null
        ? HSLColor.fromColor(widget.baseColor!)
              .withLightness(
                (HSLColor.fromColor(widget.baseColor!).lightness - 0.1).clamp(
                  0.0,
                  1.0,
                ),
              )
              .toColor()
        : colors.goldDark;

    // Content text/icon color. White on the default gold gradient was only
    // 2.24:1, so a filled button uses the same near-black the theme uses for
    // `onPrimary` — unless the caller supplied a base color dark enough that
    // white is the better choice.
    final onFilled =
        ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF241B05);
    final contentColor = disabled
        ? colors.textSecondary
        : widget.isOutline
        ? (widget.baseColor ?? colors.goldText)
        : (widget.isBg ? onFilled : colors.textPrimary);

    // The action MUST hang off onTap, not onTapUp: GestureDetector only
    // contributes SemanticsAction.tap when onTap is non-null, so with the old
    // onTapUp-only wiring TalkBack/VoiceOver double-tap did nothing on the
    // app's primary control. Semantics is explicit so the label and the
    // disabled state are announced too.
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      onTap: disabled ? null : _run,
      // One coherent "label, button" stop instead of the icon and text each
      // being their own node — same pattern as _PrayerRow / _BottomNav.
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: disabled
            ? null
            : (_) {
                _ctrl.forward();
                // lightImpact, not mediumImpact: a button press is a
                // selection, not a commit.
                HapticFeedback.lightImpact();
              },
        onTapUp: disabled ? null : (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: disabled ? null : _run,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1,
            end: 0.96,
          ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            // 12pt padding + a 15px line box came to ~44dp, under the 48dp
            // minimum touch target on both platforms.
            constraints: const BoxConstraints(minHeight: 48),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: (disabled || widget.isOutline)
                  ? null
                  : LinearGradient(colors: [primaryColor, endColor]),
              color: disabled
                  ? colors.border
                  : widget.isOutline
                  ? Colors.transparent
                  : null,
              borderRadius: AppRadius.button,
              border: widget.isOutline
                  ? Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5)
                  : null,
              boxShadow: (disabled || widget.isOutline)
                  ? null
                  : [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!disabled && !widget.isOutline)
                  if (widget.isBg)
                    const Positioned.fill(
                      child: CustomPatternBackground(
                        pattern: BackgroundPattern.adhkar,
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: _loading
                      ? Center(
                          child: TakwaLoadingIndicator(
                            size: 20,
                            // Match the label, so the spinner is legible on
                            // whatever the button is actually filled with.
                            color: widget.isBg ? onFilled : colors.textPrimary,
                          ),
                        )
                      : widget.customContent ??
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    size: 18,
                                    color: contentColor,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    // Was hardcoded to NotoNaskhArabic, which
                                    // rendered every button label in an Arabic
                                    // naskh face in the English UI.
                                    style: context.typography.labelMedium
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: contentColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
