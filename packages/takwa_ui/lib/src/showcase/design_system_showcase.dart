import 'package:flutter/material.dart';

import '../tokens/app_breakpoints.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_palettes.dart';
import '../theme/app_typography.dart';
import '../theme/context_extensions.dart';
import '../widgets/display/taqwa_badge.dart';

/// Interactive style guide for the Takwa Design System, in the spirit of
/// Shopify Polaris / IBM Carbon storybook pages.
///
/// A reference page for the token layers: primitive ramps (AppPalette),
/// semantic roles (AppColorsExtension), the type scale, and the spacing,
/// radii, motion, elevation and breakpoint tokens — all read from the
/// ambient theme, so it renders correctly under any of the four themes
/// (base/Ramadan x light/dark):
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light(),
///   darkTheme: AppTheme.dark(),
///   home: const DesignSystemShowcase(),
/// )
/// ```
class DesignSystemShowcase extends StatelessWidget {
  const DesignSystemShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Takwa Design System', style: typography.headingMedium),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding.copyWith(
          top: AppSpacing.lg,
          bottom: AppSpacing.huge,
        ),
        children: [
          const _Section(
            title: 'Color palettes',
            caption: 'Primitive tonal ramps — 50 to 900, theme-agnostic',
            child: Column(
              children: [
                _RampRow(name: 'Neutral', ramp: AppPalette.neutral),
                _RampRow(name: 'Gold', ramp: AppPalette.gold),
                _RampRow(name: 'Teal', ramp: AppPalette.teal),
                _RampRow(name: 'Green', ramp: AppPalette.green),
                _RampRow(name: 'Red', ramp: AppPalette.red),
                _RampRow(name: 'Yellow', ramp: AppPalette.yellow),
                _RampRow(name: 'Blue', ramp: AppPalette.blue),
              ],
            ),
          ),
          _Section(
            title: 'Semantic tokens',
            caption: 'Surfaces, borders, text and status roles for this theme',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TokenTile(label: 'background', color: colors.background),
                _TokenTile(label: 'deep', color: colors.deep),
                _TokenTile(label: 'card', color: colors.card),
                _TokenTile(label: 'card2', color: colors.card2),
                _TokenTile(
                  label: 'surfaceSubdued',
                  color: colors.surfaceSubdued,
                ),
                _TokenTile(
                  label: 'surfaceHovered',
                  color: colors.surfaceHovered,
                ),
                _TokenTile(
                  label: 'surfacePressed',
                  color: colors.surfacePressed,
                ),
                _TokenTile(
                  label: 'surfaceInverse',
                  color: colors.surfaceInverse,
                ),
                _TokenTile(label: 'border', color: colors.border),
                _TokenTile(label: 'borderSubdued', color: colors.borderSubdued),
                _TokenTile(label: 'borderHover', color: colors.borderHover),
                _TokenTile(label: 'borderStrong', color: colors.borderStrong),
                _TokenTile(label: 'textPrimary', color: colors.textPrimary),
                _TokenTile(label: 'textSecondary', color: colors.textSecondary),
                _TokenTile(label: 'textDim', color: colors.textDim),
                _TokenTile(label: 'gold', color: colors.gold),
                _TokenTile(label: 'teal', color: colors.teal),
                _TokenTile(label: 'success', color: colors.success),
                _TokenTile(label: 'warning', color: colors.warning),
                _TokenTile(label: 'danger', color: colors.danger),
                _TokenTile(label: 'info', color: colors.info),
                _TokenTile(label: 'focusRing', color: colors.focusRing),
                _TokenTile(label: 'disabled', color: colors.disabledBackground),
              ],
            ),
          ),
          _Section(
            title: 'Action states',
            caption: 'Rest, hover, pressed and disabled for both actions',
            child: Column(
              children: [
                _StateRow(
                  name: 'Primary (gold)',
                  rest: colors.gold,
                  hover: colors.primaryHover,
                  pressed: colors.primaryPressed,
                  disabled: colors.primaryDisabled,
                ),
                _StateRow(
                  name: 'Secondary (teal)',
                  rest: colors.teal,
                  hover: colors.secondaryHover,
                  pressed: colors.secondaryPressed,
                  disabled: colors.disabledBackground,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Status',
            caption: 'Notification styling: dim fill, AA text, tinted border',
            child: Column(
              children: [
                _StatusTile(
                  icon: Icons.check_circle_outline,
                  title: 'Success',
                  message: 'Prayer logged — streak extended',
                  fill: colors.successDim,
                  border: colors.success,
                  foreground: colors.successText,
                ),
                _StatusTile(
                  icon: Icons.warning_amber_outlined,
                  title: 'Warning',
                  message: 'Only 10 minutes left before Isha',
                  fill: colors.warning.withValues(alpha: 0.12),
                  border: colors.warning,
                  foreground: colors.warningText,
                ),
                _StatusTile(
                  icon: Icons.error_outline,
                  title: 'Danger',
                  message: 'Could not sync your progress',
                  fill: colors.dangerDim,
                  border: colors.danger,
                  foreground: colors.dangerText,
                ),
                _StatusTile(
                  icon: Icons.info_outline,
                  title: 'Info',
                  message: 'Ramadan mode starts in 3 days',
                  fill: colors.infoDim,
                  border: colors.info,
                  foreground: colors.infoText,
                ),
              ],
            ),
          ),
          _Section(
            title: 'On-colors',
            caption: 'Foregrounds guaranteed readable on each fill',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _OnColorChip(
                  fill: colors.gold,
                  foreground: colors.onGold,
                  label: 'on gold',
                ),
                _OnColorChip(
                  fill: colors.teal,
                  foreground: colors.onTeal,
                  label: 'on teal',
                ),
                _OnColorChip(
                  fill: colors.success,
                  foreground: colors.onSuccess,
                  label: 'on success',
                ),
                _OnColorChip(
                  fill: colors.warning,
                  foreground: colors.onWarning,
                  label: 'on warning',
                ),
                _OnColorChip(
                  fill: colors.danger,
                  foreground: colors.onDanger,
                  label: 'on danger',
                ),
                _OnColorChip(
                  fill: colors.info,
                  foreground: colors.onInfo,
                  label: 'on info',
                ),
              ],
            ),
          ),
          _Section(
            title: 'Typography',
            caption:
                'Dual-script type scale (Amiri/Poppins display, Naskh body)',
            child: _TypographyScale(colors: colors),
          ),
          const _Section(
            title: 'Spacing',
            caption: '4/8dp scale — every gap in the app comes from this list',
            child: _SpacingScale(),
          ),
          const _Section(
            title: 'Radii',
            caption:
                'Corner treatments, including the predefined BorderRadius shapes',
            child: _RadiusGallery(),
          ),
          const _Section(
            title: 'Motion',
            caption:
                'Durations and curves; prefersReducedMotion() overrides all three',
            child: _MotionTable(),
          ),
          const _Section(
            title: 'Elevation',
            caption:
                'Box-shadow presets (the glows read best on the dark theme)',
            child: _ShadowGallery(),
          ),
          const _Section(
            title: 'Breakpoints',
            caption:
                'Responsive bands — context.breakpoint / isCompact / isExpanded',
            child: _BreakpointTable(),
          ),
          _Section(
            title: 'Component',
            caption: 'The one design-system widget the app still builds from',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                const TaqwaBadge(label: 'TaqwaBadge'),
                TaqwaBadge(
                  label: 'teal',
                  color: colors.teal,
                  bgColor: colors.tealDim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section chrome ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String caption;
  final Widget child;

  const _Section({
    required this.title,
    required this.caption,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        // `stretch`, not `start`: in RTL the start edge is the right one, so a
        // shrink-wrapping child like the typography card hugs the right edge
        // and leaves the rest of the row empty.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: typography.headingLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(caption, style: typography.caption),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ── Palette ramps ──────────────────────────────────────────────────────

class _RampRow extends StatelessWidget {
  final String name;
  final List<Color> ramp;

  const _RampRow({required this.name, required this.ramp});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: typography.caption),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final (index, color) in ramp.indexed)
                Expanded(
                  child: Tooltip(
                    // Leading LRM: the tooltip overlay inherits the page's RTL
                    // direction, which would reorder the '#'.
                    message:
                        '\u200E${index == 0 ? 50 : index * 100} — ${_hex(color)}',
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          border: Border.all(color: colors.border),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Semantic token tiles ───────────────────────────────────────────────

class _TokenTile extends StatelessWidget {
  final String label;
  final Color color;

  const _TokenTile({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              border: Border.all(color: colors.border),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: typography.caption.copyWith(color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _LtrText(
            _hex(color),
            style: typography.caption.copyWith(color: colors.textDim),
          ),
        ],
      ),
    );
  }
}

// ── Action state strips ────────────────────────────────────────────────

class _StateRow extends StatelessWidget {
  final String name;
  final Color rest;
  final Color hover;
  final Color pressed;
  final Color disabled;

  const _StateRow({
    required this.name,
    required this.rest,
    required this.hover,
    required this.pressed,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: typography.caption),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _StateSwatch(label: 'rest', color: rest),
              _StateSwatch(label: 'hover', color: hover),
              _StateSwatch(label: 'pressed', color: pressed),
              _StateSwatch(label: 'disabled', color: disabled, dim: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final bool dim;

  const _StateSwatch({
    required this.label,
    required this.color,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: dim ? colors.disabledBackground : color,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(color: colors.border),
              ),
              alignment: Alignment.center,
              child: dim
                  ? Text(
                      'Aa',
                      style: typography.caption.copyWith(
                        color: colors.disabledContent,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: typography.caption),
          ],
        ),
      ),
    );
  }
}

// ── Status tiles ───────────────────────────────────────────────────────

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color fill;
  final Color border;
  final Color foreground;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.fill,
    required this.border,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.labelMedium.copyWith(color: foreground),
                ),
                Text(
                  message,
                  style: typography.bodySmall.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── On-color chips ─────────────────────────────────────────────────────

class _OnColorChip extends StatelessWidget {
  final Color fill;
  final Color foreground;
  final String label;

  const _OnColorChip({
    required this.fill,
    required this.foreground,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.chip),
      child: Text(
        'Aa $label',
        style: typography.labelMedium.copyWith(color: foreground),
      ),
    );
  }
}

// ── Typography scale ───────────────────────────────────────────────────

class _TypographyScale extends StatelessWidget {
  final AppColorsExtension colors;

  const _TypographyScale({required this.colors});

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<AppTypographyExtension>()!;
    final typography = context.typography;

    final styles = <(String, TextStyle)>[
      ('displayLarge', type.displayLarge),
      ('displayMedium', type.displayMedium),
      ('headingLarge', type.headingLarge),
      ('headingMedium', type.headingMedium),
      ('bodyLarge', type.bodyLarge),
      ('bodyMedium', type.bodyMedium),
      ('bodySmall', type.bodySmall),
      ('labelLarge', type.labelLarge),
      ('labelMedium', type.labelMedium),
      ('caption', type.caption),
      ('quranicVerse', type.quranicVerse),
      ('taqwaScore', type.taqwaScore),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, style) in styles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: typography.caption),
                  Text(
                    'Takwa — التقوى',
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Spacing scale ──────────────────────────────────────────────────────

class _SpacingScale extends StatelessWidget {
  const _SpacingScale();

  static const _steps = <(String, double)>[
    ('xxs', AppSpacing.xxs),
    ('xs', AppSpacing.xs),
    ('sm', AppSpacing.sm),
    ('md', AppSpacing.md),
    ('lg', AppSpacing.lg),
    ('xl', AppSpacing.xl),
    ('xxl', AppSpacing.xxl),
    ('xxxl', AppSpacing.xxxl),
    ('huge', AppSpacing.huge),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, value) in _steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    name,
                    style: typography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  height: 12,
                  width: value,
                  decoration: BoxDecoration(
                    color: colors.goldDim,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: colors.gold),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${value.toInt()}dp',
                  style: typography.caption.copyWith(color: colors.textDim),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Radius shapes ──────────────────────────────────────────────────────

class _RadiusGallery extends StatelessWidget {
  const _RadiusGallery();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final shapes = <(String, BorderRadius)>[
      ('card · lg', AppRadius.card),
      ('button · full', AppRadius.button),
      ('chip · full', AppRadius.chip),
      ('input · md', AppRadius.input),
      ('bottomSheet · xxl', AppRadius.bottomSheet),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final (name, radius) in shapes)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.card2,
                  borderRadius: radius,
                  border: Border.all(color: colors.borderStrong),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(name, style: typography.caption),
            ],
          ),
      ],
    );
  }
}

// ── Motion tokens ──────────────────────────────────────────────────────

class _MotionTable extends StatelessWidget {
  const _MotionTable();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final rows = <(String, String)>[
      ('fast', '${AppMotion.fast.inMilliseconds}ms · press feedback, toggles'),
      (
        'base',
        '${AppMotion.base.inMilliseconds}ms · crossfades, card and section transitions',
      ),
      (
        'slow',
        '${AppMotion.slow.inMilliseconds}ms · page, sheet and drawer slides',
      ),
      ('standard', 'Curves.easeOutCubic · default entrance'),
      ('emphasized', 'Curves.easeInOutCubic · morph and expand'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, detail) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    name,
                    style: typography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(child: Text(detail, style: typography.caption)),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Elevation presets ──────────────────────────────────────────────────

class _ShadowGallery extends StatelessWidget {
  const _ShadowGallery();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final presets = <(String, List<BoxShadow>)>[
      ('card', AppShadows.card),
      ('modal', AppShadows.modal),
      ('goldGlow', AppShadows.goldGlow),
      ('tealGlow', AppShadows.tealGlow),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final (name, shadows) in presets)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: colors.border),
                  boxShadow: shadows,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(name, style: typography.caption),
            ],
          ),
      ],
    );
  }
}

// ── Responsive bands ───────────────────────────────────────────────────

class _BreakpointTable extends StatelessWidget {
  const _BreakpointTable();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final band in AppBreakpoint.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    band.name,
                    style: typography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: _LtrText(
                    band.maxWidth == double.infinity
                        ? '≥ ${band.minWidth.toInt()}dp'
                        : '${band.minWidth.toInt()}–${band.maxWidth.toInt()}dp',
                    style: typography.caption,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Utilities ──────────────────────────────────────────────────────────

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

/// A token value that must keep its left-to-right glyph order even when the
/// page is rendered under Arabic RTL. `#` and `–` are directionally neutral,
/// so in an RTL paragraph `#C8A96E` prints as `C8A96E#` and `0–599dp` prints
/// as `599dp–0` — wrong values on the page that exists to report values.
class _LtrText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign textAlign;

  const _LtrText(
    this.data, {
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(data, style: style, textAlign: textAlign),
  );
}
