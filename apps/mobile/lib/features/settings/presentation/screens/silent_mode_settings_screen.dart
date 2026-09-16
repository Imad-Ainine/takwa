import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import '../widgets/settings_widgets.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Minutes options offered for "how long to silence the phone after each
/// prayer time starts" — read by OverlayBackgroundService's
/// `_checkAndApplySilentMode` (`silent_duration_mins`).
const _silentDurationOptions = [10, 15, 20, 30, 45, 60];

class SilentModeSettingsScreen extends ConsumerWidget {
  const SilentModeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(userPreferencesProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final syncError = ref.watch(lastSyncErrorProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: AppBarWidget(
        leading: const CustomLeadingButton(),
        title: l10n.silentModeSettingsTitle,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: SyncStatusIndicator(
                isSyncing: isSyncing,
                syncError: syncError,
                pendingCount: pendingSyncCount,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    prefsAsync.when(
                      loading: () =>
                          const Center(child: TakwaLoadingIndicator(size: 40)),
                      error: (err, _) =>
                          Center(child: Text(l10n.checklistErrorPrefix('$err'))),
                      data: (prefs) => Column(
                        children: [
                          SettingsCard(
                            children: [
                              ToggleSetting(
                                icon: '🔇',
                                label: l10n.silentModeEnableLabel,
                                sublabel: l10n.silentModeEnableSublabel,
                                value: prefs.silentModeEnabled,
                                onChanged: (v) {
                                  ref
                                      .read(userPreferencesProvider.notifier)
                                      .updatePref('silent_mode_enabled', v);
                                  // Push live — the background isolate only
                                  // otherwise picks this up on its next
                                  // start (see docs/specs/settings-
                                  // notifications-improvements.md R6).
                                  OverlayBackgroundService.updateSettings(
                                    silentModeEnabled: v,
                                  );
                                },
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '📳',
                                label: l10n.silentModeVibrationLabel,
                                sublabel: l10n.silentModeVibrationSublabel,
                                value: prefs.silentVibrationEnabled,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('silent_vibration_enabled', v),
                              ),
                              const SettingsDivider(),
                              SelectSetting(
                                icon: '🔔',
                                label: l10n.silentModeAlertStyleLabel,
                                value: prefs.silentModeAlertStyle,
                                options: {
                                  'none': l10n.silentModeAlertNone,
                                  'vibrate': l10n.silentModeAlertVibrateOnly,
                                  'tone': l10n.silentModeAlertToneOnly,
                                  'toneVibrate': l10n.silentModeAlertToneVibrate,
                                },
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('silent_mode_alert_style', v),
                              ),
                              if (prefs.silentModeEnabled) ...[
                                const SettingsDivider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: _SilentDurationSelector(
                                    value: prefs.silentDurationMins,
                                    onChanged: (v) {
                                      ref
                                          .read(
                                            userPreferencesProvider.notifier,
                                          )
                                          .updatePref(
                                            'silent_duration_mins',
                                            v,
                                          );
                                      OverlayBackgroundService.updateSettings(
                                        silentDurationMins: v,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  SILENT DURATION SELECTOR
// ─────────────────────────────────────────
class _SilentDurationSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _SilentDurationSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.silentModeDurationLabel,
                style: context.typography.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.silentModeDurationSublabel,
          style: context.typography.caption.copyWith(
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _silentDurationOptions.map((mins) {
            final isSelected = mins == value;
            return TakwaTappable(
              onTap: () => onChanged(mins),
              minTapSize: null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.gold.withValues(alpha: 0.12)
                      : context.colors.card.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.gold
                        : context.colors.border.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  l10n.silentModeDurationMinutes(mins),
                  style: context.typography.caption.copyWith(
                    fontSize: 12,
                    color: isSelected
                        ? context.colors.gold
                        : context.colors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
