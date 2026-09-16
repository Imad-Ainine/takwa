import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/features/quran/data/quran_models.dart';
import '../../providers/quran_providers.dart';
import '../../utils/quran_helpers.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/database_providers.dart';
import '../widgets/quran_widgets.dart';
import 'package:takwa/l10n/app_localizations.dart';

class KhatmaProgressSettingsScreen extends ConsumerWidget {
  const KhatmaProgressSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);

    final khatma = ref.watch(khatmaExProvider);
    final pagesRead = khatma?.pagesRead ?? 0;
    final progress = khatma?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: style.bg,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29). As a plain
      // Scaffold.appBar (not inside the scroll view) it's always visible
      // regardless of scroll, matching this SliverAppBar's pinned: true.
      appBar: AppBarWidget(
        title: l10n.khatmaProgressScreenTitle,
        leading: const CustomLeadingButton(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                KhatmaProgressRing(
                  progress: progress,
                  pagesRead: pagesRead,
                  totalPages: 604,
                  style: style,
                  color: style.gold,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.khatmaProgressPercentComplete(
                    (progress * 100).toStringAsFixed(1),
                  ),
                  style: style.naskh(
                    16,
                    color: style.gold,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildStatsRow(context, style, khatma, l10n),
                const SizedBox(height: AppSpacing.xxl),
                _buildChart(context, style, l10n),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AdaptiveStyle style,
    KhatmaSessionEx? khatma,
    AppLocalizations l10n,
  ) {
    final days = khatma != null
        ? DateTime.now().difference(khatma.startDate).inDays + 1
        : 0;
    final avgPerDay = days > 0
        ? (khatma!.pagesRead / days).toStringAsFixed(1)
        : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _StatsCard(
            style: style,
            icon: Icons.timer_rounded,
            label: l10n.khatmaStatDaysLabel,
            value: localizedNumeral(context, days),
            color: style.gold,
          ),
          const SizedBox(width: AppSpacing.md),
          _StatsCard(
            style: style,
            icon: Icons.auto_stories_rounded,
            label: l10n.khatmaStatPagesReadLabel,
            value: localizedNumeral(context, khatma?.pagesRead ?? 0),
            color: const Color(0xFF3AAFA9),
          ),
          const SizedBox(width: AppSpacing.md),
          _StatsCard(
            style: style,
            icon: Icons.speed_rounded,
            label: l10n.khatmaStatPagesPerDayLabel,
            value: avgPerDay,
            color: const Color(0xFF4CAF7D),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    AdaptiveStyle style,
    AppLocalizations l10n,
  ) {
    final values = [3.0, 5.0, 2.0, 7.0, 4.0, 6.0, 3.0];
    final days = [
      l10n.weekdayShortSunday,
      l10n.weekdayShortMonday,
      l10n.weekdayShortTuesday,
      l10n.weekdayShortWednesday,
      l10n.weekdayShortThursday,
      l10n.weekdayShortFriday,
      l10n.weekdayShortSaturday,
    ];
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l10n.khatmaWeeklyReadingTitle,
            style: style.amiri(18, color: style.text, weight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: style.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: style.gold.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = (values[i] / maxVal) * 100;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        localizedNumeral(context, values[i].toInt()),
                        style: style.naskh(
                          10,
                          color: style.text.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500 + i * 80),
                        width: 14,
                        height: h,
                        decoration: BoxDecoration(
                          color: i == 3
                              ? style.gold
                              : style.gold.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: style.naskh(
                          10,
                          color: style.text.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AdaptiveStyle style;
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatsCard({
    required this.style,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: style.amiri(22, color: style.text, weight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: style.naskh(10, color: style.text.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  EXTENDED SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────
class KhatmaExtendedSettingsScreen extends ConsumerWidget {
  const KhatmaExtendedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final state = ref.watch(quranStateProvider);

    return Scaffold(
      backgroundColor: style.bg,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29). As a plain
      // Scaffold.appBar (not inside the scroll view) it's always visible
      // regardless of scroll, matching this SliverAppBar's pinned: true.
      appBar: AppBarWidget(
        title: l10n.settingsScreenTitle,
        leading: const CustomLeadingButton(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _sectionLabel(style, l10n.quranReaderSettingsTitle),
                  const SizedBox(height: 14),
                  _card(
                    style: style,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.quranReaderFontSizeLabel,
                          style: style.amiri(
                            17,
                            color: style.text,
                            weight: FontWeight.bold,
                          ),
                        ),
                        Slider(
                          value: state.fontSize,
                          min: 14,
                          max: 34,
                          activeColor: style.gold,
                          inactiveColor: style.gold.withValues(alpha: 0.1),
                          onChanged: (v) => ref
                              .read(quranStateProvider.notifier)
                              .setFontSize(v),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: style.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                              style: style.amiri(
                                state.fontSize,
                                color: style.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    style: style,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.khatmaReadingAppearanceLabel,
                          style: style.amiri(
                            17,
                            color: style.text,
                            weight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            for (final theme in [
                              (l10n.quranReaderThemeNight, ReaderTheme.night),
                              (l10n.quranReaderThemeSepia, ReaderTheme.sepia),
                              (l10n.quranReaderThemeWhite, ReaderTheme.white),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                  ),
                                  child: TakwaTappable(
                                  onTap: () => ref
                                      .read(quranStateProvider.notifier)
                                      .setTheme(theme.$2),
                                  minTapSize: null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: state.theme == theme.$2
                                          ? style.gold.withValues(alpha: 0.1)
                                          : style.card,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: state.theme == theme.$2
                                            ? style.gold
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        theme.$1,
                                        style: style.amiri(
                                          14,
                                          color: state.theme == theme.$2
                                              ? style.gold
                                              : style.text.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _sectionLabel(style, l10n.khatmaSettingsSectionTitle),
                  const SizedBox(height: 14),
                  _card(
                    style: style,
                    child: Column(
                      children: [
                        _settingRow(
                          style,
                          Icons.mic_rounded,
                          l10n.khatmaReciterLabel,
                          l10n.khatmaReciterDefaultValue,
                        ),
                        Divider(color: style.gold.withValues(alpha: 0.1), height: 20),
                        _settingRow(
                          style,
                          Icons.notifications_rounded,
                          l10n.khatmaDailyReminderLabel,
                          '',
                          trailing: Switch(
                            value: false,
                            activeThumbColor: style.gold,
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AdaptiveStyle style, String t) => Text(
    t,
    style: style.amiri(
      16,
      color: style.text.withValues(alpha: 0.5),
      weight: FontWeight.bold,
    ),
  );

  Widget _card({required AdaptiveStyle style, required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: style.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: style.gold.withValues(alpha: 0.1)),
        ),
        child: child,
      );

  Widget _settingRow(
    AdaptiveStyle style,
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) => Row(
    children: [
      if (trailing != null) trailing,
      const Spacer(),
      Text(label, style: style.naskh(14, color: style.text.withValues(alpha: 0.7))),
      const SizedBox(width: AppSpacing.sm),
      Icon(icon, color: style.gold, size: 18),
      const SizedBox(width: AppSpacing.sm),
      if (value.isNotEmpty)
        Text(value, style: style.naskh(13, color: style.text.withValues(alpha: 0.4))),
    ],
  );
}
