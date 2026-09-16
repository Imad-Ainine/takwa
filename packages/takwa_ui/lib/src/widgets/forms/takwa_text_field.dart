import 'package:flutter/material.dart';
import '../../tokens/app_radii.dart';
import '../../theme/context_extensions.dart';

/// Form text field conforming to Takwa Design System input styling and accessible error contracts.
class TakwaTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  const TakwaTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final borderShape = OutlineInputBorder(
      borderRadius: AppRadius.input,
      borderSide: BorderSide(color: colors.border, width: 1.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: typography.labelMedium.copyWith(
              color: errorText != null ? colors.dangerText : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autofocus: autofocus,
          readOnly: readOnly,
          maxLines: maxLines,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          style: typography.bodyLarge.copyWith(color: colors.textPrimary),
          cursorColor: colors.goldText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: typography.bodyMedium.copyWith(color: colors.textDim),
            errorText: errorText,
            errorStyle: typography.bodySmall.copyWith(color: colors.dangerText),
            helperText: helperText,
            helperStyle: typography.caption.copyWith(color: colors.textDim),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colors.card2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            border: borderShape,
            enabledBorder: borderShape,
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: colors.goldText, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: colors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: colors.danger, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}
