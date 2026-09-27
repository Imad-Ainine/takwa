// Regression test for the launch-blocking crash seen on a real device:
//
//   SqliteException(1): duplicate column name: gold_value
//   Causing statement: ALTER TABLE "zakat_calculations" ADD COLUMN
//     "gold_value" REAL NOT NULL DEFAULT 0.0
//
// drift only writes `user_version` once `onUpgrade` returns, so a migration
// that dies midway leaves its DDL applied while the stored version stays
// behind. The next launch replays those same steps against a schema that has
// already moved on, `ALTER TABLE … ADD COLUMN` throws again, and the database
// can never open — which surfaced as a gray screen after the splash, because
// the app root read the failed provider with `.value`.
//
// This file rebuilds that half-migrated state (current schema, old version)
// and asserts the upgrade path is now re-runnable.

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/database/app_database.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('takwa_migration_replay');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}takwa.db');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Already gone, or the runner cleaned it up.
    }
  });

  Future<int> readUserVersion(AppDatabase db) async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();
    return (row.data['user_version'] as num).toInt();
  }

  /// Builds a fully-migrated v13 database, then rewinds only `user_version`
  /// to [version] — the exact shape a half-applied migration leaves behind.
  Future<void> writeHalfMigratedDatabase(int version) async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    try {
      await db.customSelect('SELECT 1').get();
      expect(await readUserVersion(db), 13);

      await db
          .into(db.zakatCalculations)
          .insert(
            const ZakatCalculationsCompanion(
              cashAmount: Value(10000),
              goldValue: Value(4200),
              silverValue: Value(900),
            ),
          );
      await db.statsDao.addAchievement(
        type: 'streak_7',
        titleAr: 'سبعة أيام',
        descAr: 'محافظة',
        emoji: '🔥',
      );

      await db.customStatement('PRAGMA user_version = $version');
      expect(await readUserVersion(db), version);
    } finally {
      await db.close();
    }
  }

  Future<AppDatabase> reopen() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);
    // The migration runs as part of opening, so this call is the assertion.
    await db.customSelect('SELECT 1').get();
    return db;
  }

  test(
    'replaying v11 → v13 over an already-migrated schema succeeds',
    () async {
      await writeHalfMigratedDatabase(11);

      final db = await reopen();

      expect(await readUserVersion(db), 13);

      final row = await (db.select(db.zakatCalculations)..limit(1)).getSingle();
      expect(row.goldValue, 4200, reason: 'the direct-value data is intact');
      expect(row.silverValue, 900);

      expect(await db.select(db.achievements).get(), hasLength(1));
    },
  );

  test('replaying from every historical version is safe', () async {
    for (final version in [2, 5, 9, 10, 11, 12]) {
      await writeHalfMigratedDatabase(version);
      final db = await reopen();
      expect(
        await readUserVersion(db),
        13,
        reason: 'v$version → v13 replay should complete',
      );
      await db.close();
    }
  });

  test('the unique achievement index survives a replay', () async {
    await writeHalfMigratedDatabase(11);
    final db = await reopen();

    final indexes = await db
        .customSelect(
          'SELECT name FROM sqlite_master WHERE type = ? AND tbl_name = ?',
          variables: [
            Variable.withString('index'),
            Variable.withString('achievements'),
          ],
        )
        .get();
    expect(
      indexes.map((r) => r.data['name']),
      contains('idx_achievements_type_unique'),
    );

    Object? rejected;
    try {
      await db
          .into(db.achievements)
          .insert(
            AchievementsCompanion(
              type: const Value('streak_7'),
              titleAr: const Value('مكرر'),
              descAr: const Value('مكرر'),
              emoji: const Value('🔥'),
              earnedAt: Value(DateTime.now()),
            ),
          );
    } catch (e) {
      rejected = e;
    }
    expect(rejected, isNotNull, reason: 'the index still de-duplicates');
  });
}
