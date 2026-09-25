// Locks in when the dua reminder fires and what it says, plus the id blocks
// the adhkar reminders schedule under.
//
// The bug this replaces: `scheduleDailyDuas` posted three alarms at hardcoded
// 09:00, 12:00 and 21:00 no matter which time the user chose, and nothing
// cancelled them when the setting was switched off — so a "switched off" daily
// dua kept arriving, three times a day, at times nobody picked.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/features/settings/data/user_preferences.dart';
import 'package:takwa/features/duas/data/duas_data.dart';

void main() {
  group('daily dua follows the hour it is scheduled for', () {
    test('each part of the day draws from its own category', () {
      expect(
        NotificationsService.duaCategoriesForHour(6),
        contains(DuaCategory.morning),
      );
      expect(
        NotificationsService.duaCategoriesForHour(13),
        contains(DuaCategory.forgiveness),
      );
      expect(
        NotificationsService.duaCategoriesForHour(18),
        contains(DuaCategory.evening),
      );
      expect(
        NotificationsService.duaCategoriesForHour(22),
        contains(DuaCategory.sleep),
      );
      expect(
        NotificationsService.duaCategoriesForHour(1),
        contains(DuaCategory.general),
      );
    });

    test(
      'every hour resolves to a dua from the categories that hour names',
      () {
        final date = DateTime(2026, 9, 25);
        for (var hour = 0; hour < 24; hour++) {
          final dua = NotificationsService.duaForHour(hour, date);
          expect(dua, isNotNull, reason: 'hour $hour has no dua to show');
          expect(
            NotificationsService.duaCategoriesForHour(hour),
            contains(dua!.category),
            reason: 'hour $hour showed a ${dua.category.name} dua',
          );
        }
      },
    );

    test('the same day always yields the same dua, so re-scheduling cannot '
        'change the text under an alarm that is already queued', () {
      final date = DateTime(2026, 9, 25);
      expect(
        NotificationsService.duaForHour(7, date)?.id,
        NotificationsService.duaForHour(7, DateTime(2026, 9, 25, 18))?.id,
      );
    });
  });

  group('reminder ids', () {
    test('the anchored adhkar horizon never collides with itself or the '
        'repeating reminders', () {
      final ids = {
        for (var day = 0; day < kPrayerScheduleDays; day++)
          NotifIds.afterFajrAdhkarId(day),
        for (var day = 0; day < kPrayerScheduleDays; day++)
          NotifIds.afterAsrAdhkarId(day),
        NotifIds.adhkarMorning,
        NotifIds.adhkarEvening,
        NotifIds.adhkarSleep,
        NotifIds.dailyDua,
      };
      expect(ids, hasLength(kPrayerScheduleDays * 2 + 4));
    });

    test('anchored ids stay above the prayer alert blocks', () {
      expect(NotifIds.afterFajrAdhkarId(0), greaterThan(3099));
    });
  });

  group('the new reminder settings survive a sync round-trip', () {
    test('toMap writes snake_case keys and fromMap reads them back', () {
      const prefs = UserPreferences(
        sleepAdhkarReminder: false,
        adhkarAfterPrayerMinutes: 20,
        duaReminderTime: TimeOfDay(hour: 13, minute: 30),
      );
      final map = prefs.toMap();
      expect(map['sleep_adhkar_reminder'], false);
      expect(map['adhkar_after_prayer_minutes'], 20);
      expect(map['dua_reminder_time'], '13:30');

      final back = UserPreferences.fromMap(map);
      expect(back.sleepAdhkarReminder, false);
      expect(back.adhkarAfterPrayerMinutes, 20);
      expect(back.duaReminderTime, const TimeOfDay(hour: 13, minute: 30));
    });

    test('a remote row written before these columns existed falls back to the '
        'defaults instead of throwing', () {
      final back = UserPreferences.fromMap(const {'language': 'ar'});
      expect(back.sleepAdhkarReminder, true);
      expect(back.adhkarAfterPrayerMinutes, 15);
      expect(back.duaReminderTime, const TimeOfDay(hour: 12, minute: 0));
    });

    test(
      'no toMap key is camelCase — every one must exist as a Supabase column',
      () {
        const prefs = UserPreferences();
        for (final key in prefs.toMap().keys) {
          expect(
            key.contains(RegExp('[A-Z]')),
            isFalse,
            reason: '"$key" would break the whole settings upsert',
          );
        }
      },
    );

    // `SyncManager.syncSettings()` pushes the entire toMap() in one upsert, so
    // one key with no `user_settings` column fails the push for *every*
    // setting — silently, because the push is fire-and-forget — and the next
    // pull then overwrites local with the stale remote row. This happened with
    // the prayer offsets and again with the adhkar reminder keys.
    //
    // The column list is reconstructed offline from the two places the schema
    // is written down: the migrations, and the signup defaults that upsert
    // `user_settings` directly (`user_settings` itself predates the migration
    // folder, so it has no CREATE TABLE to read).
    test('every settings key the app pushes exists as a database column', () {
      final migrations = Directory('supabase/migrations');
      expect(
        migrations.existsSync(),
        isTrue,
        reason: 'run this from apps/mobile',
      );
      final schema = [
        for (final f in migrations.listSync().whereType<File>())
          if (f.path.endsWith('.sql')) f.readAsStringSync(),
        File('lib/core/supabase/supabase_service.dart').readAsStringSync(),
      ].join('\n');

      const prefs = UserPreferences();
      for (final key in prefs.toMap().keys) {
        expect(
          RegExp('\\b$key\\b').hasMatch(schema),
          isTrue,
          reason:
              '"$key" is pushed by toMap() but no migration adds it to '
              'user_settings — one missing column breaks every settings push',
        );
      }
    });
  });
}
