import 'package:flutter/material.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../theme/context_extensions.dart';
import '../buttons/takwa_button.dart';

/// Modal dialog component for confirmations, alerts, and devotional prompts.
class TakwaDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;
  final Widget? icon;

  const TakwaDialog({
    super.key,
    required this.title,
    required this.content,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.isDestructive = false,
    this.icon,
  });

  /// Displays the dialog using the standard navigator.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => TakwaDialog(
        title: title,
        content: content,
        primaryActionText: primaryActionText,
        onPrimaryAction: onPrimaryAction,
        secondaryActionText: secondaryActionText,
        onSecondaryAction: onSecondaryAction,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Dialog(
      backgroundColor: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: colors.border, width: 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(child: icon!),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              title,
              style: typography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content,
              style: typography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                if (secondaryActionText != null)
                  Expanded(
                    child: TakwaButton(
                      text: secondaryActionText!,
                      variant: TakwaButtonVariant.outline,
                      onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(false),
                    ),
                  ),
                if (secondaryActionText != null && primaryActionText != null)
                  const SizedBox(width: AppSpacing.md),
                if (primaryActionText != null)
                  Expanded(
                    child: TakwaButton(
                      text: primaryActionText!,
                      variant: isDestructive
                          ? TakwaButtonVariant.destructive
                          : TakwaButtonVariant.primary,
                      onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(true),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
