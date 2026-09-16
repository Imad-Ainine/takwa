import 'package:flutter/material.dart';
import 'package:takwa/core/theme/app_theme.dart';

class AdviceCard extends StatelessWidget {
  final String title;
  final String description;

  const AdviceCard({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.goldDim,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: context.colors.goldDark,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typography.headingMedium.copyWith(
                    color: context.colors.goldDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: context.typography.bodyMedium.copyWith(
                    color: context.colors.textPrimary.withValues(alpha: 0.8),
                    height: 1.6,
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
