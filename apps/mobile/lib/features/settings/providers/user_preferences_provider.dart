import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/daos.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/supabase/sync_manager.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/notifications/overlay_background_service.dart';
import '../data/settings_prefs_bridge.dart';
import '../data/user_preferences.dart';

enum NotificationCategory { prayer, adhkar, reminders, all, none }

/// Settings that feed [PrayerTimesService.calculate] — when one of these
/// changes, the background isolate must recompute its prayer lists too, or
/// its ongoing notification disagrees with the screen until midnight.
const _kPrayerCalcKeys = {
  'madhab',
  'calc_method',
  'high_latitude_rule',
  'fajr_offset',
  'sunrise_offset',
  'dhuhr_offset',
  'asr_offset',
  'maghrib_offset',
  'isha_offset',
};

final userPreferencesProvider =
    AsyncNotifierProvider<UserPreferencesNotifier, UserPreferences>(() {
      return UserPreferencesNotifier();
    });

class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  late SettingsDao _dao;
  late SettingsPrefsBridge _prefsBridge;

  @override
  Future<UserPreferences> build() async {
    _dao = ref.watch(settingsDaoProvider);
    _prefsBridge = SettingsPrefsBridge(ref.watch(sharedPreferencesProvider));

    // Read all raw local settings
    final allSettings = await _dao.getAllSettings();
    final prefs = UserPreferences.fromMap(allSettings);

    // Re-seed the background isolate's mirror from the canonical store on
    // every build. updatePref/updateMultiplePrefs only mirror keys the user
    // actively changes, so DB-seeded defaults and Supabase-pulled values
    // (upsertFromRemote writes straight to the DAO) would otherwise never
    // reach SharedPreferences — leaving OverlayBackgroundService computing
    // prayer times with its own fallbacks while the screen used these.
    await _prefsBridge.mirrorAll(prefs.toMap());

    return prefs;
  }

  /// Update a single preference. It updates the local database immediately,
  /// triggers a sync to Supabase in the background, and updates the reactive state.
  Future<void> updatePref(
    String key,
    dynamic value, {
    NotificationCategory category = NotificationCategory.all,
    bool haptic = true,
  }) async {
    if (haptic) unawaited(HapticFeedback.lightImpact());

    // 1. Save directly to local SQLite
    await _dao.set(key, value.toString());

    // 2. Trigger syncManager to push the change
    unawaited(_syncSettingsSafely());

    // 3. Immediately re-build state from local defaults
    final allSettings = await _dao.getAllSettings();
    state = AsyncData(UserPreferences.fromMap(allSettings));

    // 4. Trigger granular notification rescheduling
    if (category != NotificationCategory.none) {
      unawaited(ref.read(notificationsManagerProvider).reschedule(category));
    }

    // 5. Sync to SharedPreferences for background isolates
    await _prefsBridge.mirror(key, value);

    // 6. Let the foreground-service isolate recompute its times with the
    // newly mirrored setting — its notification must follow the screen
    // within the same second, not on the next midnight refresh.
    if (_kPrayerCalcKeys.contains(key)) {
      OverlayBackgroundService.requestPrayerTimesRefresh();
    }
  }

  /// Helper method for modifying multiple preferences at once
  Future<void> updateMultiplePrefs(
    Map<String, dynamic> updates, {
    NotificationCategory category = NotificationCategory.all,
    bool haptic = true,
  }) async {
    if (haptic) unawaited(HapticFeedback.mediumImpact());

    for (final entry in updates.entries) {
      await _dao.set(entry.key, entry.value.toString());
    }
    unawaited(_syncSettingsSafely());
    final allSettings = await _dao.getAllSettings();
    state = AsyncData(UserPreferences.fromMap(allSettings));

    // Trigger granular notification rescheduling
    if (category != NotificationCategory.none) {
      unawaited(ref.read(notificationsManagerProvider).reschedule(category));
    }

    // Sync all to SharedPreferences
    for (final entry in updates.entries) {
      await _prefsBridge.mirror(entry.key, entry.value);
    }

    if (updates.keys.any(_kPrayerCalcKeys.contains)) {
      OverlayBackgroundService.requestPrayerTimesRefresh();
    }
  }

  /// Pushes local settings to Supabase, recording a failure instead of
  /// letting it disappear as an unhandled error on this `unawaited()` call.
  ///
  /// This push sends the *entire* local settings map in one upsert (see
  /// SyncManager.syncSettings), so one column the remote table doesn't
  /// have breaks the push for every setting, silently — and the very next
  /// full sync's pull would then overwrite local with the stale remote
  /// row, making an edit look like it "didn't save". Surfacing the error
  /// here (via the same lastSyncErrorProvider the settings screen already
  /// watches) at least makes that failure visible instead of invisible.
  Future<void> _syncSettingsSafely() async {
    try {
      await ref.read(syncManagerProvider).syncSettings();
    } catch (e, st) {
      developer.log(
        'Failed to sync settings: $e',
        name: 'UserPreferencesNotifier',
        stackTrace: st,
      );
      ref.read(lastSyncErrorProvider.notifier).state = 'settings: $e';
    }
  }
}
