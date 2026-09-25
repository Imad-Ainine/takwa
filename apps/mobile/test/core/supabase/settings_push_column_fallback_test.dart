// The settings push sends UserPreferences.toMap() as one upsert, so a key with
// no matching remote column used to reject the entire payload and freeze every
// other setting silently. SupabaseClientService.updateSettings now drops just
// that key; these tests pin down which errors it is allowed to read that way,
// because misclassifying one would silently stop syncing a preference instead.
//
// The last group checks the other half of the same contract: the push map and
// the remote→local pull mapping have to name the same settings, or a preference
// saves to the server and is simply never read back on a new device.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:takwa/core/supabase/supabase_service.dart';

void main() {
  const keys = ['madhab', 'sleep_adhkar_reminder', 'dua_reminder_time'];

  PostgrestException error(String? code, String message) =>
      PostgrestException(message: message, code: code);

  group('undefinedUserSettingsColumn', () {
    test('reads the PostgREST schema-cache wording', () {
      expect(
        undefinedUserSettingsColumn(
          error(
            'PGRST204',
            "Could not find the 'sleep_adhkar_reminder' column of "
                "'user_settings' in the schema cache",
          ),
          keys,
        ),
        'sleep_adhkar_reminder',
      );
    });

    test('reads the raw Postgres undefined-column wording', () {
      expect(
        undefinedUserSettingsColumn(
          error(
            '42703',
            'column "dua_reminder_time" of relation "user_settings" '
                'does not exist',
          ),
          keys,
        ),
        'dua_reminder_time',
      );
    });

    test('ignores a missing column the app never sent', () {
      expect(
        undefinedUserSettingsColumn(
          error('42703', 'column "favorite_qurans" does not exist'),
          keys,
        ),
        isNull,
      );
    });

    test('ignores every other failure mode', () {
      for (final e in [
        error('42501', 'new row violates row-level security policy'),
        error('22P02', 'invalid input syntax for type boolean: "madhab"'),
        error(null, 'Could not find the sleep_adhkar_reminder column'),
      ]) {
        expect(
          undefinedUserSettingsColumn(e, keys),
          isNull,
          reason: 'should not retry on ${e.code} ${e.message}',
        );
      }
    });
  });

  group('settings sync symmetry', () {
    test('the pushed map and the remote pull mapping name the same settings', () {
      final pushed = _pushedSettingKeys();
      final pulled = _pullMappedSettingKeys();
      expect(pushed, isNotEmpty);
      expect(
        pulled,
        pushed,
        reason:
            'a key pushed but not mapped back is saved to the server and lost '
            'on every other device; a key mapped but never pushed is dead code',
      );
    });
  });
}

/// Keys `UserPreferences.toMap()` sends in the `user_settings` upsert.
Set<String> _pushedSettingKeys() {
  final src = File(
    'lib/features/settings/data/user_preferences.dart',
  ).readAsStringSync();
  final start = src.indexOf('Map<String, dynamic> toMap()');
  final end = src.indexOf('factory UserPreferences.fromMap', start);
  expect(start, greaterThan(-1), reason: 'toMap() not found');
  expect(end, greaterThan(start), reason: 'end of toMap() not found');
  return RegExp(
    r"'([a-z_0-9]+)':",
  ).allMatches(src.substring(start, end)).map((m) => m.group(1)!).toSet();
}

/// Keys `upsertFromRemote` copies out of a remote `user_settings` row.
Set<String> _pullMappedSettingKeys() {
  final src = File('lib/core/database/daos.dart').readAsStringSync();
  final anchor = src.indexOf("'sleep_adhkar_reminder'");
  expect(anchor, greaterThan(-1), reason: 'remote settings mapping not found');
  final start = src.lastIndexOf('{', anchor);
  final end = src.indexOf('}', anchor);
  return RegExp(
    r"'([a-z_0-9]+)':\s*'[a-zA-Z_0-9]+'",
  ).allMatches(src.substring(start, end)).map((m) => m.group(1)!).toSet();
}
