import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/features/reminders/presentation/widgets/add_reminder_bottom_sheet.dart';

class ReminderCard extends StatelessWidget {
  final String title;
  final String time;
  final String iconKey;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const ReminderCard({
    super.key,
    required this.title,
    required this.time,
    required this.iconKey,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final icon = kReminderIcons[iconKey] ?? Icons.notifications_rounded;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.card.withValues(alpha: 0.7),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isEnabled
                ? context.colors.teal.withValues(alpha: 0.25)
                : context.colors.border,
          ),
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isEnabled ? context.colors.tealGoldGradient : null,
                color: isEnabled ? null : context.colors.card2,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.white : context.colors.textDim,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typography.headingMedium.copyWith(
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        time,
                        style: context.typography.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Toggle Switch
            Switch(
              value: isEnabled,
              onChanged: onToggle,
              activeThumbColor: Colors.white,
              activeTrackColor: context.colors.teal,
              inactiveThumbColor: context.colors.textDim,
              inactiveTrackColor: context.colors.border,
            ),
          ],
        ),
      ),
    );
  }
}
