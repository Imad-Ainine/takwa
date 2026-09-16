import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/custom_pattern_background.dart';
import '../../../../core/widgets/custom_leading_button.dart';
import '../../../../core/widgets/custom_time_picker.dart';
import 'package:takwa/l10n/app_localizations.dart';

class QiyamSleepCalculatorScreen extends StatefulWidget {
  const QiyamSleepCalculatorScreen({super.key});

  @override
  State<QiyamSleepCalculatorScreen> createState() =>
      _QiyamSleepCalculatorScreenState();
}

class _QiyamSleepCalculatorScreenState
    extends State<QiyamSleepCalculatorScreen> {
  TimeOfDay _wakeupTime = const TimeOfDay(hour: 4, minute: 30);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off Row(CustomLeadingButton + title)
      // (audit item 29) — consistent with the rest of the app's app bars.
      appBar: AppBarWidget(
        title: l10n.qiyamSleepCalcTitle,
        leading: const CustomLeadingButton(),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildWakeupSelector(context),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text(
                    l10n.qiyamSleepCalcBestTimesLabel,
                    style: context.typography.displayMedium.copyWith(
                      fontSize: 20,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._buildCycleCards(context),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Center(
          child: Text(
            l10n.qiyamSleepCalcHeaderTitle,
            style: context.typography.displayMedium.copyWith(
              fontSize: 24,
              color: context.colors.gold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            l10n.qiyamSleepCalcHeaderSubtitle,
            style: context.typography.bodyLarge.copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildWakeupSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: context.colors.gold.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              l10n.qiyamSleepCalcWakeupQuestion,
              style: context.typography.bodyLarge.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () async {
                final picked = await showCustomTimePicker(
                  context: context,
                  initialTime: _wakeupTime,
                );
                if (picked != null) {
                  setState(() => _wakeupTime = picked);
                }
              },
              child: InkWell(
                onTap: () async {
                  final TimeOfDay? picked = await showCustomTimePicker(
                    context: context,
                    initialTime: _wakeupTime,
                  );
                  if (picked != null) {
                    setState(() {
                      _wakeupTime = picked;
                    });
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: context.colors.gold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(
                          child: CustomPatternBackground(
                            pattern: BackgroundPattern.adhkar,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: AppSpacing.lg,
                          ),
                          child: Text(
                            '${_wakeupTime.hour.toString().padLeft(2, '0')}:${_wakeupTime.minute.toString().padLeft(2, '0')}',
                            style: context.typography.displayLarge.copyWith(
                              fontSize: 42,
                              color: context.colors.gold,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCycleCards(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycles = [
      {'label': l10n.qiyamSleepCycle9h, 'hours': 9.0, 'color': Colors.green},
      {
        'label': l10n.qiyamSleepCycle75h,
        'hours': 7.5,
        'color': Colors.lightGreen,
      },
      {'label': l10n.qiyamSleepCycle6h, 'hours': 6.0, 'color': Colors.orange},
      {
        'label': l10n.qiyamSleepCycle45h,
        'hours': 4.5,
        'color': Colors.deepOrange,
      },
      {'label': l10n.qiyamSleepCycle15h, 'hours': 1.5, 'color': Colors.red},
    ];

    return cycles.map((cycle) {
      final hours = cycle['hours'] as double;
      final color = cycle['color'] as Color;
      final sleepTime = _calculateSleepTime(hours);

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPatternBackground(
                    pattern: BackgroundPattern.adhkar,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          cycle['label'] as String,
                          style: context.typography.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(context, sleepTime),
                            style: context.typography.displayMedium.copyWith(
                              fontSize: 22,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.qiyamSleepCalcSleepAtLabel,
                            style: context.typography.caption.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  DateTime _calculateSleepTime(double hours) {
    final now = DateTime.now();
    var wakeup = DateTime(
      now.year,
      now.month,
      now.day,
      _wakeupTime.hour,
      _wakeupTime.minute,
    );

    // If wakeup is before now, it's for tomorrow
    if (wakeup.isBefore(now)) {
      wakeup = wakeup.add(const Duration(days: 1));
    }

    // Subtract sleep duration + 15 mins for falling asleep
    final totalMinutes = (hours * 60).toInt() + 15;
    return wakeup.subtract(Duration(minutes: totalMinutes));
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context)!;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? l10n.timePeriodAm : l10n.timePeriodPm;
    return '$ampm $h:$m';
  }
}
