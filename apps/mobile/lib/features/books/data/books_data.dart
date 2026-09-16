// ─────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────

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
      index: json['index'] ?? 0,
      titleAr: json['title_ar'] ?? '',
      pages: (json['pages'] as List? ?? [])
          .map((p) => BookPage.fromJson(p))
          .toList(),
      intro: json['intro'],
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
    return BookPage(
      index: json['index'] ?? 0,
      content: json['content'] ?? '',
      title: json['title'],
      isHadith: json['is_hadith'] ?? false,
      hadithNumber: json['hadith_number'].toString(),
      source: json['source'],
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
      id: json['id'].toString(),
      titleAr: json['title_ar'] ?? '',
      titleEn: json['title_en'] ?? '',
      authorAr: json['author_ar'] ?? '',
      authorEn: json['author_en'] ?? '',
      descriptionAr: json['description_ar'] ?? '',
      emoji: json['emoji'] ?? '📚',
      category: BookCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BookCategory.hadith,
      ),
      chapters: (json['chapters'] as List? ?? [])
          .map((c) => BookChapter.fromJson(c))
          .toList(),
      coverUrl: json['cover_url'],
      pdfUrl: json['pdf_url'],
      publishYear: json['publish_year'] ?? 0,
      coverColor: json['cover_color'] ?? '0xFFC8A96E',
      coverColor2: json['cover_color_2'] ?? '0xFF3AAFA9',
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
}

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
