import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import '../../../../core/widgets/takwa_loading_indicator.dart';
import '../../../../core/notifications/notifications_service.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamCalculatorScreen extends ConsumerWidget {
  const QiyamCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prayersAsync = ref.watch(prayerTimesProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off Row(CustomLeadingButton + title)
      // built inside the `data` branch below (audit item 29) — that also
      // meant there was no back button at all while prayer times were
      // loading or failed to load; hoisting it to Scaffold.appBar fixes
      // that for free.
      appBar: AppBarWidget(
        title: l10n.qiyamCalcScreenTitle,
        leading: const CustomLeadingButton(),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: prayersAsync.when(
              data: (prayers) => _buildContent(context, prayers),
              loading: () => const Center(child: TakwaLoadingIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.qiyamCalcLoadError('$e'))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<PrayerTimeInfo> prayers) {
    final l10n = AppLocalizations.of(context)!;
    final maghrib = prayers.firstWhere((p) => p.name == 'maghrib').time;
    final fajr = prayers.firstWhere((p) => p.name == 'fajr').time;

    // Total night duration (Maghrib to Fajr)
    // If Fajr is before Maghrib (same day), move Fajr to tomorrow
    var fajrAdjusted = fajr;
    if (fajr.isBefore(maghrib)) {
      fajrAdjusted = fajr.add(const Duration(days: 1));
    }

    final totalNight = fajrAdjusted.difference(maghrib);
    final midnight = maghrib.add(totalNight ~/ 2);
    final lastThirdStart = fajrAdjusted.subtract(totalNight ~/ 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _buildTimeCard(
            context,
            title: l10n.qiyamCalcMidnightTitle,
            time: midnight,
            subtitle: l10n.qiyamCalcMidnightSubtitle,
            icon: Icons.brightness_3,
            color: context.colors.teal,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTimeCard(
            context,
            title: l10n.qiyamCalcLastThirdTitle,
            time: lastThirdStart,
            subtitle: l10n.qiyamCalcLastThirdSubtitle,
            icon: Icons.auto_awesome,
            color: context.colors.gold,
            isHighlight: true,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildinfoSection(context),
        ],
      ),
    );
  }

  Widget _buildTimeCard(
    BuildContext context, {
    required String title,
    required DateTime time,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.5) : context.colors.border,
          width: isHighlight ? 2 : 1,
        ),
        boxShadow: isHighlight
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.typography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: context.typography.caption.copyWith(
                            color: context.colors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(context, time),
                    style: context.typography.displayMedium.copyWith(
                      fontSize: 20,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildinfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: context.colors.gold),
          const SizedBox(height: AppSpacing.md),
          Text(
            'عن أبي هريرة رضي الله عنه أن رسول الله ﷺ قال: "ينزل ربنا تبارك وتعالى كل ليلة إلى السماء الدنيا حين يبقى ثلث الليل الآخر يقول: من يدعوني فأستجيب له، من يسألني فأعطيه، من يستغفرني فأغفر له"',
            style: context.typography.quranicVerse.copyWith(
              fontSize: 14,
              color: context.colors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? l10n.timePeriodAm : l10n.timePeriodPm;
    return '$h:$m $ampm';
  }
}
