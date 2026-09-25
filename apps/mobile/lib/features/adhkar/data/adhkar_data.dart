/// Adhkar = the authenticated litanies (أوراد) and dhikr said at a given time
/// or occasion: on waking, morning, evening, after the prayers, before sleep,
/// at home, travelling, eating, and on leaving a gathering. Supplications that
/// are asked *of* Allah for a need (dua) live in
/// `features/duas/data/duas_data.dart` instead.
///
/// Texts follow Ḥiṣn al-Muslim (Saʿīd ibn ʿAlī al-Qaḥṭānī) and the six books;
/// `source` names the book as printed there, and `fadl` is the virtue from the
/// same narration — never invented.
///
/// ⚠️ `id` is stable public API: users' favorites are persisted as a set of
/// these ints (`favorite_adhkar` in SharedPreferences, synced to Supabase).
/// Never renumber or reuse an existing id — new items take the next free id in
/// their category's block. Moving an item to a different category is safe.
enum AdhkarCategory {
  wakingUp,
  morning,
  evening,
  afterPrayer,
  sleep,

  /// Ids 7xx — entering and leaving the home.
  home,

  /// Ids 8xx — riding and travelling, outward and return.
  travel,
  food,

  /// Ids 9xx — the expiation of the gathering, said as it breaks up.
  gathering,

  /// Ids 6xx. Keep this value last: it is the fallback bucket for content
  /// whose occasion is not time- or event-bound, and several callers do
  /// `kAdhkarData[cat] ?? kAdhkarData[AdhkarCategory.misc]`.
  misc,
}

/// Every dhikr in one flat list, in category order.
List<DhikrItem> get kAllAdhkar => kAdhkarData.values.expand((l) => l).toList();

/// Display name and icon for a category, in Arabic.
///
/// Single source of truth: before this existed, four separate switches mapped
/// the same enum to four slightly different Arabic strings (and the adhkar
/// screen's tab labels were in a *different order* from
/// `AdhkarCategory.values`, so every tab showed the wrong content). Localized
/// tab labels go through `AppLocalizations.adhkarTab*` in the screens that
/// have a context; this is the fallback for the background isolate and the
/// notification builders, which have no locale.
extension AdhkarCategoryLabel on AdhkarCategory {
  String get arabicLabel => switch (this) {
    AdhkarCategory.wakingUp => 'أذكار الاستيقاظ',
    AdhkarCategory.morning => 'أذكار الصباح',
    AdhkarCategory.evening => 'أذكار المساء',
    AdhkarCategory.afterPrayer => 'أذكار ما بعد الصلاة',
    AdhkarCategory.sleep => 'أذكار النوم',
    AdhkarCategory.home => 'أذكار المنزل',
    AdhkarCategory.travel => 'أذكار السفر',
    AdhkarCategory.food => 'أذكار الطعام',
    AdhkarCategory.gathering => 'أذكار المجلس',
    AdhkarCategory.misc => 'أذكار متنوعة',
  };

  String get emoji => switch (this) {
    AdhkarCategory.wakingUp => '☀️',
    AdhkarCategory.morning => '🌅',
    AdhkarCategory.evening => '🌆',
    AdhkarCategory.afterPrayer => '🕌',
    AdhkarCategory.sleep => '🌙',
    AdhkarCategory.home => '🏠',
    AdhkarCategory.travel => '🧳',
    AdhkarCategory.food => '🍽️',
    AdhkarCategory.gathering => '👥',
    AdhkarCategory.misc => '📿',
  };
}

class DhikrItem {
  final int id;
  final String arabic;

  /// Used as a short label for the item when the dhikr is better known by a
  /// name than by its opening words — e.g. 'آية الكرسي', 'سيد الاستغفار'.
  final String? transliteration;
  final String? fadl; // الفضل والفائدة
  final String? source; // المصدر
  final int count; // عدد التكرار
  final AdhkarCategory category;

  const DhikrItem({
    required this.id,
    required this.arabic,
    required this.count,
    required this.category,
    this.transliteration,
    this.fadl,
    this.source,
  });
}

/// Ayat al-Kursi, written out in full everywhere it is said (morning, evening,
/// after every prayer, before sleep) rather than abbreviated to
/// 'قراءة آية الكرسي' — an item that tells the user to read something without
/// giving them the text is not a dhikr they can actually say.
const String _ayatAlKursi =
    'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\n'
    'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ '
    'وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا '
    'الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ '
    'وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ '
    'ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ '
    'وَهُوَ الْعَلِيُّ الْعَظِيمُ';

/// The Muʿawwidhāt (al-Ikhlāṣ, al-Falaq, an-Nās) in full.
const String _alMuawwidhat =
    'قُلْ هُوَ اللَّهُ أَحَدٌ * اللَّهُ الصَّمَدُ * لَمْ يَلِدْ وَلَمْ يُولَدْ * '
    'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ\n\n'
    'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ * مِن شَرِّ مَا خَلَقَ * وَمِن شَرِّ غَاسِقٍ '
    'إِذَا وَقَبَ * وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ * وَمِن شَرِّ حَاسِدٍ '
    'إِذَا حَسَدَ\n\n'
    'قُلْ أَعُوذُ بِرَبِّ النَّاسِ * مَلِكِ النَّاسِ * إِلَٰهِ النَّاسِ * مِن '
    'شَرِّ الْوَسْوَاسِ الْخَنَّاسِ * الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ * '
    'مِنَ الْجِنَّةِ وَالنَّاسِ';

const String _sayyidAlIstighfar =
    'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، '
    'وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا '
    'صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي '
    'فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ';

const String _bismillahAlladhiLaYadurru =
    'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي '
    'السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ';

const kAdhkarData = <AdhkarCategory, List<DhikrItem>>{
  // ────────────── أذكار الاستيقاظ من النوم ──────────────
  AdhkarCategory.wakingUp: [
    DhikrItem(
      id: 1,
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      count: 1,
      category: AdhkarCategory.wakingUp,
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 2,
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ، رَبِّ اغْفِرْ لِي',
      count: 1,
      category: AdhkarCategory.wakingUp,
      fadl: 'من قالها غُفر له، وإن دعا استُجيب له، وإن توضأ وصلى قُبلت صلاته',
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 3,
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي عَافَانِي فِي جَسَدِي، وَرَدَّ عَلَيَّ رُوحِي، وَأَذِنَ لِي بِذِكْرِهِ',
      count: 1,
      category: AdhkarCategory.wakingUp,
      source: 'سنن الترمذي — حسن',
    ),
    DhikrItem(
      id: 4,
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَكَفَانَا وَآوَانَا، فَكَمْ مِمَّنْ لَا كَافِيَ لَهُ وَلَا مُؤْوِيَ',
      count: 1,
      category: AdhkarCategory.wakingUp,
      fadl: 'يقال عند التعار من الليل، أي الاستيقاظ المفاجئ',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 5,
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
      count: 1,
      category: AdhkarCategory.wakingUp,
      transliteration: 'ذكر من تقلّب في فراشه ليلاً',
      fadl: 'من تقلّب من الليل فقالها ثم قام فتوضأ وصلى، قُبلت صلاته',
      source: 'صحيح البخاري',
    ),
  ],

  // ────────────── أذكار الصباح ──────────────
  // Said between Fajr and sunrise; the evening list below is its mirror with
  // 'أمسينا' in place of 'أصبحنا', so the two stay in step.
  AdhkarCategory.morning: [
    DhikrItem(
      id: 101,
      arabic: _ayatAlKursi,
      count: 1,
      category: AdhkarCategory.morning,
      transliteration: 'آية الكرسي',
      fadl: 'من قرأها حين يصبح أُجير من الجن حتى يمسي',
      source: 'صحيح الترغيب والترهيب',
    ),
    DhikrItem(
      id: 102,
      arabic: _alMuawwidhat,
      count: 3,
      category: AdhkarCategory.morning,
      transliteration: 'المعوذات',
      fadl: 'من قرأها حين يصبح وكفت من كل شيء',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 103,
      arabic:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
      count: 1,
      category: AdhkarCategory.morning,
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 104,
      arabic:
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
      count: 1,
      category: AdhkarCategory.morning,
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 105,
      arabic: _sayyidAlIstighfar,
      count: 1,
      category: AdhkarCategory.morning,
      transliteration: 'سيد الاستغفار',
      fadl: 'من قالها موقناً بها فمات من يومه دخل الجنة',
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 106,
      arabic:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
      count: 1,
      category: AdhkarCategory.morning,
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 107,
      arabic:
          'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ. اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ، وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَٰهَ إِلَّا أَنْتَ',
      count: 3,
      category: AdhkarCategory.morning,
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 108,
      arabic: _bismillahAlladhiLaYadurru,
      count: 3,
      category: AdhkarCategory.morning,
      fadl: 'لم يضره شيء',
      source: 'سنن أبي داود والترمذي — صحيح',
    ),
    DhikrItem(
      id: 109,
      arabic:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
      count: 3,
      category: AdhkarCategory.morning,
      fadl: 'كان حقاً على الله أن يرضيه يوم القيامة',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 110,
      arabic:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      count: 1,
      category: AdhkarCategory.morning,
      source: 'السنن الكبرى للنسائي — صحيح',
    ),
    DhikrItem(
      id: 111,
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      count: 100,
      category: AdhkarCategory.morning,
      fadl: 'من قالها مئة مرة حُطَّت خطاياه وإن كانت مثل زبد البحر',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 112,
      arabic:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
      count: 3,
      category: AdhkarCategory.morning,
      fadl: 'كلماتٌ تعدل أضعافاً مضاعفة من التسبيح',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 113,
      arabic:
          'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      count: 7,
      category: AdhkarCategory.morning,
      fadl:
          'من قالها حين يصبح وحين يمسي كفاه الله ما أهمّه من أمر الدنيا والآخرة',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 114,
      arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      count: 3,
      category: AdhkarCategory.morning,
      fadl: 'لم يضره شيء حتى يرتحل من منزله ذلك',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 115,
      arabic:
          'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَشَرِّ الشَّيْطَانِ وَشِرْكِهِ',
      count: 1,
      category: AdhkarCategory.morning,
      transliteration: 'دعاء صباح ومساء',
      fadl: 'قاله حين يصبح وحين يمسي وحين يصبح، أمره الله نبيَّه أن يقوله',
      source: 'سنن أبي داود والترمذي — حسن',
    ),
    DhikrItem(
      id: 116,
      arabic:
          'أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
      count: 1,
      category: AdhkarCategory.morning,
      source: 'مسند أحمد',
    ),
  ],

  // ────────────── أذكار المساء ──────────────
  // Said between Asr and sunset (the preferred time), or after Maghrib.
  AdhkarCategory.evening: [
    DhikrItem(
      id: 201,
      arabic: _ayatAlKursi,
      count: 1,
      category: AdhkarCategory.evening,
      transliteration: 'آية الكرسي',
      fadl: 'من قرأها حين يمسي أُجير من الجن حتى يصبح',
      source: 'صحيح الترغيب والترهيب',
    ),
    DhikrItem(
      id: 202,
      arabic: _alMuawwidhat,
      count: 3,
      category: AdhkarCategory.evening,
      transliteration: 'المعوذات',
      fadl: 'تكفيك من كل شيء',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 203,
      arabic:
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
      count: 1,
      category: AdhkarCategory.evening,
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 204,
      arabic:
          'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
      count: 1,
      category: AdhkarCategory.evening,
      source: 'سنن الترمذي — صحيح',
    ),
    DhikrItem(
      id: 205,
      arabic: _sayyidAlIstighfar,
      count: 1,
      category: AdhkarCategory.evening,
      transliteration: 'سيد الاستغفار',
      fadl: 'من قالها موقناً بها فمات من ليلته دخل الجنة',
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 206,
      arabic:
          'اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَٰهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ',
      count: 4,
      category: AdhkarCategory.evening,
      fadl: 'من قالها أعتقه الله من النار',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 207,
      arabic: _bismillahAlladhiLaYadurru,
      count: 3,
      category: AdhkarCategory.evening,
      fadl: 'لم يضره شيء',
      source: 'سنن أبي داود والترمذي — صحيح',
    ),
    DhikrItem(
      id: 208,
      arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      count: 3,
      category: AdhkarCategory.evening,
      fadl: 'لم يضره شيء في تلك الليلة',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 209,
      arabic:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
      count: 1,
      category: AdhkarCategory.evening,
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 210,
      arabic:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
      count: 3,
      category: AdhkarCategory.evening,
      fadl: 'كان حقاً على الله أن يرضيه يوم القيامة',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 211,
      arabic:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      count: 1,
      category: AdhkarCategory.evening,
      source: 'السنن الكبرى للنسائي — صحيح',
    ),
    DhikrItem(
      id: 212,
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      count: 100,
      category: AdhkarCategory.evening,
      fadl:
          'لم يأتِ أحد يوم القيامة بأفضل مما جاء به إلا أحد قال مثل ما قال أو زاد',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 213,
      arabic:
          'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      count: 7,
      category: AdhkarCategory.evening,
      fadl: 'كفاه الله ما أهمّه من أمر الدنيا والآخرة',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 214,
      arabic:
          'أَعُوذُ بِوَجْهِ اللَّهِ الْكَرِيمِ، وَكَلِمَاتِ اللَّهِ التَّامَّاتِ الَّتِي لَا يُجَاوِزُهُنَّ بَرٌّ وَلَا بَحْرٌ، مِنْ شَرِّ مَا يَنْزِلُ مِنَ السَّمَاءِ، وَمِنْ شَرِّ مَا يَعْرُجُ فِيهَا، وَمِنْ شَرِّ مَا ذَرَأَ فِي الْأَرْضِ، وَمِنْ شَرِّ مَا يَخْرُجُ مِنْهَا، وَمِنْ شَرِّ فِتَنِ اللَّيْلِ وَالنَّهَارِ، وَمِنْ شَرِّ كُلِّ طَارِقٍ إِلَّا طَارِقًا يَطْرُقُ بِخَيْرٍ يَا رَحْمَنُ',
      count: 3,
      category: AdhkarCategory.evening,
      source: 'مسند أحمد — صحيح',
    ),
    DhikrItem(
      id: 215,
      arabic:
          'أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
      count: 1,
      category: AdhkarCategory.evening,
      source: 'مسند أحمد',
    ),
  ],

  // ────────────── أذكار بعد الصلاة ──────────────
  // The threefold tasbih is split into one item per phrase so the tap counter
  // in the adhkar screen can track 33/33/34 instead of guessing.
  AdhkarCategory.afterPrayer: [
    DhikrItem(
      id: 301,
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      count: 3,
      category: AdhkarCategory.afterPrayer,
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 302,
      arabic:
          'اللَّهُمَّ أَنْتَ السَّلَامُ، وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      count: 1,
      category: AdhkarCategory.afterPrayer,
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 303,
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
      count: 1,
      category: AdhkarCategory.afterPrayer,
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 304,
      arabic:
          'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ، وَشُكْرِكَ، وَحُسْنِ عِبَادَتِكَ',
      count: 1,
      category: AdhkarCategory.afterPrayer,
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 305,
      arabic: 'سُبْحَانَ اللَّهِ',
      count: 33,
      category: AdhkarCategory.afterPrayer,
      transliteration: 'تسبيح دبر كل صلاة',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 306,
      arabic: 'الْحَمْدُ لِلَّهِ',
      count: 33,
      category: AdhkarCategory.afterPrayer,
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 307,
      arabic: 'اللَّهُ أَكْبَرُ',
      count: 33,
      category: AdhkarCategory.afterPrayer,
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 308,
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      count: 1,
      category: AdhkarCategory.afterPrayer,
      transliteration: 'تمام المئة بعد التسبيح',
      fadl: 'غُفرت ذنوبه وإن كانت مثل زبد البحر',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 309,
      arabic: _ayatAlKursi,
      count: 1,
      category: AdhkarCategory.afterPrayer,
      transliteration: 'آية الكرسي دبر كل صلاة',
      fadl: 'لم يمنعه من دخول الجنة إلا أن يموت',
      source: 'النسائي في الكبرى والحاكم — صحيح',
    ),
    DhikrItem(
      id: 310,
      arabic: _alMuawwidhat,
      count: 1,
      category: AdhkarCategory.afterPrayer,
      transliteration: 'المعوذات دبر كل صلاة',
      fadl: 'تُقرأ مرة دبر كل صلاة، وثلاث مرات بعد الفجر والمغرب',
      source: 'سنن أبي داود — حسن',
    ),
    DhikrItem(
      id: 311,
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      count: 1,
      category: AdhkarCategory.afterPrayer,
      fadl: 'كان رسول الله ﷺ يستحب أن يأتي بهن دبر كل صلاة',
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 312,
      arabic:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْبُخْلِ، وَأَعُوذُ بِكَ مِنَ الْجُبْنِ، وَأَعُوذُ بِكَ مِنْ أَنْ أُرَدَّ إِلَى أَرْذَلِ الْعُمُرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الدُّنْيَا، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ',
      count: 1,
      category: AdhkarCategory.afterPrayer,
      source: 'صحيح البخاري',
    ),
  ],

  // ────────────── أذكار النوم ──────────────
  AdhkarCategory.sleep: [
    DhikrItem(
      id: 401,
      arabic:
          'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
      count: 1,
      category: AdhkarCategory.sleep,
      fadl: 'يضع جنبه على شقه الأيمن',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 402,
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      count: 1,
      category: AdhkarCategory.sleep,
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 403,
      arabic:
          'آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ * لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      count: 1,
      category: AdhkarCategory.sleep,
      transliteration: 'خواتيم سورة البقرة',
      fadl: 'من قرأهما في ليلة كفتاه',
      source: 'متفق عليه — البقرة ٢٨٥-٢٨٦',
    ),
    DhikrItem(
      id: 404,
      arabic: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
      count: 3,
      category: AdhkarCategory.sleep,
      fadl: 'يضع يده تحت خده',
      source: 'سنن أبي داود — صحيح',
    ),
    DhikrItem(
      id: 405,
      arabic: 'سُبْحَانَ اللَّهِ',
      count: 33,
      category: AdhkarCategory.sleep,
      transliteration: 'تسبيح النوم',
      fadl: 'خير لكما من خادم — علّمها فاطمة رضي الله عنها',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 406,
      arabic: 'الْحَمْدُ لِلَّهِ',
      count: 33,
      category: AdhkarCategory.sleep,
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 407,
      arabic: 'اللَّهُ أَكْبَرُ',
      count: 34,
      category: AdhkarCategory.sleep,
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 408,
      arabic: _ayatAlKursi,
      count: 1,
      category: AdhkarCategory.sleep,
      transliteration: 'آية الكرسي عند النوم',
      fadl: 'لا يزال عليك من الله حافظ ولا يقربك شيطان حتى تصبح',
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 409,
      arabic: _alMuawwidhat,
      count: 3,
      category: AdhkarCategory.sleep,
      transliteration: 'المعوذات والنفث في الكفين',
      fadl: 'كان ينفث في كفيه ويقرأ بهن ثم يمسح بهن ما استطاع من جسده',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 410,
      arabic:
          'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
      count: 1,
      category: AdhkarCategory.sleep,
      transliteration: 'آخر ما يقوله قبل النوم',
      fadl: 'إن مات من ليلته مات على الفطرة',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 411,
      arabic:
          'اللَّهُمَّ فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَشَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ',
      count: 1,
      category: AdhkarCategory.sleep,
      source: 'سنن الترمذي وأبي داود — صحيح',
    ),
    DhikrItem(
      id: 412,
      arabic: 'اللَّهُمَّ بِاسْمِكَ أَحْيَا وَأَمُوتُ',
      count: 1,
      category: AdhkarCategory.sleep,
      source: 'صحيح البخاري',
    ),
  ],

  // ────────────── أذكار المنزل ──────────────
  AdhkarCategory.home: [
    DhikrItem(
      id: 701,
      arabic:
          'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
      count: 1,
      category: AdhkarCategory.home,
      transliteration: 'عند دخول المنزل',
      fadl: 'يقولها ثم يسلم على أهله — يُكفى ويُجمع له',
      source: 'سنن أبي داود — حسن',
    ),
    DhikrItem(
      id: 702,
      arabic:
          'اللَّهُمَّ أَسْأَلُكَ خَيْرَ الْمَوْلِجِ وَخَيْرَ الْمَخْرَجِ، بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا',
      count: 1,
      category: AdhkarCategory.home,
      transliteration: 'عند دخول المنزل',
      source: 'سنن أبي داود',
    ),
    DhikrItem(
      id: 703,
      arabic:
          'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      count: 1,
      category: AdhkarCategory.home,
      transliteration: 'عند الخروج من المنزل',
      fadl: 'كُفي ووُقي، ونُودي من السماء: هُديت وكُفيت ووُقيت',
      source: 'سنن أبي داود والترمذي — حسن',
    ),
    DhikrItem(
      id: 704,
      arabic:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ أَنْ أَضِلَّ، أَوْ أُضَلَّ، أَوْ أَزِلَّ، أَوْ أُزَلَّ، أَوْ أَظْلِمَ، أَوْ أُظْلَمَ، أَوْ أَجْهَلَ، أَوْ يُجْهَلَ عَلَيَّ',
      count: 1,
      category: AdhkarCategory.home,
      transliteration: 'عند الخروج من المنزل',
      source: 'سنن أبي داود والترمذي — صحيح',
    ),
  ],

  // ────────────── أذكار السفر والركوب ──────────────
  AdhkarCategory.travel: [
    DhikrItem(
      id: 801,
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ',
      count: 3,
      category: AdhkarCategory.travel,
      transliteration: 'دعاء الركوب',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 802,
      arabic:
          'اللَّهُمَّ إِنَّا نَسْأَلُكَ فِي سَفَرِنَا هَذَا الْبِرَّ وَالتَّقْوَى، وَمِنَ الْعَمَلِ مَا تَرْضَى، اللَّهُمَّ هَوِّنْ عَلَيْنَا سَفَرَنَا هَذَا، وَاطْوِ عَنَّا بُعْدَهُ، اللَّهُمَّ أَنْتَ الصَّاحِبُ فِي السَّفَرِ، وَالْخَلِيفَةُ فِي الْأَهْلِ، اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ وَعْثَاءِ السَّفَرِ، وَكَآبَةِ الْمَنْظَرِ، وَسُوءِ الْمُنْقَلَبِ فِي الْمَالِ وَالْأَهْلِ',
      count: 1,
      category: AdhkarCategory.travel,
      transliteration: 'دعاء السفر',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 803,
      arabic: 'اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ، اللَّهُ أَكْبَرُ',
      count: 3,
      category: AdhkarCategory.travel,
      transliteration: 'عند الصعود في السفر',
      fadl: 'كان القوم إذا علوا ثنية كبروا، وإذا هبطوا وادياً سبحوا',
      source: 'صحيح البخاري',
    ),
    DhikrItem(
      id: 804,
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ، آيِبُونَ تَائِبُونَ عَابِدُونَ لِرَبِّنَا حَامِدُونَ',
      count: 1,
      category: AdhkarCategory.travel,
      transliteration: 'عند الرجوع من السفر',
      fadl: 'كان النبي ﷺ إذا رجع من السفر قالهن',
      source: 'صحيح مسلم',
    ),
  ],

  // ────────────── أذكار الطعام ──────────────
  AdhkarCategory.food: [
    DhikrItem(
      id: 501,
      arabic: 'بِسْمِ اللَّهِ',
      count: 1,
      category: AdhkarCategory.food,
      transliteration: 'قبل الطعام',
      fadl: 'إذا أكل أحدكم فليذكر اسم الله',
      source: 'سنن أبي داود والترمذي — حسن',
    ),
    DhikrItem(
      id: 502,
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا، وَرَزَقَنِيهِ، مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
      count: 1,
      category: AdhkarCategory.food,
      transliteration: 'بعد الطعام',
      fadl: 'غُفر له ما تقدم من ذنبه',
      source: 'سنن أبي داود والترمذي — حسن',
    ),
    DhikrItem(
      id: 503,
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مِنَ الْمُسْلِمِينَ',
      count: 1,
      category: AdhkarCategory.food,
      transliteration: 'بعد الطعام',
      source: 'سنن أبي داود والترمذي — صحيح',
    ),
    DhikrItem(
      id: 504,
      arabic:
          'أَكَلَ طَعَامَكُمُ الْأَبْرَارُ، وَشَرِبَ شَرَابَكُمُ الشَّاكِرُونَ، وَصَلَّتْ عَلَيْكُمُ الْمَلَائِكَةُ',
      count: 1,
      category: AdhkarCategory.food,
      transliteration: 'لدعوة من يُطعم الطعام',
      fadl: 'يقال للمُضَيَّف حين يقضي أكله',
      source: 'سنن أبي داود والنسائي — حسن',
    ),
    DhikrItem(
      id: 505,
      arabic: 'بِسْمِ اللَّهِ فِي أَوَّلِهِ وَآخِرِهِ',
      count: 1,
      category: AdhkarCategory.food,
      transliteration: 'من نسي التسمية أول الطعام',
      source: 'سنن أبي داود — صحيح',
    ),
  ],

  // ────────────── أذكار المجلس ──────────────
  AdhkarCategory.gathering: [
    DhikrItem(
      id: 901,
      arabic:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، أَشْهَدُ أَنْ لَا إِلَٰهَ إِلَّا أَنْتَ، أَسْتَغْفِرُكَ وَأَتُوبُ إِلَيْكَ',
      count: 1,
      category: AdhkarCategory.gathering,
      transliteration: 'كفارة المجلس',
      fadl: 'من قالها في مجلس غُفر له ما كان فيه من لغو',
      source: 'سنن الترمذي — صحيح',
    ),
    DhikrItem(
      id: 902,
      arabic:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَسْتَغْفِرُ اللَّهَ',
      count: 10,
      category: AdhkarCategory.gathering,
      transliteration: 'عند القيام من المجلس',
      fadl: 'كُفّر عنه ما كان في ذلك المجلس',
      source: 'مسند أحمد — صحيح',
    ),
  ],

  // ────────────── أذكار متنوعة ──────────────
  // No fixed occasion or time window; this is also the fallback bucket.
  AdhkarCategory.misc: [
    DhikrItem(
      id: 601,
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      count: 100,
      category: AdhkarCategory.misc,
      fadl: 'أفضل الذكر لا إله إلا الله',
      source: 'سنن الترمذي والنسائي — حسن',
    ),
    DhikrItem(
      id: 602,
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      count: 1,
      category: AdhkarCategory.misc,
      fadl: 'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 603,
      arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      count: 10,
      category: AdhkarCategory.misc,
      fadl: 'من صلى علي مرة واحدة صلى الله عليه بها عشراً',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 604,
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      count: 100,
      category: AdhkarCategory.misc,
      fadl: 'كنز من كنوز الجنة',
      source: 'متفق عليه',
    ),
    DhikrItem(
      id: 605,
      arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      count: 100,
      category: AdhkarCategory.misc,
      fadl: 'كان النبي ﷺ يتوب في اليوم مئة مرة',
      source: 'صحيح مسلم',
    ),
    DhikrItem(
      id: 606,
      arabic:
          'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
      count: 3,
      category: AdhkarCategory.misc,
      transliteration: 'الصلاة الإبراهيمية',
      source: 'صحيح البخاري',
    ),
  ],
};
