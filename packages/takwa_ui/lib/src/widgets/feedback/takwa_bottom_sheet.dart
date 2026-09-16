import 'package:flutter/material.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../theme/context_extensions.dart';

/// Standard bottom sheet modal container for the Takwa Design System.
abstract final class TakwaBottomSheet {
  /// Presents a standardized modal bottom sheet with drag handle and safe insets.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
  }) {
    final colors = context.colors;
    final typography = context.typography;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.bottomSheet,
            border: Border.all(color: colors.border, width: 1.0),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10.0),
                // Drag handle
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: AppRadius.chip,
                    ),
                  ),
                ),
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: typography.headingMedium,
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colors.border, height: 1.0),
                ],
                Flexible(
                  child: builder(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
