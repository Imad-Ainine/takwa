import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for secure config

/// All Supabase reads/writes the app makes, as an interface.
///
/// This exists so callers (SyncManager in particular) depend on an
/// injectable abstraction instead of a hard-wired [SupabaseClient] — the
/// production implementation is [SupabaseClientService] below; tests can
/// substitute an in-memory fake instead of talking to a real backend.
abstract class SupabaseService {
  // ─────────────── AUTH ───────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse?> signInWithGoogle();

  Future<void> signOut();

  Future<void> updateProfile(Map<String, dynamic> data);

  // ─────────────── DATA ───────────────
  Future<void> upsertDailyRecord(Map<String, dynamic> record);

  Future<List<Map<String, dynamic>>> getRecordsRange({
    required DateTime from,
    required DateTime to,
  });

  Future<Map<String, dynamic>?> getSettings();

  Future<void> updateSettings(Map<String, dynamic> settings);

  Future<void> updateUserStats({
    required int totalPoints,
    required int currentStreak,
    required int longestStreak,
    required int quranPages,
  });

  // ─────────────── PROHIBITIONS ───────────────
  Future<void> upsertProhibitionLog(Map<String, dynamic> log);

  Future<List<Map<String, dynamic>>> getProhibitionLogs({
    required DateTime from,
    required DateTime to,
  });

  // ─────────────── CUSTOM IBADAH ───────────────
  Future<void> upsertCustomIbadah(Map<String, dynamic> ibadah);

  Future<List<Map<String, dynamic>>> getCustomIbadah();

  Future<void> upsertCustomIbadahLog(Map<String, dynamic> log);

  Future<void> deleteCustomIbadah(int id);

  Future<List<Map<String, dynamic>>> getCustomIbadahLogs({
    required DateTime from,
    required DateTime to,
  });

  // ─────────────── ACHIEVEMENTS ───────────────
  Future<void> upsertAchievement(Map<String, dynamic> achievement);

  Future<List<Map<String, dynamic>>> getEarnedAchievements();

  // ─────────────── USER PERSONAL ADHKAR ───────────────
  Future<List<Map<String, dynamic>>> getUserAdhkar();

  Future<void> addUserAdhkar({
    String? id,
    required String textAr,
    int count = 1,
    String categoryHint = 'general',
  });

  Future<void> deleteUserAdhkar(String id);

  // ─────────────── USER PERSONAL DUAS ───────────────
  Future<List<Map<String, dynamic>>> getUserDuas();

  Future<void> addUserDua({
    String? id,
    required String titleAr,
    required String textAr,
    String occasion = '',
    String source = '',
    String emoji = '🤲',
  });

  Future<void> deleteUserDua(String id);

  // ─────────────── COMMUNITY ADHKAR ───────────────
  Future<List<Map<String, dynamic>>> getCommunityAdhkar();

  Future<void> likeAdhkar(String id);

  Future<void> shareAdhkarToCommunity({
    required String textAr,
    int count = 1,
    String categoryHint = 'general',
  });

  // ─────────────── COMMUNITY DUAS ───────────────
  Future<List<Map<String, dynamic>>> getCommunityDuas();

  Future<void> likeDua(String id);

  Future<void> shareDuaToCommunity({
    required String titleAr,
    required String textAr,
    String occasion = '',
    String source = '',
    String emoji = '🤲',
  });

  // ─────────────── BOOKS & READING PROGRESS ───────────────
  Future<List<Map<String, dynamic>>> getBooks();

  Future<void> upsertBookProgress(String bookId, Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> getAllBookProgress();

  // ─────────────── PDF SESSION (timer + page) ───────────────
  Future<void> upsertPdfSession(
    String bookId,
    int pdfPage,
    int totalPdfPages,
    int readingSeconds,
  );

  Future<Map<String, dynamic>?> getPdfSession(String bookId);

  // ─────────────── REMINDERS ───────────────
  Future<void> upsertReminder(Map<String, dynamic> data);

  Future<void> deleteReminder(int localId);

  Future<List<Map<String, dynamic>>> getReminders();

  // ─────────────── QURAN (bookmarks, last read, khatma sessions) ───────────────
  Future<void> upsertQuranBookmark(Map<String, dynamic> bookmark);

  Future<void> deleteQuranBookmark(int surahNum, int ayahNum);

  Future<List<Map<String, dynamic>>> getQuranBookmarks();

  Future<void> upsertQuranLastRead(Map<String, dynamic> lastRead);

  Future<Map<String, dynamic>?> getQuranLastRead();

  Future<void> upsertKhatmaSession(Map<String, dynamic> session);

  Future<List<Map<String, dynamic>>> getKhatmaSessions();
}

/// Real implementation, talking to an injected [SupabaseClient].
class SupabaseClientService implements SupabaseService {
  SupabaseClientService(this._db);

  final SupabaseClient _db;

  String? get _uid => _db.auth.currentUser?.id;

  /// Helper لإجراء الطلبات مع إعادة المحاولة في حال فشل الشبكة
  Future<T> _safeRequest<T>(Future<T> Function() request) async {
    int attempts = 0;
    const maxAttempts = 3;

    while (true) {
      attempts++;
      try {
        return await request();
      } on SocketException catch (e) {
        if (attempts >= maxAttempts) rethrow;
        developer.log(
          'Supabase Request failed (SocketException), retrying $attempts/$maxAttempts: $e',
          name: 'SupabaseService',
        );
        await Future.delayed(const Duration(seconds: 1));
      } on http.ClientException catch (e) {
        if (attempts >= maxAttempts) rethrow;
        developer.log(
          'Supabase Request failed (ClientException), retrying $attempts/$maxAttempts: $e',
          name: 'SupabaseService',
        );
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        // الأخطاء الأخرى نمررها مباشرة (مثل أخطاء الـ SQL أو الصلاحيات)
        rethrow;
      }
    }
  }

  // ─────────────── AUTH ───────────────
  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'avatar_emoji': '🌙'},
    );
    if (res.user != null) {
      await _createProfile(res.user!, username);
    }
    return res;
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _db.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse?> signInWithGoogle() async {
    final webClientId = dotenv.env['SUPABASE_WEB_CLIENT_ID'];
    final iosClientId = dotenv.env['SUPABASE_IOS_CLIENT_ID'];

    if (webClientId == null || iosClientId == null) {
      throw 'Security Error: Google Client IDs are not configured in environment.';
    }

    final googleSignIn = GoogleSignIn(
      clientId: (Platform.isIOS || Platform.isMacOS) ? iosClientId : null,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found.';
    }

    final res = await _db.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // If it's a new user, internal profiles are handled by DB triggers
    // but we can ensure username is set if available
    if (res.user != null) {
      final username =
          googleUser.displayName ?? 'user_${res.user!.id.substring(0, 5)}';
      await _db.from('profiles').upsert({
        'id': res.user!.id,
        'username': username,
        'email': res.user!.email,
        'avatar_emoji': '🌙',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return res;
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _db.auth.signOut();
  }

  Future<void> _createProfile(User user, String username) async {
    await _db.from('profiles').upsert({
      'id': user.id,
      'username': username,
      'email': user.email,
      'avatar_emoji': '🌙',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Default settings
    await _db.from('user_settings').upsert({
      'user_id': user.id,
      'madhab': 'shafi',
      'calc_method': 'MWL',
      'language': 'ar',
      'prayer_reminder': true,
      'pre_adhan_notif': true,
      'iqama_notif': true,
      'wake_up_before_fajr': false,
      'wake_up_time': '04:30',
      'morning_adhkar_reminder': true,
      'evening_adhkar_reminder': true,
      'adhkar_notif_enabled': true,
      'morning_adhkar_time': '06:30',
      'evening_adhkar_time': '17:00',
      'sleep_adhkar_time': '22:00',
      'after_fajr_adhkar': true,
      'after_asr_adhkar': true,
      'muhasaba_reminder': true,
      'evening_reminder_time': '21:00',
      'daily_duas_on': true,
      'special_reminders_on': true,
      'fasting_reminders_on': true,
      'ramadan_mode': false,
      'theme_mode': 'system',
      'adhan_sound': 'Adhan-Makkah.mp3',
      'overlay_popups_enabled': true,
      'adhan_screen_enabled': true,
      'popup_interval_minutes': 24,
      'adhan_mode': 'sound',
      'ongoing_notif_enabled': true,
      'auto_silent_after_adhan': false,
      'vibrate_with_adhan': false,
      'adhan_volume_level': 1.0,
      'silent_mode_enabled': false,
      'silent_duration_mins': 20,
      'silent_vibration_enabled': true,
      'silent_mode_alert_style': 'vibrate',
      'silent_adhan_prayers': 'fajr,dhuhr,asr,maghrib,isha,jumuah',
      'silent_notif_prayers': 'fajr,sunrise,dhuhr,asr,maghrib,isha,jumuah',
      'flip_to_silence_enabled': true,
      'adhan_alarm_enabled': true,
      'wake_screen_enabled': true,
    });
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = _uid;
    if (uid == null) throw 'User not logged in';

    await _safeRequest(() => _db.from('profiles').update(data).eq('id', uid));
  }

  // ─────────────── DATA ───────────────
  @override
  Future<void> upsertDailyRecord(Map<String, dynamic> record) async {
    final uid = _uid;
    if (uid == null) return;

    await _safeRequest(
      () => _db.from('daily_records').upsert({
        ...record,
        'user_id': uid,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,date'),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getRecordsRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _db
        .from('daily_records')
        .select()
        .eq('user_id', uid)
        .gte('date', _dateStr(from))
        .lte('date', _dateStr(to))
        .order('date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> getSettings() async {
    final uid = _uid;
    if (uid == null) return null;

    return await _safeRequest(
      () => _db.from('user_settings').select().eq('user_id', uid).maybeSingle(),
    );
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final uid = _uid;
    if (uid == null) return;

    // We assume 'settings' contains snake_case keys mapped accurately using UserPreferences.toMap()
    final payload = <String, dynamic>{
      ...settings,
      'user_id': uid,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _safeRequest(
      () => _db.from('user_settings').upsert(payload, onConflict: 'user_id'),
    );
  }

  @override
  Future<void> updateUserStats({
    required int totalPoints,
    required int currentStreak,
    required int longestStreak,
    required int quranPages,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    await _db
        .from('profiles')
        .update({
          'total_points': totalPoints,
          'current_streak': currentStreak,
          'highest_streak': longestStreak,
          'quran_pages': quranPages,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', uid);
  }

  // ─────────────── PROHIBITIONS ───────────────
  @override
  Future<void> upsertProhibitionLog(Map<String, dynamic> log) async {
    final uid = _uid;
    if (uid == null) return;

    await _safeRequest(
      () => _db.from('prohibitions_log').upsert({
        ...log,
        'user_id': uid,
      }, onConflict: 'record_id,category'),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getProhibitionLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _db
        .from('prohibitions_log')
        .select()
        .eq('user_id', uid)
        .gte('date', _dateStr(from))
        .lte('date', _dateStr(to));
    return List<Map<String, dynamic>>.from(data);
  }

  // ─────────────── CUSTOM IBADAH ───────────────
  @override
  Future<void> upsertCustomIbadah(Map<String, dynamic> ibadah) async {
    final uid = _uid;
    if (uid == null) return;

    await _safeRequest(
      () => _db.from('custom_ibadah').upsert({...ibadah, 'user_id': uid}),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomIbadah() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _db.from('custom_ibadah').select().eq('user_id', uid);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<void> upsertCustomIbadahLog(Map<String, dynamic> log) async {
    final uid = _uid;
    if (uid == null) return;

    await _safeRequest(
      () => _db.from('custom_ibadah_log').upsert({...log, 'user_id': uid}),
    );
  }

  @override
  Future<void> deleteCustomIbadah(int id) async {
    final uid = _uid;
    if (uid == null) return;

    await _safeRequest(
      () => _db.from('custom_ibadah').delete().eq('id', id).eq('user_id', uid),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomIbadahLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _db
        .from('custom_ibadah_log')
        .select()
        .eq('user_id', uid)
        .gte('date', _dateStr(from))
        .lte('date', _dateStr(to));
    return List<Map<String, dynamic>>.from(data);
  }

  // ─────────────── ACHIEVEMENTS ───────────────
  @override
  Future<void> upsertAchievement(Map<String, dynamic> achievement) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.from('achievements').upsert({
      ...achievement,
      'user_id': uid,
      'earned_at': achievement['earned_at'] ?? DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,type');
  }

  @override
  Future<List<Map<String, dynamic>>> getEarnedAchievements() async {
    final uid = _uid;
    if (uid == null) return [];

    final data = await _db.from('achievements').select().eq('user_id', uid);
    return List<Map<String, dynamic>>.from(data);
  }

  static String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // ─────────────── USER PERSONAL ADHKAR ───────────────
  @override
  Future<List<Map<String, dynamic>>> getUserAdhkar() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _db
        .from('user_adhkar')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<void> addUserAdhkar({
    String? id,
    required String textAr,
    int count = 1,
    String categoryHint = 'general',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('user_adhkar').insert({
      if (id != null) 'id': id,
      'user_id': uid,
      'text_ar': textAr,
      'count': count,
      'category_hint': categoryHint,
    });
  }

  @override
  Future<void> deleteUserAdhkar(String id) async {
    await _db.from('user_adhkar').delete().eq('id', id);
  }

  // ─────────────── USER PERSONAL DUAS ───────────────
  @override
  Future<List<Map<String, dynamic>>> getUserDuas() async {
    final uid = _uid;
    if (uid == null) return [];
    final data = await _db
        .from('user_duas')
        .select()
        .eq('user_id', uid)
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<void> addUserDua({
    String? id,
    required String titleAr,
    required String textAr,
    String occasion = '',
    String source = '',
    String emoji = '🤲',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('user_duas').insert({
      if (id != null) 'id': id,
      'user_id': uid,
      'title_ar': titleAr,
      'text_ar': textAr,
      'occasion': occasion,
      'source': source,
      'emoji': emoji,
    });
  }

  @override
  Future<void> deleteUserDua(String id) async {
    await _db.from('user_duas').delete().eq('id', id);
  }

  // ─────────────── COMMUNITY ADHKAR ───────────────
  @override
  Future<List<Map<String, dynamic>>> getCommunityAdhkar() async {
    final data = await _db
        .from('community_adhkar')
        .select()
        .eq('approved', true)
        .order('likes', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<void> likeAdhkar(String id) async {
    // A SECURITY DEFINER function (migration
    // 20260906190603_fix_community_content_policies.sql), not a client-side
    // read-then-write: the old approach both raced (two likes in quick
    // succession could read the same count and both write current+1) and
    // needed an RLS policy broad enough to let any signed-in user UPDATE
    // any column on any row. The function only ever touches `likes`, only
    // on already-approved rows, atomically.
    await _db.rpc(
      'increment_community_adhkar_likes',
      params: {'row_id': id},
    );
  }

  @override
  Future<void> shareAdhkarToCommunity({
    required String textAr,
    int count = 1,
    String categoryHint = 'general',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('community_adhkar').insert({
      'shared_by': uid,
      'text_ar': textAr,
      'count': count,
      'category_hint': categoryHint,
      // `approved` has no server-side default, and getCommunityAdhkar()'s
      // `.eq('approved', true)` filter is backed by a matching RLS SELECT
      // policy (see supabase/audit/table_checklist.md) — a row left null
      // is invisible to everyone forever, with no moderation UI anywhere
      // in this app to ever flip it. The INSERT policy only checks
      // `shared_by = auth.uid()`, so setting it true here is allowed and
      // is what makes a share actually show up in the community tab.
      'approved': true,
    });
  }

  // ─────────────── COMMUNITY DUAS ───────────────
  @override
  Future<List<Map<String, dynamic>>> getCommunityDuas() async {
    final data = await _db
        .from('community_duas')
        .select()
        .eq('approved', true)
        .order('likes', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<void> likeDua(String id) async {
    // See likeAdhkar() above — same SECURITY DEFINER-function fix.
    await _db.rpc('increment_community_duas_likes', params: {'row_id': id});
  }

  @override
  Future<void> shareDuaToCommunity({
    required String titleAr,
    required String textAr,
    String occasion = '',
    String source = '',
    String emoji = '🤲',
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.from('community_duas').insert({
      'shared_by': uid,
      'title_ar': titleAr,
      'text_ar': textAr,
      'occasion': occasion,
      'source': source,
      'emoji': emoji,
      // See the matching comment in shareAdhkarToCommunity() above: without
      // this, the row's `approved` column stays null, getCommunityDuas()'s
      // `.eq('approved', true)` (backed by an RLS SELECT policy, not just a
      // client-side filter) hides it from everyone, and nothing in this
      // app can ever flip it — the dua "shares" successfully but silently
      // never appears in the Community tab.
      'approved': true,
    });
  }

  // ─────────────────────────────────────────
  //  BOOKS & READING PROGRESS
  // ─────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> getBooks() async {
    return _safeRequest<List<Map<String, dynamic>>>(() async {
      final data = await _db.from('books').select().order('title_ar');
      return List<Map<String, dynamic>>.from(data);
    });
  }

  @override
  Future<void> upsertBookProgress(
    String bookId,
    Map<String, dynamic> data,
  ) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db.from('book_reading_progress').upsert({
        'user_id': userId,
        'book_id': bookId,
        'chapter_index': data['chapter_index'],
        'page_index': data['page_index'],
        'read_pages': data['read_pages'],
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAllBookProgress() async {
    final userId = _uid;
    if (userId == null) return [];

    return _safeRequest<List<Map<String, dynamic>>>(() async {
      final data = await _db
          .from('book_reading_progress')
          .select('book_id, chapter_index, page_index, read_pages')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(data);
    });
  }

  // ─────────────────────────────────────────
  //  PDF SESSION (timer + page)
  // ─────────────────────────────────────────

  /// Save or update the PDF reading session:
  /// current page, total PDF pages, and accumulated reading seconds.
  @override
  Future<void> upsertPdfSession(
    String bookId,
    int pdfPage,
    int totalPdfPages,
    int readingSeconds,
  ) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db.from('book_reading_progress').upsert({
        'user_id': userId,
        'book_id': bookId,
        'pdf_page': pdfPage,
        'total_pdf_pages': totalPdfPages,
        'reading_seconds': readingSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,book_id'),
    );
  }

  /// Fetch saved PDF session for a book (pdf_page, total_pdf_pages, reading_seconds).
  @override
  Future<Map<String, dynamic>?> getPdfSession(String bookId) async {
    final userId = _uid;
    if (userId == null) return null;

    return _safeRequest<Map<String, dynamic>?>(() async {
      final data = await _db
          .from('book_reading_progress')
          .select('pdf_page, total_pdf_pages, reading_seconds')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .maybeSingle();
      return data;
    });
  }

  // ─────────────────────────────────────────
  //  REMINDERS
  // ─────────────────────────────────────────
  @override
  Future<void> upsertReminder(Map<String, dynamic> data) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db.from('reminders').upsert({
        'user_id': userId,
        'local_id': data['local_id'],
        'title': data['title'],
        'icon_name': data['icon_name'],
        'time': data['time'],
        'is_enabled': data['is_enabled'],
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  @override
  Future<void> deleteReminder(int localId) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db
          .from('reminders')
          .delete()
          .eq('user_id', userId)
          .eq('local_id', localId),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getReminders() async {
    final userId = _uid;
    if (userId == null) return [];

    return _safeRequest<List<Map<String, dynamic>>>(() async {
      final data = await _db
          .from('reminders')
          .select('local_id, title, icon_name, time, is_enabled')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(data);
    });
  }

  // ─────────────────────────────────────────
  //  QURAN (bookmarks, last read, khatma sessions)
  // ─────────────────────────────────────────
  @override
  Future<void> upsertQuranBookmark(Map<String, dynamic> bookmark) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db.from('quran_bookmarks').upsert({
        'user_id': userId,
        'surah_num': bookmark['surah_num'],
        'ayah_num': bookmark['ayah_num'],
        'page': bookmark['page'],
        'surah_name': bookmark['surah_name'],
        'saved_at': bookmark['saved_at'],
      }, onConflict: 'user_id,surah_num,ayah_num'),
    );
  }

  @override
  Future<void> deleteQuranBookmark(int surahNum, int ayahNum) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db
          .from('quran_bookmarks')
          .delete()
          .eq('user_id', userId)
          .eq('surah_num', surahNum)
          .eq('ayah_num', ayahNum),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getQuranBookmarks() async {
    final userId = _uid;
    if (userId == null) return [];

    return _safeRequest<List<Map<String, dynamic>>>(() async {
      final data = await _db
          .from('quran_bookmarks')
          .select('surah_num, ayah_num, page, surah_name, saved_at')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(data);
    });
  }

  @override
  Future<void> upsertQuranLastRead(Map<String, dynamic> lastRead) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db.from('quran_last_read').upsert({
        'user_id': userId,
        'surah_num': lastRead['surah_num'],
        'ayah_num': lastRead['ayah_num'],
        'page': lastRead['page'],
        'surah_name': lastRead['surah_name'],
        'saved_at': lastRead['saved_at'],
      }),
    );
  }

  @override
  Future<Map<String, dynamic>?> getQuranLastRead() async {
    final userId = _uid;
    if (userId == null) return null;

    return _safeRequest<Map<String, dynamic>?>(() async {
      final data = await _db
          .from('quran_last_read')
          .select('surah_num, ayah_num, page, surah_name, saved_at')
          .eq('user_id', userId)
          .maybeSingle();
      return data;
    });
  }

  @override
  Future<void> upsertKhatmaSession(Map<String, dynamic> session) async {
    final userId = _uid;
    if (userId == null) return;

    await _safeRequest(
      () async => await _db.from('khatma_sessions').upsert({
        'user_id': userId,
        'id': session['id'],
        'label': session['label'],
        'type': session['type'],
        'start_date': session['start_date'],
        'end_date': session['end_date'],
        'completed_date': session['completed_date'],
        'cancelled_date': session['cancelled_date'],
        'start_page': session['start_page'],
        'current_page': session['current_page'],
        'pages_read': session['pages_read'],
        'notifications_enabled': session['notifications_enabled'],
        'daily_pages': session['daily_pages'],
        'total_reading_seconds': session['total_reading_seconds'],
        'reading_sessions_count': session['reading_sessions_count'],
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,id'),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getKhatmaSessions() async {
    final userId = _uid;
    if (userId == null) return [];

    return _safeRequest<List<Map<String, dynamic>>>(() async {
      final data = await _db.from('khatma_sessions').select().eq(
        'user_id',
        userId,
      );
      return List<Map<String, dynamic>>.from(data);
    });
  }
}
