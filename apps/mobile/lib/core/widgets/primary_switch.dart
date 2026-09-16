import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takwa/core/theme/app_theme.dart';

class PrimarySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  const PrimarySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? context.colors.teal;

    return Switch(
      value: value,
      onChanged: (val) {
        HapticFeedback.selectionClick();
        onChanged(val);
      },
      activeThumbColor: activeColor,
      activeTrackColor: activeColor.withValues(alpha: 0.3),
      inactiveTrackColor: context.colors.border,
      inactiveThumbColor: context.colors.textDim,
    );
  }
}
