import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/widgets.dart' show BuildContext, Curves;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_library/quran_library.dart' as ql;
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/quran_models.dart';
import '../data/quran_prefs_repository.dart';
import '../data/quran_reciters_setup.dart';

// ─────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────
final quranPrefsRepositoryProvider = Provider<QuranPrefsRepository>((ref) {
  return QuranPrefsRepository(ref.watch(sharedPreferencesProvider));
});

// ─────────────────────────────────────────────────────────────
// Reader State
// ─────────────────────────────────────────────────────────────
final quranStateProvider =
    StateNotifierProvider<QuranStateNotifier, QuranReadingState>(
      (ref) => QuranStateNotifier(ref.watch(quranPrefsRepositoryProvider)),
    );

class QuranStateNotifier extends StateNotifier<QuranReadingState> {
  QuranStateNotifier(this._repo)
    : super(
        QuranReadingState(
          theme: _repo.getReaderTheme(),
          fontSize: _repo.getFontSize(),
          currentPage: _repo.getLastPage(),
        ),
      );

  final QuranPrefsRepository _repo;

  Future<void> setTheme(ReaderTheme t) async {
    state = state.copyWith(theme: t);
    await _repo.setReaderTheme(t);
  }

  Future<void> setFontSize(double s) async {
    state = state.copyWith(fontSize: s.clamp(16, 36));
    await _repo.setFontSize(s);
  }

  Future<void> setPage(int page) async {
    state = state.copyWith(currentPage: page);
    await _repo.setLastPage(page);
  }

  void setMode(ReaderMode m) => state = state.copyWith(mode: m);
  void setSurah(int s) => state = state.copyWith(currentSurah: s);
  void setAyah(int a) => state = state.copyWith(currentAyah: a);
  void toggleToolbar() =>
      state = state.copyWith(showToolbar: !state.showToolbar);
}

// ─────────────────────────────────────────────────────────────
// Audio
// ─────────────────────────────────────────────────────────────
// Built on quran_library's own AudioCtrl engine (GetX-based) for
// highlighting/page-turning during playback and for the shared
// audio_service background/lock-screen session (see MainActivity/
// Info.plist) — but NOT for continuous whole-surah playback itself.
// AudioCtrl.playAyah(..., playSingleAyah: false) is quran_library's own
// API for that, but on native platforms (not web) it *requires* the
// surah's ayahs be downloaded first through its own download-management
// sheet — and confirmed by reading quran_library 4.3.0's own source
// (_playAyahsFile in src/audio/controller/extensions/ayah_ctrl_extension.
// dart), the check for whether that download actually finished re-reads a
// variable it captured *before* the download ran and never updates
// afterwards, so it always evaluates as "still not downloaded" and
// `return`s without ever playing — silently, even once the download
// sheet reports done. That's a bug in the package itself, not something
// fixable from here, and it's exactly what "play doesn't work" is.
//
// So whole-surah playback here streams the ayah audio files directly
// (the same approach quran_library's own web build uses, and the same
// CDN this app's player used before adopting quran_library) straight
// into AudioCtrl's own shared AudioPlayer, and replicates just the two
// bits of that function actually worth keeping: updating
// state.currentAyahUniqueNumber (which QuranCtrl.toggleAyahSelection
// turns into the mushaf's ayah highlight) and animating the page
// controller when playback crosses a page boundary.
final quranAudioProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>(
      (ref) => QuranAudioNotifier(),
    );

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  QuranAudioNotifier() : super(const QuranAudioState()) {
    final audioState = ql.AudioCtrl.instance.state;
    _isPlayingSub = audioState.isPlaying.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _isPreparingSub = audioState.isAudioPreparing.listen((preparing) {
      state = state.copyWith(isLoading: preparing);
    });
    _currentAyahSub = audioState.currentAyahUniqueNumber.listen((uq) {
      final (surah, ayah) = _surahAyahFromUQ(uq);
      state = state.copyWith(surah: surah, ayah: ayah);
    });
  }

  StreamSubscription? _isPlayingSub, _isPreparingSub, _currentAyahSub;
  StreamSubscription? _sequenceSub, _completionSub;

  Future<void> setReciter(String reciterId) async {
    state = state.copyWith(reciterId: reciterId);
    final idx = QuranRecitersSetup.indexOf(reciterId);
    if (idx == -1) return;
    final audioState = ql.AudioCtrl.instance.state;
    audioState.ayahReaderIndex.value = idx;
    // If a surah is already playing, restart it (from the same ayah) with
    // the newly selected reciter instead of waiting for the next tap.
    if (audioState.isPlaying.value) {
      await _playSurahStreaming(state.surah, state.ayah);
    }
  }

  /// Ayah for (surahNum, ayahNum), or null if not found.
  ql.AyahModel? _ayah(int surahNum, int ayahNum) {
    final surahs = ql.QuranLibrary.quranCtrl.surahs;
    if (surahNum < 1 || surahNum > surahs.length) return null;
    for (final a in surahs[surahNum - 1].ayahs) {
      if (a.ayahNumber == ayahNum) return a;
    }
    return null;
  }

  (int surah, int ayah) _surahAyahFromUQ(int uq) {
    final surahs = ql.QuranLibrary.quranCtrl.surahs;
    for (var i = 0; i < surahs.length; i++) {
      for (final a in surahs[i].ayahs) {
        if (a.ayahUQNumber == uq) return (i + 1, a.ayahNumber);
      }
    }
    return (1, 1);
  }

  /// Plays a single ayah (the ayah-options sheet's "Listen") through
  /// AudioCtrl.playAyah() — its single-ayah path downloads-then-plays one
  /// small file in a straight line and doesn't have the stale-check bug
  /// the multi-ayah path does, so it's fine to use as-is.
  Future<void> playAyah(BuildContext context, int surahNum, int ayahNum) async {
    final ayah = _ayah(surahNum, ayahNum);
    if (ayah == null) return;
    await ql.AudioCtrl.instance.playAyah(
      context,
      ayah.ayahUQNumber,
      playSingleAyah: true,
    );
  }

  /// Toggles whole-surah playback starting at [ayahNum] (the reader's top
  /// and bottom bar play buttons, which always pass ayah 1 — "play this
  /// surah"): pauses if that surah is already playing, resumes in place if
  /// it's already loaded but paused, otherwise starts it fresh.
  Future<void> togglePlay(BuildContext context, int surahNum, int ayahNum) async {
    final audioState = ql.AudioCtrl.instance.state;
    final surahs = ql.QuranLibrary.quranCtrl.surahs;
    if (surahNum < 1 || surahNum > surahs.length) return;
    final isThisSurahLoaded = surahs[surahNum - 1].ayahs.any(
      (a) => a.ayahUQNumber == audioState.currentAyahUniqueNumber.value,
    );
    if (isThisSurahLoaded && audioState.audioPlayer.playing) {
      await audioState.audioPlayer.pause();
      audioState.isPlaying.value = false;
    } else if (isThisSurahLoaded) {
      audioState.isPlaying.value = true;
      await audioState.audioPlayer.play();
    } else {
      await _playSurahStreaming(surahNum, ayahNum);
    }
  }

  /// Streams [surahNum] ayah-by-ayah starting at [startAyahNum], straight
  /// from the network (no local download step — see the class doc comment
  /// on why the library's own multi-ayah path can't be used for this).
  Future<void> _playSurahStreaming(int surahNum, int startAyahNum) async {
    final surahs = ql.QuranLibrary.quranCtrl.surahs;
    if (surahNum < 1 || surahNum > surahs.length) return;
    final ayahs = surahs[surahNum - 1].ayahs;
    if (ayahs.isEmpty) return;
    final foundIndex = ayahs.indexWhere((a) => a.ayahNumber == startAyahNum);
    final playAyahs = ayahs.sublist(foundIndex >= 0 ? foundIndex : 0);

    final audioState = ql.AudioCtrl.instance.state;
    final reader =
        ql.ReadersConstants.activeAyahReaders[audioState.ayahReaderIndex.value];

    String urlFor(ql.AyahModel a) {
      if (reader.url == ql.ReadersConstants.ayahs1stSource) {
        return '${reader.url}${reader.readerNamePath}/${a.ayahUQNumber}.mp3';
      }
      final s = surahNum.toString().padLeft(3, '0');
      final n = a.ayahNumber.toString().padLeft(3, '0');
      return '${reader.url}${reader.readerNamePath}/$s$n.mp3';
    }

    await _sequenceSub?.cancel();
    await _completionSub?.cancel();
    audioState.isAudioPreparing.value = true;
    try {
      await audioState.audioPlayer.stop();
      await audioState.audioPlayer.setAudioSources(
        [for (final a in playAyahs) ql.AudioSource.uri(Uri.parse(urlFor(a)))],
        initialIndex: 0,
      );
      await audioState.audioPlayer.setShuffleModeEnabled(false);
      await audioState.audioPlayer.setLoopMode(ql.LoopMode.off);

      int? lastPage;
      _sequenceSub = audioState.audioPlayer.sequenceStateStream.listen((seq) {
        final idx = seq.currentIndex;
        if (idx == null || idx < 0 || idx >= playAyahs.length) return;
        final ayah = playAyahs[idx];
        audioState.currentAyahUniqueNumber.value = ayah.ayahUQNumber;
        ql.QuranCtrl.instance.toggleAyahSelection(ayah.ayahUQNumber);
        if (lastPage != null && lastPage != ayah.page) {
          ql.QuranCtrl.instance.quranPagesController.animateToPage(
            ayah.page - 1,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
        lastPage = ayah.page;
      });
      _completionSub = audioState.audioPlayer.playerStateStream.listen((s) {
        if (s.processingState == ql.ProcessingState.completed) {
          audioState.isPlaying.value = false;
        }
      });

      audioState.isAudioPreparing.value = false;
      audioState.isPlaying.value = true;
      await audioState.audioPlayer.play();
    } catch (e) {
      audioState.isAudioPreparing.value = false;
      audioState.isPlaying.value = false;
      developer.log('Failed to stream surah $surahNum: $e', name: 'QuranAudio');
    }
  }

  Future<void> stop() async {
    final audioState = ql.AudioCtrl.instance.state;
    await _sequenceSub?.cancel();
    await _completionSub?.cancel();
    await audioState.stopAllAudio();
  }

  Future<void> setSpeed(double s) async {
    state = state.copyWith(speed: s);
    await ql.AudioCtrl.instance.state.audioPlayer.setSpeed(s);
  }

  @override
  void dispose() {
    _isPlayingSub?.cancel();
    _isPreparingSub?.cancel();
    _currentAyahSub?.cancel();
    _sequenceSub?.cancel();
    _completionSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
// Last Read / Bookmarks
// ─────────────────────────────────────────────────────────────

/// Coalesces high-frequency remote writes (a Supabase upsert per page
/// swipe was one per second of reading) into at most one request per
/// [window]: the first change pushes immediately, later ones fold into a
/// single push when the window closes, and [flush] forces whatever is
/// queued to go out now (reader dispose, terminal state changes).
class _ThrottledPush {
  _ThrottledPush(this.window);

  final Duration window;
  Timer? _timer;
  DateTime? _lastRun;
  Future<void> Function()? _queued;

  /// Records that a push happened outside [schedule] (create/cancel/
  /// finish push immediately), so the coalescing window applies to it too.
  void note() => _lastRun = DateTime.now();

  void schedule(Future<void> Function() task) {
    final last = _lastRun;
    final now = DateTime.now();
    if (last == null || now.difference(last) >= window) {
      _run(task);
      return;
    }
    _queued = task;
    _timer ??= Timer(window - now.difference(last), () {
      _timer = null;
      final q = _queued;
      _queued = null;
      if (q != null) _run(q);
    });
  }

  /// Drops the queued task — used when a newer authoritative push (or a
  /// deletion) makes it stale.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _queued = null;
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final q = _queued;
    _queued = null;
    if (q != null) await _run(q);
  }

  Future<void> _run(Future<void> Function() task) async {
    _lastRun = DateTime.now();
    await task();
  }
}

final quranLastReadProvider =
    StateNotifierProvider<QuranLastReadNotifier, QuranBookmark?>(
      (ref) => QuranLastReadNotifier(
        ref,
        ref.watch(quranPrefsRepositoryProvider),
      ),
    );

class QuranLastReadNotifier extends StateNotifier<QuranBookmark?> {
  QuranLastReadNotifier(this._ref, this._repo) : super(_repo.getLastRead());

  final Ref _ref;
  final QuranPrefsRepository _repo;

  static const _kOutboxTable = 'quran_last_read';
  static const _kOutboxKey = 'current';

  final _push = _ThrottledPush(const Duration(seconds: 60));

  Map<String, dynamic> _remoteRow(QuranBookmark b) => {
    'surah_num': b.surahNum,
    'ayah_num': b.ayahNum,
    'page': b.page,
    'surah_name': b.surahName,
    'saved_at': (b.savedAt ?? DateTime.now()).toIso8601String(),
  };

  Future<void> _pushNow(QuranBookmark b) async {
    final outbox = _ref.read(syncOutboxDaoProvider);
    try {
      await _ref
          .read(supabaseServiceProvider)
          .upsertQuranLastRead(_remoteRow(b));
      await outbox.clearPending(_kOutboxTable, _kOutboxKey);
    } catch (e) {
      // Queued for the next fullSync retry — before this, a push that
      // failed offline was lost forever because the pull side never has
      // anything to send this position back with.
      await outbox.markPending(_kOutboxTable, _kOutboxKey, '$e');
      developer.log(
        'Failed to sync quran last-read, queued for retry: $e',
        name: 'QuranProviders',
      );
    }
  }

  Future<void> save(QuranBookmark b) async {
    state = b;
    await _repo.setLastRead(b);
    _push.schedule(() => _pushNow(b));
  }

  /// Called when the reader closes so the last few pages read inside the
  /// throttle window reach Supabase without waiting for the next app start.
  Future<void> flushPendingPush() => _push.flush();

  Future<void> clear() async {
    state = null;
    _push.cancel();
    await _repo.clearLastRead();
  }

  @override
  void dispose() {
    _push.cancel();
    super.dispose();
  }

  /// Two-way newest-wins sync (called from SyncManager): whichever side
  /// has the newer `saved_at` keeps its position, and the other side gets
  /// pushed — so a position saved while offline still reaches Supabase
  /// instead of being overwritten by the remote row.
  Future<void> syncFromRemote() async {
    try {
      final remote = await _ref
          .read(supabaseServiceProvider)
          .getQuranLastRead();
      final local = state;
      if (remote == null) {
        if (local != null) await _pushNow(local);
        return;
      }
      final remoteSavedAt = DateTime.tryParse(
        remote['saved_at']?.toString() ?? '',
      );
      if (local != null &&
          local.savedAt != null &&
          (remoteSavedAt == null || !remoteSavedAt.isAfter(local.savedAt!))) {
        if (!_samePosition(local, remote)) await _pushNow(local);
        return;
      }
      final bookmark = QuranBookmark(
        surahNum: remote['surah_num'] as int,
        ayahNum: remote['ayah_num'] as int,
        page: remote['page'] as int,
        surahName: remote['surah_name'] as String,
        savedAt: remoteSavedAt,
      );
      state = bookmark;
      await _repo.setLastRead(bookmark);
    } catch (e) {
      developer.log(
        'Failed to sync remote quran last-read: $e',
        name: 'QuranProviders',
      );
    }
  }

  bool _samePosition(QuranBookmark local, Map<String, dynamic> remote) =>
      remote['surah_num'] == local.surahNum &&
      remote['ayah_num'] == local.ayahNum &&
      remote['page'] == local.page;
}

final quranBookmarksProvider =
    StateNotifierProvider<_BookmarksNotifier, List<QuranBookmark>>(
      (ref) => _BookmarksNotifier(ref, ref.watch(quranPrefsRepositoryProvider)),
    );

class _BookmarksNotifier extends StateNotifier<List<QuranBookmark>> {
  _BookmarksNotifier(this._ref, this._repo) : super(_repo.getBookmarks());

  final Ref _ref;
  final QuranPrefsRepository _repo;

  static const _kOutboxTable = 'quran_bookmarks';
  static const _kDeletePrefix = 'del:';

  String _key(int surah, int ayah) => '$surah:$ayah';

  Map<String, dynamic> _remoteRow(QuranBookmark b) => {
    'surah_num': b.surahNum,
    'ayah_num': b.ayahNum,
    'page': b.page,
    'surah_name': b.surahName,
    'saved_at': (b.savedAt ?? DateTime.now()).toIso8601String(),
  };

  Future<void> _pushAdd(QuranBookmark b) async {
    final outbox = _ref.read(syncOutboxDaoProvider);
    try {
      await _ref
          .read(supabaseServiceProvider)
          .upsertQuranBookmark(_remoteRow(b));
      await outbox.clearPending(_kOutboxTable, _key(b.surahNum, b.ayahNum));
    } catch (e) {
      await outbox.markPending(
        _kOutboxTable,
        _key(b.surahNum, b.ayahNum),
        '$e',
      );
      developer.log(
        'Failed to sync quran bookmark, queued for retry: $e',
        name: 'QuranProviders',
      );
    }
  }

  Future<void> add(QuranBookmark b) async {
    if (state.any((x) => x.surahNum == b.surahNum && x.ayahNum == b.ayahNum)) {
      return;
    }
    state = [...state, b];
    await _repo.setBookmarks(state);
    await _pushAdd(b);
  }

  Future<void> remove(int surah, int ayah) async {
    state = state
        .where((x) => !(x.surahNum == surah && x.ayahNum == ayah))
        .toList();
    await _repo.setBookmarks(state);
    final outbox = _ref.read(syncOutboxDaoProvider);
    try {
      await _ref.read(supabaseServiceProvider).deleteQuranBookmark(surah, ayah);
      // Also drop a queued add push for the same ayah — the bookmark is
      // gone now, re-adding it on the next sync would resurrect it.
      await outbox.clearPending(_kOutboxTable, _key(surah, ayah));
    } catch (e) {
      // Journal the delete: without it an offline-removed bookmark comes
      // back on the next pull, since the remote row still exists.
      await outbox.markPending(
        _kOutboxTable,
        '$_kDeletePrefix${_key(surah, ayah)}',
        '$e',
      );
      developer.log(
        'Failed to sync quran bookmark delete, queued for retry: $e',
        name: 'QuranProviders',
      );
    }
  }

  /// Two-way merge (called from SyncManager): remote-only bookmarks are
  /// added locally, local-only ones (saved while offline) are pushed, and
  /// journaled deletions are retried — so a bookmark removed on one device
  /// stays removed everywhere.
  Future<void> syncFromRemote() async {
    try {
      final outbox = _ref.read(syncOutboxDaoProvider);
      final pending = await outbox.getPendingKeys(_kOutboxTable);

      final deletedKeys = <String>{};
      for (final key in pending.where((k) => k.startsWith(_kDeletePrefix))) {
        final parts = key.substring(_kDeletePrefix.length).split(':');
        final surah = int.tryParse(parts.isNotEmpty ? parts[0] : '');
        final ayah = int.tryParse(parts.length > 1 ? parts[1] : '');
        if (surah == null || ayah == null) {
          await outbox.clearPending(_kOutboxTable, key);
          continue;
        }
        final bookmarkKey = _key(surah, ayah);
        deletedKeys.add(bookmarkKey);
        try {
          await _ref
              .read(supabaseServiceProvider)
              .deleteQuranBookmark(surah, ayah);
          await outbox.clearPending(_kOutboxTable, key);
          deletedKeys.remove(bookmarkKey);
        } catch (e) {
          developer.log(
            'Bookmark delete retry deferred to next sync: $e',
            name: 'QuranProviders',
          );
        }
      }

      final remote = await _ref
          .read(supabaseServiceProvider)
          .getQuranBookmarks();
      final remoteKeys = <String>{
        for (final r in remote)
          _key(r['surah_num'] as int, r['ayah_num'] as int),
      }..removeAll(deletedKeys);

      // Push bookmarks this device added while offline (they never reached
      // the remote, and nothing else in the app would ever send them).
      for (final b in state) {
        final key = _key(b.surahNum, b.ayahNum);
        if (!remoteKeys.contains(key) && !deletedKeys.contains(key)) {
          await _pushAdd(b);
        }
      }

      // Retry previously-failed add pushes for bookmarks still saved here.
      for (final key in pending.where((k) => !k.startsWith(_kDeletePrefix))) {
        final bookmark = state.cast<QuranBookmark?>().firstWhere(
          (b) => _key(b!.surahNum, b.ayahNum) == key,
          orElse: () => null,
        );
        if (bookmark == null) {
          await outbox.clearPending(_kOutboxTable, key);
        } else {
          await _pushAdd(bookmark);
        }
      }

      final merged = [...state];
      for (final r in remote) {
        final surahNum = r['surah_num'] as int;
        final ayahNum = r['ayah_num'] as int;
        final key = _key(surahNum, ayahNum);
        if (deletedKeys.contains(key) ||
            merged.any((x) => _key(x.surahNum, x.ayahNum) == key)) {
          continue;
        }
        merged.add(
          QuranBookmark(
            surahNum: surahNum,
            ayahNum: ayahNum,
            page: r['page'] as int,
            surahName: r['surah_name'] as String,
            savedAt: DateTime.tryParse(r['saved_at']?.toString() ?? ''),
          ),
        );
      }
      if (merged.length != state.length) {
        state = merged;
        await _repo.setBookmarks(state);
      }
    } catch (e) {
      developer.log(
        'Failed to sync remote quran bookmarks: $e',
        name: 'QuranProviders',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Khatma Notifier (extended)
// ─────────────────────────────────────────────────────────────
final khatmaExProvider =
    StateNotifierProvider<KhatmaExNotifier, KhatmaSessionEx?>(
      (ref) => KhatmaExNotifier(ref, ref.watch(quranPrefsRepositoryProvider)),
    );

class KhatmaExNotifier extends StateNotifier<KhatmaSessionEx?> {
  KhatmaExNotifier(this._ref, this._repo) : super(_repo.getActiveKhatma());

  final Ref _ref;
  final QuranPrefsRepository _repo;

  /// Outbox rows under this table: a bare session id is a failed progress
  /// push awaiting retry; `del:<id>` journals a session deleted while
  /// offline, so the next sync removes the remote row (and reconciles
  /// don't resurrect the local one) instead of silently losing the delete.
  static const _kOutboxTable = 'khatma_sessions';
  static const _kDeletePrefix = 'del:';

  final _push = _ThrottledPush(const Duration(seconds: 45));

  Future<void> _pushNow(KhatmaSessionEx session) async {
    _push.note();
    final outbox = _ref.read(syncOutboxDaoProvider);
    try {
      await _ref
          .read(supabaseServiceProvider)
          .upsertKhatmaSession(session.toRemoteRow());
      await outbox.clearPending(_kOutboxTable, session.id);
    } catch (e) {
      await outbox.markPending(_kOutboxTable, session.id, '$e');
      developer.log(
        'Khatma push failed, queued for retry: $e',
        name: 'QuranProviders',
      );
    }
  }

  void _queuePush(KhatmaSessionEx session) {
    _push.schedule(() => _pushNow(session));
  }

  /// Called when the reader closes so progress made inside the throttle
  /// window reaches Supabase without waiting for the next app start.
  Future<void> flushPendingPush() => _push.flush();

  Future<void> createNew({
    required String label,
    required KhatmaType type,
    required int startPage,
    bool notificationsEnabled = false,
    int? dailyPages,
    DateTime? endDate,
  }) async {
    KhatmaSessionEx? superseded;
    if (state != null && state!.isActive) {
      superseded = state;
      await _repo.archiveKhatma(superseded!);
    }
    final session = KhatmaSessionEx(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      type: type,
      startDate: DateTime.now(),
      endDate: endDate,
      startPage: startPage,
      currentPage: startPage,
      notificationsEnabled: notificationsEnabled,
      dailyPages: dailyPages,
    );
    state = session;
    await _repo.setActiveKhatma(session);
    if (superseded != null) await _pushNow(superseded);
    _push.cancel();
    await _pushNow(session);
  }

  Future<void> advancePage(int page) async {
    if (state == null) return;
    final newPagesRead = page > state!.currentPage
        ? state!.pagesRead + (page - state!.currentPage)
        : state!.pagesRead;
    final updated = state!.copyWith(
      currentPage: page,
      pagesRead: newPagesRead,
      completedDate: newPagesRead >= KhatmaSessionEx.totalPages
          ? DateTime.now()
          : null,
    );
    state = updated;
    await _repo.setActiveKhatma(updated);
    if (updated.isCompleted) {
      await _repo.archiveKhatma(updated);
      _push.cancel();
      await _pushNow(updated);
    } else {
      _queuePush(updated);
    }
  }

  Future<void> cancel() async {
    if (state == null) return;
    final cancelled = state!.copyWith(cancelledDate: DateTime.now());
    await _repo.archiveKhatma(cancelled);
    state = null;
    await _repo.clearActiveKhatma();
    _push.cancel();
    await _pushNow(cancelled);
  }

  /// Marks the active Khatma as finished regardless of pagesRead —
  /// distinct from the automatic completion in [advancePage] (which
  /// triggers only once every page has actually been read through the
  /// app). This is the "I finished reading from another source" path:
  /// user-declared, not derived from tracked pages.
  Future<void> markAsFinished() async {
    if (state == null) return;
    final finished = state!.copyWith(completedDate: DateTime.now());
    await _repo.archiveKhatma(finished);
    state = null;
    await _repo.clearActiveKhatma();
    _push.cancel();
    await _pushNow(finished);
  }

  /// Accumulates time spent actively reading toward this Khatma. Called
  /// once per reading session (see QuranReaderScreen's dispose), not per
  /// page, so "average reading time" means "average per sitting" rather
  /// than some fraction of a page.
  Future<void> addReadingTime(int seconds) async {
    if (state == null || seconds <= 0) return;
    final updated = state!.copyWith(
      totalReadingSeconds: state!.totalReadingSeconds + seconds,
      readingSessionsCount: state!.readingSessionsCount + 1,
    );
    state = updated;
    await _repo.setActiveKhatma(updated);
    _queuePush(updated);
  }

  @override
  void dispose() {
    _push.cancel();
    super.dispose();
  }

  /// Permanently removes a Khatma (usually a finished/cancelled history
  /// entry) from local storage and Supabase. Offline deletes are journaled
  /// so the row can't reappear on a later pull.
  Future<void> deleteSession(String id) async {
    await _repo.deleteFromHistory(id);
    if (state?.id == id) {
      state = null;
      await _repo.clearActiveKhatma();
    }
    // Discard a queued progress push first — pushing after the delete
    // would re-create the remote row through the upsert.
    _push.cancel();
    final outbox = _ref.read(syncOutboxDaoProvider);
    try {
      await _ref.read(supabaseServiceProvider).deleteKhatmaSession(id);
      await outbox.clearPending(_kOutboxTable, id);
    } catch (e) {
      await outbox.markPending(_kOutboxTable, '$_kDeletePrefix$id', '$e');
      developer.log(
        'Khatma delete deferred to next sync: $e',
        name: 'QuranProviders',
      );
    }
  }

  static bool _isMoreAdvanced(KhatmaSessionEx a, KhatmaSessionEx b) =>
      a.pagesRead > b.pagesRead ||
      (a.pagesRead == b.pagesRead && a.startDate.isAfter(b.startDate));

  /// Full two-way reconcile with `khatma_sessions` (called from
  /// SyncManager), so the merge converges no matter which device was
  /// offline:
  ///
  /// * journaled deletes are retried first and suppress their ids for the
  ///   rest of the pass (a row whose delete failed offline must not be
  ///   re-adopted from the pull);
  /// * sessions that exist only locally (created or archived while
  ///   offline) are pushed — this is what makes data survive a reinstall
  ///   or device switch even when the creating device never had a
  ///   successful live push;
  /// * failed progress pushes are retried from the latest local state;
  /// * finished/cancelled remote sessions go into local history, and a
  ///   session that ended on *this* device while offline is pushed
  ///   instead of being resurrected by its stale remote row;
  /// * at most one session stays active: when two devices both have one,
  ///   the furthest along wins and the other is archived as cancelled
  ///   (visible in history rather than an invisible zombie).
  Future<void> syncFromRemote() async {
    try {
      final outbox = _ref.read(syncOutboxDaoProvider);
      final pending = await outbox.getPendingKeys(_kOutboxTable);

      final deletedIds = <String>{};
      for (final key in pending.where((k) => k.startsWith(_kDeletePrefix))) {
        final id = key.substring(_kDeletePrefix.length);
        deletedIds.add(id);
        try {
          await _ref.read(supabaseServiceProvider).deleteKhatmaSession(id);
          await outbox.clearPending(_kOutboxTable, key);
          deletedIds.remove(id);
        } catch (e) {
          developer.log(
            'Khatma delete retry deferred to next sync: $e',
            name: 'QuranProviders',
          );
        }
      }

      final rows = await _ref.read(supabaseServiceProvider).getKhatmaSessions();
      final remote = <String, KhatmaSessionEx>{};
      for (final r in rows) {
        final id = r['id'];
        if (id is! String || deletedIds.contains(id)) continue;
        remote[id] = KhatmaSessionEx.fromRemoteRow(r);
      }

      final localHistory = _repo.getKhatmaHistory();
      final localById = <String, KhatmaSessionEx>{
        for (final s in localHistory) s.id: s,
      };
      final localActive = state;
      if (localActive != null) localById[localActive.id] = localActive;

      for (final entry in localById.entries) {
        if (!remote.containsKey(entry.key)) await _pushNow(entry.value);
      }

      for (final key in pending.where((k) => !k.startsWith(_kDeletePrefix))) {
        final session = localById[key];
        if (session == null) {
          await outbox.clearPending(_kOutboxTable, key);
        } else {
          await _pushNow(session);
        }
      }

      final activeCandidates = <String, KhatmaSessionEx>{};
      void consider(KhatmaSessionEx s) {
        final current = activeCandidates[s.id];
        if (current == null || _isMoreAdvanced(s, current)) {
          activeCandidates[s.id] = s;
        }
      }

      for (final s in remote.values) {
        if (!s.isActive) {
          await _repo.archiveKhatma(s);
          continue;
        }
        final localCopy = localById[s.id];
        if (localCopy != null && !localCopy.isActive) {
          // This session completed/was cancelled here while offline — the
          // local outcome is newer than the still-active remote row.
          await _pushNow(localCopy);
          continue;
        }
        consider(s);
      }
      if (localActive != null) {
        final remoteTwin = remote[localActive.id];
        if (remoteTwin == null || remoteTwin.isActive) consider(localActive);
        // A non-active remote twin was already archived above; the local
        // active copy is dropped after the reconcile below.
      }

      if (activeCandidates.isEmpty) {
        if (localActive != null &&
            remote.containsKey(localActive.id) &&
            !remote[localActive.id]!.isActive) {
          state = null;
          await _repo.clearActiveKhatma();
        }
        return;
      }

      var winner = activeCandidates.values.first;
      for (final candidate in activeCandidates.values) {
        if (_isMoreAdvanced(candidate, winner)) winner = candidate;
      }
      for (final entry in activeCandidates.entries) {
        if (entry.key == winner.id) continue;
        final loser = entry.value.copyWith(cancelledDate: DateTime.now());
        await _repo.archiveKhatma(loser);
        await _pushNow(loser);
        if (localActive?.id == loser.id) {
          state = null;
          await _repo.clearActiveKhatma();
        }
      }
      final needsAdopt =
          localActive == null ||
          localActive.id != winner.id ||
          localActive.pagesRead != winner.pagesRead ||
          localActive.currentPage != winner.currentPage;
      if (needsAdopt) {
        state = winner;
        await _repo.setActiveKhatma(winner);
      }
    } catch (e) {
      developer.log(
        'Failed to sync remote khatma sessions: $e',
        name: 'QuranProviders',
      );
    }
  }
}

// History providers
final khatmaCompletedProvider = FutureProvider<List<KhatmaSessionEx>>((
  ref,
) async {
  final history = ref.watch(quranPrefsRepositoryProvider).getKhatmaHistory();
  return history.where((s) => s.isCompleted).toList().reversed.toList();
});

final khatmaCancelledProvider = FutureProvider<List<KhatmaSessionEx>>((
  ref,
) async {
  final history = ref.watch(quranPrefsRepositoryProvider).getKhatmaHistory();
  return history.where((s) => s.isCancelled).toList().reversed.toList();
});

/// Permanently deletes one history entry (completed or cancelled) by id,
/// locally *and* in Supabase (journaling offline deletes) — deleting only
/// locally would let the entry reappear on the next pull or after a
/// reinstall. Callers must invalidate
/// khatmaCompletedProvider/khatmaCancelledProvider afterward.
final khatmaDeleteHistoryProvider = Provider<Future<void> Function(String)>(
  (ref) => (id) => ref.read(khatmaExProvider.notifier).deleteSession(id),
);

// ─────────────────────────────────────────────────────────────
// Reading-habit stats (from real daily_records rows)
// ─────────────────────────────────────────────────────────────

/// Aggregated reading-habit stats derived from real `daily_records` rows
/// (the same table the Stats/Prayer screens read), scoped to whatever a
/// Khatma progress screen needs: which recent days had Quran reading
/// logged (for the reading-days calendar), and the streaks/last-read date
/// that follow from that. Computed fresh on every watch rather than
/// cached — cheap (≤60 rows) and must reflect today's just-logged pages
/// immediately.
class KhatmaReadingStats {
  final Map<DateTime, int> pagesByDay; // date-only keys
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;

  const KhatmaReadingStats({
    required this.pagesByDay,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastReadDate,
  });

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

final khatmaReadingStatsProvider = FutureProvider<KhatmaReadingStats>((
  ref,
) async {
  final records = await ref.watch(dailyRecordDaoProvider).getLastNDays(60);
  final byDay = <DateTime, int>{
    for (final r in records)
      KhatmaReadingStats.dayOnly(r.date): r.quranPages,
  };

  final today = KhatmaReadingStats.dayOnly(DateTime.now());

  // Current streak: walk back from today, or from yesterday if today
  // simply hasn't been read yet — a day still in progress shouldn't zero
  // out an otherwise-intact streak.
  int currentStreak = 0;
  var cursor = (byDay[today] ?? 0) > 0
      ? today
      : today.subtract(const Duration(days: 1));
  while ((byDay[cursor] ?? 0) > 0) {
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Longest streak within the fetched 60-day window.
  int longestStreak = 0;
  int running = 0;
  for (int i = 59; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    if ((byDay[d] ?? 0) > 0) {
      running++;
      if (running > longestStreak) longestStreak = running;
    } else {
      running = 0;
    }
  }

  DateTime? lastRead;
  for (final entry in byDay.entries) {
    if (entry.value > 0 && (lastRead == null || entry.key.isAfter(lastRead))) {
      lastRead = entry.key;
    }
  }

  return KhatmaReadingStats(
    pagesByDay: byDay,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastReadDate: lastRead,
  );
});

// ─────────────────────────────────────────────────────────────
// Daily Verse
// ─────────────────────────────────────────────────────────────
// Bumped by the verse card's "refresh" button to pick a new random verse
// on demand. dailyVerseProvider is a plain Provider that Riverpod caches
// after the first read, so without depending on something that actually
// changes, tapping refresh (previously just a bare setState()) rebuilt the
// screen but kept returning the exact same cached verse.
final dailyVerseRefreshProvider = StateProvider<int>((ref) => 0);

final dailyVerseProvider = Provider<Map<String, dynamic>>((ref) {
  final refreshNonce = ref.watch(dailyVerseRefreshProvider);
  final surahs = ql.QuranLibrary.quranCtrl.surahs;
  final now = DateTime.now();
  final seed = now.year * 1000 + now.month * 30 + now.day + refreshNonce;
  final rng = Random(seed);
  final surahIdx = rng.nextInt(surahs.length);
  final surah = surahs[surahIdx];
  final ayahIdx = rng.nextInt(surah.ayahs.length);
  final ayah = surah.ayahs[ayahIdx];
  return {
    'surahName': surah.arabicName,
    'surahNumber': surahIdx + 1,
    'ayahNumber': ayah.ayahNumber,
    'text': ayah.text,
    // Included so the "»»" navigation and share button can jump straight
    // to this exact ayah instead of only the start of its surah.
    'page': ayah.page,
    'ayahUQNumber': ayah.ayahUQNumber,
  };
});
