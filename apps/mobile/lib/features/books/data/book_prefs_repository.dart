import 'package:shared_preferences/shared_preferences.dart';

/// A cached local PDF reading session (page/total/elapsed seconds).
class PdfSessionSnapshot {
  const PdfSessionSnapshot({
    required this.page,
    required this.total,
    required this.secs,
  });

  final int page;
  final int total;
  final int secs;
}

/// Owns the SharedPreferences keys the Books feature persists to directly —
/// reader font size and the per-book PDF session cache (page/total/elapsed
/// seconds) — so notifiers read/write through here instead of calling the
/// plugin directly. Book *progress* itself lives in Drift (see
/// `BookProgressDao`); this repository only covers the local-only cache that
/// exists to render instantly before Drift/Supabase settle.
class BookPrefsRepository {
  BookPrefsRepository(this._prefs);

  final SharedPreferences _prefs;

  // ── Reader font size (0=small, 1=medium, 2=large) ──
  static const _fontSizeKey = 'book_font_size';

  int getFontSizeLevel() => _prefs.getInt(_fontSizeKey) ?? 1;
  Future<void> setFontSizeLevel(int level) =>
      _prefs.setInt(_fontSizeKey, level);

  // ── PDF session cache, per book ──
  static String _pageKey(String bookId) => 'pdf_session_${bookId}_page';
  static String _totalKey(String bookId) => 'pdf_session_${bookId}_total';
  static String _secsKey(String bookId) => 'pdf_session_${bookId}_secs';

  PdfSessionSnapshot getPdfSession(String bookId) => PdfSessionSnapshot(
    page: _prefs.getInt(_pageKey(bookId)) ?? 1,
    total: _prefs.getInt(_totalKey(bookId)) ?? 0,
    secs: _prefs.getInt(_secsKey(bookId)) ?? 0,
  );

  Future<void> setPdfSession(
    String bookId, {
    required int page,
    required int total,
    required int secs,
  }) async {
    await _prefs.setInt(_pageKey(bookId), page);
    await _prefs.setInt(_totalKey(bookId), total);
    await _prefs.setInt(_secsKey(bookId), secs);
  }
}
