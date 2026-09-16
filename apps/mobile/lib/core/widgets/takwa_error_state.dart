import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Shared "this section failed to load" state, with a retry action.
///
/// Used to replace the pattern of `error: (_, _) => const SizedBox()` on an
/// [AsyncValue.when] — which hid the failure from the user entirely, leaving
/// a silent gap where the card should be — with something visible and
/// actionable. `onRetry` is typically `() => ref.invalidate(someProvider)`.
///
/// [message] defaults to a generic, localized fallback; pass a
/// feature-specific string when a more precise one is available and already
/// localized.
class TakwaErrorState extends StatelessWidget {
  const TakwaErrorState({
    super.key,
    required this.onRetry,
    this.message,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.compact = false,
  });

  final VoidCallback onRetry;
  final String? message;
  final EdgeInsetsGeometry padding;

  /// A smaller icon/text/button for use inside an already-bounded card
  /// rather than a full screen or sliver.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Padding(
      padding: padding,
      child: Center(
        child: Semantics(
          // Announces once, on entry, without stealing focus — the failure
          // itself is the thing worth surfacing to assistive tech.
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: compact ? 28 : 40,
                color: colors.textDim,
              ),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              Text(
                message ?? l10n.genericErrorMessage,
                textAlign: TextAlign.center,
                style: compact
                    ? context.typography.caption
                    : context.typography.bodySmall,
              ),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.retryButtonLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.goldText,
                  side: BorderSide(color: colors.goldText),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: compact ? AppSpacing.xs : AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A minimal retry affordance for a small, tightly bounded area — a stat
/// tile, a chip-sized badge, a drawer row — where [TakwaErrorState]'s icon +
/// message + button would break the layout it sits in.
///
/// When [onRetry] is null the failure is still visible (a muted "!" glyph
/// instead of nothing) but not interactive — used where the surrounding
/// widget has no reasonable provider to invalidate without deeper plumbing.
class TakwaInlineError extends StatelessWidget {
  const TakwaInlineError({super.key, this.onRetry, this.height});

  final VoidCallback? onRetry;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final icon = Icon(
      Icons.error_outline_rounded,
      size: 16,
      color: context.colors.textDim,
    );

    final content = SizedBox(
      height: height,
      child: Center(child: icon),
    );

    if (onRetry == null) {
      return Semantics(label: l10n.genericErrorMessage, child: content);
    }

    return Semantics(
      button: true,
      label: l10n.inlineErrorRetryLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: content,
      ),
    );
  }
}
