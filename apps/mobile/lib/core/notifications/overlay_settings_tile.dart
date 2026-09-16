import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/widgets/takwa_error_state.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/l10n/app_localizations.dart';

import '../theme/app_theme.dart';
import '../../features/settings/providers/user_preferences_provider.dart';
import '../../features/settings/presentation/widgets/settings_widgets.dart';

/// Whether the OS "display over other apps" permission is currently
/// granted. Both the Adhan screen and the adhkar/dua popups depend on it
/// to fire while the app is backgrounded or killed — see
/// docs/specs/adhan-overlay-auto-open.md. Re-read via
/// `ref.invalidate(overlayPermissionGrantedProvider)` after a permission
/// request completes.
final overlayPermissionGrantedProvider = FutureProvider<bool>((ref) {
  return OverlayBackgroundService.isOverlayPermissionGranted();
});

// ─────────────────────────────────────────
//  OVERLAY SETTINGS SECTION
// ─────────────────────────────────────────
class OverlayNotificationSettings extends ConsumerWidget {
  const OverlayNotificationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final l10n = AppLocalizations.of(context)!;

    return prefsAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: TakwaLoadingIndicator()),
      ),
      error: (_, __) => TakwaErrorState(
        compact: true,
        onRetry: () => ref.invalidate(userPreferencesProvider),
      ),
      data: (prefs) {
        // Make sure enabling either toggle below actually asks for the
        // permission it silently depends on, instead of leaving the
        // toggle "on" with no effect once the app is closed.
        Future<void> ensureOverlayPermission() async {
          OverlayBackgroundService.start();
          await OverlayBackgroundService.requestPermissions();
          ref.invalidate(overlayPermissionGrantedProvider);
        }

        final permissionGranted = ref
            .watch(overlayPermissionGrantedProvider)
            .valueOrNull;
        final needsPermission =
            (prefs.adhanScreenEnabled || prefs.overlayEnabled) &&
            permissionGranted == false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renamed from a near-duplicate of the "🔔 Adhan & Notification
            // Settings" section title just above it in settings_screen.dart
            // — the two used to be almost indistinguishable ("Adhan &
            // Notification Settings" vs "Adhkar & Notifications"), so a
            // user looking for "does the adhan screen open automatically"
            // had no real signal for which section to check. This section
            // is specifically the things that appear *on top of* other
            // apps (the adhan screen + the adhkar/dua popups), hence 🪟 and
            // a name that says so. See docs/specs/settings-notifications-
            // improvements.md R2.
            SectionHeader(title: l10n.overlaySettingsSectionTitle, icon: '🪟'),
            SettingsCard(
              children: [
                // ── شاشة الأذان التلقائية ──
                ToggleSetting(
                  icon: '🕌',
                  label: l10n.overlaySettingAdhanScreenLabel,
                  sublabel: l10n.overlaySettingAdhanScreenSublabel,
                  value: prefs.adhanScreenEnabled,
                  onChanged: (v) {
                    ref
                        .read(userPreferencesProvider.notifier)
                        .updatePref('adhan_screen_enabled', v);
                    // Push the new value to the background foreground-task
                    // isolate right away — it only reads SharedPreferences
                    // on its own start, so without this, turning the Adhan
                    // screen off wouldn't stop the killed-app system overlay
                    // from still appearing until the service next restarts.
                    OverlayBackgroundService.updateSettings(
                      adhanScreenEnabled: v,
                    );
                    if (v) ensureOverlayPermission();
                  },
                ),
                const SettingsDivider(),

                // NOTE: the old standalone "صوت الأذان" (adhan sound)
                // toggle used to live here, separately from the "نمط
                // الأذان" (sound/vibrate/silent) selector on the Adhan
                // settings screen — the two could disagree, which was a
                // real bug (see docs/specs/settings-notifications-
                // improvements.md R1). Removed; `adhanMode` is now the
                // single control for whether the adhan makes sound.

                // ── نوافذ الأذكار المنبثقة ──
                ToggleSetting(
                  icon: '📿',
                  label: l10n.overlaySettingPopupsLabel,
                  sublabel: l10n.overlaySettingPopupsSublabel,
                  value: prefs.overlayEnabled,
                  onChanged: (v) {
                    ref
                        .read(userPreferencesProvider.notifier)
                        .updatePref('overlay_popups_enabled', v);
                    OverlayBackgroundService.updateSettings(overlayEnabled: v);
                    if (v) ensureOverlayPermission();
                  },
                ),
                if (needsPermission) ...[
                  const SettingsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: AppSpacing.sm,
                    ),
                    child: _OverlayPermissionWarning(
                      onGrant: ensureOverlayPermission,
                    ),
                  ),
                ],
                if (prefs.overlayEnabled) ...[
                  const SettingsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        _IntervalSelector(
                          value: prefs.popupIntervalMins,
                          onChanged: (v) {
                            ref
                                .read(userPreferencesProvider.notifier)
                                .updatePref('popup_interval_minutes', v);
                            OverlayBackgroundService.updateSettings(
                              popupIntervalMins: v,
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // إحصاء: عدد المرات في اليوم
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: context.colors.teal.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '📊',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: context.colors.teal,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.overlaySettingDailyCount(
                                    (1440 / prefs.popupIntervalMins).floor(),
                                  ),
                                  style: context.typography.caption.copyWith(
                                    color: context.colors.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────
//  OVERLAY PERMISSION WARNING BANNER
// ─────────────────────────────────────────
class _OverlayPermissionWarning extends StatelessWidget {
  final Future<void> Function() onGrant;

  const _OverlayPermissionWarning({required this.onGrant});

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
              Text('⚠️', style: TextStyle(fontSize: 16, color: context.colors.warningText)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.overlayPermissionWarningTitle,
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
            l10n.overlayPermissionWarningBody,
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

// ─────────────────────────────────────────
//  SHARED CHILD WIDGETS
// ─────────────────────────────────────────

class _IntervalSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _IntervalSelector({required this.value, required this.onChanged});

  List<({String label, int mins})> _options(AppLocalizations l10n) => [
    (label: l10n.overlaySettingInterval15Min, mins: 15),
    (label: l10n.overlaySettingInterval20Min, mins: 20),
    (label: l10n.overlaySettingInterval24Min, mins: 24),
    (label: l10n.overlaySettingInterval30Min, mins: 30),
    (label: l10n.overlaySettingInterval1Hour, mins: 60),
    (label: l10n.overlaySettingInterval2Hours, mins: 120),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _options(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.overlaySettingIntervalHeader,
              style: context.typography.bodyMedium.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = opt.mins == value;
            return TakwaTappable(
              onTap: () => onChanged(opt.mins),
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
                  opt.label,
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
