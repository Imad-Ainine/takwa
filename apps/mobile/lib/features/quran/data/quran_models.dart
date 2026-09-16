enum ReaderMode { reading, tahajjud, tafseer, translation }

enum KhatmaType { muyassara, multazima }

enum ReaderTheme { night, sepia, white }

// ─── Reading State ───────────────────────────────────────────
class QuranReadingState {
  final int currentSurah;
  final int currentAyah;
  final int currentPage;
  final ReaderMode mode;
  final ReaderTheme theme;
  final double fontSize;
  final bool isPlaying;
  final int playingAyah;
  final double playbackSpeed;
  final bool showToolbar;

  const QuranReadingState({
    this.currentSurah = 1,
    this.currentAyah = 1,
    this.currentPage = 1,
    this.mode = ReaderMode.reading,
    this.theme = ReaderTheme.night,
    this.fontSize = 22.0,
    this.isPlaying = false,
    this.playingAyah = -1,
    this.playbackSpeed = 1.0,
    this.showToolbar = true,
  });

  QuranReadingState copyWith({
    int? currentSurah,
    int? currentAyah,
    int? currentPage,
    ReaderMode? mode,
    ReaderTheme? theme,
    double? fontSize,
    bool? isPlaying,
    int? playingAyah,
    double? playbackSpeed,
    bool? showToolbar,
  }) => QuranReadingState(
    currentSurah: currentSurah ?? this.currentSurah,
    currentAyah: currentAyah ?? this.currentAyah,
    currentPage: currentPage ?? this.currentPage,
    mode: mode ?? this.mode,
    theme: theme ?? this.theme,
    fontSize: fontSize ?? this.fontSize,
    isPlaying: isPlaying ?? this.isPlaying,
    playingAyah: playingAyah ?? this.playingAyah,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    showToolbar: showToolbar ?? this.showToolbar,
  );
}

// ─── Reciter Model ───────────────────────────────────────────
class QuranReciter {
  final String id;
  final String nameAr;
  final String nameEn;
  final String subfolder;

  const QuranReciter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.subfolder,
  });
}

const kDefaultReciters = <QuranReciter>[
  QuranReciter(
    id: 'ar.alafasy',
    nameAr: 'مشاري راشد العفاسي',
    nameEn: 'Mishary Alafasy',
    subfolder: 'ar.alafasy',
  ),
  QuranReciter(
    id: 'ar.abdulbasitmurattal',
    nameAr: 'عبد الباسط عبد الصمد (مرتل)',
    nameEn: 'Abdul Basit (Murattal)',
    subfolder: 'ar.abdulbasitmurattal',
  ),
  QuranReciter(
    id: 'ar.husary',
    nameAr: 'محمود خليل الحصري',
    nameEn: 'Mahmoud Khalil Al-Husary',
    subfolder: 'ar.husary',
  ),
  QuranReciter(
    id: 'ar.minshawi',
    nameAr: 'محمد صديق المنشاوي (مرتل)',
    nameEn: 'Mohamed Siddiq Al-Minshawi',
    subfolder: 'ar.minshawi',
  ),
  QuranReciter(
    id: 'ar.mahermuaiqly',
    nameAr: 'ماهر المعيقلي',
    nameEn: 'Maher Al-Muaiqly',
    subfolder: 'ar.mahermuaiqly',
  ),
  QuranReciter(
    id: 'ar.saadalghamidi',
    nameAr: 'سعد الغامدي',
    nameEn: 'Saad Al-Ghamdi',
    subfolder: 'ar.saadalghamidi',
  ),
  QuranReciter(
    id: 'ar.shaatree',
    nameAr: 'أبو بكر الشاطري',
    nameEn: 'Abu Bakr Al-Shatri',
    subfolder: 'ar.shaatree',
  ),
];

// ─── Audio State ─────────────────────────────────────────────
class QuranAudioState {
  final bool isPlaying, isLoading;
  // Set when the last playAyah() attempt failed (e.g. no network) so the UI
  // can surface it instead of looking like a silent no-op; cleared as soon
  // as a new play attempt starts.
  final bool hasError;
  final int surah, ayah;
  final double speed;
  final String reciterId;
  const QuranAudioState({
    this.isPlaying = false,
    this.isLoading = false,
    this.hasError = false,
    this.surah = 1,
    this.ayah = 1,
    this.speed = 1.0,
    this.reciterId = 'ar.alafasy',
  });
  QuranAudioState copyWith({
    bool? isPlaying,
    bool? isLoading,
    bool? hasError,
    int? surah,
    int? ayah,
    double? speed,
    String? reciterId,
  }) => QuranAudioState(
    isPlaying: isPlaying ?? this.isPlaying,
    isLoading: isLoading ?? this.isLoading,
    hasError: hasError ?? this.hasError,
    surah: surah ?? this.surah,
    ayah: ayah ?? this.ayah,
    speed: speed ?? this.speed,
    reciterId: reciterId ?? this.reciterId,
  );
}

// ─── Bookmark ────────────────────────────────────────────────
class QuranBookmark {
  final int surahNum, ayahNum, page;
  final String surahName;
  final DateTime? savedAt;

  const QuranBookmark({
    required this.surahNum,
    required this.ayahNum,
    required this.page,
    required this.surahName,
    this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'surahNum': surahNum,
    'ayahNum': ayahNum,
    'page': page,
    'surahName': surahName,
    'savedAt': savedAt?.toIso8601String(),
  };

  factory QuranBookmark.fromJson(Map<String, dynamic> j) => QuranBookmark(
    surahNum: j['surahNum'] as int,
    ayahNum: j['ayahNum'] as int,
    page: j['page'] as int? ?? 0,
    surahName: j['surahName'] as String,
    savedAt: j['savedAt'] != null
        ? DateTime.tryParse(j['savedAt'].toString())
        : null,
  );
}

// ─── Khatma (extended) session ─────────────────────────────────
class KhatmaSessionEx {
  final String id;
  final String label;
  final KhatmaType type;
  final DateTime startDate;
  final DateTime? endDate; // target end date for multazima
  final DateTime? completedDate;
  final DateTime? cancelledDate;
  final int startPage;
  final int currentPage;
  final int pagesRead;
  final bool notificationsEnabled;
  final int? dailyPages; // for multazima
  final int totalReadingSeconds;
  final int readingSessionsCount;
  static const int totalPages = 604;

  const KhatmaSessionEx({
    required this.id,
    required this.label,
    required this.type,
    required this.startDate,
    this.endDate,
    this.completedDate,
    this.cancelledDate,
    this.startPage = 1,
    this.currentPage = 1,
    this.pagesRead = 0,
    this.notificationsEnabled = false,
    this.dailyPages,
    this.totalReadingSeconds = 0,
    this.readingSessionsCount = 0,
  });

  double get progress => pagesRead / totalPages;
  bool get isCompleted => completedDate != null || pagesRead >= totalPages;
  bool get isCancelled => cancelledDate != null;
  bool get isActive => !isCompleted && !isCancelled;

  /// Rough estimate of the reward ("حسنات") this Khatma's progress is
  /// worth, following the same "10 hasanat per letter" convention other
  /// Quran apps use for this kind of estimator — the Quran is
  /// conventionally cited at ~334,343 hasanat-bearing units for that
  /// calculation, scaled here per page (604 total) and by pages actually
  /// read. Explicitly an estimate, labeled as such in the UI — not a
  /// precise count.
  static const int _estimatedTotalHasanat = 3343430;
  int get estimatedHasanat =>
      (pagesRead * _estimatedTotalHasanat / totalPages).round();

  KhatmaSessionEx copyWith({
    int? currentPage,
    int? pagesRead,
    DateTime? completedDate,
    DateTime? cancelledDate,
    String? label,
    int? totalReadingSeconds,
    int? readingSessionsCount,
  }) => KhatmaSessionEx(
    id: id,
    label: label ?? this.label,
    type: type,
    startDate: startDate,
    endDate: endDate,
    completedDate: completedDate ?? this.completedDate,
    cancelledDate: cancelledDate ?? this.cancelledDate,
    startPage: startPage,
    currentPage: currentPage ?? this.currentPage,
    pagesRead: pagesRead ?? this.pagesRead,
    notificationsEnabled: notificationsEnabled,
    dailyPages: dailyPages,
    totalReadingSeconds: totalReadingSeconds ?? this.totalReadingSeconds,
    readingSessionsCount: readingSessionsCount ?? this.readingSessionsCount,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
    'cancelledDate': cancelledDate?.toIso8601String(),
    'startPage': startPage,
    'currentPage': currentPage,
    'pagesRead': pagesRead,
    'notificationsEnabled': notificationsEnabled,
    'dailyPages': dailyPages,
    'totalReadingSeconds': totalReadingSeconds,
    'readingSessionsCount': readingSessionsCount,
  };

  factory KhatmaSessionEx.fromJson(Map<String, dynamic> j) => KhatmaSessionEx(
    id: j['id'] as String,
    label: j['label'] as String? ?? 'ختمة',
    type: KhatmaType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => KhatmaType.muyassara,
    ),
    startDate: DateTime.parse(j['startDate'].toString()),
    endDate: j['endDate'] != null
        ? DateTime.tryParse(j['endDate'].toString())
        : null,
    completedDate: j['completedDate'] != null
        ? DateTime.tryParse(j['completedDate'].toString())
        : null,
    cancelledDate: j['cancelledDate'] != null
        ? DateTime.tryParse(j['cancelledDate'].toString())
        : null,
    startPage: j['startPage'] as int? ?? 1,
    currentPage: j['currentPage'] as int? ?? 1,
    pagesRead: j['pagesRead'] as int? ?? 0,
    notificationsEnabled: j['notificationsEnabled'] as bool? ?? false,
    dailyPages: j['dailyPages'] as int?,
    totalReadingSeconds: j['totalReadingSeconds'] as int? ?? 0,
    readingSessionsCount: j['readingSessionsCount'] as int? ?? 0,
  );
}

// ─── Daily Reading Log ───────────────────────────────────────
class DailyReadingEntry {
  final DateTime date;
  final int pagesRead;
  const DailyReadingEntry({required this.date, required this.pagesRead});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'pagesRead': pagesRead,
  };
  factory DailyReadingEntry.fromJson(Map<String, dynamic> j) =>
      DailyReadingEntry(
        date: DateTime.parse(j['date'].toString()),
        pagesRead: j['pagesRead'] as int? ?? 0,
      );
}
