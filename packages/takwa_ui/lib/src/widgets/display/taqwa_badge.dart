import 'package:flutter/material.dart';

import '../../theme/context_extensions.dart';
import '../../tokens/app_radii.dart';

/// Tag badge with rounded chip styling and subtle background opacity.
///
/// The only design-system component with call sites in the app; the rest of
/// the widget layer was dropped when it turned out to have zero adoption.
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
