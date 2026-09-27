import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/islamic_glyph.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/l10n/app_localizations.dart';

// ══════════════════════════════════════════════════════
//  AUTH VISUAL SYSTEM — shared shell, surfaces and
//  feedback used by every authentication screen so the
//  flow reads as one cohesive, premium experience in
//  both light and dark themes.
// ══════════════════════════════════════════════════════

/// Full-screen auth backdrop: geometric pattern, depth wash, safe area and a
/// centered, keyboard-aware scroll column. All auth screens mount through it.
class AuthScaffold extends StatelessWidget {
  final List<Widget> children;
  final bool showBack;
  final VoidCallback? onBack;
  final String? backTooltip;
  final double maxContentWidth;
  final EdgeInsetsGeometry padding;

  const AuthScaffold({
    super.key,
    required this.children,
    this.showBack = false,
    this.onBack,
    this.backTooltip,
    this.maxContentWidth = 460,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.lg,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(
              pattern: BackgroundPattern.adhkar,
              opacity: 0.09,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withValues(alpha: 0.15),
                    colors.background.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (showBack)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.sm,
                      top: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        _AuthBackButton(
                          onPressed: onBack ?? Navigator.of(context).pop,
                          tooltip: backTooltip,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      // Keep the form clear of the keyboard like the rest of
                      // the flow's input-heavy screens.
                      padding: padding.add(
                        EdgeInsets.only(
                          bottom: MediaQuery.viewInsetsOf(context).bottom +
                              AppSpacing.huge,
                        ),
                      ),
                      child: AuthEntrance(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: children,
                          ),
                        ),
                      ),
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
}

class _AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;
  const _AuthBackButton({required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: tooltip ?? l10n.authBackTooltip,
      child: TakwaTappable(
        onTap: onPressed,
        minTapSize: null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.card.withValues(alpha: 0.55),
              border: Border.all(
                color: colors.gold.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.gold,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// One elegant entrance for every auth screen: content rises into place with
/// a soft fade. Honors reduce-motion by appearing instantly.
class AuthEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const AuthEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<AuthEntrance> createState() => _AuthEntranceState();
}

class _AuthEntranceState extends State<AuthEntrance> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = prefersReducedMotion(context);
    return AnimatedOpacity(
      opacity: _shown || reduced ? 1 : 0,
      duration: reduced ? Duration.zero : widget.duration,
      curve: AppMotion.emphasized,
      child: AnimatedSlide(
        offset: _shown || reduced ? Offset.zero : const Offset(0, 0.06),
        duration: reduced ? Duration.zero : widget.duration,
        curve: AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}

/// Frosted glass card that frames every auth form.
class AuthGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool blur;
  const AuthGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: blur ? 0.78 : 0.92),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: colors.gold.withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.gold.withValues(alpha: 0.09),
            blurRadius: 36,
            spreadRadius: 2,
          ),
          ...AppShadows.card,
        ],
      ),
      child: child,
    );
    if (!blur) return card;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: card,
      ),
    );
  }
}

/// Circular gold-ring emblem used at the head of the flow.
class AuthEmblem extends StatelessWidget {
  final double size;
  final Widget child;
  final bool glow;
  const AuthEmblem({
    super.key,
    this.size = 94,
    required this.child,
    this.glow = true,
  });

  AuthEmblem.moon({super.key, this.size = 94, this.glow = true})
    : child = IslamicGlyph('🌙', size: size * 0.47);

  AuthEmblem.icon({super.key, this.size = 94, this.glow = true, required IconData icon})
    : child = Icon(icon, size: size * 0.47, color: null);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.gold.withValues(alpha: 0.18),
            colors.background,
          ],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: colors.gold.withValues(alpha: 0.36),
                  blurRadius: size * 0.34,
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
        border: Border.all(
          color: colors.gold.withValues(alpha: 0.55),
          width: size > 80 ? 1.6 : 1.3,
        ),
      ),
      child: Center(
        // The .icon variant pins color=null so the gold tint resolves here
        // against the active theme.
        child: IconTheme.merge(
          data: IconThemeData(color: colors.gold),
          child: child,
        ),
      ),
    );
  }
}

/// App name / screen title rendered with the brand gold gradient.
class AuthGoldTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign textAlign;
  const AuthGoldTitle(
    this.text, {
    super.key,
    this.fontSize = 48,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ShaderMask(
      shaderCallback: (bounds) => colors.goldGradient.createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: context.typography.displayLarge.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum AuthBannerKind { error, success, info }

/// Animated status banner — one visual language for every validation,
/// transport and recovery message in the flow.
class AuthBanner extends StatelessWidget {
  final String message;
  final AuthBannerKind kind;
  const AuthBanner({
    super.key,
    required this.message,
    this.kind = AuthBannerKind.error,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (Color bg, Color border, Color fg, IconData icon) = switch (kind) {
      AuthBannerKind.error => (
        colors.dangerDim,
        colors.danger.withValues(alpha: 0.4),
        colors.dangerText,
        Icons.warning_amber_rounded,
      ),
      AuthBannerKind.success => (
        colors.successDim,
        colors.success.withValues(alpha: 0.4),
        colors.successText,
        Icons.check_circle_outline_rounded,
      ),
      AuthBannerKind.info => (
        colors.card.withValues(alpha: 0.7),
        colors.gold.withValues(alpha: 0.3),
        colors.textSecondary,
        Icons.info_outline_rounded,
      ),
    };
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.emphasized,
      child: Padding(
        key: ValueKey('$kind:$message'),
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.card,
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.typography.bodySmall.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted modal spinner shown while an auth request is in flight.
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(
        color: colors.overlay,
        alignment: Alignment.center,
        child: const TakwaLoadingIndicator(),
      ),
    );
  }
}

/// "i••••••e@gmail.com" — show enough of the address to orient the user
/// without a full re-display on the verification step.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 2) return email;
  final local = email.substring(0, at);
  return '${local[0]}${'•' * (local.length - 2)}'
      '${local[local.length - 1]}${email.substring(at)}';
}
