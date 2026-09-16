import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/book_prefs_repository.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/providers/database_providers.dart';
import 'books_reading_provider.dart' show bookPrefsRepositoryProvider;

// ─────────────────────────────────────────
//  STATE MODEL
// ─────────────────────────────────────────

class PdfSessionState {
  final int currentPage;
  final int totalPages;
  final int readingSeconds;
  final bool isRunning;

  const PdfSessionState({
    this.currentPage = 1,
    this.totalPages = 0,
    this.readingSeconds = 0,
    this.isRunning = false,
  });

  PdfSessionState copyWith({
    int? currentPage,
    int? totalPages,
    int? readingSeconds,
    bool? isRunning,
  }) => PdfSessionState(
    currentPage: currentPage ?? this.currentPage,
    totalPages: totalPages ?? this.totalPages,
    readingSeconds: readingSeconds ?? this.readingSeconds,
    isRunning: isRunning ?? this.isRunning,
  );

  /// 0.0 → 1.0
  double get progressFraction =>
      (totalPages > 0) ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  /// Formatted as HH:MM:SS
  String get timerLabel {
    final h = readingSeconds ~/ 3600;
    final m = (readingSeconds % 3600) ~/ 60;
    final s = readingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────

class PdfSessionNotifier extends StateNotifier<PdfSessionState> {
  PdfSessionNotifier(this._ref) : super(const PdfSessionState());

  final Ref _ref;

  Timer? _ticker;
  Timer? _autoSave;
  String? _currentBookId;

  BookPrefsRepository get _repo => _ref.read(bookPrefsRepositoryProvider);

  // ── lifecycle ────────────────────────────

  /// Load persisted local session, then try to fetch from Supabase.
  Future<void> loadSession(String bookId) async {
    _currentBookId = bookId;

    // 1. Load local cache first (instant)
    final cached = _repo.getPdfSession(bookId);
    if (!mounted) return;

    final page = cached.page;
    final total = cached.total;
    final secs = cached.secs;

    state = state.copyWith(
      currentPage: page,
      totalPages: total,
      readingSeconds: secs,
    );

    // 2. Fetch remote (overrides local if newer)
    try {
      final remote = await _ref
          .read(supabaseServiceProvider)
          .getPdfSession(bookId);
      if (remote != null) {
        final remoteSecs = (remote['reading_seconds'] as int?) ?? 0;
        final remotePage = (remote['pdf_page'] as int?) ?? 1;
        final remoteTotal = (remote['total_pdf_pages'] as int?) ?? 0;

        // Use whichever has more reading time (more authoritative)
        if (remoteSecs >= secs) {
          if (!mounted) return;
          state = state.copyWith(
            currentPage: remotePage,
            totalPages: remoteTotal > 0 ? remoteTotal : total,
            readingSeconds: remoteSecs,
          );
          // Persist locally too
          await _saveLocal(bookId, remotePage, remoteTotal, remoteSecs);
        }
      }
    } catch (_) {
      // Best-effort — local state is already restored
    }
  }

  /// Start the 1-second ticker and auto-save every 30 s.
  void start() {
    if (state.isRunning) return;
    if (mounted) state = state.copyWith(isRunning: true);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        state = state.copyWith(readingSeconds: state.readingSeconds + 1);
      }
    });

    _autoSave = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_currentBookId != null && mounted) await saveSession(_currentBookId!);
    });
  }

  /// Pause the ticker (call when app goes to background or screen closes).
  void pause() {
    _ticker?.cancel();
    _ticker = null;
    _autoSave?.cancel();
    _autoSave = null;
    if (mounted) {
      state = state.copyWith(isRunning: false);
    }
  }

  /// Set current PDF page.
  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  /// Set total pages (called once PDF is loaded).
  void setTotal(int total) {
    state = state.copyWith(totalPages: total);
  }

  /// Persist session locally (SharedPreferences + Drift) + push to Supabase.
  Future<void> saveSession(String bookId) async {
    final page = state.currentPage;
    final total = state.totalPages;
    final secs = state.readingSeconds;

    await _saveLocal(bookId, page, total, secs);

    // Also write to Drift for SyncManager
    try {
      await _ref
          .read(bookProgressDaoProvider)
          .savePdfSession(
            bookId: bookId,
            pdfPage: page,
            totalPdfPages: total,
            readingSeconds: secs,
          );
    } catch (_) {
      // Drift may not be ready — SharedPreferences fallback is already saved.
    }

    try {
      await _ref
          .read(supabaseServiceProvider)
          .upsertPdfSession(bookId, page, total, secs);
    } catch (_) {
      // Offline fallback — local already saved
    }
  }

  // ── helpers ──────────────────────────────

  Future<void> _saveLocal(String bookId, int page, int total, int secs) {
    return _repo.setPdfSession(bookId, page: page, total: total, secs: secs);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoSave?.cancel();

    if (_currentBookId != null) {
      saveSession(_currentBookId!);
    }

    super.dispose();
  }
}

// ─────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────

/// Scoped per book via family — use book.id as key.
final pdfSessionProvider = StateNotifierProvider.autoDispose
    .family<PdfSessionNotifier, PdfSessionState, String>(
      (ref, bookId) => PdfSessionNotifier(ref),
    );
