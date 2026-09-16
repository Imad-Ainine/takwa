// An in-memory implementation of SupabaseService for tests, standing in
// for a real Supabase backend. Behavior (upsert-by-key semantics, filters)
// mirrors what SupabaseClientService actually does against Postgres, just
// backed by Dart collections instead of network calls.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takwa/core/supabase/supabase_service.dart';

class FakeSupabaseService implements SupabaseService {
  // Keyed storage, mirroring each table's real unique constraint.
  final Map<String, Map<String, dynamic>> dailyRecordsByDate = {};
  final List<Map<String, dynamic>> prohibitionLogs = [];
  final Map<int, Map<String, dynamic>> customIbadah = {};
  final List<Map<String, dynamic>> customIbadahLogs = [];
  final Map<String, Map<String, dynamic>> achievementsByType = {};
  Map<String, dynamic>? settings;
  Map<String, dynamic>? userStats;
  final Map<int, Map<String, dynamic>> remindersByLocalId = {};
  final Map<String, Map<String, dynamic>> userAdhkarById = {};
  final Map<String, Map<String, dynamic>> userDuasById = {};
  final List<Map<String, dynamic>> communityAdhkar = [];
  final List<Map<String, dynamic>> communityDuas = [];
  final List<Map<String, dynamic>> books = [];
  final Map<String, Map<String, dynamic>> bookProgressByBookId = {};
  final Map<String, Map<String, dynamic>> pdfSessionsByBookId = {};
  // Keyed by "surahNum:ayahNum", mirroring the real table's unique constraint.
  final Map<String, Map<String, dynamic>> quranBookmarksByKey = {};
  Map<String, dynamic>? quranLastRead;
  final Map<String, Map<String, dynamic>> khatmaSessionsById = {};

  /// Calls made, in order — lets a test assert what was pushed without
  /// caring about internal storage shape (e.g. "was upsertDailyRecord
  /// called for 2026-01-01 with fajr_status performed?").
  final List<String> callLog = [];

  static String _dateStr(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // ─────────────── AUTH (not exercised by fullSync; no-ops) ───────────────
  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) => throw UnimplementedError('not used by these tests');

  @override
  Future<AuthResponse> signIn({required String email, required String password}) =>
      throw UnimplementedError('not used by these tests');

  @override
  Future<AuthResponse?> signInWithGoogle() =>
      throw UnimplementedError('not used by these tests');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    callLog.add('updateProfile');
  }

  // ─────────────── DATA ───────────────
  @override
  Future<void> upsertDailyRecord(Map<String, dynamic> record) async {
    callLog.add('upsertDailyRecord:${record['date']}');
    dailyRecordsByDate[record['date'] as String] = Map.of(record);
  }

  @override
  Future<List<Map<String, dynamic>>> getRecordsRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = _dateStr(from);
    final toStr = _dateStr(to);
    return dailyRecordsByDate.entries
        .where((e) => e.key.compareTo(fromStr) >= 0 && e.key.compareTo(toStr) <= 0)
        .map((e) => e.value)
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getSettings() async => settings;

  @override
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    callLog.add('updateSettings');
    settings = {...?settings, ...newSettings};
  }

  @override
  Future<void> updateUserStats({
    required int totalPoints,
    required int currentStreak,
    required int longestStreak,
    required int quranPages,
  }) async {
    callLog.add('updateUserStats');
    userStats = {
      'total_points': totalPoints,
      'current_streak': currentStreak,
      'highest_streak': longestStreak,
      'quran_pages': quranPages,
    };
  }

  // ─────────────── PROHIBITIONS ───────────────
  @override
  Future<void> upsertProhibitionLog(Map<String, dynamic> log) async {
    callLog.add('upsertProhibitionLog');
    prohibitionLogs.removeWhere(
      (l) => l['record_id'] == log['record_id'] && l['category'] == log['category'],
    );
    prohibitionLogs.add(Map.of(log));
  }

  @override
  Future<List<Map<String, dynamic>>> getProhibitionLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = _dateStr(from);
    final toStr = _dateStr(to);
    return prohibitionLogs
        .where(
          (l) =>
              (l['date'] as String).compareTo(fromStr) >= 0 &&
              (l['date'] as String).compareTo(toStr) <= 0,
        )
        .toList();
  }

  // ─────────────── CUSTOM IBADAH ───────────────
  @override
  Future<void> upsertCustomIbadah(Map<String, dynamic> ibadah) async {
    callLog.add('upsertCustomIbadah:${ibadah['id']}');
    customIbadah[ibadah['id'] as int] = Map.of(ibadah);
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomIbadah() async =>
      customIbadah.values.toList();

  @override
  Future<void> upsertCustomIbadahLog(Map<String, dynamic> log) async {
    callLog.add('upsertCustomIbadahLog');
    customIbadahLogs.removeWhere(
      (l) => l['ibadah_id'] == log['ibadah_id'] && l['date'] == log['date'],
    );
    customIbadahLogs.add(Map.of(log));
  }

  @override
  Future<void> deleteCustomIbadah(int id) async {
    callLog.add('deleteCustomIbadah:$id');
    customIbadah.remove(id);
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomIbadahLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = _dateStr(from);
    final toStr = _dateStr(to);
    return customIbadahLogs
        .where(
          (l) =>
              (l['date'] as String).compareTo(fromStr) >= 0 &&
              (l['date'] as String).compareTo(toStr) <= 0,
        )
        .toList();
  }

  // ─────────────── ACHIEVEMENTS ───────────────
  @override
  Future<void> upsertAchievement(Map<String, dynamic> achievement) async {
    callLog.add('upsertAchievement:${achievement['type']}');
    achievementsByType[achievement['type'] as String] = Map.of(achievement);
  }

  @override
  Future<List<Map<String, dynamic>>> getEarnedAchievements() async =>
      achievementsByType.values.toList();

  // ─────────────── USER PERSONAL ADHKAR ───────────────
  @override
  Future<List<Map<String, dynamic>>> getUserAdhkar() async =>
      userAdhkarById.values.toList();

  @override
  Future<void> addUserAdhkar({
    String? id,
    required String textAr,
    int count = 1,
    String categoryHint = 'general',
  }) async {
    final key = id ?? 'generated-${userAdhkarById.length}';
    userAdhkarById[key] = {
      'id': key,
      'text_ar': textAr,
      'count': count,
      'category_hint': categoryHint,
    };
  }

  @override
  Future<void> deleteUserAdhkar(String id) async {
    userAdhkarById.remove(id);
  }

  // ─────────────── USER PERSONAL DUAS ───────────────
  @override
  Future<List<Map<String, dynamic>>> getUserDuas() async =>
      userDuasById.values.toList();

  @override
  Future<void> addUserDua({
    String? id,
    required String titleAr,
    required String textAr,
    String occasion = '',
    String source = '',
    String emoji = '🤲',
  }) async {
    final key = id ?? 'generated-${userDuasById.length}';
    userDuasById[key] = {
      'id': key,
      'title_ar': titleAr,
      'text_ar': textAr,
      'occasion': occasion,
      'source': source,
      'emoji': emoji,
    };
  }

  @override
  Future<void> deleteUserDua(String id) async {
    userDuasById.remove(id);
  }

  // ─────────────── COMMUNITY ADHKAR / DUAS ───────────────
  @override
  Future<List<Map<String, dynamic>>> getCommunityAdhkar() async => communityAdhkar;

  @override
  Future<void> likeAdhkar(String id) async {}

  @override
  Future<void> shareAdhkarToCommunity({
    required String textAr,
    int count = 1,
    String categoryHint = 'general',
  }) async {
    communityAdhkar.add({'text_ar': textAr, 'count': count, 'likes': 0});
  }

  @override
  Future<List<Map<String, dynamic>>> getCommunityDuas() async => communityDuas;

  @override
  Future<void> likeDua(String id) async {}

  @override
  Future<void> shareDuaToCommunity({
    required String titleAr,
    required String textAr,
    String occasion = '',
    String source = '',
    String emoji = '🤲',
  }) async {
    communityDuas.add({'title_ar': titleAr, 'text_ar': textAr, 'likes': 0});
  }

  // ─────────────── BOOKS & READING PROGRESS ───────────────
  @override
  Future<List<Map<String, dynamic>>> getBooks() async => books;

  @override
  Future<void> upsertBookProgress(String bookId, Map<String, dynamic> data) async {
    bookProgressByBookId[bookId] = {...?bookProgressByBookId[bookId], ...data};
  }

  @override
  Future<List<Map<String, dynamic>>> getAllBookProgress() async =>
      bookProgressByBookId.values.toList();

  // ─────────────── PDF SESSION ───────────────
  @override
  Future<void> upsertPdfSession(
    String bookId,
    int pdfPage,
    int totalPdfPages,
    int readingSeconds,
  ) async {
    pdfSessionsByBookId[bookId] = {
      'pdf_page': pdfPage,
      'total_pdf_pages': totalPdfPages,
      'reading_seconds': readingSeconds,
    };
  }

  @override
  Future<Map<String, dynamic>?> getPdfSession(String bookId) async =>
      pdfSessionsByBookId[bookId];

  // ─────────────── REMINDERS ───────────────
  @override
  Future<void> upsertReminder(Map<String, dynamic> data) async {
    callLog.add('upsertReminder');
    remindersByLocalId[data['local_id'] as int] = Map.of(data);
  }

  @override
  Future<void> deleteReminder(int localId) async {
    callLog.add('deleteReminder:$localId');
    remindersByLocalId.remove(localId);
  }

  @override
  Future<List<Map<String, dynamic>>> getReminders() async =>
      remindersByLocalId.values.toList();

  // ─────────────── QURAN (bookmarks, last read, khatma sessions) ───────────────
  @override
  Future<void> upsertQuranBookmark(Map<String, dynamic> bookmark) async {
    callLog.add('upsertQuranBookmark');
    final key = '${bookmark['surah_num']}:${bookmark['ayah_num']}';
    quranBookmarksByKey[key] = Map.of(bookmark);
  }

  @override
  Future<void> deleteQuranBookmark(int surahNum, int ayahNum) async {
    callLog.add('deleteQuranBookmark');
    quranBookmarksByKey.remove('$surahNum:$ayahNum');
  }

  @override
  Future<List<Map<String, dynamic>>> getQuranBookmarks() async =>
      quranBookmarksByKey.values.toList();

  @override
  Future<void> upsertQuranLastRead(Map<String, dynamic> lastRead) async {
    callLog.add('upsertQuranLastRead');
    quranLastRead = Map.of(lastRead);
  }

  @override
  Future<Map<String, dynamic>?> getQuranLastRead() async => quranLastRead;

  @override
  Future<void> upsertKhatmaSession(Map<String, dynamic> session) async {
    callLog.add('upsertKhatmaSession:${session['id']}');
    khatmaSessionsById[session['id'] as String] = Map.of(session);
  }

  @override
  Future<List<Map<String, dynamic>>> getKhatmaSessions() async =>
      khatmaSessionsById.values.toList();
}
