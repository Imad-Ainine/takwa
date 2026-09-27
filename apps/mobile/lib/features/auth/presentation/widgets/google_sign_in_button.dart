import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:takwa/core/theme/app_theme.dart';

/// Google's official "Sign in with Google" button shape — pill, 18dp
/// four-color G logo, medium-weight label — dressed in Takwa's theme tokens
/// so it sits cohesively in light, dark and Ramadan modes. The G logo itself
/// keeps its brand colors.
class GoogleSignInButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;

  const GoogleSignInButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 48,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _tapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = widget.onTap == null;

    final surface = colors.card;
    final border = colors.borderSubdued;
    final labelColor = colors.textPrimary;
    final radius = BorderRadius.circular(widget.height / 2);

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      onTap: disabled ? null : widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: _tapDown,
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1,
            end: 0.97,
          ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut)),
          child: AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: disabled ? 0.38 : 1,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: radius,
                border: Border.all(color: border),
                boxShadow: AppShadows.card,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: null,
                  // Swallow the visual splash only — the GestureDetector
                  // above owns the tap. A theme splash (gold-tinted here)
                  // would violate the brand surface.
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  borderRadius: radius,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/google.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.typography.labelLarge.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
