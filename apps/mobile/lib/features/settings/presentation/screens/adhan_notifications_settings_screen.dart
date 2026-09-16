import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/settings/providers/user_preferences_provider.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:takwa/core/providers/database_providers.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/location_picker_sheet.dart';
import 'silent_mode_settings_screen.dart';
import '../widgets/prayer_selection_sheet.dart';
import 'package:takwa/l10n/app_localizations.dart';

Map<String, String> adhanOptions(AppLocalizations l10n) => {
  'Adhan-Makkah.mp3': l10n.adhanSoundMakkah,
  'Adhan-Madinah.mp3': l10n.adhanSoundMadinah,
  'Adhan-Alaqsa.mp3': l10n.adhanSoundAlaqsa,
  'Adhan-Egypt.mp3': l10n.adhanSoundEgypt,
  'Abdul-Basit.mp3': l10n.adhanSoundAbdulBasit,
  'Minshawi.mp3': l10n.adhanSoundMinshawi,
  'Naghshbandi.mp3': l10n.adhanSoundNaghshbandi,
  'Saber.mp3': l10n.adhanSoundSaber,
  'Al-Hussaini.mp3': l10n.adhanSoundAlHussaini,
  'Bakir-Bash.mp3': l10n.adhanSoundBakirBash,
  'Hafez.mp3': l10n.adhanSoundHafez,
  'Hafiz-Murad.mp3': l10n.adhanSoundHafizMurad,
  'Sharif-Doman.mp3': l10n.adhanSoundSharifDoman,
  'Yusuf-Islam.mp3': l10n.adhanSoundYusufIslam,
};

final adhanPreviewPlayerProvider = Provider.autoDispose((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

final currentlyPlayingAdhanProvider = StateProvider<String?>((ref) => null);

/// Whether the OS notification + exact-alarm permissions are currently
/// granted. `NotificationsManager.scheduleAll()` silently returns doing
/// nothing at all if either is missing (`if (!await NotificationsService.
/// checkPermissions()) return;`) — no prayer-time notification, no
/// full-screen-intent Adhan-screen launch, and nothing in the UI ever
/// said so. Both were previously only ever requested once, during
/// onboarding. Re-read via `ref.invalidate(notificationPermissionsGranted
/// Provider)` after a permission request completes. See
/// docs/specs/adhan-overlay-auto-open.md R6.
final notificationPermissionsGrantedProvider = FutureProvider<bool>((ref) {
  return NotificationsService.checkPermissions();
});

class AdhanNotificationSettingsScreen extends ConsumerWidget {
  const AdhanNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final syncError = ref.watch(lastSyncErrorProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider).value ?? 0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      // AppBarWidget instead of a one-off SliverAppBar — consistent with
      // the rest of the app's app bars (audit item 29).
      appBar: AppBarWidget(
        leading: const CustomLeadingButton(),
        title: l10n.settingsAdhanNotificationsLabel,
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
                      error: (err, _) => Center(
                        child: Text(l10n.checklistErrorPrefix(err.toString())),
                      ),
                      data: (prefs) {
                        final permissionGranted = ref
                            .watch(notificationPermissionsGrantedProvider)
                            .valueOrNull;
                        final needsPermission = permissionGranted == false;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (needsPermission) ...[
                              _NotificationPermissionWarning(
                                onGrant: () async {
                                  await NotificationsService.requestPermissions();
                                  ref.invalidate(
                                    notificationPermissionsGrantedProvider,
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                            SectionHeader(
                              icon: '🕌',
                              title: l10n.adhanSettingsAccountSectionTitle,
                            ),
                          SettingsCard(
                            children: [
                              SelectSetting(
                                icon: '⚖️',
                                label: l10n.adhanMadhabLabel,
                                value: prefs.madhab,
                                options: {
                                  'shafi': l10n.madhabShafi,
                                  'hanafi': l10n.madhabHanafi,
                                },
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('madhab', v),
                              ),
                              const SettingsDivider(),
                              SelectSetting(
                                icon: '🌍',
                                label: l10n.adhanCalcMethodLabel,
                                value: prefs.calcMethod,
                                options: {
                                  'Algeria': l10n.calcMethodAlgeria,
                                  'MWL': l10n.calcMethodMWL,
                                  'Egypt': l10n.calcMethodEgypt,
                                  'Karachi': l10n.calcMethodKarachi,
                                  'UmmAlQura': l10n.calcMethodUmmAlQura,
                                  'ISNA': l10n.calcMethodISNA,
                                },
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('calc_method', v),
                              ),
                              const SettingsDivider(),
                              Builder(
                                builder: (context) {
                                  // `cityName` isn't part of UserPreferences —
                                  // it's written directly via SettingsDao by
                                  // LocationPrayerManager/the background
                                  // isolate — so it's watched separately here,
                                  // same pattern prayer_screen.dart uses.
                                  final cityName = ref
                                      .watch(settingStreamProvider('cityName'))
                                      .value;
                                  return ActionSetting(
                                    icon: '📍',
                                    label: l10n.adhanLocationLabel,
                                    sublabel:
                                        (cityName != null &&
                                            cityName.isNotEmpty)
                                        ? cityName
                                        : l10n.adhanLocationSublabel,
                                    onTap: () => LocationPickerSheet.show(
                                      context,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // Manual per-prayer minute offsets + high-latitude
                          // rule — these were previously stored/consumed
                          // (packages/takwa_core's adhan.CalculationParameters
                          // .adjustments, via notifications_service.dart and
                          // location_prayer_update.dart) but had NO settings
                          // UI anywhere, so a user could never actually set
                          // them. See docs/specs/settings-notifications-
                          // improvements.md R5.
                          SectionHeader(
                            icon: '🧭',
                            title: l10n.settingsAdjustmentsSectionTitle,
                          ),
                          SettingsCard(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  10,
                                  14,
                                  4,
                                ),
                                child: Text(
                                  l10n.settingsAdjustmentsSectionSublabel,
                                  style: context.typography.caption.copyWith(
                                    fontSize: 12,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                              const SettingsDivider(),
                              _PrayerOffsetRow(
                                icon: '🌅',
                                label: l10n.prayerFajr,
                                value: prefs.fajrOffset,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('fajr_offset', v),
                              ),
                              const SettingsDivider(),
                              _PrayerOffsetRow(
                                icon: '🌄',
                                label: l10n.prayerSunrise,
                                value: prefs.sunriseOffset,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('sunrise_offset', v),
                              ),
                              const SettingsDivider(),
                              _PrayerOffsetRow(
                                icon: '☀️',
                                label: l10n.prayerDhuhr,
                                value: prefs.dhuhrOffset,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('dhuhr_offset', v),
                              ),
                              const SettingsDivider(),
                              _PrayerOffsetRow(
                                icon: '🌤',
                                label: l10n.prayerAsr,
                                value: prefs.asrOffset,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('asr_offset', v),
                              ),
                              const SettingsDivider(),
                              _PrayerOffsetRow(
                                icon: '🌆',
                                label: l10n.prayerMaghrib,
                                value: prefs.maghribOffset,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('maghrib_offset', v),
                              ),
                              const SettingsDivider(),
                              _PrayerOffsetRow(
                                icon: '🌃',
                                label: l10n.prayerIsha,
                                value: prefs.ishaOffset,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('isha_offset', v),
                              ),
                              const SettingsDivider(),
                              SelectSetting(
                                icon: '🌐',
                                label: l10n.highLatitudeRuleLabel,
                                value: prefs.highLatitudeRule,
                                options: {
                                  'middle_of_the_night':
                                      l10n.highLatitudeRuleMiddleOfNight,
                                  'seventh_of_the_night':
                                      l10n.highLatitudeRuleSeventhOfNight,
                                  'twilight_angle':
                                      l10n.highLatitudeRuleTwilightAngle,
                                },
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('high_latitude_rule', v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            icon: '🔊',
                            title: l10n.adhanSoundSectionTitle,
                          ),
                          SettingsCard(
                            children: [
                              SelectSetting(
                                icon: '🎵',
                                label: l10n.adhanSoundSectionTitle,
                                value: prefs.adhanSound,
                                options: adhanOptions(l10n),
                                itemTrailingBuilder: (ctx, key, isSelected) =>
                                    AdhanSoundPreviewButton(soundPath: key),
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('adhan_sound', v),
                              ),
                              const SettingsDivider(),
                              SelectSetting(
                                icon: '🔈',
                                label: l10n.adhanModeLabel,
                                value: prefs.adhanMode,
                                options: {
                                  'sound': l10n.adhanModeSound,
                                  'vibrate': l10n.adhanModeVibrate,
                                  'silent': l10n.adhanModeSilent,
                                },
                                onChanged: (v) {
                                  ref
                                      .read(userPreferencesProvider.notifier)
                                      .updatePref('adhan_mode', v);
                                  // Push the new mode to the background
                                  // foreground-task isolate right away — it
                                  // only reads SharedPreferences on its own
                                  // start, so without this the adhan-time
                                  // sound decision there would keep using
                                  // the old mode until the app/service next
                                  // restarts. See
                                  // docs/specs/settings-notifications-
                                  // improvements.md R6.
                                  OverlayBackgroundService.updateSettings(
                                    adhanMode: v,
                                  );
                                },
                              ),
                              const SettingsDivider(),
                              SliderSetting(
                                icon: '🔊',
                                label: l10n.adhanVolumeLabel,
                                value: prefs.adhanVolumeLevel,
                                valueLabelBuilder: (v) =>
                                    '${(v * 100).round()}%',
                                onChanged: (v) {
                                  ref
                                      .read(userPreferencesProvider.notifier)
                                      .updatePref('adhan_volume_level', v);
                                  // Same reasoning as adhanMode above: push
                                  // the new volume to the background
                                  // isolate right away instead of leaving
                                  // it stuck at whatever it was on last
                                  // service start (R6).
                                  OverlayBackgroundService.updateSettings(
                                    adhanVolumeLevel: v,
                                  );
                                },
                              ),
                              const SettingsDivider(),
                              ToggleSetting(
                                icon: '📳',
                                label: l10n.adhanVibrateTypeLabel,
                                sublabel: l10n.adhanVibrateTypeSublabel,
                                value: prefs.vibrateWithAdhan,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('vibrate_with_adhan', v),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            icon: '⚙️',
                            title: l10n.adhanAdvancedSectionTitle,
                          ),
                          SettingsCard(
                            children: [
                              ToggleSetting(
                                icon: '🔇',
                                label: l10n.adhanAutoSilentLabel,
                                sublabel: l10n.adhanAutoSilentSublabel,
                                value: prefs.autoSilentAfterAdhan,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('auto_silent_after_adhan', v),
                              ),
                              const SettingsDivider(),
                              ActionSetting(
                                icon: '⚙️',
                                label: l10n.adhanSilentModeSettingsLabel,
                                sublabel: l10n.adhanSilentModeSettingsSublabel,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const SilentModeSettingsScreen(),
                                  ),
                                ),
                              ),
                              const SettingsDivider(),
                              ActionSetting(
                                icon: '🕌',
                                label: l10n.adhanEnableInSilentLabel,
                                sublabel: l10n.adhanEnableInSilentSublabel,
                                onTap: () => PrayerSelectionSheet.show(
                                  context: context,
                                  title: l10n.adhanEnableInSilentLabel,
                                  selectedPrayers: prefs.silentAdhanPrayers
                                      .split(','),
                                  onChanged: (prayers) => ref
                                      .read(userPreferencesProvider.notifier)
                                      .updatePref(
                                        'silent_adhan_prayers',
                                        prayers.join(','),
                                      ),
                                ),
                              ),
                              const SettingsDivider(),
                              ActionSetting(
                                icon: '📢',
                                label: l10n.adhanEnableNotifInSilentLabel,
                                sublabel: l10n.adhanEnableNotifInSilentSublabel,
                                onTap: () => PrayerSelectionSheet.show(
                                  context: context,
                                  title: l10n.adhanNotifSilentSheetTitle,
                                  selectedPrayers: prefs.silentNotifPrayers
                                      .split(','),
                                  includeSunrise: true,
                                  onChanged: (prayers) => ref
                                      .read(userPreferencesProvider.notifier)
                                      .updatePref(
                                        'silent_notif_prayers',
                                        prayers.join(','),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            icon: '📱',
                            title: l10n.adhanSystemNotifSectionTitle,
                          ),
                          SettingsCard(
                            children: [
                              CheckboxSetting(
                                label: l10n.adhanWakeScreenLabel,
                                sublabel: l10n.adhanWakeScreenSublabel,
                                value: prefs.wakeScreenEnabled,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('wake_screen_enabled', v),
                              ),
                              const SettingsDivider(),
                              CheckboxSetting(
                                label: l10n.adhanFlipToSilenceLabel,
                                sublabel: l10n.adhanFlipToSilenceSublabel,
                                value: prefs.flipToSilenceEnabled,
                                onChanged: (v) {
                                  ref
                                      .read(userPreferencesProvider.notifier)
                                      .updatePref('flip_to_silence_enabled', v);
                                  // `updateSettings()` already had a
                                  // `flipToSilenceEnabled` parameter — this
                                  // toggle just never called it, so the
                                  // background isolate kept using whatever
                                  // value it loaded on its last start (R6).
                                  OverlayBackgroundService.updateSettings(
                                    flipToSilenceEnabled: v,
                                  );
                                },
                              ),
                              const SettingsDivider(),
                              CheckboxSetting(
                                label: l10n.adhanAlarmNotifLabel,
                                sublabel: l10n.adhanAlarmNotifSublabel,
                                value: prefs.adhanAlarmEnabled,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('adhan_alarm_enabled', v),
                              ),
                              const SettingsDivider(),
                              CheckboxSetting(
                                label: l10n.adhanOngoingNotifLabel,
                                sublabel: l10n.adhanOngoingNotifSublabel,
                                value: prefs.ongoingNotifEnabled,
                                onChanged: (v) => ref
                                    .read(userPreferencesProvider.notifier)
                                    .updatePref('ongoing_notif_enabled', v),
                              ),
                            ],
                          ),
                        ],
                      );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
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

class AdhanSoundPreviewButton extends ConsumerWidget {
  final String soundPath;
  const AdhanSoundPreviewButton({super.key, required this.soundPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(adhanPreviewPlayerProvider);
    final playingPath = ref.watch(currentlyPlayingAdhanProvider);
    final isPlaying = playingPath == soundPath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: IconButton(
        onPressed: () async {
          if (isPlaying) {
            await player.stop();
            ref.read(currentlyPlayingAdhanProvider.notifier).state = null;
          } else {
            await player.stop();
            try {
              await player.setAsset('assets/sounds/$soundPath');
              ref.read(currentlyPlayingAdhanProvider.notifier).state =
                  soundPath;
              await player.play();
              // Reset when finished
              player.processingStateStream.listen((state) {
                if (state == ProcessingState.completed) {
                  if (ref.read(currentlyPlayingAdhanProvider) == soundPath) {
                    ref.read(currentlyPlayingAdhanProvider.notifier).state =
                        null;
                  }
                }
              });
            } catch (e) {
              debugPrint('Error playing adhan preview: $e');
            }
          }
        },
        icon: Icon(
          isPlaying
              ? Icons.stop_circle_rounded
              : Icons.play_circle_fill_rounded,
          color: context.colors.gold,
          size: 32,
        ),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  PER-PRAYER MINUTE OFFSET ROW
// ─────────────────────────────────────────
/// A single "− N min +" stepper row for one prayer's manual calculation
/// offset (`fajr_offset`, `dhuhr_offset`, …). Kept as a plain +/- stepper
/// rather than a [SliderSetting] since a slider that never shows its
/// current value would just reproduce the "can't tell what it's set to"
/// problem this whole section exists to fix (docs/specs/settings-
/// notifications-improvements.md R7) — a ±1 min-at-a-time stepper needs
/// its value visible to be usable at all.
class _PrayerOffsetRow extends StatelessWidget {
  final String icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  static const int _min = -30;
  static const int _max = 30;

  const _PrayerOffsetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signed = value > 0 ? '+$value' : '$value';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: context.typography.bodyMedium.copyWith(
                fontSize: 15,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          _OffsetStepButton(
            icon: Icons.remove_rounded,
            onTap: value > _min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              l10n.settingsOffsetMinutesShort(signed),
              textAlign: TextAlign.center,
              style: context.typography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: value == 0
                    ? context.colors.textSecondary
                    : context.colors.gold,
              ),
            ),
          ),
          _OffsetStepButton(
            icon: Icons.add_rounded,
            onTap: value < _max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _OffsetStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OffsetStepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return TakwaTappable(
      onTap: onTap,
      minTapSize: null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.card.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? context.colors.textPrimary
              : context.colors.textSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  NOTIFICATION / EXACT-ALARM PERMISSION WARNING
// ─────────────────────────────────────────
/// Same visual pattern as overlay_settings_tile.dart's
/// `_OverlayPermissionWarning` (kept as a separate private widget since
/// that one isn't exported) — a tinted warning card + a "grant
/// permission" action, shown whenever `NotificationsManager.scheduleAll()`
/// would otherwise silently do nothing.
class _NotificationPermissionWarning extends StatelessWidget {
  final Future<void> Function() onGrant;

  const _NotificationPermissionWarning({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️',
                style: TextStyle(fontSize: 16, color: context.colors.warningText),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.notifPermissionWarningTitle,
                  style: context.typography.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.notifPermissionWarningBody,
            style: context.typography.caption.copyWith(
              fontSize: 12,
              color: context.colors.warningText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TakwaTappable(
              onTap: onGrant,
              minTapSize: null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.colors.warning),
                ),
                child: Text(
                  l10n.overlayPermissionGrantButton,
                  style: context.typography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.colors.warningText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
