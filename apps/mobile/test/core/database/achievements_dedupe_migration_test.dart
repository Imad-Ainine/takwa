// Upgrade-path test for schema v13 (achievements de-duplication).
//
// The v13 step is the one that can silently corrupt data: it DELETEs rows
// before building the unique index on achievements.type, so it has to keep
// the *earliest* row per type (the original earn timestamp and its `seen`
// flag) and it must not fail on a database that already holds duplicates.
// Building fresh at v13 can't show any of that — hence a v12-shaped file is
// written by hand first, then reopened through the real migration.

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/database/app_database.dart';

/// The pre-13 `achievements` table exactly as drift generated it: same
/// columns, no unique index on `type`.
const _v12AchievementsDdl = '''
CREATE TABLE achievements (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  title_ar TEXT NOT NULL,
  desc_ar TEXT NOT NULL,
  emoji TEXT NOT NULL,
  points_reward INTEGER NOT NULL DEFAULT 0,
  earned_at INTEGER NOT NULL,
  seen INTEGER NOT NULL DEFAULT 0
)
''';

/// A database pinned at schemaVersion 12 whose migration strategy creates
/// nothing, so the test can hand-write the old schema into the file.
class _V12Database extends AppDatabase {
  _V12Database(super.executor) : super.forTesting();

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {});
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('takwa_migration_v13');
    dbFile = File('${tempDir.path}${Platform.pathSeparator}takwa.db');
  });

  tearDown(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Already gone, or the runner cleaned it up.
    }
  });

  /// Writes a v12 database holding [rows] — `(id, type, title, seen)` — and
  /// leaves the file closed and ready to be upgraded. `earned_at` grows with
  /// the id, so the earliest row of a type is also its first grant.
  Future<void> writeV12Database(List<(int, String, String, int)> rows) async {
    final v12 = _V12Database(NativeDatabase(dbFile));
    try {
      await v12.customStatement(_v12AchievementsDdl);
      for (final (id, type, title, seen) in rows) {
        await v12.customStatement(
          'INSERT INTO achievements (id, type, title_ar, desc_ar, emoji, '
          'points_reward, earned_at, seen) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [id, type, title, 'desc $type', '🏅', 50, id * 86400000, seen],
        );
      }
      // Reads the version back so a drift bookkeeping change shows up here
      // rather than as a migration that quietly never runs.
      final version = await v12.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], 12);
    } finally {
      await v12.close();
    }
  }

  /// Reopens the file through the real AppDatabase, which runs the
  /// v12 → v13 upgrade on first query.
  Future<AppDatabase> openUpgraded() async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();
    return db;
  }

  Future<List<Achievement>> allAchievements(AppDatabase db) => (db.select(
    db.achievements,
  )..where((a) => a.type.equals('streak_7'))).get();

  test('v12 → v13 keeps the earliest row per achievement type', () async {
    await writeV12Database([
      (1, 'streak_7', 'original', 1), // earliest, already seen by the user
      (2, 'streak_7', 'duplicate', 0), // from a racing sweep
      (3, 'streak_7', 'duplicate', 0), // and another
      (4, 'quran_juz', 'sole', 0), // untouched: the only row of its type
    ]);

    final db = await openUpgraded();

    final streak7 = await allAchievements(db);
    expect(streak7.map((a) => a.id), [1], reason: 'MIN(id) is the winner');
    expect(streak7.single.seen, isTrue, reason: 'the original row survives');
    expect(streak7.single.titleAr, 'original');

    final others = await (db.select(
      db.achievements,
    )..where((a) => a.type.equals('quran_juz'))).get();
    expect(others.single.id, 4);
    expect(await db.select(db.achievements).get(), hasLength(2));
  });

  test(
    'v12 → v13 builds the unique index and a clean database passes',
    () async {
      await writeV12Database([
        (1, 'streak_7', 'first', 0),
        (2, 'quran_juz', 'sole', 0),
      ]);

      final db = await openUpgraded();

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
      // The index exists and actually bites — asserted by outcome, since the
      // native driver reports a constraint violation as its own SqliteException
      // class, which isn't a declared dependency here.
      Object? rejected;
      try {
        await db
            .into(db.achievements)
            .insert(
              AchievementsCompanion(
                type: const Value('streak_7'),
                titleAr: const Value('again'),
                descAr: const Value('again'),
                emoji: const Value('🔥'),
                earnedAt: Value(DateTime.now()),
              ),
            );
      } catch (e) {
        rejected = e;
      }
      expect(rejected, isNotNull);
      expect(await allAchievements(db), hasLength(1));
    },
  );

  test('v12 → v13 on an empty achievements table is a no-op', () async {
    await writeV12Database([]);

    final db = await openUpgraded();

    expect(await db.customSelect('SELECT * FROM achievements').get(), isEmpty);
    // Still usable: the grant path works against an upgraded, empty database.
    await db.statsDao.addAchievement(
      type: 'streak_7',
      titleAr: 'x',
      descAr: 'y',
      emoji: '🏅',
    );
    expect(await allAchievements(db), hasLength(1));
  });
}
