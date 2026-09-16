import 'package:flutter/material.dart';
import '../../tokens/app_radii.dart';
import '../../theme/context_extensions.dart';

/// Tag badge with rounded chip styling and subtle background opacity.
class TaqwaBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;

  const TaqwaBadge({super.key, required this.label, this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.gold;
    final bg = bgColor ?? context.colors.goldDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.chip,
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: context.typography.caption.copyWith(color: c)),
    );
  }
}

/// Streak badge with fire emoji and high-contrast success styling.
class StreakBadge extends StatelessWidget {
  final String label;
  const StreakBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.successDim,
        borderRadius: AppRadius.chip,
        border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.typography.caption.copyWith(
              color: context.colors.successText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider header with section label and trailing hairline stroke.
class SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const SectionLabel({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.teal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: context.typography.caption.copyWith(color: c)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: c.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

/// Interactive filter or selection chip adhering to Takwa Design System tokens.
class TakwaChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? icon;

  const TakwaChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final bg = isSelected ? colors.goldDim : colors.card;
    final borderCol = isSelected ? colors.gold : colors.border;
    final fg = isSelected ? colors.goldText : colors.textSecondary;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.chip,
        side: BorderSide(color: borderCol, width: 1),
      ),
      child: InkWell(
        borderRadius: AppRadius.chip,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: typography.labelMedium.copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
