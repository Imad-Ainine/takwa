import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'quran_models.dart';

/// Owns every raw `SharedPreferences` key the Quran feature persists to —
/// reader prefs, the last-read bookmark, saved bookmarks, and Khatma
/// (extended) progress/history — so notifiers read/write through here
/// instead of calling the plugin directly.
///
/// The [SharedPreferences] instance is resolved once in `main()` (see
/// `sharedPreferencesProvider`), so every method here is synchronous.
class QuranPrefsRepository {
  QuranPrefsRepository(this._prefs);

  final SharedPreferences _prefs;

  // ── Reader prefs ──────────────────────────────────────────
  static const _kTheme = 'q_theme';
  static const _kFontSize = 'q_fontsize';
  static const _kLastPage = 'q_last_page';

  ReaderTheme getReaderTheme() =>
      ReaderTheme.values[_prefs.getInt(_kTheme) ?? 0];
  double getFontSize() => _prefs.getDouble(_kFontSize) ?? 22.0;
  int getLastPage() => _prefs.getInt(_kLastPage) ?? 1;

  Future<void> setReaderTheme(ReaderTheme theme) =>
      _prefs.setInt(_kTheme, theme.index);
  Future<void> setFontSize(double size) => _prefs.setDouble(_kFontSize, size);
  Future<void> setLastPage(int page) => _prefs.setInt(_kLastPage, page);

  // ── Last-read bookmark ────────────────────────────────────
  static const _kLastRead = 'q_last_read';

  QuranBookmark? getLastRead() {
    final raw = _prefs.getString(_kLastRead);
    if (raw == null) return null;
    return QuranBookmark.fromJson(jsonDecode(raw));
  }

  Future<void> setLastRead(QuranBookmark bookmark) =>
      _prefs.setString(_kLastRead, jsonEncode(bookmark.toJson()));

  Future<void> clearLastRead() => _prefs.remove(_kLastRead);

  // ── Saved bookmarks ───────────────────────────────────────
  static const _kBookmarks = 'q_bookmarks';

  List<QuranBookmark> getBookmarks() {
    final list = _prefs.getStringList(_kBookmarks) ?? [];
    return list.map((s) => QuranBookmark.fromJson(jsonDecode(s))).toList();
  }

  Future<void> setBookmarks(List<QuranBookmark> bookmarks) =>
      _prefs.setStringList(
        _kBookmarks,
        bookmarks.map((b) => jsonEncode(b.toJson())).toList(),
      );

  // ── Khatma (extended) ─────────────────────────────────────
  static const _kKhatmaActive = 'khatma_ex_active';
  static const _kKhatmaHistory = 'khatma_ex_history';

  KhatmaSessionEx? getActiveKhatma() {
    final raw = _prefs.getString(_kKhatmaActive);
    if (raw == null) return null;
    try {
      return KhatmaSessionEx.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> setActiveKhatma(KhatmaSessionEx session) =>
      _prefs.setString(_kKhatmaActive, jsonEncode(session.toJson()));

  Future<void> clearActiveKhatma() => _prefs.remove(_kKhatmaActive);

  List<KhatmaSessionEx> getKhatmaHistory() {
    final list = _prefs.getStringList(_kKhatmaHistory) ?? [];
    return list.map((s) => KhatmaSessionEx.fromJson(jsonDecode(s))).toList();
  }

  /// Removes any existing history entry with the same id, then appends
  /// [session] — matches the dedup-by-id behavior the old inline notifier
  /// code used when archiving a completed/cancelled Khatma.
  Future<void> archiveKhatma(KhatmaSessionEx session) async {
    final list = _prefs.getStringList(_kKhatmaHistory) ?? [];
    list.removeWhere((item) {
      try {
        final m = jsonDecode(item) as Map;
        return m['id'] == session.id;
      } catch (_) {
        return false;
      }
    });
    list.add(jsonEncode(session.toJson()));
    await _prefs.setStringList(_kKhatmaHistory, list);
  }

  /// Permanently removes one entry from history by id. The delete button
  /// on a cancelled/completed Khatma card in the history screen used to
  /// just show a "deleted" toast and refresh the list without actually
  /// calling anything like this — the entry would silently reappear on
  /// the next read since nothing was ever removed from storage.
  Future<void> deleteFromHistory(String id) async {
    final list = _prefs.getStringList(_kKhatmaHistory) ?? [];
    list.removeWhere((item) {
      try {
        final m = jsonDecode(item) as Map;
        return m['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await _prefs.setStringList(_kKhatmaHistory, list);
  }
}
