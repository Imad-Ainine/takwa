// ─────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────

import 'package:flutter/painting.dart';

/// Parses a book accent colour coming from either Dart literal (`0xFF…`) or
/// web (`#RRGGBB` / `RRGGBB`) notation. Server-authored rows use the web form,
/// so every call site must not re-implement this — most of the earlier copies
/// silently fell back to gold on `#`-prefixed values.
Color bookColorFromHex(String? hex, {Color fallback = const Color(0xFFC8A96E)}) {
  if (hex == null) return fallback;
  final value = hex.trim();
  if (value.isEmpty) return fallback;
  final body = value.startsWith('#') ? value.substring(1) : value;
  if (body.startsWith('0x')) return _tryColor(int.tryParse(body) ?? 0, fallback);
  // 6-digit web hex has no alpha channel; promote to opaque.
  final normalized = body.length == 6 ? 'FF$body' : body;
  return _tryColor(int.tryParse(normalized, radix: 16) ?? 0, fallback);
}

Color _tryColor(int value, Color fallback) =>
    value == 0 ? fallback : Color(value);

enum BookCategory {
  hadith, // الحديث
  fiqh, // الفقه
  seerah, // السيرة
  aqeedah, // العقيدة
  adab, // الآداب والأخلاق
  tazkiyah, // التزكية
  quran, // علوم القرآن
}

class BookChapter {
  final int index;
  final String titleAr;
  final List<BookPage> pages;
  final String? intro;

  const BookChapter({
    required this.index,
    required this.titleAr,
    required this.pages,
    this.intro,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    return BookChapter(
      index: _asInt(json['index']),
      titleAr: _asString(json['title_ar']),
      pages: (json['pages'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BookPage.fromJson)
          .toList(),
      intro: json['intro'] is String ? json['intro'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'title_ar': titleAr,
    'pages': pages.map((p) => p.toJson()).toList(),
    'intro': intro,
  };

  int get totalPages => pages.length;
  int get estimatedMinutes =>
      (pages.fold<int>(0, (sum, p) => sum + p.content.split(' ').length) ~/ 200)
          .clamp(1, 999);
}

class BookPage {
  final int index;
  final String content;
  final String? title;
  final bool isHadith;
  final String? hadithNumber;
  final String? source;

  const BookPage({
    required this.index,
    required this.content,
    this.title,
    this.isHadith = false,
    this.hadithNumber,
    this.source,
  });

  factory BookPage.fromJson(Map<String, dynamic> json) {
    // `hadith_number` used to go through `.toString()`, which turned a
    // missing value into the literal string "null" and rendered a "null"
    // badge on every non-hadith page.
    final hadithNumber = json['hadith_number'];
    return BookPage(
      index: _asInt(json['index']),
      content: _asString(json['content']),
      title: json['title'] is String ? json['title'] as String : null,
      isHadith: json['is_hadith'] == true,
      hadithNumber: hadithNumber == null ? null : '$hadithNumber',
      source: json['source'] is String ? json['source'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'content': content,
    'title': title,
    'is_hadith': isHadith,
    'hadith_number': hadithNumber,
    'source': source,
  };
}

class IslamicBook {
  final String id;
  final String titleAr;
  final String titleEn;
  final String authorAr;
  final String authorEn;
  final String descriptionAr;
  final String emoji;
  final BookCategory category;
  final List<BookChapter> chapters;
  final String? coverUrl;
  final String? pdfUrl;
  final int publishYear; // hijri
  final String coverColor; // hex
  final String coverColor2;

  const IslamicBook({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.authorAr,
    required this.authorEn,
    required this.descriptionAr,
    required this.emoji,
    required this.category,
    this.chapters = const [],
    this.coverUrl,
    this.pdfUrl,
    required this.publishYear,
    required this.coverColor,
    required this.coverColor2,
  });

  factory IslamicBook.fromJson(Map<String, dynamic> json) {
    return IslamicBook(
      id: json['id']?.toString() ?? '',
      titleAr: _asString(json['title_ar']),
      titleEn: _asString(json['title_en']),
      authorAr: _asString(json['author_ar']),
      authorEn: _asString(json['author_en']),
      descriptionAr: _asString(json['description_ar']),
      emoji: json['emoji'] is String && (json['emoji'] as String).isNotEmpty
          ? json['emoji'] as String
          : '📚',
      category: BookCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BookCategory.hadith,
      ),
      chapters: (json['chapters'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BookChapter.fromJson)
          .toList(),
      coverUrl: _asNonEmptyString(json['cover_url']),
      pdfUrl: _asNonEmptyString(json['pdf_url']),
      publishYear: _asInt(json['publish_year']),
      coverColor: json['cover_color'] is String
          ? json['cover_color'] as String
          : '0xFFC8A96E',
      coverColor2: json['cover_color_2'] is String
          ? json['cover_color_2'] as String
          : '0xFF3AAFA9',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title_ar': titleAr,
    'title_en': titleEn,
    'author_ar': authorAr,
    'author_en': authorEn,
    'description_ar': descriptionAr,
    'emoji': emoji,
    'category': category.name,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'cover_url': coverUrl,
    'pdf_url': pdfUrl,
    'publish_year': publishYear,
    'cover_color': coverColor,
    'cover_color_2': coverColor2,
  };

  int get totalPages => chapters.fold<int>(0, (sum, c) => sum + c.totalPages);

  int get estimatedReadingMinutes =>
      chapters.fold<int>(0, (sum, c) => sum + c.estimatedMinutes);

  String get categoryLabel => switch (category) {
    BookCategory.hadith => 'الحديث',
    BookCategory.fiqh => 'الفقه',
    BookCategory.seerah => 'السيرة',
    BookCategory.aqeedah => 'العقيدة',
    BookCategory.adab => 'الآداب',
    BookCategory.tazkiyah => 'التزكية',
    BookCategory.quran => 'علوم القرآن',
  };

  /// Whether the built-in text reader can render anything at all. Most rows
  /// in the remote `books` table are PDF-only (or metadata-only), and opening
  /// the reader on them used to index into an empty `chapters` list and crash
  /// the route with a RangeError.
  bool get hasReadableText => chapters.any((c) => c.pages.isNotEmpty);

  /// What the reader can offer: a full PDF, inline text, both, or neither.
  BookFormat get format {
    final pdf = pdfUrl != null && pdfUrl!.isNotEmpty;
    if (pdf && hasReadableText) return BookFormat.pdfAndText;
    if (pdf) return BookFormat.pdf;
    return hasReadableText ? BookFormat.text : BookFormat.none;
  }

  /// Accent colour for covers, app bars and the reader chrome.
  Color get accentColor => bookColorFromHex(coverColor);

  /// Second stop of the cover gradient.
  Color get secondaryColor => bookColorFromHex(coverColor2);
}

/// How a book can be opened.
enum BookFormat { none, text, pdf, pdfAndText }

/// Colour mode of the inline reader. Declared here because it is persisted by
/// [BookPrefsRepository] and read back before any screen exists.
enum ReaderTheme { light, sepia, dark }

int _asInt(Object? value) => switch (value) {
  final int i => i,
  final num n => n.toInt(),
  final String s => int.tryParse(s.trim()) ?? 0,
  _ => 0,
};

String _asString(Object? value) => value is String ? value : '';

String? _asNonEmptyString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

// ─────────────────────────────────────────
//  BOOK 1: الأربعون النووية
// ─────────────────────────────────────────
const _arbaounNawawiyya = IslamicBook(
  id: 'arboun_nawawi',
  titleAr: 'الأربعون النووية',
  titleEn: 'The Forty Hadith of Imam al-Nawawi',
  authorAr: 'الإمام يحيى بن شرف النووي',
  authorEn: 'Imam al-Nawawi',
  descriptionAr:
      'مجموعة من أهم الأحاديث النبوية الشريفة، جمعها الإمام النووي رحمه الله، وهي تمثل أسس الإسلام وأركانه، تشمل مواضيع شتى من العقيدة والعبادات والمعاملات والأخلاق.',
  emoji: '📜',
  category: BookCategory.hadith,
  publishYear: 631,
  coverColor: '0xFFC8A96E',
  coverColor2: '0xFF3AAFA9',
  coverUrl:
      'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1381021768i/6740315.jpg', // Sample real cover
  // Hosted in the `book-pdfs` Supabase Storage bucket — see the Security &
  // Privacy audit (2026-09-06): this used to point at islamhouse.com and
  // needed a spoofed desktop User-Agent to get past its anti-bot checks.
  // Same PDF, verified byte-identical before the move.
  pdfUrl:
      'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/arboun_nawawi.pdf',
);

// ─────────────────────────────────────────
//  BOOK 2: رياض الصالحين
// ─────────────────────────────────────────
const _riyadhSalihin = IslamicBook(
  id: 'riyad_salihin',
  titleAr: 'رياض الصالحين',
  titleEn: 'Gardens of the Righteous',
  authorAr: 'الإمام يحيى بن شرف النووي',
  authorEn: 'Imam al-Nawawi',
  descriptionAr:
      'كتاب جامع للآيات القرآنية والأحاديث النبوية الشريفة في ترقية النفوس وتزكيتها والسمو بها نحو الكمال، مرتب على أبواب من الآداب والأخلاق والعبادات.',
  emoji: '🌿',
  category: BookCategory.adab,
  publishYear: 670,
  coverColor: '0xFF2E7D32',
  coverColor2: '0xFFC8A96E',
  coverUrl:
      'https://www.noor-book.com/publice/covers_cache_webp/3/b/6/2/277b87d65ab623e3b228d355b7322ae6.jpg.webp',
  // See the note on _arbaounNawawiyya above — same Storage-hosted change.
  pdfUrl:
      'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/riyad_salihin.pdf',
);

// ─────────────────────────────────────────
//  BOOK 3: زاد المعاد
// ─────────────────────────────────────────
const _zadAlMaad = IslamicBook(
  id: 'zad_al_maad_4',
  titleAr: 'زاد المعاد المجلد الرابع',
  titleEn: 'Provisions for the Hereafter Vol 4',
  authorAr: 'الإمام ابن قيم الجوزية',
  authorEn: 'Ibn Qayyim al-Jawziyyah',
  descriptionAr:
      'كتاب نفيس في السيرة النبوية وهَدي النبي ﷺ في عباداته ومعاملاته وأحكامه، يجمع بين الفقه والسيرة في أسلوب علمي رائع.',
  emoji: '🏹',
  category: BookCategory.seerah,
  publishYear: 751,
  coverColor: '0xFF1565C0',
  coverColor2: '0xFFC8A96E',
  coverUrl:
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTSZge4_YviGc-FhpZ5O4YRV1t_9Nmuqw16gQ&s',
  // See the note on _arbaounNawawiyya above — same Storage-hosted change.
  pdfUrl:
      'https://fmmgiykwebwruhxeztvs.supabase.co/storage/v1/object/public/book-pdfs/zad_al_maad_4.pdf',
);

// ─────────────────────────────────────────
//  BOOKS REGISTRY
// ─────────────────────────────────────────
const kIslamicBooks = <IslamicBook>[
  _arbaounNawawiyya,
  _riyadhSalihin,
  _zadAlMaad,
];

IslamicBook? findBook(String id) {
  try {
    return kIslamicBooks.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}
