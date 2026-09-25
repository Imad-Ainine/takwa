import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Achievement title: 3-day accountability streak
  ///
  /// In ar, this message translates to:
  /// **'البداية الطيبة'**
  String get achievementStreak3Title;

  /// Achievement description: 3-day accountability streak
  ///
  /// In ar, this message translates to:
  /// **'حافظت على المحاسبة لثلاثة أيام متواصلة'**
  String get achievementStreak3Desc;

  /// Achievement title: 7-day accountability streak
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع المثالي'**
  String get achievementStreak7Title;

  /// Achievement description: 7-day accountability streak
  ///
  /// In ar, this message translates to:
  /// **'سبعة أيام من الالتزام والمحاسبة'**
  String get achievementStreak7Desc;

  /// Achievement title: 30-day accountability streak
  ///
  /// In ar, this message translates to:
  /// **'المجاهد المثابر'**
  String get achievementStreak30Title;

  /// Achievement description: 30-day accountability streak
  ///
  /// In ar, this message translates to:
  /// **'ثلاثون يوماً من مراقبة النفس والتقوى'**
  String get achievementStreak30Desc;

  /// Achievement title: read a full juz of Quran in a month
  ///
  /// In ar, this message translates to:
  /// **'أهل القرآن'**
  String get achievementQuranJuzTitle;

  /// Achievement description: read a full juz of Quran in a month
  ///
  /// In ar, this message translates to:
  /// **'ختمت جزءاً كاملاً من كتاب الله'**
  String get achievementQuranJuzDesc;

  /// Achievement title: completed today's self-accountability
  ///
  /// In ar, this message translates to:
  /// **'المحاسب المجتهد'**
  String get achievementDailyMuhasabaTitle;

  /// Achievement description: completed today's self-accountability
  ///
  /// In ar, this message translates to:
  /// **'أكملت محاسبة النفس لهذا اليوم'**
  String get achievementDailyMuhasabaDesc;

  /// Achievement title: completed morning adhkar
  ///
  /// In ar, this message translates to:
  /// **'نور الصباح'**
  String get achievementMorningAdhkarTitle;

  /// Achievement description: completed morning adhkar
  ///
  /// In ar, this message translates to:
  /// **'أكملت أذكار الصباح بالكامل'**
  String get achievementMorningAdhkarDesc;

  /// Achievement title: completed evening adhkar
  ///
  /// In ar, this message translates to:
  /// **'تحصين المساء'**
  String get achievementEveningAdhkarTitle;

  /// Achievement description: completed evening adhkar
  ///
  /// In ar, this message translates to:
  /// **'أكملت أذكار المساء بالكامل'**
  String get achievementEveningAdhkarDesc;

  /// Achievement title: first sadaqah logged through the app
  ///
  /// In ar, this message translates to:
  /// **'اليد المعطية'**
  String get achievementFirstSadaqahTitle;

  /// Achievement description: first sadaqah logged through the app
  ///
  /// In ar, this message translates to:
  /// **'أخرجت أول صدقة لك عبر التطبيق'**
  String get achievementFirstSadaqahDesc;

  /// Achievement title: 100 tasbeeh in one day
  ///
  /// In ar, this message translates to:
  /// **'الذاكر الشاكر'**
  String get achievementTasbeeh100Title;

  /// Achievement description: 100 tasbeeh in one day
  ///
  /// In ar, this message translates to:
  /// **'سبحت الله 100 مرة في يوم واحد'**
  String get achievementTasbeeh100Desc;

  /// Achievement title: Fajr on time for 3 consecutive days
  ///
  /// In ar, this message translates to:
  /// **'في ذمة الله'**
  String get achievementFajrOnTimeTitle;

  /// Achievement description: Fajr on time for 3 consecutive days
  ///
  /// In ar, this message translates to:
  /// **'صليت الفجر في وقته لثلاثة أيام متتالية'**
  String get achievementFajrOnTimeDesc;

  /// Achievement title: read Quran 3 consecutive days
  ///
  /// In ar, this message translates to:
  /// **'القارئ المداوم'**
  String get achievementConstantReaderTitle;

  /// Achievement description: read Quran 3 consecutive days
  ///
  /// In ar, this message translates to:
  /// **'قرأت القرآن لثلاثة أيام متتالية'**
  String get achievementConstantReaderDesc;

  /// Achievement title: all 5 prayers on time for 7 days
  ///
  /// In ar, this message translates to:
  /// **'الصلاة نور'**
  String get achievementPerfectWeekPrayerTitle;

  /// Achievement description: all 5 prayers on time for 7 days
  ///
  /// In ar, this message translates to:
  /// **'أديت جميع الصلوات في وقتها لسبعة أيام'**
  String get achievementPerfectWeekPrayerDesc;

  /// Achievement title: first voluntary (nafl) fast
  ///
  /// In ar, this message translates to:
  /// **'باب الريان'**
  String get achievementFastingNaflTitle;

  /// Achievement description: first voluntary (nafl) fast
  ///
  /// In ar, this message translates to:
  /// **'أكملت صيام النفل الأول لك'**
  String get achievementFastingNaflDesc;

  /// Achievement title: 10 days of Ramadan fasting logged
  ///
  /// In ar, this message translates to:
  /// **'فارس رمضان'**
  String get achievementRamadanKnightTitle;

  /// Achievement description: 10 days of Ramadan fasting logged
  ///
  /// In ar, this message translates to:
  /// **'أكملت 10 أيام من رمضان في المحاسبة'**
  String get achievementRamadanKnightDesc;

  /// Achievement title: fasted every day of the current Ramadan
  ///
  /// In ar, this message translates to:
  /// **'شهر كامل'**
  String get achievementRamadanCompleteTitle;

  /// Achievement description: fasted every day of the current Ramadan
  ///
  /// In ar, this message translates to:
  /// **'صمت رمضان كاملاً هذا العام'**
  String get achievementRamadanCompleteDesc;

  /// Achievement title: joined or created a family/community accountability circle
  ///
  /// In ar, this message translates to:
  /// **'دائرة العائلة'**
  String get achievementCircleJoinedTitle;

  /// Achievement description: joined or created a family/community accountability circle
  ///
  /// In ar, this message translates to:
  /// **'انضممت إلى أول دائرة محاسبة لك'**
  String get achievementCircleJoinedDesc;

  /// Achievement title: reached 100 lifetime Taqwa points
  ///
  /// In ar, this message translates to:
  /// **'مئة خطوة'**
  String get achievementPoints100Title;

  /// Achievement description: reached 100 lifetime Taqwa points
  ///
  /// In ar, this message translates to:
  /// **'جمعت أول 100 نقطة تقوى'**
  String get achievementPoints100Desc;

  /// Achievement title: reached 1000 lifetime Taqwa points
  ///
  /// In ar, this message translates to:
  /// **'فارس التقوى'**
  String get achievementPoints1000Title;

  /// Achievement description: reached 1000 lifetime Taqwa points
  ///
  /// In ar, this message translates to:
  /// **'بلغت 1000 نقطة في مسيرتك'**
  String get achievementPoints1000Desc;

  /// No description provided for @prayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerIsha;

  /// Short chip label: prayer performed on time
  ///
  /// In ar, this message translates to:
  /// **'في وقتها ✓'**
  String get prayerStatusOnTimeShort;

  /// Short chip label: prayer made up late
  ///
  /// In ar, this message translates to:
  /// **'قضاء'**
  String get prayerStatusQadaaShort;

  /// Short chip label: prayer missed
  ///
  /// In ar, this message translates to:
  /// **'فاتت'**
  String get prayerStatusMissedShort;

  /// Short chip label: prayer time has come but not yet marked
  ///
  /// In ar, this message translates to:
  /// **'لم تُؤدَّ بعد'**
  String get prayerStatusPendingShort;

  /// Short chip label: prayer time hasn't come yet
  ///
  /// In ar, this message translates to:
  /// **'لم يحن وقتها'**
  String get prayerStatusNotDueShort;

  /// Status picker option: prayer performed on time
  ///
  /// In ar, this message translates to:
  /// **'أُديت في وقتها'**
  String get prayerStatusPerformedFull;

  /// Status picker option: prayer made up late
  ///
  /// In ar, this message translates to:
  /// **'قُضيت خارج الوقت'**
  String get prayerStatusQadaaFull;

  /// Status picker option: prayer missed
  ///
  /// In ar, this message translates to:
  /// **'فاتت (استغفر الله)'**
  String get prayerStatusMissedFull;

  /// No description provided for @ibadahMorningAdhkarLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get ibadahMorningAdhkarLabel;

  /// No description provided for @ibadahMorningAdhkarSublabel.
  ///
  /// In ar, this message translates to:
  /// **'بعد صلاة الفجر'**
  String get ibadahMorningAdhkarSublabel;

  /// No description provided for @ibadahEveningAdhkarLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get ibadahEveningAdhkarLabel;

  /// No description provided for @ibadahEveningAdhkarSublabel.
  ///
  /// In ar, this message translates to:
  /// **'بعد صلاة العصر'**
  String get ibadahEveningAdhkarSublabel;

  /// No description provided for @ibadahQiyamLabel.
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل'**
  String get ibadahQiyamLabel;

  /// No description provided for @ibadahQiyamSublabel.
  ///
  /// In ar, this message translates to:
  /// **'الثلث الأخير من الليل'**
  String get ibadahQiyamSublabel;

  /// No description provided for @ibadahSadaqahLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصدقة'**
  String get ibadahSadaqahLabel;

  /// No description provided for @ibadahSadaqahSublabel.
  ///
  /// In ar, this message translates to:
  /// **'ولو بكلمة طيبة'**
  String get ibadahSadaqahSublabel;

  /// No description provided for @ibadahGhadhBasarLabel.
  ///
  /// In ar, this message translates to:
  /// **'غضّ البصر'**
  String get ibadahGhadhBasarLabel;

  /// No description provided for @ibadahGhadhBasarSublabel.
  ///
  /// In ar, this message translates to:
  /// **'حفظ النظر عن الحرام'**
  String get ibadahGhadhBasarSublabel;

  /// No description provided for @prohibitionGheebaName.
  ///
  /// In ar, this message translates to:
  /// **'الغيبة'**
  String get prohibitionGheebaName;

  /// No description provided for @prohibitionGheebaDesc.
  ///
  /// In ar, this message translates to:
  /// **'ذكر الناس بما يكرهون'**
  String get prohibitionGheebaDesc;

  /// No description provided for @prohibitionNameemaName.
  ///
  /// In ar, this message translates to:
  /// **'النميمة'**
  String get prohibitionNameemaName;

  /// No description provided for @prohibitionNameemaDesc.
  ///
  /// In ar, this message translates to:
  /// **'نقل الكلام بقصد الإفساد'**
  String get prohibitionNameemaDesc;

  /// No description provided for @prohibitionKadhbName.
  ///
  /// In ar, this message translates to:
  /// **'الكذب'**
  String get prohibitionKadhbName;

  /// No description provided for @prohibitionKadhbDesc.
  ///
  /// In ar, this message translates to:
  /// **'قول غير الحق'**
  String get prohibitionKadhbDesc;

  /// No description provided for @prohibitionGhadabName.
  ///
  /// In ar, this message translates to:
  /// **'الغضب'**
  String get prohibitionGhadabName;

  /// No description provided for @prohibitionGhadabDesc.
  ///
  /// In ar, this message translates to:
  /// **'إن غضبت فاسكت'**
  String get prohibitionGhadabDesc;

  /// No description provided for @prohibitionIdaatWaqtName.
  ///
  /// In ar, this message translates to:
  /// **'إضاعة الوقت'**
  String get prohibitionIdaatWaqtName;

  /// No description provided for @prohibitionIdaatWaqtDesc.
  ///
  /// In ar, this message translates to:
  /// **'التقصير في استثمار الوقت'**
  String get prohibitionIdaatWaqtDesc;

  /// No description provided for @hijriMuharram.
  ///
  /// In ar, this message translates to:
  /// **'محرم'**
  String get hijriMuharram;

  /// No description provided for @hijriSafar.
  ///
  /// In ar, this message translates to:
  /// **'صفر'**
  String get hijriSafar;

  /// No description provided for @hijriRabiAlAwwal.
  ///
  /// In ar, this message translates to:
  /// **'ربيع الأول'**
  String get hijriRabiAlAwwal;

  /// No description provided for @hijriRabiAlThani.
  ///
  /// In ar, this message translates to:
  /// **'ربيع الآخر'**
  String get hijriRabiAlThani;

  /// No description provided for @hijriJumadaAlAwwal.
  ///
  /// In ar, this message translates to:
  /// **'جمادى الأولى'**
  String get hijriJumadaAlAwwal;

  /// No description provided for @hijriJumadaAlThani.
  ///
  /// In ar, this message translates to:
  /// **'جمادى الآخرة'**
  String get hijriJumadaAlThani;

  /// No description provided for @hijriRajab.
  ///
  /// In ar, this message translates to:
  /// **'رجب'**
  String get hijriRajab;

  /// No description provided for @hijriShaban.
  ///
  /// In ar, this message translates to:
  /// **'شعبان'**
  String get hijriShaban;

  /// No description provided for @hijriRamadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get hijriRamadan;

  /// No description provided for @hijriShawwal.
  ///
  /// In ar, this message translates to:
  /// **'شوال'**
  String get hijriShawwal;

  /// No description provided for @hijriDhulQadah.
  ///
  /// In ar, this message translates to:
  /// **'ذو القعدة'**
  String get hijriDhulQadah;

  /// No description provided for @hijriDhulHijjah.
  ///
  /// In ar, this message translates to:
  /// **'ذو الحجة'**
  String get hijriDhulHijjah;

  /// No description provided for @checklistTitle.
  ///
  /// In ar, this message translates to:
  /// **'محاسبة اليوم'**
  String get checklistTitle;

  /// No description provided for @checklistTodayProgress.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز اليوم'**
  String get checklistTodayProgress;

  /// No description provided for @checklistFivePrayersTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصلوات الخمس'**
  String get checklistFivePrayersTitle;

  /// No description provided for @checklistQuranAdhkarTitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن والأذكار'**
  String get checklistQuranAdhkarTitle;

  /// No description provided for @checklistProhibitionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحظورات والمهلكات'**
  String get checklistProhibitionsTitle;

  /// No description provided for @checklistProhibitionsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حدد ما وقعت فيه اليوم بصدق مع نفسك'**
  String get checklistProhibitionsSubtitle;

  /// No description provided for @checklistMotivationComplete.
  ///
  /// In ar, this message translates to:
  /// **'يوم مكتمل الحمد لله ✨'**
  String get checklistMotivationComplete;

  /// No description provided for @checklistMotivationGreat.
  ///
  /// In ar, this message translates to:
  /// **'رائع، أنت على الطريق 💪'**
  String get checklistMotivationGreat;

  /// No description provided for @checklistMotivationKeepGoing.
  ///
  /// In ar, this message translates to:
  /// **'استمر، لا تتوقف 🌿'**
  String get checklistMotivationKeepGoing;

  /// No description provided for @checklistMotivationStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية الآن 🤲'**
  String get checklistMotivationStart;

  /// No description provided for @checklistQuranInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة القرآن الكريم'**
  String get checklistQuranInputLabel;

  /// No description provided for @checklistQuranPagesHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عدد الصفحات التي قرأتها'**
  String get checklistQuranPagesHint;

  /// No description provided for @checklistNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة اليوم'**
  String get checklistNoteTitle;

  /// No description provided for @checklistNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظتك أو دعاءك لهذا اليوم...'**
  String get checklistNoteHint;

  /// No description provided for @checklistNoteSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الملاحظة'**
  String get checklistNoteSaveButton;

  /// No description provided for @checklistNoteSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ ✓'**
  String get checklistNoteSaved;

  /// Error message prefix, followed by the raw error text
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {error}'**
  String checklistErrorPrefix(String error);

  /// Screen-reader label for the prohibition '+1 count' button
  ///
  /// In ar, this message translates to:
  /// **'زد عدد مرات {name}، حدث {count} مرة'**
  String checklistIncrementSemanticLabel(String name, int count);

  /// Status picker sheet title, e.g. 'Fajr prayer'
  ///
  /// In ar, this message translates to:
  /// **'صلاة {prayerName}'**
  String checklistPrayerSheetTitle(String prayerName);

  /// No description provided for @checklistNetPointsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصافي'**
  String get checklistNetPointsLabel;

  /// No description provided for @checklistPointsSuffix.
  ///
  /// In ar, this message translates to:
  /// **' نقطة'**
  String get checklistPointsSuffix;

  /// No description provided for @checklistFastingLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصيام'**
  String get checklistFastingLabel;

  /// No description provided for @fastingTypeFard.
  ///
  /// In ar, this message translates to:
  /// **'فريضة'**
  String get fastingTypeFard;

  /// No description provided for @fastingTypeNafl.
  ///
  /// In ar, this message translates to:
  /// **'نافلة'**
  String get fastingTypeNafl;

  /// No description provided for @fastingTypeNone.
  ///
  /// In ar, this message translates to:
  /// **'لم أصم'**
  String get fastingTypeNone;

  /// No description provided for @checklistQuranPageSuffix.
  ///
  /// In ar, this message translates to:
  /// **'/صفحة'**
  String get checklistQuranPageSuffix;

  /// Separator joining two clauses in a screen-reader label, e.g. 'name, status'
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get semanticsSeparator;

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقوى'**
  String get appTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguageLabel;

  /// Language name shown in its own native form, regardless of the app's current UI language
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Language name shown in its own native form, regardless of the app's current UI language
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsScreenTitle;

  /// No description provided for @settingsAdhanSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الأذان و التنبيهات'**
  String get settingsAdhanSectionTitle;

  /// No description provided for @settingsAdhanNotificationsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأذان والتنبيهات'**
  String get settingsAdhanNotificationsLabel;

  /// No description provided for @settingsAdhanNotificationsSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص الأذان، الوضع الصامت، والتنبيهات'**
  String get settingsAdhanNotificationsSublabel;

  /// No description provided for @settingsWakeBeforeFajrLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاستيقاظ قبل الفجر'**
  String get settingsWakeBeforeFajrLabel;

  /// No description provided for @settingsWakeBeforeFajrSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه بصوت الأذان في الوقت المحدد'**
  String get settingsWakeBeforeFajrSublabel;

  /// No description provided for @settingsWakeTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت الاستيقاظ'**
  String get settingsWakeTimeLabel;

  /// No description provided for @settingsMorningAdhkarLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get settingsMorningAdhkarLabel;

  /// No description provided for @settingsMorningAdhkarSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير في الوقت المحدد أو بعد الفجر'**
  String get settingsMorningAdhkarSublabel;

  /// No description provided for @settingsEveningAdhkarLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get settingsEveningAdhkarLabel;

  /// No description provided for @settingsEveningAdhkarSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير في الوقت المحدد أو بعد العصر'**
  String get settingsEveningAdhkarSublabel;

  /// No description provided for @settingsSleepAdhkarLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار النوم'**
  String get settingsSleepAdhkarLabel;

  /// No description provided for @settingsSleepAdhkarSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير قبل النوم في الوقت المحدد'**
  String get settingsSleepAdhkarSublabel;

  /// No description provided for @settingsMuhasabaLabel.
  ///
  /// In ar, this message translates to:
  /// **'محاسبة مسائية'**
  String get settingsMuhasabaLabel;

  /// No description provided for @settingsMuhasabaSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي للمحاسبة'**
  String get settingsMuhasabaSublabel;

  /// No description provided for @settingsDailyDuasLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية اليومية'**
  String get settingsDailyDuasLabel;

  /// No description provided for @settingsDailyDuasSublabel.
  ///
  /// In ar, this message translates to:
  /// **'نفحات من الأدعية النبوية'**
  String get settingsDailyDuasSublabel;

  /// No description provided for @settingsFridaySunnahLabel.
  ///
  /// In ar, this message translates to:
  /// **'سنن الجمعة'**
  String get settingsFridaySunnahLabel;

  /// No description provided for @settingsFridaySunnahSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بسورة الكهف والجمعة'**
  String get settingsFridaySunnahSublabel;

  /// No description provided for @settingsFastingRemindersLabel.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصيام'**
  String get settingsFastingRemindersLabel;

  /// No description provided for @settingsFastingRemindersSublabel.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين والخميس والأيام البيض'**
  String get settingsFastingRemindersSublabel;

  /// No description provided for @settingsMuhasabaTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت المحاسبة'**
  String get settingsMuhasabaTimeLabel;

  /// No description provided for @settingsDuaTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت دعاء اليوم'**
  String get settingsDuaTimeLabel;

  /// No description provided for @settingsAppearanceSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsAppearanceSectionTitle;

  /// No description provided for @settingsThemeModeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وضع المظهر'**
  String get settingsThemeModeLabel;

  /// No description provided for @settingsDesignSystemLabel.
  ///
  /// In ar, this message translates to:
  /// **'نظام التصميم'**
  String get settingsDesignSystemLabel;

  /// No description provided for @settingsDesignSystemSublabel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الألوان والمكوّنات'**
  String get settingsDesignSystemSublabel;

  /// No description provided for @themeModeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي (حسب النظام)'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get themeModeDark;

  /// No description provided for @settingsRamadanSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع رمضان'**
  String get settingsRamadanSectionTitle;

  /// No description provided for @settingsRamadanModeSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل المميزات الرمضانية'**
  String get settingsRamadanModeSublabel;

  /// No description provided for @settingsAppSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get settingsAppSectionTitle;

  /// No description provided for @settingsTestNotifLabel.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الإشعارات والنافذة'**
  String get settingsTestNotifLabel;

  /// No description provided for @settingsTestNotifSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من عمل الإشعارات والنوافذ العائمة'**
  String get settingsTestNotifSublabel;

  /// No description provided for @settingsSubscriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get settingsSubscriptionLabel;

  /// No description provided for @settingsSubscriptionSublabel.
  ///
  /// In ar, this message translates to:
  /// **'دعم المشروع والاستمرار'**
  String get settingsSubscriptionSublabel;

  /// No description provided for @settingsAboutDevLabel.
  ///
  /// In ar, this message translates to:
  /// **'عن المطور'**
  String get settingsAboutDevLabel;

  /// No description provided for @settingsAboutDevSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تعرف على مبرمج التطبيق'**
  String get settingsAboutDevSublabel;

  /// No description provided for @settingsTermsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والخصوصية'**
  String get settingsTermsLabel;

  /// No description provided for @settingsTermsSublabel.
  ///
  /// In ar, this message translates to:
  /// **'شروط الدخول والخصوصية'**
  String get settingsTermsSublabel;

  /// No description provided for @settingsLogoutLabel.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get settingsLogoutLabel;

  /// No description provided for @settingsLogoutSublabel.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من الحساب أو وضع الزائر'**
  String get settingsLogoutSublabel;

  /// No description provided for @settingsBismillah.
  ///
  /// In ar, this message translates to:
  /// **'بسم الله الرحمن الرحيم'**
  String get settingsBismillah;

  /// No description provided for @settingsAppVersionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقوى — v1.0.5'**
  String get settingsAppVersionLabel;

  /// No description provided for @settingsTestNotifSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الإشعارات'**
  String get settingsTestNotifSheetTitle;

  /// No description provided for @settingsTestNotifPlainLabel.
  ///
  /// In ar, this message translates to:
  /// **'إشعار عادي'**
  String get settingsTestNotifPlainLabel;

  /// No description provided for @settingsTestNotifPlainSublabel.
  ///
  /// In ar, this message translates to:
  /// **'إشعار النظام التقليدي'**
  String get settingsTestNotifPlainSublabel;

  /// No description provided for @settingsTestAdhanLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذان الصلاة'**
  String get settingsTestAdhanLabel;

  /// No description provided for @settingsTestAdhanSublabel.
  ///
  /// In ar, this message translates to:
  /// **'شاشة الأذان الكاملة مع الصوت'**
  String get settingsTestAdhanSublabel;

  /// No description provided for @settingsResetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الضبط'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف جميع الإعدادات؟'**
  String get settingsResetConfirm;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في تسجيل الخروج؟'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLogoutConfirmButton.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get settingsLogoutConfirmButton;

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get commonDelete;

  /// No description provided for @settingsTestNotifTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الإشعار'**
  String get settingsTestNotifTitle;

  /// No description provided for @settingsTestNotifBody.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات تعمل بشكل صحيح'**
  String get settingsTestNotifBody;

  /// No description provided for @prayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunrise;

  /// No description provided for @labelQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get labelQuran;

  /// No description provided for @labelAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get labelAdhkar;

  /// No description provided for @labelPoints.
  ///
  /// In ar, this message translates to:
  /// **'نقطة'**
  String get labelPoints;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير 🌅'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير 🌤'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء النور 🌙'**
  String get homeGreetingEvening;

  /// No description provided for @homeRamadanBannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمضان كريم'**
  String get homeRamadanBannerTitle;

  /// No description provided for @homeRamadanBannerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {day} من شهر رمضان المبارك'**
  String homeRamadanBannerSubtitle(int day);

  /// No description provided for @homeRamadanDaysRemaining.
  ///
  /// In ar, this message translates to:
  /// **'يوم\nمتبقي'**
  String get homeRamadanDaysRemaining;

  /// No description provided for @homeCountdownNow.
  ///
  /// In ar, this message translates to:
  /// **'حان الوقت الآن'**
  String get homeCountdownNow;

  /// No description provided for @homeCountdownHoursMinutes.
  ///
  /// In ar, this message translates to:
  /// **'بعد {hours}س {minutes}د'**
  String homeCountdownHoursMinutes(int hours, int minutes);

  /// No description provided for @homeCountdownMinutesOnly.
  ///
  /// In ar, this message translates to:
  /// **'بعد {minutes} دقيقة'**
  String homeCountdownMinutesOnly(int minutes);

  /// No description provided for @homeNextPrayerLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get homeNextPrayerLabel;

  /// No description provided for @homePrayerTimesTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة'**
  String get homePrayerTimesTitle;

  /// No description provided for @homeTodayIbadahTitle.
  ///
  /// In ar, this message translates to:
  /// **'عبادات اليوم'**
  String get homeTodayIbadahTitle;

  /// No description provided for @homeViewAllLabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل ←'**
  String get homeViewAllLabel;

  /// No description provided for @homeIbadahProgressLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} من ١٠ عبادات'**
  String homeIbadahProgressLabel(int count);

  /// No description provided for @homeStreakDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'{n} يوم متواصل'**
  String homeStreakDaysLabel(int n);

  /// No description provided for @homeLevelMubtadi.
  ///
  /// In ar, this message translates to:
  /// **'مبتدئ 🌱'**
  String get homeLevelMubtadi;

  /// No description provided for @homeLevelSalik.
  ///
  /// In ar, this message translates to:
  /// **'سالك 🌿'**
  String get homeLevelSalik;

  /// No description provided for @homeLevelMujahid.
  ///
  /// In ar, this message translates to:
  /// **'مجاهد ⚔️'**
  String get homeLevelMujahid;

  /// No description provided for @homeLevelMutaqi.
  ///
  /// In ar, this message translates to:
  /// **'متقي ✨'**
  String get homeLevelMutaqi;

  /// No description provided for @homeProgressMsgComplete.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله! 🌟'**
  String get homeProgressMsgComplete;

  /// No description provided for @homeProgressMsgGreat.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت، استمر 💪'**
  String get homeProgressMsgGreat;

  /// No description provided for @homeProgressMsgGood.
  ///
  /// In ar, this message translates to:
  /// **'بداية جيدة 🌿'**
  String get homeProgressMsgGood;

  /// No description provided for @homeProgressMsgStart.
  ///
  /// In ar, this message translates to:
  /// **'بسم الله 🤲'**
  String get homeProgressMsgStart;

  /// No description provided for @homeRingTodayLabel.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get homeRingTodayLabel;

  /// No description provided for @homeFeaturesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الميزات'**
  String get homeFeaturesTitle;

  /// No description provided for @homeFeaturePrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'أوقات\nالصلاة'**
  String get homeFeaturePrayerTimes;

  /// No description provided for @homeFeatureQibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get homeFeatureQibla;

  /// No description provided for @homeFeatureDuas.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get homeFeatureDuas;

  /// No description provided for @homeFeatureMisbaha.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get homeFeatureMisbaha;

  /// No description provided for @homeFeatureMosques.
  ///
  /// In ar, this message translates to:
  /// **'المساجد'**
  String get homeFeatureMosques;

  /// No description provided for @homeFeatureStatistics.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات'**
  String get homeFeatureStatistics;

  /// No description provided for @homeFeatureAchievements.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get homeFeatureAchievements;

  /// No description provided for @homeFeatureReminders.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get homeFeatureReminders;

  /// Prefix label before a Quranic verse reference; the reference itself stays untranslated Arabic content
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم - {reference}'**
  String homeVerseOfDayLabel(String reference);

  /// No description provided for @homeRamadanTimesTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت رمضان'**
  String get homeRamadanTimesTitle;

  /// No description provided for @homeIftarLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإفطار'**
  String get homeIftarLabel;

  /// No description provided for @homeSuhoorLabel.
  ///
  /// In ar, this message translates to:
  /// **'السحور'**
  String get homeSuhoorLabel;

  /// No description provided for @homeCountdownPassed.
  ///
  /// In ar, this message translates to:
  /// **'مضى ✓'**
  String get homeCountdownPassed;

  /// No description provided for @homeDailyDhikrLabel.
  ///
  /// In ar, this message translates to:
  /// **'ذكر اليوم'**
  String get homeDailyDhikrLabel;

  /// No description provided for @homeBooksLibraryTitle.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة الإسلامية'**
  String get homeBooksLibraryTitle;

  /// No description provided for @homeMinutesLabel.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String homeMinutesLabel(int minutes);

  /// No description provided for @onboardingGpsDisabledMessage.
  ///
  /// In ar, this message translates to:
  /// **'GPS غير مفعّل، يرجى تفعيله للمتابعة.'**
  String get onboardingGpsDisabledMessage;

  /// No description provided for @onboardingSettingsAction.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات'**
  String get onboardingSettingsAction;

  /// No description provided for @onboardingLocationPermissionDeniedMessage.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تفعيل إذن الموقع من الإعدادات.'**
  String get onboardingLocationPermissionDeniedMessage;

  /// No description provided for @onboardingEditLaterHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك التعديل لاحقًا'**
  String get onboardingEditLaterHint;

  /// No description provided for @onboardingContinueButton.
  ///
  /// In ar, this message translates to:
  /// **'استمرار'**
  String get onboardingContinueButton;

  /// No description provided for @onboardingIntro1Title.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في تقوى'**
  String get onboardingIntro1Title;

  /// No description provided for @onboardingIntro1Subtitle.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في رحلة التزكية والقرب من الله عز وجل، من خلال أدوات ذكية ومميزة.'**
  String get onboardingIntro1Subtitle;

  /// No description provided for @onboardingIntro2Title.
  ///
  /// In ar, this message translates to:
  /// **'نظام المحاسبة الدقيق'**
  String get onboardingIntro2Title;

  /// No description provided for @onboardingIntro2Subtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل صلواتك، أذكارك، وطاعاتك يومياً لترى تطورك وتثبّت عزيمتك.'**
  String get onboardingIntro2Subtitle;

  /// No description provided for @onboardingIntro3Title.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات وتقدم'**
  String get onboardingIntro3Title;

  /// No description provided for @onboardingIntro3Subtitle.
  ///
  /// In ar, this message translates to:
  /// **'تابِع نتائج محاسبتك عبر رسوم بيانية وتقارير مفصلة تعينك على الثبات.'**
  String get onboardingIntro3Subtitle;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الموقع'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج لموقعك لنحدد لك أوقات الصلاة واتجاه القبلة بدقة متناهية'**
  String get onboardingLocationSubtitle;

  /// No description provided for @onboardingLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'بيانات موقعك تبقى في جهازك ولا نطلع عليها أبداً'**
  String get onboardingLocationHint;

  /// No description provided for @onboardingLocationAllowButton.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الموقع 📍'**
  String get onboardingLocationAllowButton;

  /// No description provided for @onboardingSkipButton.
  ///
  /// In ar, this message translates to:
  /// **'تخطى'**
  String get onboardingSkipButton;

  /// No description provided for @onboardingNotificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'السماح بإرسال التنبيهات'**
  String get onboardingNotificationsTitle;

  /// No description provided for @onboardingNotificationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يمكننا من تذكيرك بالصلاة والأذكار والمحاسبة المسائية والمزيد'**
  String get onboardingNotificationsSubtitle;

  /// No description provided for @onboardingNotificationsHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغيير هذا لاحقًا من الإعدادات'**
  String get onboardingNotificationsHint;

  /// No description provided for @onboardingNotificationsAllowButton.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالتنبيهات 🔔'**
  String get onboardingNotificationsAllowButton;

  /// No description provided for @onboardingGenderTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدد الجنس'**
  String get onboardingGenderTitle;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In ar, this message translates to:
  /// **'مسلم'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In ar, this message translates to:
  /// **'مسلمة'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderInfoHint.
  ///
  /// In ar, this message translates to:
  /// **'تجربة استخدام مناسبة، وختمات عامة للرجال وأخرى للنساء'**
  String get onboardingGenderInfoHint;

  /// No description provided for @onboardingNextButton.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNextButton;

  /// No description provided for @onboardingOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'نافذة الأذكار 🪟'**
  String get onboardingOverlayTitle;

  /// No description provided for @onboardingOverlaySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تسمح بعرض الأذكار والتنبيهات فوق التطبيقات الأخرى لتذكيرك الدائم'**
  String get onboardingOverlaySubtitle;

  /// No description provided for @onboardingOverlayHint.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب إذن \"الظهور فوق التطبيقات\" على أندرويد'**
  String get onboardingOverlayHint;

  /// No description provided for @onboardingOverlayAllowButton.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل النافذة'**
  String get onboardingOverlayAllowButton;

  /// No description provided for @onboardingBackgroundTitle.
  ///
  /// In ar, this message translates to:
  /// **'التشغيل في الخلفية'**
  String get onboardingBackgroundTitle;

  /// No description provided for @onboardingBackgroundSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لضمان وصول تنبيهات الأذان والأذكار في وقتها بدقة دون توقف التطبيق'**
  String get onboardingBackgroundSubtitle;

  /// No description provided for @onboardingBackgroundHint.
  ///
  /// In ar, this message translates to:
  /// **'يطلب النظام استثناء التطبيق من تحسين البطارية'**
  String get onboardingBackgroundHint;

  /// No description provided for @onboardingBackgroundAllowButton.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالتشغيل 🔋'**
  String get onboardingBackgroundAllowButton;

  /// No description provided for @statsPeriodLast7Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر ٧ أيام'**
  String get statsPeriodLast7Days;

  /// No description provided for @statsPeriodThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get statsPeriodThisMonth;

  /// No description provided for @statsPeriodRamadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get statsPeriodRamadan;

  /// No description provided for @statsPeriodThisWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get statsPeriodThisWeek;

  /// No description provided for @statsPeriodRamadanEmoji.
  ///
  /// In ar, this message translates to:
  /// **'رمضان 🌙'**
  String get statsPeriodRamadanEmoji;

  /// No description provided for @statsRamadanReportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير رمضان 🌙'**
  String get statsRamadanReportTitle;

  /// No description provided for @statsScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get statsScreenTitle;

  /// No description provided for @statsRamadanDayOf30.
  ///
  /// In ar, this message translates to:
  /// **'يوم {day} من ٣٠'**
  String statsRamadanDayOf30(int day);

  /// No description provided for @statsPointsThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة هذا الشهر'**
  String statsPointsThisMonth(int points);

  /// No description provided for @statsNextLevelLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى التالي'**
  String get statsNextLevelLabel;

  /// No description provided for @statsPointsRemaining.
  ///
  /// In ar, this message translates to:
  /// **'{remaining} نقطة متبقية'**
  String statsPointsRemaining(int remaining);

  /// No description provided for @statsMaxLevelReached.
  ///
  /// In ar, this message translates to:
  /// **'أقصى مستوى ✨'**
  String get statsMaxLevelReached;

  /// No description provided for @statsPerformanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'أداء الفترة'**
  String get statsPerformanceTitle;

  /// No description provided for @statsPreviousDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'أيام سابقة'**
  String get statsPreviousDaysLabel;

  /// No description provided for @statsQuranPagesLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحات القرآن'**
  String get statsQuranPagesLabel;

  /// No description provided for @statsPrayerAttendanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'حضور الصلوات'**
  String get statsPrayerAttendanceLabel;

  /// No description provided for @statsLongestStreakLabel.
  ///
  /// In ar, this message translates to:
  /// **'أطول سلسلة'**
  String get statsLongestStreakLabel;

  /// No description provided for @statsDaysUnit.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String statsDaysUnit(int count);

  /// No description provided for @statsTaqwaPointsLabel.
  ///
  /// In ar, this message translates to:
  /// **'نقاط التقوى'**
  String get statsTaqwaPointsLabel;

  /// No description provided for @statsAchievementsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات والشارات'**
  String get statsAchievementsSectionTitle;

  /// No description provided for @statsAchievementsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} إنجاز'**
  String statsAchievementsCount(int count);

  /// No description provided for @statsPointsRewardShort.
  ///
  /// In ar, this message translates to:
  /// **'+{points} نقطة'**
  String statsPointsRewardShort(int points);

  /// No description provided for @statsNoAchievementsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا إنجازات بعد'**
  String get statsNoAchievementsYet;

  /// No description provided for @statsNoAchievementsHint.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على العبادات لتحصل على أول إنجاز'**
  String get statsNoAchievementsHint;

  /// No description provided for @statsComingSoonLabel.
  ///
  /// In ar, this message translates to:
  /// **'قادم قريباً 🔒'**
  String get statsComingSoonLabel;

  /// No description provided for @statsLockedStreak30Title.
  ///
  /// In ar, this message translates to:
  /// **'شهر المجاهد'**
  String get statsLockedStreak30Title;

  /// No description provided for @statsLockedStreak30Desc.
  ///
  /// In ar, this message translates to:
  /// **'٣٠ يوم متواصل'**
  String get statsLockedStreak30Desc;

  /// No description provided for @statsLockedKhatmaTitle.
  ///
  /// In ar, this message translates to:
  /// **'ختمة كاملة'**
  String get statsLockedKhatmaTitle;

  /// No description provided for @statsLockedKhatmaDesc.
  ///
  /// In ar, this message translates to:
  /// **'إتمام القرآن'**
  String get statsLockedKhatmaDesc;

  /// No description provided for @statsLockedFullWeekTitle.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع مثالي'**
  String get statsLockedFullWeekTitle;

  /// No description provided for @statsLockedFullWeekDesc.
  ///
  /// In ar, this message translates to:
  /// **'٧ أيام مكتملة'**
  String get statsLockedFullWeekDesc;

  /// No description provided for @statsThanksButtonLabel.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لله 🤲'**
  String get statsThanksButtonLabel;

  /// No description provided for @statsPointsRewardFull.
  ///
  /// In ar, this message translates to:
  /// **'+{points} نقطة مكافأة 🌟'**
  String statsPointsRewardFull(int points);

  /// No description provided for @statsNewAchievementLabel.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز جديد! 🎉'**
  String get statsNewAchievementLabel;

  /// No description provided for @drawerLevelLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى: {level}'**
  String drawerLevelLabel(String level);

  /// Fallback username shown in the drawer when the user has no username set
  ///
  /// In ar, this message translates to:
  /// **'مستخدم تقوى'**
  String get drawerDefaultUsername;

  /// Gender badge label for male users in the drawer header
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get drawerGenderMale;

  /// Gender badge label for female users in the drawer header
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get drawerGenderFemale;

  /// Subtitle link in the drawer header that navigates to the profile screen
  ///
  /// In ar, this message translates to:
  /// **'عرض البروفايل'**
  String get drawerViewProfile;

  /// Drawer navigation item: Home
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get drawerNavHome;

  /// Drawer navigation item: Daily accountability checklist
  ///
  /// In ar, this message translates to:
  /// **'محاسبة اليوم'**
  String get drawerNavChecklist;

  /// Drawer navigation item: Prayer times
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة'**
  String get drawerNavPrayer;

  /// Drawer navigation item: Islamic library
  ///
  /// In ar, this message translates to:
  /// **'المكتبة الإسلامية'**
  String get drawerNavBooks;

  /// Drawer navigation item: Statistics
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get drawerNavStatistics;

  /// Drawer navigation item: The 99 Names of Allah
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله الحسنى'**
  String get drawerNavAsma;

  /// Drawer navigation item: Achievements
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get drawerNavAchievements;

  /// Drawer navigation item: User profile
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get drawerNavProfile;

  /// Drawer navigation item: Settings
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get drawerNavSettings;

  /// Label under the Taqwa points mini-stat card in the drawer
  ///
  /// In ar, this message translates to:
  /// **'نقطة التقوى'**
  String get drawerStatTaqwaPoints;

  /// Label under the consecutive-days streak mini-stat card in the drawer
  ///
  /// In ar, this message translates to:
  /// **'يوم متواصل'**
  String get drawerStatStreakDays;

  /// Label on the logout button at the bottom of the drawer
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get drawerLogoutButton;

  /// Title of the logout confirmation dialog
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get drawerLogoutDialogTitle;

  /// Body text of the logout confirmation dialog
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في تسجيل الخروج؟'**
  String get drawerLogoutDialogBody;

  /// Cancel button in the logout confirmation dialog
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get drawerLogoutDialogCancel;

  /// Confirm button in the logout confirmation dialog
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get drawerLogoutDialogConfirm;

  /// Islamic quote shown in the drawer footer
  ///
  /// In ar, this message translates to:
  /// **'\"حَاسِبُوا أَنفُسَكُمْ قَبْلَ أَنْ تُحَاسَبُوا\"'**
  String get drawerFooterQuote;

  /// App version label shown in the drawer footer
  ///
  /// In ar, this message translates to:
  /// **' v1.0.5'**
  String get drawerFooterVersion;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @duaCategoryMorning.
  ///
  /// In ar, this message translates to:
  /// **'الصباح'**
  String get duaCategoryMorning;

  /// No description provided for @duaCategoryEvening.
  ///
  /// In ar, this message translates to:
  /// **'المساء'**
  String get duaCategoryEvening;

  /// No description provided for @duaCategorySleep.
  ///
  /// In ar, this message translates to:
  /// **'النوم'**
  String get duaCategorySleep;

  /// No description provided for @duaCategoryWakingUp.
  ///
  /// In ar, this message translates to:
  /// **'الاستيقاظ'**
  String get duaCategoryWakingUp;

  /// No description provided for @duaCategoryDistress.
  ///
  /// In ar, this message translates to:
  /// **'الكرب'**
  String get duaCategoryDistress;

  /// No description provided for @duaCategoryGuidance.
  ///
  /// In ar, this message translates to:
  /// **'الهداية'**
  String get duaCategoryGuidance;

  /// No description provided for @duaCategoryForgiveness.
  ///
  /// In ar, this message translates to:
  /// **'المغفرة'**
  String get duaCategoryForgiveness;

  /// No description provided for @duaCategoryRizq.
  ///
  /// In ar, this message translates to:
  /// **'الرزق'**
  String get duaCategoryRizq;

  /// No description provided for @duaCategoryHealth.
  ///
  /// In ar, this message translates to:
  /// **'الصحة'**
  String get duaCategoryHealth;

  /// No description provided for @duaCategoryParents.
  ///
  /// In ar, this message translates to:
  /// **'الوالدين'**
  String get duaCategoryParents;

  /// No description provided for @duaCategoryTravel.
  ///
  /// In ar, this message translates to:
  /// **'السفر'**
  String get duaCategoryTravel;

  /// No description provided for @duaCategoryRain.
  ///
  /// In ar, this message translates to:
  /// **'الاستسقاء'**
  String get duaCategoryRain;

  /// No description provided for @duaCategoryIstikhara.
  ///
  /// In ar, this message translates to:
  /// **'الاستخارة'**
  String get duaCategoryIstikhara;

  /// No description provided for @duaCategoryMosque.
  ///
  /// In ar, this message translates to:
  /// **'المسجد'**
  String get duaCategoryMosque;

  /// No description provided for @duaCategoryKnowledge.
  ///
  /// In ar, this message translates to:
  /// **'طلب العلم'**
  String get duaCategoryKnowledge;

  /// No description provided for @duaCategoryAfterPrayer.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصلاة'**
  String get duaCategoryAfterPrayer;

  /// No description provided for @duaCategoryHome.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get duaCategoryHome;

  /// No description provided for @duaCategoryFood.
  ///
  /// In ar, this message translates to:
  /// **'الطعام'**
  String get duaCategoryFood;

  /// No description provided for @duaCategoryAnger.
  ///
  /// In ar, this message translates to:
  /// **'الغضب'**
  String get duaCategoryAnger;

  /// No description provided for @duaCategoryClothing.
  ///
  /// In ar, this message translates to:
  /// **'اللباس'**
  String get duaCategoryClothing;

  /// No description provided for @duaCategoryGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عامة'**
  String get duaCategoryGeneral;

  /// No description provided for @duaCategoryOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get duaCategoryOther;

  /// No description provided for @duaCategoryAllFilter.
  ///
  /// In ar, this message translates to:
  /// **'🤲 الكل'**
  String get duaCategoryAllFilter;

  /// No description provided for @duasScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية المأثورة'**
  String get duasScreenTitle;

  /// No description provided for @duasScreenSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'من الكتاب والسنة'**
  String get duasScreenSubtitle;

  /// No description provided for @duasSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأدعية...'**
  String get duasSearchHint;

  /// No description provided for @duasTabTraditional.
  ///
  /// In ar, this message translates to:
  /// **'المأثورة'**
  String get duasTabTraditional;

  /// No description provided for @duasTabMine.
  ///
  /// In ar, this message translates to:
  /// **'أدعيتي'**
  String get duasTabMine;

  /// No description provided for @duasTabCommunity.
  ///
  /// In ar, this message translates to:
  /// **'من المجتمع'**
  String get duasTabCommunity;

  /// No description provided for @duasNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get duasNoResults;

  /// No description provided for @duasCopiedLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ ✓'**
  String get duasCopiedLabel;

  /// No description provided for @duasCopyTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get duasCopyTooltip;

  /// No description provided for @duasFetchErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في جلب أدعيتك'**
  String get duasFetchErrorMessage;

  /// No description provided for @duasNoUserDuasYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تقم بإضافة أي أدعية بعد'**
  String get duasNoUserDuasYet;

  /// No description provided for @duasShareWithCommunityLabel.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة مع المجتمع'**
  String get duasShareWithCommunityLabel;

  /// No description provided for @duasDeleteDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الدعاء'**
  String get duasDeleteDialogTitle;

  /// No description provided for @duasDeleteConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا الدعاء؟'**
  String get duasDeleteConfirmMessage;

  /// No description provided for @duasSharedSuccessLabel.
  ///
  /// In ar, this message translates to:
  /// **'✅ تمت المشاركة!'**
  String get duasSharedSuccessLabel;

  /// No description provided for @duasShareSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'🌍 مشاركة مع المجتمع'**
  String get duasShareSheetTitle;

  /// No description provided for @duasShareThanksMessage.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لمشاركتك مع مجتمع تقوى 🤍'**
  String get duasShareThanksMessage;

  /// No description provided for @duasCommunityLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل أدعية المجتمع'**
  String get duasCommunityLoadError;

  /// No description provided for @duasCommunityEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أدعية مشتركة حالياً'**
  String get duasCommunityEmptyTitle;

  /// No description provided for @duasPullToRefreshHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للأسفل للتحديث'**
  String get duasPullToRefreshHint;

  /// No description provided for @duasAddSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دعاء'**
  String get duasAddSheetTitle;

  /// No description provided for @duasAddTitleFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدعاء'**
  String get duasAddTitleFieldLabel;

  /// No description provided for @duasAddTextFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'نص الدعاء (عربي)'**
  String get duasAddTextFieldLabel;

  /// No description provided for @duasAddOccasionFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'المناسبة (اختياري)'**
  String get duasAddOccasionFieldLabel;

  /// No description provided for @duasAddShareToggleLabel.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة مع مجتمع تقوى (ليستفيد منه الآخرون)'**
  String get duasAddShareToggleLabel;

  /// No description provided for @adhanSoundMakkah.
  ///
  /// In ar, this message translates to:
  /// **'أذان مكة المكرمة'**
  String get adhanSoundMakkah;

  /// No description provided for @adhanSoundMadinah.
  ///
  /// In ar, this message translates to:
  /// **'أذان المدينة المنورة'**
  String get adhanSoundMadinah;

  /// No description provided for @adhanSoundAlaqsa.
  ///
  /// In ar, this message translates to:
  /// **'أذان المسجد الأقصى'**
  String get adhanSoundAlaqsa;

  /// No description provided for @adhanSoundEgypt.
  ///
  /// In ar, this message translates to:
  /// **'الأذان المصري'**
  String get adhanSoundEgypt;

  /// No description provided for @adhanSoundAbdulBasit.
  ///
  /// In ar, this message translates to:
  /// **'عبد الباسط عبد الصمد'**
  String get adhanSoundAbdulBasit;

  /// No description provided for @adhanSoundMinshawi.
  ///
  /// In ar, this message translates to:
  /// **'محمد صديق المنشاوي'**
  String get adhanSoundMinshawi;

  /// No description provided for @adhanSoundNaghshbandi.
  ///
  /// In ar, this message translates to:
  /// **'سيد النقشبندي'**
  String get adhanSoundNaghshbandi;

  /// No description provided for @adhanSoundSaber.
  ///
  /// In ar, this message translates to:
  /// **'جامع صابر'**
  String get adhanSoundSaber;

  /// No description provided for @adhanSoundAlHussaini.
  ///
  /// In ar, this message translates to:
  /// **'الحسيني'**
  String get adhanSoundAlHussaini;

  /// No description provided for @adhanSoundBakirBash.
  ///
  /// In ar, this message translates to:
  /// **'بكير باش'**
  String get adhanSoundBakirBash;

  /// No description provided for @adhanSoundHafez.
  ///
  /// In ar, this message translates to:
  /// **'حافظ'**
  String get adhanSoundHafez;

  /// No description provided for @adhanSoundHafizMurad.
  ///
  /// In ar, this message translates to:
  /// **'حافظ مراد'**
  String get adhanSoundHafizMurad;

  /// No description provided for @adhanSoundSharifDoman.
  ///
  /// In ar, this message translates to:
  /// **'شريف دومان'**
  String get adhanSoundSharifDoman;

  /// No description provided for @adhanSoundYusufIslam.
  ///
  /// In ar, this message translates to:
  /// **'يوسف إسلام'**
  String get adhanSoundYusufIslam;

  /// No description provided for @notifPermissionWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'قد لا تعمل إشعارات وأوقات الأذان في وقتها'**
  String get notifPermissionWarningTitle;

  /// No description provided for @notifPermissionWarningBody.
  ///
  /// In ar, this message translates to:
  /// **'امنح إذن الإشعارات والمنبهات الدقيقة ليعمل تذكير الأذان وشاشته في وقتهما بالضبط.'**
  String get notifPermissionWarningBody;

  /// No description provided for @adhanFullScreenIntentLabel.
  ///
  /// In ar, this message translates to:
  /// **'فتح شاشة الأذان فوق التطبيقات'**
  String get adhanFullScreenIntentLabel;

  /// No description provided for @adhanFullScreenIntentSublabel.
  ///
  /// In ar, this message translates to:
  /// **'في أندرويد 14 وما بعده قد يلغي النظام هذا الإذن تلقائياً، فتصبح شاشة الأذان مجرد إشعار عادي. اضغط للتأكد منه ومنحه.'**
  String get adhanFullScreenIntentSublabel;

  /// No description provided for @adhanFullScreenIntentGranted.
  ///
  /// In ar, this message translates to:
  /// **'النافذة الكاملة مفعّلة ✓'**
  String get adhanFullScreenIntentGranted;

  /// No description provided for @adhanFullScreenIntentDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُفعَّل الإذن — فعّله من إعدادات النظام'**
  String get adhanFullScreenIntentDenied;

  /// No description provided for @batteryOptimizationWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'قد يتأخر الأذان بسبب توفير البطارية'**
  String get batteryOptimizationWarningTitle;

  /// No description provided for @batteryOptimizationWarningBody.
  ///
  /// In ar, this message translates to:
  /// **'اسمح للتطبيق بالعمل في الخلفية دون قيود، حتى تصل شاشة الأذان في وقتها وأنت نائم.'**
  String get batteryOptimizationWarningBody;

  /// No description provided for @adhanSettingsAccountSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الحساب'**
  String get adhanSettingsAccountSectionTitle;

  /// No description provided for @adhanMadhabLabel.
  ///
  /// In ar, this message translates to:
  /// **'المذهب'**
  String get adhanMadhabLabel;

  /// No description provided for @madhabShafi.
  ///
  /// In ar, this message translates to:
  /// **'شافعي، مالكي، حنبلي'**
  String get madhabShafi;

  /// No description provided for @madhabHanafi.
  ///
  /// In ar, this message translates to:
  /// **'حنفي'**
  String get madhabHanafi;

  /// No description provided for @adhanCalcMethodLabel.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get adhanCalcMethodLabel;

  /// No description provided for @adhanLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get adhanLocationLabel;

  /// No description provided for @adhanLocationSublabel.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لتحديد موقعك أو اختياره يدوياً'**
  String get adhanLocationSublabel;

  /// No description provided for @calcMethodAlgeria.
  ///
  /// In ar, this message translates to:
  /// **'الجزائر (وزارة الشؤون الدينية)'**
  String get calcMethodAlgeria;

  /// No description provided for @calcMethodMWL.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get calcMethodMWL;

  /// No description provided for @calcMethodEgypt.
  ///
  /// In ar, this message translates to:
  /// **'دار الإفتاء المصرية'**
  String get calcMethodEgypt;

  /// No description provided for @calcMethodKarachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة كراتشي'**
  String get calcMethodKarachi;

  /// No description provided for @calcMethodUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى (مكة المكرمة)'**
  String get calcMethodUmmAlQura;

  /// No description provided for @calcMethodISNA.
  ///
  /// In ar, this message translates to:
  /// **'أمريكا الشمالية'**
  String get calcMethodISNA;

  /// No description provided for @highLatitudeRuleLabel.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة خطوط العرض العليا'**
  String get highLatitudeRuleLabel;

  /// No description provided for @highLatitudeRuleMiddleOfNight.
  ///
  /// In ar, this message translates to:
  /// **'منتصف الليل'**
  String get highLatitudeRuleMiddleOfNight;

  /// No description provided for @highLatitudeRuleSeventhOfNight.
  ///
  /// In ar, this message translates to:
  /// **'سُبع الليل'**
  String get highLatitudeRuleSeventhOfNight;

  /// No description provided for @highLatitudeRuleTwilightAngle.
  ///
  /// In ar, this message translates to:
  /// **'زاوية الشفق'**
  String get highLatitudeRuleTwilightAngle;

  /// No description provided for @settingsAdjustmentsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل أوقات الصلاة يدوياً'**
  String get settingsAdjustmentsSectionTitle;

  /// No description provided for @settingsAdjustmentsSectionSublabel.
  ///
  /// In ar, this message translates to:
  /// **'إذا اختلف وقت الأذان في مسجدك عن الوقت المحسوب، يمكنك ضبط كل صلاة بالدقائق'**
  String get settingsAdjustmentsSectionSublabel;

  /// Compact signed minute-offset label, e.g. "+3 د" or "-2 د"
  ///
  /// In ar, this message translates to:
  /// **'{value} د'**
  String settingsOffsetMinutesShort(String value);

  /// No description provided for @adhanSoundSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوت الأذان'**
  String get adhanSoundSectionTitle;

  /// No description provided for @adhanModeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وضع الأذان'**
  String get adhanModeLabel;

  /// No description provided for @adhanModeSound.
  ///
  /// In ar, this message translates to:
  /// **'صوت'**
  String get adhanModeSound;

  /// No description provided for @adhanModeVibrate.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز'**
  String get adhanModeVibrate;

  /// No description provided for @adhanModeSilent.
  ///
  /// In ar, this message translates to:
  /// **'صامت'**
  String get adhanModeSilent;

  /// No description provided for @adhanVolumeLabel.
  ///
  /// In ar, this message translates to:
  /// **'مستوى الصوت'**
  String get adhanVolumeLabel;

  /// No description provided for @adhanVibrateTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الاهتزاز'**
  String get adhanVibrateTypeLabel;

  /// No description provided for @adhanVibrateTypeSublabel.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز مصاحب للأذان'**
  String get adhanVibrateTypeSublabel;

  /// No description provided for @adhanAdvancedSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'خصائص متقدمة'**
  String get adhanAdvancedSectionTitle;

  /// No description provided for @adhanAutoSilentLabel.
  ///
  /// In ar, this message translates to:
  /// **'التحويل إلى الصامت'**
  String get adhanAutoSilentLabel;

  /// No description provided for @adhanAutoSilentSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل وضع الصامت بعد الأذان'**
  String get adhanAutoSilentSublabel;

  /// No description provided for @adhanSilentModeSettingsLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الوضع الصامت'**
  String get adhanSilentModeSettingsLabel;

  /// No description provided for @adhanSilentModeSettingsSublabel.
  ///
  /// In ar, this message translates to:
  /// **'إدارة خيارات وضع الصامت'**
  String get adhanSilentModeSettingsSublabel;

  /// No description provided for @adhanEnableInSilentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الأذان في الوضع الصامت'**
  String get adhanEnableInSilentLabel;

  /// No description provided for @adhanEnableInSilentSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الأذان حتى وإن كان الجهاز في وضع الصامت'**
  String get adhanEnableInSilentSublabel;

  /// No description provided for @adhanEnableNotifInSilentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل التنبيهات في الوضع الصامت'**
  String get adhanEnableNotifInSilentLabel;

  /// No description provided for @adhanEnableNotifInSilentSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل صوت التنبيهات حتى وإن كان الجهاز في وضع الصامت'**
  String get adhanEnableNotifInSilentSublabel;

  /// No description provided for @adhanNotifSilentSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات المفعلة في الوضع الصامت'**
  String get adhanNotifSilentSheetTitle;

  /// No description provided for @adhanSystemNotifSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات النظام'**
  String get adhanSystemNotifSectionTitle;

  /// No description provided for @adhanScreenEnabledLabel.
  ///
  /// In ar, this message translates to:
  /// **'شاشة الأذان'**
  String get adhanScreenEnabledLabel;

  /// No description provided for @adhanScreenEnabledSublabel.
  ///
  /// In ar, this message translates to:
  /// **'عرض شاشة الأذان الكاملة عند دخول وقت الصلاة'**
  String get adhanScreenEnabledSublabel;

  /// No description provided for @adhanWakeScreenLabel.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الشاشة أثناء الأذان'**
  String get adhanWakeScreenLabel;

  /// No description provided for @adhanWakeScreenSublabel.
  ///
  /// In ar, this message translates to:
  /// **'إبقاء الشاشة مفعلة عند تشغيل الأذان'**
  String get adhanWakeScreenSublabel;

  /// No description provided for @adhanFlipToSilenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'ايقاف الأذان عند قلب الجهاز'**
  String get adhanFlipToSilenceLabel;

  /// No description provided for @adhanFlipToSilenceSublabel.
  ///
  /// In ar, this message translates to:
  /// **'اقلب الهاتف على وجهه لإسكات صوت الأذان'**
  String get adhanFlipToSilenceSublabel;

  /// No description provided for @adhanAlarmNotifLabel.
  ///
  /// In ar, this message translates to:
  /// **'إشعار الأذان بالجرس المنبه'**
  String get adhanAlarmNotifLabel;

  /// No description provided for @adhanAlarmNotifSublabel.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه حتى في وضع الصامت'**
  String get adhanAlarmNotifSublabel;

  /// No description provided for @adhanOngoingNotifLabel.
  ///
  /// In ar, this message translates to:
  /// **'إشعار دائم بأوقات الصلاة'**
  String get adhanOngoingNotifLabel;

  /// No description provided for @adhanOngoingNotifSublabel.
  ///
  /// In ar, this message translates to:
  /// **'إظهار شريط إشعار دائم بالمتبقي للصلاة'**
  String get adhanOngoingNotifSublabel;

  /// AppBar title on the About the Developer screen
  ///
  /// In ar, this message translates to:
  /// **'عن المطور'**
  String get aboutScreenTitle;

  /// Section heading: about the developer
  ///
  /// In ar, this message translates to:
  /// **'عن المطور'**
  String get aboutSectionDeveloper;

  /// Section heading: technical skills
  ///
  /// In ar, this message translates to:
  /// **'المهارات التقنية'**
  String get aboutSectionSkills;

  /// Section heading: connect with me / social links
  ///
  /// In ar, this message translates to:
  /// **'تواصل معي'**
  String get aboutSectionConnect;

  /// Developer's full name in Arabic
  ///
  /// In ar, this message translates to:
  /// **'عماد الدين عينين'**
  String get aboutDevNameArabic;

  /// Developer's full name in Latin script
  ///
  /// In ar, this message translates to:
  /// **'Imadeddine Ainine'**
  String get aboutDevNameLatin;

  /// Role badge shown under the developer's name
  ///
  /// In ar, this message translates to:
  /// **'Fullstack Developer'**
  String get aboutDevBadge;

  /// Short developer biography shown on the About screen
  ///
  /// In ar, this message translates to:
  /// **'مطور برمجيات شغوف ببناء تطبيقات الهاتف والمواقع الإلكترونية بأحدث التقنيات. أهتم بجودة الكود وتجربة المستخدم، وأسعى دوماً لتقديم حلول تقنية مبتكرة تخدم المجتمع المسلم.'**
  String get aboutBio;

  /// Footer line asking users to make dua for the developer
  ///
  /// In ar, this message translates to:
  /// **'ادعوا لي من خالص دعائكم'**
  String get aboutFooterDuaRequest;

  /// Footer tagline: made with love for the Muslim community
  ///
  /// In ar, this message translates to:
  /// **'صنع بكل حب للأمة الإسلامية'**
  String get aboutFooterMadeWithLove;

  /// Copyright line in the About screen footer
  ///
  /// In ar, this message translates to:
  /// **'© 2026 - Imadeddine Ainine'**
  String get aboutFooterCopyright;

  /// AppBar title on the Khatma progress screen
  ///
  /// In ar, this message translates to:
  /// **'تقدم الختمة'**
  String get khatmaScreenTitle;

  /// Progress label, e.g. '9.9٪ مكتملة'
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪ مكتملة'**
  String khatmaProgressPercent(String percent);

  /// Stat card label: number of completed khatmas
  ///
  /// In ar, this message translates to:
  /// **'ختمات مكتملة'**
  String get khatmaStatCompletedLabel;

  /// Stat card label: consecutive days reading
  ///
  /// In ar, this message translates to:
  /// **'أيام متواصلة'**
  String get khatmaStatStreakLabel;

  /// Stat card label: average pages per day
  ///
  /// In ar, this message translates to:
  /// **'صفحة/يوم'**
  String get khatmaStatPagesPerDayLabel;

  /// Title above the weekly reading bar chart
  ///
  /// In ar, this message translates to:
  /// **'القراءة الأسبوعية'**
  String get khatmaWeeklyChartTitle;

  /// No description provided for @khatmaDaySun.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get khatmaDaySun;

  /// No description provided for @khatmaDayMon.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get khatmaDayMon;

  /// No description provided for @khatmaDayTue.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get khatmaDayTue;

  /// No description provided for @khatmaDayWed.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get khatmaDayWed;

  /// No description provided for @khatmaDayThu.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get khatmaDayThu;

  /// No description provided for @khatmaDayFri.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get khatmaDayFri;

  /// No description provided for @khatmaDaySat.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get khatmaDaySat;

  /// Full weekday name: Sunday
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get weekdayFullSunday;

  /// Two-letter weekday abbreviation: Sunday
  ///
  /// In ar, this message translates to:
  /// **'أح'**
  String get weekdayShortSunday;

  /// Single-letter weekday initial: Sunday
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get weekdayInitialSunday;

  /// Full weekday name: Monday
  ///
  /// In ar, this message translates to:
  /// **'الإثنين'**
  String get weekdayFullMonday;

  /// Two-letter weekday abbreviation: Monday
  ///
  /// In ar, this message translates to:
  /// **'إث'**
  String get weekdayShortMonday;

  /// Single-letter weekday initial: Monday
  ///
  /// In ar, this message translates to:
  /// **'ن'**
  String get weekdayInitialMonday;

  /// Full weekday name: Tuesday
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get weekdayFullTuesday;

  /// Two-letter weekday abbreviation: Tuesday
  ///
  /// In ar, this message translates to:
  /// **'ثل'**
  String get weekdayShortTuesday;

  /// Single-letter weekday initial: Tuesday
  ///
  /// In ar, this message translates to:
  /// **'ث'**
  String get weekdayInitialTuesday;

  /// Full weekday name: Wednesday
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get weekdayFullWednesday;

  /// Two-letter weekday abbreviation: Wednesday
  ///
  /// In ar, this message translates to:
  /// **'أر'**
  String get weekdayShortWednesday;

  /// Single-letter weekday initial: Wednesday
  ///
  /// In ar, this message translates to:
  /// **'ر'**
  String get weekdayInitialWednesday;

  /// Full weekday name: Thursday
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get weekdayFullThursday;

  /// Two-letter weekday abbreviation: Thursday
  ///
  /// In ar, this message translates to:
  /// **'خم'**
  String get weekdayShortThursday;

  /// Single-letter weekday initial: Thursday
  ///
  /// In ar, this message translates to:
  /// **'خ'**
  String get weekdayInitialThursday;

  /// Full weekday name: Friday
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get weekdayFullFriday;

  /// Two-letter weekday abbreviation: Friday
  ///
  /// In ar, this message translates to:
  /// **'جم'**
  String get weekdayShortFriday;

  /// Single-letter weekday initial: Friday
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get weekdayInitialFriday;

  /// Full weekday name: Saturday
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get weekdayFullSaturday;

  /// Two-letter weekday abbreviation: Saturday
  ///
  /// In ar, this message translates to:
  /// **'سب'**
  String get weekdayShortSaturday;

  /// Single-letter weekday initial: Saturday
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get weekdayInitialSaturday;

  /// The app's own name/brand
  ///
  /// In ar, this message translates to:
  /// **'تقوى'**
  String get appName;

  /// No description provided for @onboardingSignInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لحفظ بياناتك ومزامنتها'**
  String get onboardingSignInSubtitle;

  /// No description provided for @onboardingBenefitSaveProgress.
  ///
  /// In ar, this message translates to:
  /// **'حفظ بياناتك وتقدمك'**
  String get onboardingBenefitSaveProgress;

  /// No description provided for @onboardingBenefitCompete.
  ///
  /// In ar, this message translates to:
  /// **'التنافس مع المسلمين حول العالم'**
  String get onboardingBenefitCompete;

  /// No description provided for @onboardingBenefitStats.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات مفصلة ومتقدمة'**
  String get onboardingBenefitStats;

  /// No description provided for @onboardingBenefitSync.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة تلقائية بين أجهزتك'**
  String get onboardingBenefitSync;

  /// No description provided for @onboardingContinueWithoutAccount.
  ///
  /// In ar, this message translates to:
  /// **'متابعة بدون حساب'**
  String get onboardingContinueWithoutAccount;

  /// No description provided for @onboardingChoosePlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطتك'**
  String get onboardingChoosePlanTitle;

  /// No description provided for @onboardingChoosePlanSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى عائلة تقوى'**
  String get onboardingChoosePlanSubtitle;

  /// No description provided for @onboardingPremiumTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقوى ⭐ Premium'**
  String get onboardingPremiumTitle;

  /// No description provided for @onboardingPremiumDesc.
  ///
  /// In ar, this message translates to:
  /// **'بلا إعلانات + إحصائيات متقدمة + مزامنة سحابية + دعم أولوي'**
  String get onboardingPremiumDesc;

  /// No description provided for @onboardingPremiumBadge.
  ///
  /// In ar, this message translates to:
  /// **'الأفضل'**
  String get onboardingPremiumBadge;

  /// Hardcoded Algerian Dinar price — not currency-aware
  ///
  /// In ar, this message translates to:
  /// **'99 دج / شهر'**
  String get onboardingPremiumPrice;

  /// No description provided for @onboardingPremiumFeature1.
  ///
  /// In ar, this message translates to:
  /// **'بلا إعلانات نهائياً'**
  String get onboardingPremiumFeature1;

  /// No description provided for @onboardingPremiumFeature2.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات متقدمة ورسوم بيانية'**
  String get onboardingPremiumFeature2;

  /// No description provided for @onboardingPremiumFeature3.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة سحابية تلقائية'**
  String get onboardingPremiumFeature3;

  /// No description provided for @onboardingPremiumFeature4.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات مخصصة لا نهاية لها'**
  String get onboardingPremiumFeature4;

  /// No description provided for @onboardingPremiumFeature5.
  ///
  /// In ar, this message translates to:
  /// **'أولوية في الدعم الفني'**
  String get onboardingPremiumFeature5;

  /// No description provided for @onboardingFreeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقوى 🌙 مجاني'**
  String get onboardingFreeTitle;

  /// No description provided for @onboardingFreeDesc.
  ///
  /// In ar, this message translates to:
  /// **'جميع الميزات الأساسية مع إعلانات بسيطة للإبقاء على الخدمة'**
  String get onboardingFreeDesc;

  /// No description provided for @onboardingFreeFeature1.
  ///
  /// In ar, this message translates to:
  /// **'جميع ميزات المحاسبة'**
  String get onboardingFreeFeature1;

  /// No description provided for @onboardingFreeFeature2.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة والقبلة'**
  String get onboardingFreeFeature2;

  /// No description provided for @onboardingFreeFeature3.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار والأدعية'**
  String get onboardingFreeFeature3;

  /// No description provided for @onboardingFreeFeature4.
  ///
  /// In ar, this message translates to:
  /// **'إعلانات بسيطة'**
  String get onboardingFreeFeature4;

  /// No description provided for @onboardingStartPremiumCta.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ Premium 🌟'**
  String get onboardingStartPremiumCta;

  /// No description provided for @onboardingStartFreeCta.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مجاناً 🤲'**
  String get onboardingStartFreeCta;

  /// Decorative demo text in an onboarding illustration graphic
  ///
  /// In ar, this message translates to:
  /// **'سبحان الله'**
  String get onboardingDemoTasbeehText;

  /// No description provided for @notifChannelPrayerSoundName.
  ///
  /// In ar, this message translates to:
  /// **'أذان الصلاة (صوت)'**
  String get notifChannelPrayerSoundName;

  /// No description provided for @notifChannelPrayerSoundDesc.
  ///
  /// In ar, this message translates to:
  /// **'إشعار وقت الأذان مع صوت الأذان'**
  String get notifChannelPrayerSoundDesc;

  /// No description provided for @notifChannelPrayerVibrateName.
  ///
  /// In ar, this message translates to:
  /// **'أذان الصلاة (اهتزاز)'**
  String get notifChannelPrayerVibrateName;

  /// No description provided for @notifChannelPrayerVibrateDesc.
  ///
  /// In ar, this message translates to:
  /// **'إشعار وقت الأذان باهتزاز فقط'**
  String get notifChannelPrayerVibrateDesc;

  /// No description provided for @notifChannelPrayerSilentName.
  ///
  /// In ar, this message translates to:
  /// **'أذان الصلاة (صامت)'**
  String get notifChannelPrayerSilentName;

  /// No description provided for @notifChannelPrayerSilentDesc.
  ///
  /// In ar, this message translates to:
  /// **'إشعار صامت لوقت الأذان'**
  String get notifChannelPrayerSilentDesc;

  /// No description provided for @notifChannelAlertName.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصلاة'**
  String get notifChannelAlertName;

  /// No description provided for @notifChannelAlertDesc.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات قبل الأذان وبعد الإقامة'**
  String get notifChannelAlertDesc;

  /// No description provided for @notifChannelMuhasabaName.
  ///
  /// In ar, this message translates to:
  /// **'محاسبة النفس'**
  String get notifChannelMuhasabaName;

  /// No description provided for @notifChannelMuhasabaDesc.
  ///
  /// In ar, this message translates to:
  /// **'تذكير محاسبة النفس المسائية'**
  String get notifChannelMuhasabaDesc;

  /// No description provided for @notifChannelAdhkarName.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار اليومية'**
  String get notifChannelAdhkarName;

  /// No description provided for @notifChannelAdhkarDesc.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح والمساء وبعد الصلاة'**
  String get notifChannelAdhkarDesc;

  /// No description provided for @notifChannelDuasName.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get notifChannelDuasName;

  /// No description provided for @notifChannelDuasDesc.
  ///
  /// In ar, this message translates to:
  /// **'نفحات من الأدعية النبوية والقرآنية'**
  String get notifChannelDuasDesc;

  /// No description provided for @notifChannelAchievementName.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get notifChannelAchievementName;

  /// No description provided for @notifChannelAchievementDesc.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات الإنجازات الجديدة'**
  String get notifChannelAchievementDesc;

  /// No description provided for @notifChannelRemindersName.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات إيمانية'**
  String get notifChannelRemindersName;

  /// No description provided for @notifChannelRemindersDesc.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات بسنن الجمعة والصيام والأيام البيض'**
  String get notifChannelRemindersDesc;

  /// No description provided for @notifChannelRamadanName.
  ///
  /// In ar, this message translates to:
  /// **'رمضان المبارك'**
  String get notifChannelRamadanName;

  /// No description provided for @notifChannelRamadanDesc.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات السحور والإفطار'**
  String get notifChannelRamadanDesc;

  /// No description provided for @notifChannelWakeUpAlarmName.
  ///
  /// In ar, this message translates to:
  /// **'منبه الاستيقاظ'**
  String get notifChannelWakeUpAlarmName;

  /// No description provided for @notifChannelWakeUpAlarmDesc.
  ///
  /// In ar, this message translates to:
  /// **'منبه مخصص للاستيقاظ لصلاة الفجر'**
  String get notifChannelWakeUpAlarmDesc;

  /// No description provided for @notifChannelAppUpdatesName.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات التطبيق'**
  String get notifChannelAppUpdatesName;

  /// No description provided for @notifChannelAppUpdatesDesc.
  ///
  /// In ar, this message translates to:
  /// **'إشعار عند توفر إصدار جديد من التطبيق'**
  String get notifChannelAppUpdatesDesc;

  /// Local notification title shown when a newer app version is detected
  ///
  /// In ar, this message translates to:
  /// **'تحديث جديد لتطبيق تقوى 🌙'**
  String get updateAvailableNotifTitle;

  /// Local notification body shown when a newer app version is detected
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version} متوفر الآن — اضغط للتحميل'**
  String updateAvailableNotifBody(String version);

  /// No description provided for @overlayServiceChannelDesc.
  ///
  /// In ar, this message translates to:
  /// **'يُبقي خدمة الأذان والأذكار نشطة'**
  String get overlayServiceChannelDesc;

  /// No description provided for @overlayServiceLoadingPrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل أوقات الصلاة...'**
  String get overlayServiceLoadingPrayerTimes;

  /// No description provided for @overlayServiceOpenAppButton.
  ///
  /// In ar, this message translates to:
  /// **'افتح تقوى'**
  String get overlayServiceOpenAppButton;

  /// No description provided for @overlayServiceUpdateLocationButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الموقع'**
  String get overlayServiceUpdateLocationButton;

  /// No description provided for @overlayServiceUpdatingLocation.
  ///
  /// In ar, this message translates to:
  /// **'🔄 جاري تحديث الموقع...'**
  String get overlayServiceUpdatingLocation;

  /// No description provided for @overlayServiceDefaultCity.
  ///
  /// In ar, this message translates to:
  /// **'الجزائر'**
  String get overlayServiceDefaultCity;

  /// No description provided for @overlayServiceUnknownCity.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get overlayServiceUnknownCity;

  /// No description provided for @overlayServicePrayerTimeOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت الصلاة'**
  String get overlayServicePrayerTimeOverlayTitle;

  /// No description provided for @overlayServicePrayerTimeOverlayContent.
  ///
  /// In ar, this message translates to:
  /// **'حان الآن موعد أذان {prayer}'**
  String overlayServicePrayerTimeOverlayContent(String prayer);

  /// No description provided for @overlayServiceDuaOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعاء من تقوى'**
  String get overlayServiceDuaOverlayTitle;

  /// No description provided for @overlayServiceAdhkarOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكار تقوى'**
  String get overlayServiceAdhkarOverlayTitle;

  /// No description provided for @overlayServiceDuaOverlayContent.
  ///
  /// In ar, this message translates to:
  /// **'دعاء'**
  String get overlayServiceDuaOverlayContent;

  /// No description provided for @overlayServiceAdhkarOverlayContent.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get overlayServiceAdhkarOverlayContent;

  /// No description provided for @prayerScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة'**
  String get prayerScreenTitle;

  /// No description provided for @prayerScreenIqamaTimeFor.
  ///
  /// In ar, this message translates to:
  /// **'وقت الإقامة — {prayer}'**
  String prayerScreenIqamaTimeFor(String prayer);

  /// No description provided for @prayerScreenPrayerFor.
  ///
  /// In ar, this message translates to:
  /// **'صلاة {prayer}'**
  String prayerScreenPrayerFor(String prayer);

  /// No description provided for @prayerScreenEstablishPrayer.
  ///
  /// In ar, this message translates to:
  /// **'أقم الصلاة'**
  String get prayerScreenEstablishPrayer;

  /// No description provided for @prayerScreenNextPrayerLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get prayerScreenNextPrayerLabel;

  /// No description provided for @prayerScreenIqamaCountdownLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإقامة بعد'**
  String get prayerScreenIqamaCountdownLabel;

  /// No description provided for @prayerScreenAdhanCountdownLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأذان بعد'**
  String get prayerScreenAdhanCountdownLabel;

  /// No description provided for @prayerScreenGetReady.
  ///
  /// In ar, this message translates to:
  /// **'استعد'**
  String get prayerScreenGetReady;

  /// No description provided for @prayerScreenAdhanTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت الأذان'**
  String get prayerScreenAdhanTimeLabel;

  /// No description provided for @prayerScreenSalvationSlogan.
  ///
  /// In ar, this message translates to:
  /// **'صلاتك نجاتك'**
  String get prayerScreenSalvationSlogan;

  /// No description provided for @prayerScreenIqamaTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت الإقامة'**
  String get prayerScreenIqamaTimeLabel;

  /// No description provided for @prayerScreenIqamaOffsetShort.
  ///
  /// In ar, this message translates to:
  /// **'+{minutes}د'**
  String prayerScreenIqamaOffsetShort(int minutes);

  /// No description provided for @prayerScreenIqamaAfterMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{بعد دقيقة واحدة} two{بعد دقيقتين} few{بعد {count} دقائق} many{بعد {count} دقيقة} other{بعد {count} دقيقة}}'**
  String prayerScreenIqamaAfterMinutes(num count);

  /// No description provided for @prayerScreenTodaysPrayers.
  ///
  /// In ar, this message translates to:
  /// **'صلوات اليوم'**
  String get prayerScreenTodaysPrayers;

  /// No description provided for @prayerScreenAdhanNowBadge.
  ///
  /// In ar, this message translates to:
  /// **'الأذان الآن'**
  String get prayerScreenAdhanNowBadge;

  /// No description provided for @prayerScreenSunriseBadge.
  ///
  /// In ar, this message translates to:
  /// **'شروق'**
  String get prayerScreenSunriseBadge;

  /// No description provided for @prayerScreenAdhanBadge.
  ///
  /// In ar, this message translates to:
  /// **'أذان'**
  String get prayerScreenAdhanBadge;

  /// No description provided for @prayerScreenIqamaBadge.
  ///
  /// In ar, this message translates to:
  /// **'إقامة'**
  String get prayerScreenIqamaBadge;

  /// No description provided for @prayerScreenLocationErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد الموقع'**
  String get prayerScreenLocationErrorTitle;

  /// No description provided for @prayerScreenLocationErrorSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من تفعيل GPS'**
  String get prayerScreenLocationErrorSubtitle;

  /// No description provided for @prayerScreenRetryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get prayerScreenRetryButton;

  /// No description provided for @quranReaderFallbackName.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get quranReaderFallbackName;

  /// No description provided for @quranReaderMeccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get quranReaderMeccan;

  /// No description provided for @quranReaderMedinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get quranReaderMedinan;

  /// No description provided for @quranReaderSurahHeaderTitle.
  ///
  /// In ar, this message translates to:
  /// **'سُورَةُ {name}'**
  String quranReaderSurahHeaderTitle(String name);

  /// No description provided for @quranReaderAyahCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{آية واحدة} two{آيتان} few{{count} آيات} many{{count} آية} other{{count} آية}}'**
  String quranReaderAyahCountBadge(num count);

  /// No description provided for @quranReaderSurahLabel.
  ///
  /// In ar, this message translates to:
  /// **'سورة {name}'**
  String quranReaderSurahLabel(String name);

  /// No description provided for @quranReaderAyahRefLabel.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah} — سورة {surah}'**
  String quranReaderAyahRefLabel(String ayah, String surah);

  /// No description provided for @quranReaderJuzChip.
  ///
  /// In ar, this message translates to:
  /// **'جزء: {juz}'**
  String quranReaderJuzChip(String juz);

  /// No description provided for @quranReaderPageOfTotalChip.
  ///
  /// In ar, this message translates to:
  /// **'صفحة: {current} من {total}'**
  String quranReaderPageOfTotalChip(String current, String total);

  /// No description provided for @quranReaderReadCountChip.
  ///
  /// In ar, this message translates to:
  /// **'قرأت {read} من {total} صفحات'**
  String quranReaderReadCountChip(String read, String total);

  /// No description provided for @quranReaderGuideTitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل القراءة'**
  String get quranReaderGuideTitle;

  /// No description provided for @quranReaderGuideTapToggle.
  ///
  /// In ar, this message translates to:
  /// **'اضغط ضغطة واحدة لإظهار أو إخفاء أزرار التحكم'**
  String get quranReaderGuideTapToggle;

  /// No description provided for @quranReaderGuideDoubleTapZoom.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مرتين للتكبير والتصغير'**
  String get quranReaderGuideDoubleTapZoom;

  /// No description provided for @quranReaderGuideSwipeNavigate.
  ///
  /// In ar, this message translates to:
  /// **'اسحب يميناً أو يساراً للتنقل بين الصفحات'**
  String get quranReaderGuideSwipeNavigate;

  /// No description provided for @quranReaderGuideLongPress.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على أي آية لعرض:'**
  String get quranReaderGuideLongPress;

  /// No description provided for @quranReaderGuideSaveAyah.
  ///
  /// In ar, this message translates to:
  /// **'⭐ حفظ الآية كمرجع'**
  String get quranReaderGuideSaveAyah;

  /// No description provided for @quranReaderGuideShareAyah.
  ///
  /// In ar, this message translates to:
  /// **'📤 مشاركة الآية (نص أو صورة أو فيديو)'**
  String get quranReaderGuideShareAyah;

  /// No description provided for @quranReaderGuideTafsir.
  ///
  /// In ar, this message translates to:
  /// **'📖 التفسير الميسر'**
  String get quranReaderGuideTafsir;

  /// No description provided for @quranReaderGuideTranslation.
  ///
  /// In ar, this message translates to:
  /// **'🌐 الترجمة'**
  String get quranReaderGuideTranslation;

  /// No description provided for @quranReaderGuideListen.
  ///
  /// In ar, this message translates to:
  /// **'🔊 استماع للآية أو الصفحة أو السورة'**
  String get quranReaderGuideListen;

  /// No description provided for @quranReaderGuideAudioButton.
  ///
  /// In ar, this message translates to:
  /// **'زر السماعة في الأعلى للاستماع للصفحة كاملة'**
  String get quranReaderGuideAudioButton;

  /// No description provided for @quranReaderGuideNightModeButton.
  ///
  /// In ar, this message translates to:
  /// **'زر الوضع الليلي لتبديل المظهر'**
  String get quranReaderGuideNightModeButton;

  /// No description provided for @quranReaderGuideGotIt.
  ///
  /// In ar, this message translates to:
  /// **'فهمت ✓'**
  String get quranReaderGuideGotIt;

  /// No description provided for @quranReaderPageJumpError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رقم صحيح بين ١ و {max}'**
  String quranReaderPageJumpError(String max);

  /// No description provided for @quranReaderGoToPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال إلى صفحة'**
  String get quranReaderGoToPageTitle;

  /// No description provided for @quranReaderCurrentPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'أنت الآن في صفحة {page}'**
  String quranReaderCurrentPageLabel(String page);

  /// No description provided for @quranReaderPageInputLabel.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الصفحة ({range})'**
  String quranReaderPageInputLabel(String range);

  /// No description provided for @quranReaderPageRangeHint.
  ///
  /// In ar, this message translates to:
  /// **'١ - {max}'**
  String quranReaderPageRangeHint(String max);

  /// No description provided for @quranReaderCancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get quranReaderCancelButton;

  /// No description provided for @quranReaderGoButton.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get quranReaderGoButton;

  /// No description provided for @quranReaderSaveAyahOption.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الآية كمرجع'**
  String get quranReaderSaveAyahOption;

  /// No description provided for @quranReaderShareAyahOption.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الآية'**
  String get quranReaderShareAyahOption;

  /// No description provided for @quranReaderTafsirOption.
  ///
  /// In ar, this message translates to:
  /// **'التفسير الميسر'**
  String get quranReaderTafsirOption;

  /// No description provided for @quranReaderTranslationOption.
  ///
  /// In ar, this message translates to:
  /// **'الترجمة'**
  String get quranReaderTranslationOption;

  /// No description provided for @quranReaderListenAyahOption.
  ///
  /// In ar, this message translates to:
  /// **'استماع للآية'**
  String get quranReaderListenAyahOption;

  /// No description provided for @quranReaderComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة قيد التطوير قريباً'**
  String get quranReaderComingSoon;

  /// No description provided for @quranReaderAudioError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل الصوت، تحقق من اتصالك بالإنترنت'**
  String get quranReaderAudioError;

  /// No description provided for @quranReaderSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات القراءة'**
  String get quranReaderSettingsTitle;

  /// No description provided for @quranReaderFontSizeLabel.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get quranReaderFontSizeLabel;

  /// No description provided for @quranReaderBackgroundStyleLabel.
  ///
  /// In ar, this message translates to:
  /// **'نمط الخلفية'**
  String get quranReaderBackgroundStyleLabel;

  /// No description provided for @quranReaderThemeNight.
  ///
  /// In ar, this message translates to:
  /// **'ليلي'**
  String get quranReaderThemeNight;

  /// No description provided for @quranReaderThemeSepia.
  ///
  /// In ar, this message translates to:
  /// **'عاجي'**
  String get quranReaderThemeSepia;

  /// No description provided for @quranReaderThemeWhite.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get quranReaderThemeWhite;

  /// No description provided for @createKhatmaDefaultNamePrefix.
  ///
  /// In ar, this message translates to:
  /// **'ختمة {monthYear}'**
  String createKhatmaDefaultNamePrefix(String monthYear);

  /// No description provided for @createKhatmaTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ختمة جديدة'**
  String get createKhatmaTitle;

  /// No description provided for @createKhatmaNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الختمة'**
  String get createKhatmaNameLabel;

  /// No description provided for @createKhatmaTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الختمة'**
  String get createKhatmaTypeLabel;

  /// No description provided for @createKhatmaTypeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الختمة التي تريد إنشاءها'**
  String get createKhatmaTypeSubtitle;

  /// No description provided for @createKhatmaTypeMuyassaraTitle.
  ///
  /// In ar, this message translates to:
  /// **'ختمة ميسرة'**
  String get createKhatmaTypeMuyassaraTitle;

  /// No description provided for @createKhatmaTypeMuyassaraDesc.
  ///
  /// In ar, this message translates to:
  /// **'قراءة القرآن كاملاً بالترتيب بدون ورد يومي محدد أو وقت ختم محدد'**
  String get createKhatmaTypeMuyassaraDesc;

  /// No description provided for @createKhatmaTypeMultazimaTitle.
  ///
  /// In ar, this message translates to:
  /// **'ختمة ملتزمة'**
  String get createKhatmaTypeMultazimaTitle;

  /// No description provided for @createKhatmaTypeMultazimaDesc.
  ///
  /// In ar, this message translates to:
  /// **'ختمة مع ورد يومي محدد ووقت ختم محدد'**
  String get createKhatmaTypeMultazimaDesc;

  /// No description provided for @createKhatmaStartDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get createKhatmaStartDateLabel;

  /// No description provided for @createKhatmaStartPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة البداية'**
  String get createKhatmaStartPageLabel;

  /// No description provided for @createKhatmaPageOption.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {n}'**
  String createKhatmaPageOption(String n);

  /// No description provided for @createKhatmaEnableNotifications.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإشعارات'**
  String get createKhatmaEnableNotifications;

  /// No description provided for @createKhatmaNotificationsDisabledWarning.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات معطلة - لن يتم إرسال أي تذكرات'**
  String get createKhatmaNotificationsDisabledWarning;

  /// No description provided for @createKhatmaSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الختمة'**
  String get createKhatmaSummaryTitle;

  /// No description provided for @createKhatmaTypeFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الختمة:'**
  String get createKhatmaTypeFieldLabel;

  /// No description provided for @createKhatmaNameFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الختمة:'**
  String get createKhatmaNameFieldLabel;

  /// No description provided for @createKhatmaStartDateFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية:'**
  String get createKhatmaStartDateFieldLabel;

  /// No description provided for @createKhatmaFirstPageFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الأولى:'**
  String get createKhatmaFirstPageFieldLabel;

  /// No description provided for @createKhatmaNotificationsFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات:'**
  String get createKhatmaNotificationsFieldLabel;

  /// No description provided for @createKhatmaNotificationsEnabledValue.
  ///
  /// In ar, this message translates to:
  /// **'مفعّلة'**
  String get createKhatmaNotificationsEnabledValue;

  /// No description provided for @createKhatmaNotificationsDisabledValue.
  ///
  /// In ar, this message translates to:
  /// **'معطلة'**
  String get createKhatmaNotificationsDisabledValue;

  /// No description provided for @createKhatmaStartReadingHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك البدء في القراءة فوراً بعد إنشاء الختمة'**
  String get createKhatmaStartReadingHint;

  /// No description provided for @createKhatmaPreviousButton.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get createKhatmaPreviousButton;

  /// No description provided for @createKhatmaNextButton.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get createKhatmaNextButton;

  /// No description provided for @createKhatmaCreateButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الختمة'**
  String get createKhatmaCreateButton;

  /// No description provided for @createKhatmaDefaultLabelFallback.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جديدة'**
  String get createKhatmaDefaultLabelFallback;

  /// No description provided for @createKhatmaSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الختمة بنجاح'**
  String get createKhatmaSuccessMessage;

  /// No description provided for @userAdhkarAddButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ذكر'**
  String get userAdhkarAddButton;

  /// No description provided for @userAdhkarEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكاري الخاصة'**
  String get userAdhkarEmptyTitle;

  /// No description provided for @userAdhkarEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أذكار مضافة حالياً.\nاضغط على الزر لإضافة ذكرك الأول.'**
  String get userAdhkarEmptyBody;

  /// No description provided for @adhkarGenericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {error}'**
  String adhkarGenericError(String error);

  /// No description provided for @adhkarCopyTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get adhkarCopyTooltip;

  /// No description provided for @adhkarCopiedSnackbar.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get adhkarCopiedSnackbar;

  /// No description provided for @adhkarShareWithCommunity.
  ///
  /// In ar, this message translates to:
  /// **'شارك مع المجتمع'**
  String get adhkarShareWithCommunity;

  /// No description provided for @adhkarDeleteTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get adhkarDeleteTooltip;

  /// No description provided for @adhkarDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الذكر؟'**
  String get adhkarDeleteConfirmTitle;

  /// No description provided for @adhkarDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا الذكر نهائياً؟'**
  String get adhkarDeleteConfirmBody;

  /// No description provided for @adhkarCancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get adhkarCancelButton;

  /// No description provided for @adhkarShareToCommunityTitle.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة مع المجتمع'**
  String get adhkarShareToCommunityTitle;

  /// No description provided for @adhkarShareToCommunityDesc.
  ///
  /// In ar, this message translates to:
  /// **'سيُضاف الذكر للمراجعة ثم يظهر في تبويب المجتمع'**
  String get adhkarShareToCommunityDesc;

  /// No description provided for @adhkarCountTimesLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{مرة واحدة} two{مرتان} few{{count} مرات} many{{count} مرة} other{{count} مرة}}'**
  String adhkarCountTimesLabel(num count);

  /// No description provided for @adhkarSharedSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تمت المشاركة بنجاح!'**
  String get adhkarSharedSuccessMessage;

  /// No description provided for @communityAdhkarEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجتمع الأذكار'**
  String get communityAdhkarEmptyTitle;

  /// No description provided for @communityAdhkarEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مشاركات من المجتمع حالياً.\nشارك أذكارك من تبويب \"أذكاري\".'**
  String get communityAdhkarEmptyBody;

  /// No description provided for @communityAdhkarRetryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get communityAdhkarRetryButton;

  /// No description provided for @addAdhkarSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ذكر جديد'**
  String get addAdhkarSheetTitle;

  /// No description provided for @addAdhkarTextHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الذكر هنا بحروف عربية واضحة...'**
  String get addAdhkarTextHint;

  /// No description provided for @addAdhkarRepeatCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد التكرار:'**
  String get addAdhkarRepeatCountLabel;

  /// No description provided for @addAdhkarShareToggleDesc.
  ///
  /// In ar, this message translates to:
  /// **'يُضاف الذكر للمراجعة ثم يظهر للجميع'**
  String get addAdhkarShareToggleDesc;

  /// No description provided for @addAdhkarAndShareButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ومشاركة مع المجتمع'**
  String get addAdhkarAndShareButton;

  /// No description provided for @addAdhkarButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة الذكر'**
  String get addAdhkarButton;

  /// No description provided for @locationResultSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الموقع بنجاح ✓'**
  String get locationResultSuccess;

  /// No description provided for @locationResultServiceDisabled.
  ///
  /// In ar, this message translates to:
  /// **'GPS غير مفعّل، يرجى تفعيله'**
  String get locationResultServiceDisabled;

  /// No description provided for @locationResultPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض إذن الموقع'**
  String get locationResultPermissionDenied;

  /// No description provided for @locationResultPermissionDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تفعيل إذن الموقع من الإعدادات'**
  String get locationResultPermissionDeniedForever;

  /// No description provided for @locationResultError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحديد الموقع'**
  String get locationResultError;

  /// No description provided for @locationResultCachedLocation.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد GPS — يتم استخدام الموقع المحفوظ'**
  String get locationResultCachedLocation;

  /// No description provided for @locationEnableAction.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get locationEnableAction;

  /// No description provided for @locationUpdateTileLabel.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الموقع وأوقات الصلاة'**
  String get locationUpdateTileLabel;

  /// No description provided for @timezoneAlgiers.
  ///
  /// In ar, this message translates to:
  /// **'الجزائر (UTC+1)'**
  String get timezoneAlgiers;

  /// No description provided for @timezoneTunis.
  ///
  /// In ar, this message translates to:
  /// **'تونس (UTC+1)'**
  String get timezoneTunis;

  /// No description provided for @timezoneEgypt.
  ///
  /// In ar, this message translates to:
  /// **'مصر (UTC+2)'**
  String get timezoneEgypt;

  /// No description provided for @timezoneRiyadh.
  ///
  /// In ar, this message translates to:
  /// **'الرياض (UTC+3)'**
  String get timezoneRiyadh;

  /// No description provided for @timezoneDubai.
  ///
  /// In ar, this message translates to:
  /// **'دبي (UTC+4)'**
  String get timezoneDubai;

  /// No description provided for @timezoneKuwait.
  ///
  /// In ar, this message translates to:
  /// **'الكويت (UTC+3)'**
  String get timezoneKuwait;

  /// No description provided for @timezoneBeirut.
  ///
  /// In ar, this message translates to:
  /// **'بيروت (UTC+3)'**
  String get timezoneBeirut;

  /// No description provided for @timezoneJerusalem.
  ///
  /// In ar, this message translates to:
  /// **'القدس (UTC+3)'**
  String get timezoneJerusalem;

  /// No description provided for @locationPickerLocationSetTo.
  ///
  /// In ar, this message translates to:
  /// **'تم تحيين الموقع إلى {city} ✓'**
  String locationPickerLocationSetTo(String city);

  /// No description provided for @locationPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الموقع الجغرافي'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر موقعك بدقة لحساب أوقات الصلاة'**
  String get locationPickerSubtitle;

  /// No description provided for @locationPickerOrChooseCity.
  ///
  /// In ar, this message translates to:
  /// **'أو اختر مدينة رئيسية'**
  String get locationPickerOrChooseCity;

  /// No description provided for @locationPickerAutoDetectTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الموقع تلقائياً'**
  String get locationPickerAutoDetectTitle;

  /// No description provided for @locationPickerAutoDetectSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'باستخدام GPS'**
  String get locationPickerAutoDetectSubtitle;

  /// No description provided for @locationPickerSelectButton.
  ///
  /// In ar, this message translates to:
  /// **'اختر'**
  String get locationPickerSelectButton;

  /// No description provided for @manageIbadahTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العادات'**
  String get manageIbadahTitle;

  /// No description provided for @manageIbadahPositiveTab.
  ///
  /// In ar, this message translates to:
  /// **'إيجابية'**
  String get manageIbadahPositiveTab;

  /// No description provided for @manageIbadahNegativeTab.
  ///
  /// In ar, this message translates to:
  /// **'سلبية (محظورات)'**
  String get manageIbadahNegativeTab;

  /// No description provided for @manageIbadahEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عادات مضافة بعد'**
  String get manageIbadahEmpty;

  /// No description provided for @manageIbadahLoadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل البيانات'**
  String get manageIbadahLoadError;

  /// No description provided for @manageIbadahPointsEarned.
  ///
  /// In ar, this message translates to:
  /// **'النقاط: {points}'**
  String manageIbadahPointsEarned(String points);

  /// No description provided for @manageIbadahPointsDeducted.
  ///
  /// In ar, this message translates to:
  /// **'خصم النقاط: {points}'**
  String manageIbadahPointsDeducted(String points);

  /// No description provided for @manageIbadahDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get manageIbadahDeleteConfirmTitle;

  /// No description provided for @manageIbadahDeleteConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف \"{name}\"؟'**
  String manageIbadahDeleteConfirmBody(String name);

  /// No description provided for @manageIbadahCancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get manageIbadahCancelButton;

  /// No description provided for @manageIbadahDeleteButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get manageIbadahDeleteButton;

  /// No description provided for @manageIbadahDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف بنجاح'**
  String get manageIbadahDeletedSuccess;

  /// No description provided for @manageIbadahDeleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الحذف: {error}'**
  String manageIbadahDeleteFailed(String error);

  /// No description provided for @manageIbadahEditHabitTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العادة'**
  String get manageIbadahEditHabitTitle;

  /// No description provided for @manageIbadahEditProhibitionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المحظور'**
  String get manageIbadahEditProhibitionTitle;

  /// No description provided for @manageIbadahAddPositiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عادة إيجابية'**
  String get manageIbadahAddPositiveTitle;

  /// No description provided for @manageIbadahAddNegativeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عادة سلبية (محظور)'**
  String get manageIbadahAddNegativeTitle;

  /// No description provided for @manageIbadahNameFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العادة'**
  String get manageIbadahNameFieldLabel;

  /// No description provided for @manageIbadahRequiredValidation.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get manageIbadahRequiredValidation;

  /// No description provided for @manageIbadahPointsEarnedFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'النقاط التي ستكتسبها'**
  String get manageIbadahPointsEarnedFieldLabel;

  /// No description provided for @manageIbadahPointsDeductedFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'النقاط التي ستُخصم'**
  String get manageIbadahPointsDeductedFieldLabel;

  /// No description provided for @manageIbadahInvalidNumberValidation.
  ///
  /// In ar, this message translates to:
  /// **'رقم غير صحيح'**
  String get manageIbadahInvalidNumberValidation;

  /// No description provided for @manageIbadahSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get manageIbadahSaveButton;

  /// No description provided for @manageIbadahAddButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get manageIbadahAddButton;

  /// No description provided for @manageIbadahUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التعديل بنجاح'**
  String get manageIbadahUpdatedSuccess;

  /// No description provided for @manageIbadahAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت الإضافة بنجاح'**
  String get manageIbadahAddedSuccess;

  /// No description provided for @adhanOverlayPrayerTimeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت {prayer}'**
  String adhanOverlayPrayerTimeTitle(String prayer);

  /// No description provided for @adhanOverlayCloseButton.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get adhanOverlayCloseButton;

  /// No description provided for @adhanOverlayGoToPrayerButton.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب للصلاة'**
  String get adhanOverlayGoToPrayerButton;

  /// No description provided for @adhanOverlayDuaSectionLabel.
  ///
  /// In ar, this message translates to:
  /// **'دعاء ما بعد الأذان'**
  String get adhanOverlayDuaSectionLabel;

  /// No description provided for @hijriEraSuffix.
  ///
  /// In ar, this message translates to:
  /// **'هـ'**
  String get hijriEraSuffix;

  /// No description provided for @authEnterEmailPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد وكلمة المرور'**
  String get authEnterEmailPassword;

  /// No description provided for @authUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get authUnexpectedError;

  /// No description provided for @authEnterUsername.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المستخدم'**
  String get authEnterUsername;

  /// No description provided for @authGoogleConfigIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات Google غير مكتملة: تأكد من إضافة بصمة SHA-1 ومعرف الويب في Google Cloud Console.'**
  String get authGoogleConfigIncomplete;

  /// No description provided for @authGoogleNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بخوادم Google، تحقق من اتصالك بالإنترنت'**
  String get authGoogleNetworkError;

  /// No description provided for @authGoogleGenericError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تسجيل الدخول عبر Google، يرجى المحاولة لاحقاً'**
  String get authGoogleGenericError;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد بريدك الإلكتروني عبر الرابط المرسل إليك أولاً'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorEmailAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول'**
  String get authErrorEmailAlreadyRegistered;

  /// No description provided for @authErrorUsernameTaken.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم مستخدم بالفعل، اختر اسماً آخر'**
  String get authErrorUsernameTaken;

  /// No description provided for @authErrorPasswordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تتكون من 6 خانات على الأقل'**
  String get authErrorPasswordTooShort;

  /// No description provided for @authErrorRateLimit.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت عدد المحاولات المسموح بها، يرجى الانتظار قليلاً'**
  String get authErrorRateLimit;

  /// No description provided for @authErrorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاتصال، تحقق من اتصالك بالإنترنت'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في عملية التسجيل، يرجى المحاولة لاحقاً'**
  String get authErrorGeneric;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'متابعة كضيف — استكشف التطبيق ➜'**
  String get authContinueAsGuest;

  /// No description provided for @authSignInTab.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authSignInTab;

  /// No description provided for @authSignUpTab.
  ///
  /// In ar, this message translates to:
  /// **'حساب جديد'**
  String get authSignUpTab;

  /// No description provided for @authUsernameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get authUsernameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPasswordHint;

  /// No description provided for @authShowPasswordTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get authShowPasswordTooltip;

  /// No description provided for @authHidePasswordTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get authHidePasswordTooltip;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authSecureSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول آمن'**
  String get authSecureSignInButton;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authCreateAccountButton;

  /// No description provided for @authOrSeparator.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get authOrSeparator;

  /// No description provided for @authGoogleSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'الدخول عبر Google'**
  String get authGoogleSignInButton;

  /// No description provided for @authTagline.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في محاسبة النفس والطاعات'**
  String get authTagline;

  /// No description provided for @bottomNavHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get bottomNavHome;

  /// No description provided for @bottomNavQiyam.
  ///
  /// In ar, this message translates to:
  /// **'قيام'**
  String get bottomNavQiyam;

  /// No description provided for @bottomNavMuhasaba.
  ///
  /// In ar, this message translates to:
  /// **'المحاسبة'**
  String get bottomNavMuhasaba;

  /// No description provided for @bottomNavStatistics.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات'**
  String get bottomNavStatistics;

  /// No description provided for @bottomNavAsma.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله'**
  String get bottomNavAsma;

  /// No description provided for @bottomNavSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get bottomNavSettings;

  /// No description provided for @settingEnabled.
  ///
  /// In ar, this message translates to:
  /// **'مفعل'**
  String get settingEnabled;

  /// No description provided for @settingDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطل'**
  String get settingDisabled;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In ar, this message translates to:
  /// **'جاري المزامنة...'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة بنجاح'**
  String get syncStatusSuccess;

  /// No description provided for @syncStatusError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت آخر مزامنة، ستتم إعادة المحاولة تلقائيًا'**
  String get syncStatusError;

  /// No description provided for @syncStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{عنصر واحد بانتظار المزامنة} two{عنصران بانتظار المزامنة} few{{count} عناصر بانتظار المزامنة} many{{count} عنصرًا بانتظار المزامنة} other{{count} عنصر بانتظار المزامنة}}'**
  String syncStatusPending(num count);

  /// No description provided for @overlaySettingsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الشاشة'**
  String get overlaySettingsSectionTitle;

  /// No description provided for @overlaySettingAdhanScreenLabel.
  ///
  /// In ar, this message translates to:
  /// **'شاشة الأذان التلقائية'**
  String get overlaySettingAdhanScreenLabel;

  /// No description provided for @overlaySettingAdhanScreenSublabel.
  ///
  /// In ar, this message translates to:
  /// **'يُظهر شاشة الأذان عند دخول وقت الصلاة'**
  String get overlaySettingAdhanScreenSublabel;

  /// No description provided for @overlaySettingAdhanSoundLabel.
  ///
  /// In ar, this message translates to:
  /// **'صوت الأذان'**
  String get overlaySettingAdhanSoundLabel;

  /// No description provided for @overlaySettingAdhanSoundSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل صوت الأذان تلقائياً عند دخول الوقت'**
  String get overlaySettingAdhanSoundSublabel;

  /// No description provided for @overlaySettingPopupsLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوافذ الأذكار والأدعية'**
  String get overlaySettingPopupsLabel;

  /// No description provided for @overlaySettingPopupsSublabel.
  ///
  /// In ar, this message translates to:
  /// **'يُظهر أذكاراً وأدعيةً بشكل منبثق على الشاشة'**
  String get overlaySettingPopupsSublabel;

  /// No description provided for @overlaySettingIntervalHeader.
  ///
  /// In ar, this message translates to:
  /// **'معدل ظهور الأذكار'**
  String get overlaySettingIntervalHeader;

  /// No description provided for @overlaySettingInterval15Min.
  ///
  /// In ar, this message translates to:
  /// **'كل 15 دقيقة (~96/يوم)'**
  String get overlaySettingInterval15Min;

  /// No description provided for @overlaySettingInterval20Min.
  ///
  /// In ar, this message translates to:
  /// **'كل 20 دقيقة (~72/يوم)'**
  String get overlaySettingInterval20Min;

  /// No description provided for @overlaySettingInterval24Min.
  ///
  /// In ar, this message translates to:
  /// **'كل 24 دقيقة (~60/يوم)'**
  String get overlaySettingInterval24Min;

  /// No description provided for @overlaySettingInterval30Min.
  ///
  /// In ar, this message translates to:
  /// **'كل 30 دقيقة (~48/يوم)'**
  String get overlaySettingInterval30Min;

  /// No description provided for @overlaySettingInterval1Hour.
  ///
  /// In ar, this message translates to:
  /// **'كل ساعة (~24/يوم)'**
  String get overlaySettingInterval1Hour;

  /// No description provided for @overlaySettingInterval2Hours.
  ///
  /// In ar, this message translates to:
  /// **'كل ساعتين (~12/يوم)'**
  String get overlaySettingInterval2Hours;

  /// Daily count estimate for popup windows
  ///
  /// In ar, this message translates to:
  /// **'ستظهر النوافذ ~{count} مرة يومياً'**
  String overlaySettingDailyCount(int count);

  /// No description provided for @overlayPermissionWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'لن تعمل شاشة الأذان أو النوافذ المنبثقة عند إغلاق التطبيق'**
  String get overlayPermissionWarningTitle;

  /// No description provided for @overlayPermissionWarningBody.
  ///
  /// In ar, this message translates to:
  /// **'امنح إذن «العرض فوق التطبيقات الأخرى» ليستمر عملها حتى عند إغلاق التطبيق.'**
  String get overlayPermissionWarningBody;

  /// No description provided for @overlayPermissionGrantButton.
  ///
  /// In ar, this message translates to:
  /// **'منح الإذن'**
  String get overlayPermissionGrantButton;

  /// No description provided for @adhkarTabMorning.
  ///
  /// In ar, this message translates to:
  /// **'الصباح'**
  String get adhkarTabMorning;

  /// No description provided for @adhkarTabEvening.
  ///
  /// In ar, this message translates to:
  /// **'المساء'**
  String get adhkarTabEvening;

  /// No description provided for @adhkarTabAfterPrayer.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصلاة'**
  String get adhkarTabAfterPrayer;

  /// No description provided for @adhkarTabSleep.
  ///
  /// In ar, this message translates to:
  /// **'النوم'**
  String get adhkarTabSleep;

  /// No description provided for @adhkarTabWakingUp.
  ///
  /// In ar, this message translates to:
  /// **'الاستيقاظ من النوم'**
  String get adhkarTabWakingUp;

  /// No description provided for @adhkarTabHome.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get adhkarTabHome;

  /// No description provided for @adhkarTabTravel.
  ///
  /// In ar, this message translates to:
  /// **'السفر'**
  String get adhkarTabTravel;

  /// No description provided for @adhkarTabFood.
  ///
  /// In ar, this message translates to:
  /// **'الطعام'**
  String get adhkarTabFood;

  /// No description provided for @adhkarTabGathering.
  ///
  /// In ar, this message translates to:
  /// **'المجلس'**
  String get adhkarTabGathering;

  /// No description provided for @adhkarTabMisc.
  ///
  /// In ar, this message translates to:
  /// **'متنوعة'**
  String get adhkarTabMisc;

  /// No description provided for @adhkarTabMine.
  ///
  /// In ar, this message translates to:
  /// **'أذكاري'**
  String get adhkarTabMine;

  /// No description provided for @adhkarTabCommunity.
  ///
  /// In ar, this message translates to:
  /// **'المجتمع'**
  String get adhkarTabCommunity;

  /// No description provided for @adhkarScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار والأدعية'**
  String get adhkarScreenTitle;

  /// No description provided for @adhkarScreenSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حصن المسلم'**
  String get adhkarScreenSubtitle;

  /// No description provided for @adhkarProgressComplete.
  ///
  /// In ar, this message translates to:
  /// **'✅ مكتمل الحمد لله!'**
  String get adhkarProgressComplete;

  /// No description provided for @adhkarProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{done} / {total} ذكر'**
  String adhkarProgressCount(String done, String total);

  /// No description provided for @adhkarResetButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة'**
  String get adhkarResetButton;

  /// No description provided for @adhkarRemainingCount.
  ///
  /// In ar, this message translates to:
  /// **'{remaining} متبقي'**
  String adhkarRemainingCount(String remaining);

  /// No description provided for @adhkarCompletedCount.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل {count}×'**
  String adhkarCompletedCount(String count);

  /// No description provided for @adhkarHideFadl.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get adhkarHideFadl;

  /// No description provided for @adhkarShowFadl.
  ///
  /// In ar, this message translates to:
  /// **'الفضل'**
  String get adhkarShowFadl;

  /// No description provided for @adhkarNotifSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات الأذكار'**
  String get adhkarNotifSettingsTitle;

  /// No description provided for @adhkarNotifDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات متوقفة'**
  String get adhkarNotifDisabled;

  /// No description provided for @adhkarNotifMorningLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get adhkarNotifMorningLabel;

  /// No description provided for @adhkarNotifEveningLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get adhkarNotifEveningLabel;

  /// No description provided for @adhkarNotifSleepLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذكار النوم'**
  String get adhkarNotifSleepLabel;

  /// No description provided for @adhkarNotifAfterFajrLabel.
  ///
  /// In ar, this message translates to:
  /// **'بعد صلاة الفجر'**
  String get adhkarNotifAfterFajrLabel;

  /// No description provided for @adhkarNotifAfterAsrLabel.
  ///
  /// In ar, this message translates to:
  /// **'بعد صلاة العصر'**
  String get adhkarNotifAfterAsrLabel;

  /// No description provided for @adhkarNotifDailySection.
  ///
  /// In ar, this message translates to:
  /// **'تذكير في وقت محدد'**
  String get adhkarNotifDailySection;

  /// No description provided for @adhkarNotifPrayerSection.
  ///
  /// In ar, this message translates to:
  /// **'تذكير مرتبط بالصلاة'**
  String get adhkarNotifPrayerSection;

  /// No description provided for @adhkarNotifDelayLabel.
  ///
  /// In ar, this message translates to:
  /// **'التأخير بعد الصلاة'**
  String get adhkarNotifDelayLabel;

  /// No description provided for @adhkarNotifDelayMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{mins} دقيقة'**
  String adhkarNotifDelayMinutes(int mins);

  /// No description provided for @adhkarNotifAfterPrayerHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصلاة بـ {mins} دقيقة'**
  String adhkarNotifAfterPrayerHint(int mins);

  /// No description provided for @adhkarNotifAnchorNote.
  ///
  /// In ar, this message translates to:
  /// **'يُرسل التذكير بعد وقت الصلاة في موقعك ويحلّ محل الوقت المحدد، فلا يصلك تنبيهان للأذكار نفسها.'**
  String get adhkarNotifAnchorNote;

  /// No description provided for @qiblaScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة'**
  String get qiblaScreenTitle;

  /// No description provided for @qiblaScreenSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نحو الكعبة المشرفة 🕋'**
  String get qiblaScreenSubtitle;

  /// No description provided for @qiblaCompassLabelAligned.
  ///
  /// In ar, this message translates to:
  /// **'بوصلة القبلة، أنت متجه إلى القبلة الآن'**
  String get qiblaCompassLabelAligned;

  /// No description provided for @qiblaCompassLabelUnaligned.
  ///
  /// In ar, this message translates to:
  /// **'بوصلة القبلة، أدر جهازك {deg} درجة إلى {dir} لمواجهة القبلة'**
  String qiblaCompassLabelUnaligned(String deg, String dir);

  /// No description provided for @qiblaDirRight.
  ///
  /// In ar, this message translates to:
  /// **'اليمين'**
  String get qiblaDirRight;

  /// No description provided for @qiblaDirLeft.
  ///
  /// In ar, this message translates to:
  /// **'اليسار'**
  String get qiblaDirLeft;

  /// No description provided for @qiblaTurnRightShort.
  ///
  /// In ar, this message translates to:
  /// **'يميناً'**
  String get qiblaTurnRightShort;

  /// No description provided for @qiblaTurnLeftShort.
  ///
  /// In ar, this message translates to:
  /// **'يساراً'**
  String get qiblaTurnLeftShort;

  /// No description provided for @qiblaCurrentDirectionLabel.
  ///
  /// In ar, this message translates to:
  /// **'اتجاهك الحالي'**
  String get qiblaCurrentDirectionLabel;

  /// No description provided for @qiblaAlignedLabel.
  ///
  /// In ar, this message translates to:
  /// **'محاذٍ ✓'**
  String get qiblaAlignedLabel;

  /// No description provided for @qiblaTurnLabel.
  ///
  /// In ar, this message translates to:
  /// **'أدر {dir}'**
  String qiblaTurnLabel(String dir);

  /// No description provided for @qiblaCorrectValue.
  ///
  /// In ar, this message translates to:
  /// **'صحيح'**
  String get qiblaCorrectValue;

  /// No description provided for @qiblaFacingNowHint.
  ///
  /// In ar, this message translates to:
  /// **'أنت تواجه القبلة الآن'**
  String get qiblaFacingNowHint;

  /// No description provided for @qiblaHoldPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'أمسك هاتفك أفقياً وابتعد عن المعادن'**
  String get qiblaHoldPhoneHint;

  /// No description provided for @qiblaLocationRequiredTitle.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تفعيل الموقع'**
  String get qiblaLocationRequiredTitle;

  /// No description provided for @qiblaLocationRequiredSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لحساب اتجاه القبلة'**
  String get qiblaLocationRequiredSubtitle;

  /// No description provided for @qiblaCompassUnavailableTitle.
  ///
  /// In ar, this message translates to:
  /// **'البوصلة غير متاحة'**
  String get qiblaCompassUnavailableTitle;

  /// No description provided for @qiblaCompassUnavailableSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من دعم جهازك للبوصلة'**
  String get qiblaCompassUnavailableSubtitle;

  /// No description provided for @qiblaCompassNorth.
  ///
  /// In ar, this message translates to:
  /// **'ش'**
  String get qiblaCompassNorth;

  /// No description provided for @qiblaCompassEast.
  ///
  /// In ar, this message translates to:
  /// **'ق'**
  String get qiblaCompassEast;

  /// No description provided for @qiblaCompassSouth.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get qiblaCompassSouth;

  /// No description provided for @qiblaCompassWest.
  ///
  /// In ar, this message translates to:
  /// **'غ'**
  String get qiblaCompassWest;

  /// No description provided for @khatmaProgressScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقدم الختمة'**
  String get khatmaProgressScreenTitle;

  /// No description provided for @khatmaProgressPercentComplete.
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪ مكتملة'**
  String khatmaProgressPercentComplete(String percent);

  /// No description provided for @khatmaStatDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'أيام'**
  String get khatmaStatDaysLabel;

  /// No description provided for @khatmaStatPagesReadLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة مقروءة'**
  String get khatmaStatPagesReadLabel;

  /// No description provided for @khatmaWeeklyReadingTitle.
  ///
  /// In ar, this message translates to:
  /// **'القراءة الأسبوعية'**
  String get khatmaWeeklyReadingTitle;

  /// No description provided for @khatmaReadingAppearanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'مظهر القراءة'**
  String get khatmaReadingAppearanceLabel;

  /// No description provided for @khatmaSettingsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الختمة'**
  String get khatmaSettingsSectionTitle;

  /// No description provided for @khatmaReciterLabel.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get khatmaReciterLabel;

  /// No description provided for @khatmaReciterDefaultValue.
  ///
  /// In ar, this message translates to:
  /// **'الشيخ المنشاوي'**
  String get khatmaReciterDefaultValue;

  /// No description provided for @khatmaDailyReminderLabel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي'**
  String get khatmaDailyReminderLabel;

  /// No description provided for @overlayTypeDua.
  ///
  /// In ar, this message translates to:
  /// **'دعاء'**
  String get overlayTypeDua;

  /// No description provided for @overlayTypeDhikr.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get overlayTypeDhikr;

  /// No description provided for @overlayTypePrayer.
  ///
  /// In ar, this message translates to:
  /// **'أذان'**
  String get overlayTypePrayer;

  /// No description provided for @overlayPrayerAnnouncementTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الساعة {time}'**
  String overlayPrayerAnnouncementTimeLabel(String time);

  /// No description provided for @overlayTapOutsideToClose.
  ///
  /// In ar, this message translates to:
  /// **'اضغط خارجاً للإغلاق'**
  String get overlayTapOutsideToClose;

  /// No description provided for @forgotPasswordEnterEmail.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال البريد الإلكتروني'**
  String get forgotPasswordEnterEmail;

  /// No description provided for @forgotPasswordInvalidEmailFormat.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد الإلكتروني غير صحيحة'**
  String get forgotPasswordInvalidEmailFormat;

  /// No description provided for @forgotPasswordCodeSentMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رمز التحقق ورابط إعادة التعيين إلى بريدك الإلكتروني.'**
  String get forgotPasswordCodeSentMessage;

  /// No description provided for @forgotPasswordSendCodeFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال الرمز، تأكد من اتصال الإنترنت.'**
  String get forgotPasswordSendCodeFailed;

  /// No description provided for @forgotPasswordEnterOtp.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رمز التحقق المكون من 6 أرقام'**
  String get forgotPasswordEnterOtp;

  /// No description provided for @forgotPasswordInvalidOtp.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق غير صحيح أو منتهي الصلاحية'**
  String get forgotPasswordInvalidOtp;

  /// No description provided for @forgotPasswordVerifyFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر التحقق من الرمز، حاول مجدداً'**
  String get forgotPasswordVerifyFailed;

  /// No description provided for @forgotPasswordRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت الحد المسموح من المحاولات، يرجى الانتظار قليلاً'**
  String get forgotPasswordRateLimited;

  /// No description provided for @forgotPasswordTokenInvalidOrExpired.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق غير صحيح أو انتهت صلاحيته'**
  String get forgotPasswordTokenInvalidOrExpired;

  /// No description provided for @forgotPasswordNoAccountFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب مرتبط بهذا البريد الإلكتروني'**
  String get forgotPasswordNoAccountFound;

  /// No description provided for @forgotPasswordGenericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء المعالجة، يرجى المحاولة لاحقاً'**
  String get forgotPasswordGenericError;

  /// No description provided for @forgotPasswordEnterCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدخال رمز التحقق'**
  String get forgotPasswordEnterCodeTitle;

  /// No description provided for @forgotPasswordRecoverTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotPasswordRecoverTitle;

  /// No description provided for @forgotPasswordEnterCodeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكون من 6 أرقام المرسل إلى بريدك أو اضغط على الرابط في الرسالة'**
  String get forgotPasswordEnterCodeSubtitle;

  /// No description provided for @forgotPasswordRecoverSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني المسجل لنرسل لك رمز تأكيد إعادة تعيين كلمة المرور'**
  String get forgotPasswordRecoverSubtitle;

  /// No description provided for @forgotPasswordOtpHint.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق (6 أرقام)'**
  String get forgotPasswordOtpHint;

  /// No description provided for @forgotPasswordProcessing.
  ///
  /// In ar, this message translates to:
  /// **'جاري المعالجة...'**
  String get forgotPasswordProcessing;

  /// No description provided for @forgotPasswordVerifyAndContinue.
  ///
  /// In ar, this message translates to:
  /// **'تحقق ومتابعة'**
  String get forgotPasswordVerifyAndContinue;

  /// No description provided for @forgotPasswordSendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get forgotPasswordSendCode;

  /// No description provided for @forgotPasswordResendCountdown.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال بعد {seconds} ثانية'**
  String forgotPasswordResendCountdown(String seconds);

  /// No description provided for @forgotPasswordResendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get forgotPasswordResendCode;

  /// No description provided for @timePeriodAm.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get timePeriodAm;

  /// No description provided for @timePeriodPm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get timePeriodPm;

  /// No description provided for @wakeUpOverlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الاستيقاظ'**
  String get wakeUpOverlayTitle;

  /// No description provided for @wakeUpSnoozeButton.
  ///
  /// In ar, this message translates to:
  /// **'غفوة 10د'**
  String get wakeUpSnoozeButton;

  /// No description provided for @wakeUpStopAlarmButton.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المنبه'**
  String get wakeUpStopAlarmButton;

  /// No description provided for @booksLibraryTitle.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة الإسلامية'**
  String get booksLibraryTitle;

  /// No description provided for @booksListViewTooltip.
  ///
  /// In ar, this message translates to:
  /// **'عرض القائمة'**
  String get booksListViewTooltip;

  /// No description provided for @booksGridViewTooltip.
  ///
  /// In ar, this message translates to:
  /// **'عرض الشبكة'**
  String get booksGridViewTooltip;

  /// No description provided for @booksNoResultsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على كتب'**
  String get booksNoResultsFound;

  /// No description provided for @booksServerConnectionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالخادم'**
  String get booksServerConnectionError;

  /// No description provided for @booksConnectionErrorHint.
  ///
  /// In ar, this message translates to:
  /// **'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً\nأو اسحب الشاشة للأسفل للتحديث'**
  String get booksConnectionErrorHint;

  /// No description provided for @booksSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن كتاب أو مؤلف...'**
  String get booksSearchHint;

  /// No description provided for @booksCategoryAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get booksCategoryAll;

  /// No description provided for @booksCategoryHadith.
  ///
  /// In ar, this message translates to:
  /// **'الحديث'**
  String get booksCategoryHadith;

  /// No description provided for @booksCategoryFiqh.
  ///
  /// In ar, this message translates to:
  /// **'الفقه'**
  String get booksCategoryFiqh;

  /// No description provided for @booksCategorySeerah.
  ///
  /// In ar, this message translates to:
  /// **'السيرة'**
  String get booksCategorySeerah;

  /// No description provided for @booksCategoryAqeedah.
  ///
  /// In ar, this message translates to:
  /// **'العقيدة'**
  String get booksCategoryAqeedah;

  /// No description provided for @booksCategoryAdab.
  ///
  /// In ar, this message translates to:
  /// **'الآداب'**
  String get booksCategoryAdab;

  /// No description provided for @booksCategoryTazkiyah.
  ///
  /// In ar, this message translates to:
  /// **'التزكية'**
  String get booksCategoryTazkiyah;

  /// No description provided for @booksCategoryQuranicSciences.
  ///
  /// In ar, this message translates to:
  /// **'علوم القرآن'**
  String get booksCategoryQuranicSciences;

  /// No description provided for @booksVolumeLabel.
  ///
  /// In ar, this message translates to:
  /// **'مجلد'**
  String get booksVolumeLabel;

  /// No description provided for @booksBookletLabel.
  ///
  /// In ar, this message translates to:
  /// **'كتيب'**
  String get booksBookletLabel;

  /// No description provided for @booksLoadingMessage.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الكتب...'**
  String get booksLoadingMessage;

  /// No description provided for @khatmaDailyGoalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهدف اليومي'**
  String get khatmaDailyGoalLabel;

  /// No description provided for @khatmaDailyGoalPages.
  ///
  /// In ar, this message translates to:
  /// **'{n} صفحات'**
  String khatmaDailyGoalPages(String n);

  /// No description provided for @khatmaAppInfoSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التطبيق'**
  String get khatmaAppInfoSectionTitle;

  /// No description provided for @khatmaVersionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get khatmaVersionLabel;

  /// No description provided for @khatmaRateAppLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقييم التطبيق'**
  String get khatmaRateAppLabel;

  /// No description provided for @khatmaHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الختمات'**
  String get khatmaHistoryTitle;

  /// No description provided for @khatmaHistoryCompletedTab.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة ({count})'**
  String khatmaHistoryCompletedTab(String count);

  /// No description provided for @khatmaHistoryCancelledTab.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة ({count})'**
  String khatmaHistoryCancelledTab(String count);

  /// No description provided for @khatmaHistoryError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get khatmaHistoryError;

  /// No description provided for @khatmaHistoryEmptyCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ختمات مكتملة أو منتهية'**
  String get khatmaHistoryEmptyCompletedTitle;

  /// No description provided for @khatmaHistoryEmptyCompletedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة لتظهر هنا عند اكتمالها أو إنهائها'**
  String get khatmaHistoryEmptyCompletedSubtitle;

  /// No description provided for @khatmaHistoryEmptyCancelledTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ختمات ملغاة'**
  String get khatmaHistoryEmptyCancelledTitle;

  /// No description provided for @khatmaHistoryEmptyCancelledSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الختمات الملغاة ستظهر هنا'**
  String get khatmaHistoryEmptyCancelledSubtitle;

  /// No description provided for @khatmaHistoryDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الختمة'**
  String get khatmaHistoryDeleteTitle;

  /// No description provided for @khatmaHistoryDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذه الختمة نهائياً؟'**
  String get khatmaHistoryDeleteConfirm;

  /// No description provided for @khatmaHistoryDeletedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الختمة بنجاح'**
  String get khatmaHistoryDeletedToast;

  /// No description provided for @khatmaHistoryStatusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get khatmaHistoryStatusCompleted;

  /// No description provided for @khatmaHistoryStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get khatmaHistoryStatusCancelled;

  /// No description provided for @khatmaHistoryDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'{n} يوم'**
  String khatmaHistoryDaysLabel(String n);

  /// No description provided for @khatmaHistoryPagesProgress.
  ///
  /// In ar, this message translates to:
  /// **'{read} / {total} صفحة'**
  String khatmaHistoryPagesProgress(String read, String total);

  /// No description provided for @qiyamWirdTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد القيام'**
  String get qiyamWirdTitle;

  /// No description provided for @qiyamWirdBeforeQiyamHeader.
  ///
  /// In ar, this message translates to:
  /// **'أذكار ما قبل القيام'**
  String get qiyamWirdBeforeQiyamHeader;

  /// No description provided for @qiyamWirdIstighfarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاستغفار'**
  String get qiyamWirdIstighfarTitle;

  /// No description provided for @qiyamWirdTasbihTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسبيح'**
  String get qiyamWirdTasbihTitle;

  /// No description provided for @qiyamWirdLastThirdHeader.
  ///
  /// In ar, this message translates to:
  /// **'أدعية مأثورة في السحر'**
  String get qiyamWirdLastThirdHeader;

  /// No description provided for @qiyamWirdProphetDuaTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعاء النبي ﷺ'**
  String get qiyamWirdProphetDuaTitle;

  /// No description provided for @qiyamWirdSayyidIstighfarTitle.
  ///
  /// In ar, this message translates to:
  /// **'سيد الاستغفار'**
  String get qiyamWirdSayyidIstighfarTitle;

  /// No description provided for @qiyamWirdMulkHeader.
  ///
  /// In ar, this message translates to:
  /// **'سورة الملك (المنجية)'**
  String get qiyamWirdMulkHeader;

  /// No description provided for @qiyamWirdReadMulkTitle.
  ///
  /// In ar, this message translates to:
  /// **'قراءة سورة الملك'**
  String get qiyamWirdReadMulkTitle;

  /// No description provided for @qiyamWirdMulkSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تشفع لصاحبها وتنجي من عذاب القبر'**
  String get qiyamWirdMulkSubtitle;

  /// No description provided for @qiyamWirdCompletedButton.
  ///
  /// In ar, this message translates to:
  /// **'تم الورد بنجاح'**
  String get qiyamWirdCompletedButton;

  /// No description provided for @qiyamWirdTapToCountButton.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للعد'**
  String get qiyamWirdTapToCountButton;

  /// No description provided for @qiyamDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل'**
  String get qiyamDashboardTitle;

  /// No description provided for @qiyamDashboardStageProgress.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {current} من {total}'**
  String qiyamDashboardStageProgress(String current, String total);

  /// No description provided for @qiyamDashboardChooseStageDuration.
  ///
  /// In ar, this message translates to:
  /// **'اختر مدة المرحلة'**
  String get qiyamDashboardChooseStageDuration;

  /// No description provided for @qiyamDashboardMinutesLabel.
  ///
  /// In ar, this message translates to:
  /// **'{mins, plural, one{دقيقة واحدة} two{دقيقتان} few{{mins} دقائق} many{{mins} دقيقة} other{{mins} دقيقة}}'**
  String qiyamDashboardMinutesLabel(num mins);

  /// No description provided for @qiyamDashboardTimeRemainingLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المتبقي'**
  String get qiyamDashboardTimeRemainingLabel;

  /// No description provided for @qiyamDashboardStoriesTitle.
  ///
  /// In ar, this message translates to:
  /// **'عجائب وقصص القيام'**
  String get qiyamDashboardStoriesTitle;

  /// No description provided for @qiyamDashboardStoriesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قصص واقعية ملهمة عن أثر قيام الليل'**
  String get qiyamDashboardStoriesSubtitle;

  /// No description provided for @qiyamDashboardToolsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات والدليل الإيماني'**
  String get qiyamDashboardToolsSectionTitle;

  /// No description provided for @qiyamDashboardVirtuesTool.
  ///
  /// In ar, this message translates to:
  /// **'فضائل القيام'**
  String get qiyamDashboardVirtuesTool;

  /// No description provided for @qiyamDashboardSleepCalcTool.
  ///
  /// In ar, this message translates to:
  /// **'حاسبة النوم'**
  String get qiyamDashboardSleepCalcTool;

  /// No description provided for @qiyamDashboardSunnahTool.
  ///
  /// In ar, this message translates to:
  /// **'السنة النبوية'**
  String get qiyamDashboardSunnahTool;

  /// No description provided for @qiyamDashboardBeginnerGuideTool.
  ///
  /// In ar, this message translates to:
  /// **'دليل المبتدئين'**
  String get qiyamDashboardBeginnerGuideTool;

  /// No description provided for @qiyamDashboardHourCalcTool.
  ///
  /// In ar, this message translates to:
  /// **'حاسبة الساعة'**
  String get qiyamDashboardHourCalcTool;

  /// No description provided for @qiyamDashboardBannerLabel.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه'**
  String get qiyamDashboardBannerLabel;

  /// No description provided for @qiyamDashboardBannerDesc.
  ///
  /// In ar, this message translates to:
  /// **'برنامج متكامل لصلاة الليل... خطوة للقرب من الله.'**
  String get qiyamDashboardBannerDesc;

  /// No description provided for @qiyamGuideIntroTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطوتك الأولى في قيام الليل'**
  String get qiyamGuideIntroTitle;

  /// No description provided for @qiyamGuideIntroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لا تقلق إذا كنت في البداية، فكل قائم لليل بدأ بخطوة بسيطة. إليك خارطة الطريق.'**
  String get qiyamGuideIntroSubtitle;

  /// No description provided for @qiyamGuideTip1Title.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بالقليل'**
  String get qiyamGuideTip1Title;

  /// No description provided for @qiyamGuideTip1Content.
  ///
  /// In ar, this message translates to:
  /// **'لا تشق على نفسك في البداية، ابدأ بركعتين فقط بعد صلاة العشاء، ثم زد تدريجياً.'**
  String get qiyamGuideTip1Content;

  /// No description provided for @qiyamGuideTip2Title.
  ///
  /// In ar, this message translates to:
  /// **'التبكير في النوم'**
  String get qiyamGuideTip2Title;

  /// No description provided for @qiyamGuideTip2Content.
  ///
  /// In ar, this message translates to:
  /// **'النوم مبكراً هو المفتاح الذهبي للاستيقاظ بنشاط في وقت السحر.'**
  String get qiyamGuideTip2Content;

  /// No description provided for @qiyamGuideTip3Title.
  ///
  /// In ar, this message translates to:
  /// **'وضوء وبسملة'**
  String get qiyamGuideTip3Title;

  /// No description provided for @qiyamGuideTip3Content.
  ///
  /// In ar, this message translates to:
  /// **'توضأ قبل النوم واقرأ الأذكار، فذلك يعين الروح على القيام.'**
  String get qiyamGuideTip3Content;

  /// No description provided for @qiyamGuideTip4Title.
  ///
  /// In ar, this message translates to:
  /// **'اجعلها عادة'**
  String get qiyamGuideTip4Title;

  /// No description provided for @qiyamGuideTip4Content.
  ///
  /// In ar, this message translates to:
  /// **'الاستمرارية أهم من الكثرة، \"أحب الأعمال إلى الله أدومها وإن قل\".'**
  String get qiyamGuideTip4Content;

  /// No description provided for @qiyamGuideFaqTitle.
  ///
  /// In ar, this message translates to:
  /// **'أسئلة شائعة'**
  String get qiyamGuideFaqTitle;

  /// No description provided for @qiyamGuideFaqQ1.
  ///
  /// In ar, this message translates to:
  /// **'هل يجب النوم قبل القيام؟'**
  String get qiyamGuideFaqQ1;

  /// No description provided for @qiyamGuideFaqA1.
  ///
  /// In ar, this message translates to:
  /// **'لا يشترط، ولكن ما كان بعد نوم يسمى \"تهجداً\".'**
  String get qiyamGuideFaqA1;

  /// No description provided for @qiyamGuideFaqQ2.
  ///
  /// In ar, this message translates to:
  /// **'ما هو أقل عدد للركعات؟'**
  String get qiyamGuideFaqQ2;

  /// No description provided for @qiyamGuideFaqA2.
  ///
  /// In ar, this message translates to:
  /// **'ركعة واحدة (الوتر)، وأفضلها إحدى عشرة ركعة.'**
  String get qiyamGuideFaqA2;

  /// No description provided for @qiyamGuideFaqQ3.
  ///
  /// In ar, this message translates to:
  /// **'متى يبدأ وقت القيام؟'**
  String get qiyamGuideFaqQ3;

  /// No description provided for @qiyamGuideFaqA3.
  ///
  /// In ar, this message translates to:
  /// **'من بعد صلاة العشاء وحتى أذان الفجر.'**
  String get qiyamGuideFaqA3;

  /// No description provided for @mosquesCannotOpenMaps.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن فتح الخرائط'**
  String get mosquesCannotOpenMaps;

  /// No description provided for @mosquesCannotMakeCall.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إجراء المكالمة'**
  String get mosquesCannotMakeCall;

  /// No description provided for @mosquesNearbyTitle.
  ///
  /// In ar, this message translates to:
  /// **'المساجد القريبة'**
  String get mosquesNearbyTitle;

  /// No description provided for @mosquesCurrentLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الحالي: {city}'**
  String mosquesCurrentLocationLabel(String city);

  /// No description provided for @mosquesViewOnMapButton.
  ///
  /// In ar, this message translates to:
  /// **'عرض على الخريطة'**
  String get mosquesViewOnMapButton;

  /// No description provided for @mosquesDistanceMeters.
  ///
  /// In ar, this message translates to:
  /// **'{n} متر'**
  String mosquesDistanceMeters(String n);

  /// No description provided for @mosquesDistanceKm.
  ///
  /// In ar, this message translates to:
  /// **'{n} كم'**
  String mosquesDistanceKm(String n);

  /// No description provided for @mosquesNextPrayerLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة: {time}'**
  String mosquesNextPrayerLabel(String time);

  /// No description provided for @mosquesDirectionsButton.
  ///
  /// In ar, this message translates to:
  /// **'توجيه'**
  String get mosquesDirectionsButton;

  /// No description provided for @mosquesCallButton.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get mosquesCallButton;

  /// No description provided for @mosquesHadithSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'فضل الذهاب للمسجد'**
  String get mosquesHadithSectionTitle;

  /// No description provided for @mosquesEmptyState.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مساجد قريبة في محيط 5 كيلومتر'**
  String get mosquesEmptyState;

  /// No description provided for @quranScreenKhatmaLabel.
  ///
  /// In ar, this message translates to:
  /// **'ختمة'**
  String get quranScreenKhatmaLabel;

  /// No description provided for @quranScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get quranScreenTitle;

  /// No description provided for @quranScreenAyahLabel.
  ///
  /// In ar, this message translates to:
  /// **'آية {n}'**
  String quranScreenAyahLabel(String n);

  /// No description provided for @quranScreenContinueKhatma.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الختمة'**
  String get quranScreenContinueKhatma;

  /// No description provided for @quranScreenStartNewKhatma.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة'**
  String get quranScreenStartNewKhatma;

  /// No description provided for @quranScreenContinueFromPage.
  ///
  /// In ar, this message translates to:
  /// **'أكمل القراءة من صفحة {page}'**
  String quranScreenContinueFromPage(String page);

  /// No description provided for @quranScreenChooseKhatmaOptions.
  ///
  /// In ar, this message translates to:
  /// **'حدد خيارات الختمة التي تناسبك'**
  String get quranScreenChooseKhatmaOptions;

  /// No description provided for @quranScreenFreeReadingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قراءة حرة'**
  String get quranScreenFreeReadingTitle;

  /// No description provided for @quranScreenFreeReadingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن الكريم بحرية'**
  String get quranScreenFreeReadingSubtitle;

  /// No description provided for @quranScreenHistoryGridSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الختمات المكتملة'**
  String get quranScreenHistoryGridSubtitle;

  /// No description provided for @quranScreenProgressGridSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات القراءة'**
  String get quranScreenProgressGridSubtitle;

  /// No description provided for @quranScreenSettingsGridSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص التطبيق'**
  String get quranScreenSettingsGridSubtitle;

  /// No description provided for @quranScreenAiMemorizeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحفيظ ذكي'**
  String get quranScreenAiMemorizeTitle;

  /// No description provided for @quranScreenAiMemorizeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حفظ القرآن بالذكاء الاصطناعي'**
  String get quranScreenAiMemorizeSubtitle;

  /// No description provided for @remindersAdviceTitle.
  ///
  /// In ar, this message translates to:
  /// **'نصيحة'**
  String get remindersAdviceTitle;

  /// No description provided for @remindersAdviceDesc.
  ///
  /// In ar, this message translates to:
  /// **'المداومة على الأذكار اليومية تجلب السكينة والطمأنينة للقلب. احرص على تفعيل التذكيرات لتبقى على اتصال دائم بالله.'**
  String get remindersAdviceDesc;

  /// No description provided for @remindersScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get remindersScreenTitle;

  /// No description provided for @remindersAddButtonTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تذكير جديد'**
  String get remindersAddButtonTitle;

  /// No description provided for @remindersAddButtonSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اضغط هنا لإنشاء تذكير مخصص'**
  String get remindersAddButtonSubtitle;

  /// No description provided for @remindersEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تذكيرات بعد'**
  String get remindersEmptyTitle;

  /// No description provided for @remindersEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف أول تذكير لك بالضغط على الزر أعلاه'**
  String get remindersEmptySubtitle;

  /// No description provided for @remindersMyRemindersTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكيراتي'**
  String get remindersMyRemindersTitle;

  /// No description provided for @remindersCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{تذكير واحد} two{تذكيران} few{{count} تذكيرات} many{{count} تذكيراً} other{{count} تذكير}}'**
  String remindersCountBadge(num count);

  /// No description provided for @remindersDeleteDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف التذكير'**
  String get remindersDeleteDialogTitle;

  /// No description provided for @remindersDeleteDialogConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف \"{title}\"؟'**
  String remindersDeleteDialogConfirm(String title);

  /// No description provided for @profileScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileScreenTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل البيانات'**
  String get profileLoadError;

  /// No description provided for @profileDefaultUsername.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم تقوى'**
  String get profileDefaultUsername;

  /// No description provided for @profileGenderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get profileGenderMale;

  /// No description provided for @profileGenderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get profileGenderFemale;

  /// No description provided for @profileMemberBadge.
  ///
  /// In ar, this message translates to:
  /// **'عضو مجتهد'**
  String get profileMemberBadge;

  /// No description provided for @profileTaqwaPointsLabel.
  ///
  /// In ar, this message translates to:
  /// **'نقاط التقوى'**
  String get profileTaqwaPointsLabel;

  /// No description provided for @profileStreakDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'أيام متواصلة'**
  String get profileStreakDaysLabel;

  /// No description provided for @profileAchievementsMenuTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get profileAchievementsMenuTitle;

  /// No description provided for @profileAccountingLogMenuTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل المحاسبة'**
  String get profileAccountingLogMenuTitle;

  /// No description provided for @profileAccountSettingsMenuTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الحساب'**
  String get profileAccountSettingsMenuTitle;

  /// No description provided for @profileLogoutDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get profileLogoutDialogTitle;

  /// No description provided for @profileLogoutDialogConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في تسجيل الخروج؟'**
  String get profileLogoutDialogConfirm;

  /// No description provided for @profileLogoutConfirmButton.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get profileLogoutConfirmButton;

  /// No description provided for @updatePasswordEnterNew.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور الجديدة'**
  String get updatePasswordEnterNew;

  /// No description provided for @updatePasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمات المرور غير متطابقة'**
  String get updatePasswordMismatch;

  /// No description provided for @updatePasswordSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين كلمة المرور الجديدة بنجاح ✓'**
  String get updatePasswordSuccessMessage;

  /// No description provided for @updatePasswordUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً'**
  String get updatePasswordUnexpectedError;

  /// No description provided for @updatePasswordSameAsOld.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة مطابقة لكلمة المرور الحالية'**
  String get updatePasswordSameAsOld;

  /// No description provided for @updatePasswordMinLength.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get updatePasswordMinLength;

  /// No description provided for @updatePasswordSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الجلسة، يرجى طلب رمز استعادة جديد'**
  String get updatePasswordSessionExpired;

  /// No description provided for @updatePasswordGenericFailure.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث كلمة المرور، حاول مجدداً'**
  String get updatePasswordGenericFailure;

  /// No description provided for @updatePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة مرور جديدة'**
  String get updatePasswordTitle;

  /// No description provided for @updatePasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قم بإدخال كلمة المرور الجديدة لحسابك لتسجيل الدخول بأمان'**
  String get updatePasswordSubtitle;

  /// No description provided for @updatePasswordNewHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get updatePasswordNewHint;

  /// No description provided for @updatePasswordConfirmHint.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get updatePasswordConfirmHint;

  /// No description provided for @updatePasswordSavingButton.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحفظ...'**
  String get updatePasswordSavingButton;

  /// No description provided for @updatePasswordSaveAndSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة المرور والدخول'**
  String get updatePasswordSaveAndSignInButton;

  /// No description provided for @qiyamSunnahGuideTitle.
  ///
  /// In ar, this message translates to:
  /// **'طريقة القيام والتهجد'**
  String get qiyamSunnahGuideTitle;

  /// No description provided for @qiyamSunnahGuideHeaderTitle.
  ///
  /// In ar, this message translates to:
  /// **'هدي النبي ﷺ في قيام الليل'**
  String get qiyamSunnahGuideHeaderTitle;

  /// No description provided for @qiyamSunnahGuideHeaderSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل شامل لتعلم كيفية صلاة التهجد كما وردت عن الرسول ﷺ والصحابة الكرام.'**
  String get qiyamSunnahGuideHeaderSubtitle;

  /// No description provided for @qiyamSunnahStep1Title.
  ///
  /// In ar, this message translates to:
  /// **'النية والإخلاص'**
  String get qiyamSunnahStep1Title;

  /// No description provided for @qiyamSunnahStep1Content.
  ///
  /// In ar, this message translates to:
  /// **'أن ينوي العبد قيام الليل تقرباً لله عز وجل، ويفضل أن ينام على طهارة.'**
  String get qiyamSunnahStep1Content;

  /// No description provided for @qiyamSunnahStep2Title.
  ///
  /// In ar, this message translates to:
  /// **'الاستفتاح بركعتين خفيفتين'**
  String get qiyamSunnahStep2Title;

  /// No description provided for @qiyamSunnahStep2Content.
  ///
  /// In ar, this message translates to:
  /// **'كان النبي ﷺ إذا قام من الليل افتتح صلاته بركعتين خفيفتين، لتنشيط الجسد.'**
  String get qiyamSunnahStep2Content;

  /// No description provided for @qiyamSunnahStep3Title.
  ///
  /// In ar, this message translates to:
  /// **'كيفية الصلاة (مثنى مثنى)'**
  String get qiyamSunnahStep3Title;

  /// No description provided for @qiyamSunnahStep3Content.
  ///
  /// In ar, this message translates to:
  /// **'صلاة الليل مثنى مثنى، أي يسلم بعد كل ركعتين، ويطيل الركوع والسجود حسب الاستطاعة.'**
  String get qiyamSunnahStep3Content;

  /// No description provided for @qiyamSunnahStep4Title.
  ///
  /// In ar, this message translates to:
  /// **'القراءة بتدبر'**
  String get qiyamSunnahStep4Title;

  /// No description provided for @qiyamSunnahStep4Content.
  ///
  /// In ar, this message translates to:
  /// **'يستحب أن تكون القراءة بترتيل وتدبر، ويسأل الله عند آية الرحمة، ويتعوذ عند آية العذاب.'**
  String get qiyamSunnahStep4Content;

  /// No description provided for @qiyamSunnahStep5Title.
  ///
  /// In ar, this message translates to:
  /// **'ختم القيام بالوتر'**
  String get qiyamSunnahStep5Title;

  /// No description provided for @qiyamSunnahStep5Content.
  ///
  /// In ar, this message translates to:
  /// **'يختم المصلي قيامه بركعة واحدة توتر له ما صلى، لقوله ﷺ: \"اجعلوا آخر صلاتكم بالليل وتراً\".'**
  String get qiyamSunnahStep5Content;

  /// No description provided for @qiyamVirtuesScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'فضائل قيام الليل'**
  String get qiyamVirtuesScreenTitle;

  /// No description provided for @qiyamVirtuesFromQuran.
  ///
  /// In ar, this message translates to:
  /// **'من القرآن الكريم'**
  String get qiyamVirtuesFromQuran;

  /// No description provided for @qiyamVirtuesFromSunnah.
  ///
  /// In ar, this message translates to:
  /// **'من السنة النبوية'**
  String get qiyamVirtuesFromSunnah;

  /// No description provided for @qiyamVirtuesFromSalaf.
  ///
  /// In ar, this message translates to:
  /// **'من أقوال السلف'**
  String get qiyamVirtuesFromSalaf;

  /// No description provided for @qiyamStoriesScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'قصص وعجائب القيام'**
  String get qiyamStoriesScreenTitle;

  /// No description provided for @qiyamStoryTitle1.
  ///
  /// In ar, this message translates to:
  /// **'شرف المؤمن'**
  String get qiyamStoryTitle1;

  /// No description provided for @qiyamStoryTitle2.
  ///
  /// In ar, this message translates to:
  /// **'سيد التابعين والقيام'**
  String get qiyamStoryTitle2;

  /// No description provided for @qiyamStoryTitle3.
  ///
  /// In ar, this message translates to:
  /// **'سهام الليل لا تخطئ'**
  String get qiyamStoryTitle3;

  /// No description provided for @qiyamStoryTitle4.
  ///
  /// In ar, this message translates to:
  /// **'نور الوجه من القيام'**
  String get qiyamStoryTitle4;

  /// No description provided for @accountSettingsSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التغييرات بنجاح'**
  String get accountSettingsSavedSuccess;

  /// No description provided for @accountSettingsSaveError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء حفظ التغييرات'**
  String get accountSettingsSaveError;

  /// No description provided for @accountSettingsPersonalInfoSection.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية'**
  String get accountSettingsPersonalInfoSection;

  /// No description provided for @accountSettingsNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get accountSettingsNameLabel;

  /// No description provided for @accountSettingsNameHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك'**
  String get accountSettingsNameHint;

  /// No description provided for @accountSettingsNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال الاسم'**
  String get accountSettingsNameRequired;

  /// No description provided for @accountSettingsEmailImmutableNote.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغيير البريد الإلكتروني حالياً'**
  String get accountSettingsEmailImmutableNote;

  /// No description provided for @accountSettingsSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get accountSettingsSaveButton;

  /// No description provided for @accountSettingsSecuritySection.
  ///
  /// In ar, this message translates to:
  /// **'الأمان'**
  String get accountSettingsSecuritySection;

  /// No description provided for @accountSettingsChangePasswordTile.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get accountSettingsChangePasswordTile;

  /// No description provided for @bookReaderCustomizeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص القراءة'**
  String get bookReaderCustomizeTitle;

  /// No description provided for @bookReaderThemeDay.
  ///
  /// In ar, this message translates to:
  /// **'نهاري'**
  String get bookReaderThemeDay;

  /// No description provided for @bookReaderThemeSepia.
  ///
  /// In ar, this message translates to:
  /// **'ورقي'**
  String get bookReaderThemeSepia;

  /// No description provided for @bookReaderFontSizeSampleLetter.
  ///
  /// In ar, this message translates to:
  /// **'أ'**
  String get bookReaderFontSizeSampleLetter;

  /// No description provided for @bookReaderNextButton.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get bookReaderNextButton;

  /// No description provided for @bookReaderPrevButton.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get bookReaderPrevButton;

  /// No description provided for @bookReaderPageProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total}'**
  String bookReaderPageProgress(String done, String total);

  /// No description provided for @bookReaderPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get bookReaderPageLabel;

  /// No description provided for @favoriteAdhkarScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكاري المفضلة'**
  String get favoriteAdhkarScreenTitle;

  /// No description provided for @favoriteAdhkarCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{ذكر واحد محفوظ} two{ذكران محفوظان} few{{count} أذكار محفوظة} many{{count} ذكرًا محفوظًا} other{{count} ذكر محفوظ}}'**
  String favoriteAdhkarCountLabel(int count);

  /// No description provided for @favoriteAdhkarEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أذكار مفضلة بعد'**
  String get favoriteAdhkarEmptyTitle;

  /// No description provided for @favoriteAdhkarEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على ❤️ في أي ذكر لحفظه هنا'**
  String get favoriteAdhkarEmptySubtitle;

  /// No description provided for @favoriteAdhkarCopiedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ ✓'**
  String get favoriteAdhkarCopiedToast;

  /// No description provided for @qiyamSleepCalcTitle.
  ///
  /// In ar, this message translates to:
  /// **'حاسبة النوم الذكية'**
  String get qiyamSleepCalcTitle;

  /// No description provided for @qiyamSleepCalcHeaderTitle.
  ///
  /// In ar, this message translates to:
  /// **'استيقظ نشيطاً لقيام الليل'**
  String get qiyamSleepCalcHeaderTitle;

  /// No description provided for @qiyamSleepCalcHeaderSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تعتمد الحاسبة على دورات النوم (90 دقيقة) لتحديد أفضل وقت للنوم حتى تستيقظ في قمة نشاطك.'**
  String get qiyamSleepCalcHeaderSubtitle;

  /// No description provided for @qiyamSleepCalcWakeupQuestion.
  ///
  /// In ar, this message translates to:
  /// **'متى تريد الاستيقاظ؟'**
  String get qiyamSleepCalcWakeupQuestion;

  /// No description provided for @qiyamSleepCalcBestTimesLabel.
  ///
  /// In ar, this message translates to:
  /// **'أفضل أوقات النوم:'**
  String get qiyamSleepCalcBestTimesLabel;

  /// No description provided for @qiyamSleepCycle9h.
  ///
  /// In ar, this message translates to:
  /// **'9 ساعات (مثالي)'**
  String get qiyamSleepCycle9h;

  /// No description provided for @qiyamSleepCycle75h.
  ///
  /// In ar, this message translates to:
  /// **'7.5 ساعات (ممتاز)'**
  String get qiyamSleepCycle75h;

  /// No description provided for @qiyamSleepCycle6h.
  ///
  /// In ar, this message translates to:
  /// **'6 ساعات (جيد)'**
  String get qiyamSleepCycle6h;

  /// No description provided for @qiyamSleepCycle45h.
  ///
  /// In ar, this message translates to:
  /// **'4.5 ساعات (كافٍ)'**
  String get qiyamSleepCycle45h;

  /// No description provided for @qiyamSleepCycle15h.
  ///
  /// In ar, this message translates to:
  /// **'1.5 ساعة (غفوة)'**
  String get qiyamSleepCycle15h;

  /// No description provided for @qiyamSleepCalcSleepAtLabel.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تنام الساعة'**
  String get qiyamSleepCalcSleepAtLabel;

  /// No description provided for @bookPdfNoUrlError.
  ///
  /// In ar, this message translates to:
  /// **'عذراً، لم يتم العثور على رابط PDF لهذا الكتاب.'**
  String get bookPdfNoUrlError;

  /// No description provided for @bookPdfDownloadingLabel.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get bookPdfDownloadingLabel;

  /// No description provided for @bookPdfDownloadingPercentLabel.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل... {pct}%'**
  String bookPdfDownloadingPercentLabel(int pct);

  /// No description provided for @bookPdfLoadFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الملف'**
  String get bookPdfLoadFailedTitle;

  /// No description provided for @bookPdfShareAction.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get bookPdfShareAction;

  /// No description provided for @bookPdfCopiedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get bookPdfCopiedToast;

  /// No description provided for @bookPdfHighlightAction.
  ///
  /// In ar, this message translates to:
  /// **'تحديد'**
  String get bookPdfHighlightAction;

  /// No description provided for @bookPdfHighlightedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديد النص'**
  String get bookPdfHighlightedToast;

  /// No description provided for @notifPreAdhanTitle.
  ///
  /// In ar, this message translates to:
  /// **'⏳ اقترب وقت {prayerName}'**
  String notifPreAdhanTitle(String prayerName);

  /// No description provided for @notifPreAdhanBody.
  ///
  /// In ar, this message translates to:
  /// **'15 دقيقة على أذان {prayerName}، استعدَّ للصلاة'**
  String notifPreAdhanBody(String prayerName);

  /// No description provided for @notifAdhanTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت {prayerName}'**
  String notifAdhanTitle(String prayerName);

  /// No description provided for @notifAdhanBody.
  ///
  /// In ar, this message translates to:
  /// **'اللهُ أكبر، اللهُ أكبر — حيَّ على الصلاة، حيَّ على الفلاح'**
  String get notifAdhanBody;

  /// No description provided for @notifIqamaTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت الإقامة — {prayerName}'**
  String notifIqamaTitle(String prayerName);

  /// No description provided for @notifIqamaBody.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت إقامة صلاة {prayerName}، الله أكبر الله أكبر'**
  String notifIqamaBody(String prayerName);

  /// No description provided for @notifMuhasabaTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت محاسبة النفس'**
  String get notifMuhasabaTitle;

  /// No description provided for @notifMuhasabaMsg1.
  ///
  /// In ar, this message translates to:
  /// **'كيف كان يومك مع الله؟ حاسب نفسك قبل أن تنام 🌙'**
  String get notifMuhasabaMsg1;

  /// No description provided for @notifMuhasabaMsg2.
  ///
  /// In ar, this message translates to:
  /// **'\"حَاسِبُوا أَنفُسَكُمْ قَبْلَ أَنْ تُحَاسَبُوا\" — عمر بن الخطاب'**
  String get notifMuhasabaMsg2;

  /// No description provided for @notifMuhasabaMsg3.
  ///
  /// In ar, this message translates to:
  /// **'ماذا قدَّمتَ اليوم؟ سجِّل عباداتك الآن 📝'**
  String get notifMuhasabaMsg3;

  /// No description provided for @notifMuhasabaMsg4.
  ///
  /// In ar, this message translates to:
  /// **'الليل ينادي: أيها المؤمن، ماذا عملتَ اليوم؟ 🌟'**
  String get notifMuhasabaMsg4;

  /// No description provided for @notifMuhasabaMsg5.
  ///
  /// In ar, this message translates to:
  /// **'لا تنم قبل أن تحاسب نفسك على يومك 💫'**
  String get notifMuhasabaMsg5;

  /// No description provided for @notifMuhasabaMsg6.
  ///
  /// In ar, this message translates to:
  /// **'ثلاث دقائق لمحاسبة النفس خير من ساعات الندم 🤲'**
  String get notifMuhasabaMsg6;

  /// No description provided for @notifMuhasabaMsg7.
  ///
  /// In ar, this message translates to:
  /// **'أنجزتَ شيئاً جيداً اليوم؟ دوِّنه واشكر الله 🙏'**
  String get notifMuhasabaMsg7;

  /// No description provided for @notifDuaMorningTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعاء الصباح'**
  String get notifDuaMorningTitle;

  /// No description provided for @notifDuaEveningTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعاء المساء'**
  String get notifDuaEveningTitle;

  /// No description provided for @notifDuaTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعاء اليوم'**
  String get notifDuaTodayTitle;

  /// No description provided for @notifFridayKahfTitle.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف'**
  String get notifFridayKahfTitle;

  /// No description provided for @notifFridayKahfBody.
  ///
  /// In ar, this message translates to:
  /// **'لا تنس قراءة سورة الكهف اليوم — نور ما بين الجمعتين'**
  String get notifFridayKahfBody;

  /// No description provided for @notifFridaySalawatTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة على النبي ﷺ'**
  String get notifFridaySalawatTitle;

  /// No description provided for @notifFridaySalawatBody.
  ///
  /// In ar, this message translates to:
  /// **'اللهم صلِّ وسلِّم على سيدنا محمد — أكثِر من الصلاة يوم الجمعة'**
  String get notifFridaySalawatBody;

  /// No description provided for @notifFastingMondayTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بصيام الاثنين'**
  String get notifFastingMondayTitle;

  /// No description provided for @notifFastingMondayBody.
  ///
  /// In ar, this message translates to:
  /// **'غداً الاثنين — تُعرض فيه الأعمال، فليكن عملك وأنت صائم'**
  String get notifFastingMondayBody;

  /// No description provided for @notifFastingThursdayTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بصيام الخميس'**
  String get notifFastingThursdayTitle;

  /// No description provided for @notifFastingThursdayBody.
  ///
  /// In ar, this message translates to:
  /// **'غداً الخميس — تُرفع فيه الأعمال، هنيئاً لمن صام'**
  String get notifFastingThursdayBody;

  /// No description provided for @notifWhiteDaysTitle.
  ///
  /// In ar, this message translates to:
  /// **'غداً من الأيام البيض'**
  String get notifWhiteDaysTitle;

  /// No description provided for @notifWhiteDaysBody.
  ///
  /// In ar, this message translates to:
  /// **'غداً يوم {day} من {month} الهجري — صيام الأيام البيض سنّة مؤكدة'**
  String notifWhiteDaysBody(int day, String month);

  /// No description provided for @notifSuhoorTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه السحور'**
  String get notifSuhoorTitle;

  /// No description provided for @notifSuhoorBody.
  ///
  /// In ar, this message translates to:
  /// **'بقي 30 دقيقة على الإمساك — استيقظ للسحور وبارك الله لك'**
  String get notifSuhoorBody;

  /// No description provided for @notifIftarTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الإفطار'**
  String get notifIftarTitle;

  /// No description provided for @notifIftarBody.
  ///
  /// In ar, this message translates to:
  /// **'اللهم لك صمت وعلى رزقك أفطرت — رمضان مبارك'**
  String get notifIftarBody;

  /// No description provided for @notifWakeUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الاستيقاظ'**
  String get notifWakeUpTitle;

  /// No description provided for @notifWakeUpBody.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة خير من النوم — استيقظ لصلاة الفجر'**
  String get notifWakeUpBody;

  /// No description provided for @notifWakeUpSnoozeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الاستيقاظ (غفوة)'**
  String get notifWakeUpSnoozeTitle;

  /// No description provided for @notifAchievementNewPrefix.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز جديد: {title}'**
  String notifAchievementNewPrefix(String title);

  /// No description provided for @notifAchievementPointsSuffix.
  ///
  /// In ar, this message translates to:
  /// **'+{points} نقطة تقوى 🌟'**
  String notifAchievementPointsSuffix(int points);

  /// No description provided for @notifAchievementPointsShort.
  ///
  /// In ar, this message translates to:
  /// **'+{points} نقطة تقوى'**
  String notifAchievementPointsShort(int points);

  /// No description provided for @notifAdhkarMorningTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار الصباح'**
  String get notifAdhkarMorningTitle;

  /// No description provided for @notifAdhkarEveningTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار المساء'**
  String get notifAdhkarEveningTitle;

  /// No description provided for @notifAdhkarSleepTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت أذكار النوم'**
  String get notifAdhkarSleepTitle;

  /// No description provided for @notifAdhkarAfterFajrTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح بعد صلاة الفجر'**
  String get notifAdhkarAfterFajrTitle;

  /// No description provided for @notifAdhkarAfterAsrTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء بعد صلاة العصر'**
  String get notifAdhkarAfterAsrTitle;

  /// No description provided for @notifAdhkarMorningChannelName.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get notifAdhkarMorningChannelName;

  /// No description provided for @notifAdhkarEveningChannelName.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get notifAdhkarEveningChannelName;

  /// No description provided for @notifAdhkarSleepChannelName.
  ///
  /// In ar, this message translates to:
  /// **'أذكار النوم'**
  String get notifAdhkarSleepChannelName;

  /// No description provided for @notifAdhkarChannelDesc.
  ///
  /// In ar, this message translates to:
  /// **'أذكار وأدعية من حصن المسلم'**
  String get notifAdhkarChannelDesc;

  /// No description provided for @notifAdhkarActionRead.
  ///
  /// In ar, this message translates to:
  /// **'قرأت الأذكار ✓'**
  String get notifAdhkarActionRead;

  /// No description provided for @notifAdhkarActionOpen.
  ///
  /// In ar, this message translates to:
  /// **'فتح الأذكار'**
  String get notifAdhkarActionOpen;

  /// No description provided for @silentModeSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الوضع الصامت'**
  String get silentModeSettingsTitle;

  /// No description provided for @silentModeEnableLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل وضع الصامت'**
  String get silentModeEnableLabel;

  /// No description provided for @silentModeEnableSublabel.
  ///
  /// In ar, this message translates to:
  /// **'ننصح بتفعيل هذه الخاصية إذا كان الأذان لا يشتغل بشكل منتظم في هاتفكم'**
  String get silentModeEnableSublabel;

  /// No description provided for @silentModeVibrationLabel.
  ///
  /// In ar, this message translates to:
  /// **'إهتزاز'**
  String get silentModeVibrationLabel;

  /// No description provided for @silentModeVibrationSublabel.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإهتزاز أثناء الوضع الصامت'**
  String get silentModeVibrationSublabel;

  /// No description provided for @silentModeAlertStyleLabel.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه عند التحويل'**
  String get silentModeAlertStyleLabel;

  /// No description provided for @silentModeAlertNone.
  ///
  /// In ar, this message translates to:
  /// **'بدون تنبيه'**
  String get silentModeAlertNone;

  /// No description provided for @silentModeAlertVibrateOnly.
  ///
  /// In ar, this message translates to:
  /// **'اهتزاز فقط'**
  String get silentModeAlertVibrateOnly;

  /// No description provided for @silentModeAlertToneOnly.
  ///
  /// In ar, this message translates to:
  /// **'نغمة بدون اهتزاز'**
  String get silentModeAlertToneOnly;

  /// No description provided for @silentModeAlertToneVibrate.
  ///
  /// In ar, this message translates to:
  /// **'نغمة مع اهتزاز'**
  String get silentModeAlertToneVibrate;

  /// No description provided for @silentModeDurationLabel.
  ///
  /// In ar, this message translates to:
  /// **'مدة الصمت بعد الأذان'**
  String get silentModeDurationLabel;

  /// No description provided for @silentModeDurationSublabel.
  ///
  /// In ar, this message translates to:
  /// **'مدة إسكات الهاتف تلقائياً بعد دخول وقت كل صلاة'**
  String get silentModeDurationSublabel;

  /// Silent-mode duration option label, e.g. "20 minutes"
  ///
  /// In ar, this message translates to:
  /// **'{mins, plural, one{دقيقة واحدة} two{دقيقتان} few{{mins} دقائق} many{{mins} دقيقة} other{{mins} دقيقة}}'**
  String silentModeDurationMinutes(num mins);

  /// No description provided for @booksChapterAboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن الكتاب'**
  String get booksChapterAboutTitle;

  /// No description provided for @booksChapterTocTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفصول المحتواة'**
  String get booksChapterTocTitle;

  /// No description provided for @booksChapterPagesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{صفحة واحدة} two{صفحتان} few{{count} صفحات} many{{count} صفحة} other{{count} صفحة}}'**
  String booksChapterPagesCount(int count);

  /// No description provided for @booksChapterChaptersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{فصل واحد} two{فصلان} few{{count} فصول} many{{count} فصلاً} other{{count} فصل}}'**
  String booksChapterChaptersCount(int count);

  /// No description provided for @booksChapterMinutesAbbrev.
  ///
  /// In ar, this message translates to:
  /// **'~{minutes} د'**
  String booksChapterMinutesAbbrev(int minutes);

  /// No description provided for @booksChapterReadPdfButton.
  ///
  /// In ar, this message translates to:
  /// **'قراءة نسخة PDF'**
  String get booksChapterReadPdfButton;

  /// No description provided for @booksChapterStartReadingButton.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ القراءة'**
  String get booksChapterStartReadingButton;

  /// No description provided for @booksChapterContinueReadingButton.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get booksChapterContinueReadingButton;

  /// No description provided for @booksChapterReadingProgressLabel.
  ///
  /// In ar, this message translates to:
  /// **'تقدم القراءة'**
  String get booksChapterReadingProgressLabel;

  /// No description provided for @asmaScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله الحسنى'**
  String get asmaScreenTitle;

  /// No description provided for @asmaScreenSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'٩٩ اسماً مباركاً'**
  String get asmaScreenSubtitle;

  /// No description provided for @asmaSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأسماء...'**
  String get asmaSearchHint;

  /// No description provided for @asmaNoResultsLabel.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get asmaNoResultsLabel;

  /// No description provided for @asmaDuaLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدعاء'**
  String get asmaDuaLabel;

  /// No description provided for @asmaDetailExplanationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشرح والبيان'**
  String get asmaDetailExplanationTitle;

  /// No description provided for @asmaDetailQuranTitle.
  ///
  /// In ar, this message translates to:
  /// **'من القرآن الكريم'**
  String get asmaDetailQuranTitle;

  /// No description provided for @asmaDetailDuaTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعاء بهذا الاسم'**
  String get asmaDetailDuaTitle;

  /// No description provided for @achievementsScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنجازاتي'**
  String get achievementsScreenTitle;

  /// No description provided for @achievementsProgressLabel.
  ///
  /// In ar, this message translates to:
  /// **'التقدم المحرز'**
  String get achievementsProgressLabel;

  /// No description provided for @achievementsCategoryDaily.
  ///
  /// In ar, this message translates to:
  /// **'إنجازات يومية'**
  String get achievementsCategoryDaily;

  /// No description provided for @achievementsCategoryMilestone.
  ///
  /// In ar, this message translates to:
  /// **'محطات رئيسية'**
  String get achievementsCategoryMilestone;

  /// No description provided for @achievementsCategoryIbadah.
  ///
  /// In ar, this message translates to:
  /// **'العبادات والذكر'**
  String get achievementsCategoryIbadah;

  /// No description provided for @achievementsCategorySpecial.
  ///
  /// In ar, this message translates to:
  /// **'إنجازات خاصة'**
  String get achievementsCategorySpecial;

  /// No description provided for @achievementsAchievedOnLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقيق في {date}'**
  String achievementsAchievedOnLabel(String date);

  /// No description provided for @achievementsEncourageMessage.
  ///
  /// In ar, this message translates to:
  /// **'استمر لمضاعفة جهودك وتحقيق هذا الإنجاز! ✨'**
  String get achievementsEncourageMessage;

  /// No description provided for @achievementsGotItButton.
  ///
  /// In ar, this message translates to:
  /// **'فهمت'**
  String get achievementsGotItButton;

  /// No description provided for @prayerJumuah.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get prayerJumuah;

  /// No description provided for @prayerSelectionSunriseAlertsLabel.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الشروق'**
  String get prayerSelectionSunriseAlertsLabel;

  /// No description provided for @prayerSelectionAdhanLabel.
  ///
  /// In ar, this message translates to:
  /// **'أذان {name}'**
  String prayerSelectionAdhanLabel(String name);

  /// No description provided for @termsPrivacyScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والخصوصية'**
  String get termsPrivacyScreenTitle;

  /// No description provided for @termsPrivacyAppName.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق تقوى'**
  String get termsPrivacyAppName;

  /// No description provided for @termsPrivacySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الشروط وسياسة الخصوصية'**
  String get termsPrivacySubtitle;

  /// No description provided for @termsPrivacyTermsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get termsPrivacyTermsSectionTitle;

  /// No description provided for @termsPrivacyPolicySectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get termsPrivacyPolicySectionTitle;

  /// No description provided for @termsPrivacyTermsBody.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في تطبيق \"تقوى\". باستخدامك لهذا التطبيق، فإنك توافق على شروط وأحكام الاستخدام الموضحة. نهدف من خلال هذا التطبيق لتقديم خدمات إسلامية من أذكار، مواقيت الصلاة، والقيم الإسلامية بما ينفع أمتنا الإسلامية. يرجى استخدام التطبيق وفق الغرض المخصص له، وعدم إساءة استخدام الخدمات أو المحتوى.'**
  String get termsPrivacyTermsBody;

  /// No description provided for @termsPrivacyPolicyBody.
  ///
  /// In ar, this message translates to:
  /// **'نحن نحترم خصوصيتك ونهتم بحماية بياناتك الشخصية. التطبيق قد يحتاج إلى الوصول لموقعك الجغرافي فقط لتحديد أوقات الصلاة بدقة. لا نقوم بمشاركة أو بيع بياناتك الشخصية لأي جهة خارجية. بياناتك تُستخدم محلياً داخل جهازك لتوفير تجربة مستخدم أفضل.'**
  String get termsPrivacyPolicyBody;

  /// No description provided for @termsPrivacyFooterThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لثقتكم بتطبيق تقوى'**
  String get termsPrivacyFooterThanks;

  /// No description provided for @termsPrivacyFooterDua.
  ///
  /// In ar, this message translates to:
  /// **'نسأل الله أن ينفعنا وإياكم بما فيه الخير'**
  String get termsPrivacyFooterDua;

  /// No description provided for @addReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تذكير جديد'**
  String get addReminderTitle;

  /// No description provided for @addReminderTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التذكير'**
  String get addReminderTitleLabel;

  /// No description provided for @addReminderTitleRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال عنوان للتذكير'**
  String get addReminderTitleRequired;

  /// No description provided for @addReminderTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: صلاة الضحى، قراءة ورد يومي...'**
  String get addReminderTitleHint;

  /// No description provided for @addReminderTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get addReminderTimeLabel;

  /// No description provided for @addReminderIconLabel.
  ///
  /// In ar, this message translates to:
  /// **'أيقونة التذكير'**
  String get addReminderIconLabel;

  /// No description provided for @addReminderSaveError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الحفظ: {error}'**
  String addReminderSaveError(String error);

  /// No description provided for @addReminderAddButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get addReminderAddButton;

  /// No description provided for @freeReadingScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'القراءة الحرة'**
  String get freeReadingScreenTitle;

  /// No description provided for @freeReadingTabSurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة'**
  String get freeReadingTabSurah;

  /// No description provided for @freeReadingTabReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get freeReadingTabReview;

  /// No description provided for @freeReadingTabIndex.
  ///
  /// In ar, this message translates to:
  /// **'فهرس'**
  String get freeReadingTabIndex;

  /// No description provided for @freeReadingTabJuz.
  ///
  /// In ar, this message translates to:
  /// **'جزء'**
  String get freeReadingTabJuz;

  /// No description provided for @freeReadingTabRub.
  ///
  /// In ar, this message translates to:
  /// **'ربع'**
  String get freeReadingTabRub;

  /// No description provided for @freeReadingSearchHintSurah.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن سورة أو آية أو صفحة'**
  String get freeReadingSearchHintSurah;

  /// No description provided for @freeReadingSearchHintOther.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في السور'**
  String get freeReadingSearchHintOther;

  /// No description provided for @freeReadingLastReadLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر قراءة: {surah} - صفحة {page}'**
  String freeReadingLastReadLabel(String surah, String page);

  /// No description provided for @freeReadingLastReadNone.
  ///
  /// In ar, this message translates to:
  /// **'آخر قراءة: لا يوجد'**
  String get freeReadingLastReadNone;

  /// No description provided for @freeReadingHizbLabel.
  ///
  /// In ar, this message translates to:
  /// **'حزب {number}'**
  String freeReadingHizbLabel(String number);

  /// No description provided for @misbahaScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة الإلكترونية'**
  String get misbahaScreenTitle;

  /// No description provided for @misbahaSelectedDhikrLabel.
  ///
  /// In ar, this message translates to:
  /// **'الذكر المختار'**
  String get misbahaSelectedDhikrLabel;

  /// No description provided for @misbahaChooseDhikrPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اختر ذكراً للتسبيح'**
  String get misbahaChooseDhikrPrompt;

  /// No description provided for @misbahaTapToChooseHint.
  ///
  /// In ar, this message translates to:
  /// **'انقر هنا لاختيار ذكر من القائمة لتركيز عبادتك'**
  String get misbahaTapToChooseHint;

  /// No description provided for @misbahaListeningLabel.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاستماع...'**
  String get misbahaListeningLabel;

  /// No description provided for @misbahaTapOrHoldHint.
  ///
  /// In ar, this message translates to:
  /// **'انقر أو اضغط مطولاً'**
  String get misbahaTapOrHoldHint;

  /// No description provided for @misbahaResetButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة'**
  String get misbahaResetButton;

  /// No description provided for @misbahaSoundButton.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get misbahaSoundButton;

  /// No description provided for @misbahaChooseDhikrTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر ذكراً'**
  String get misbahaChooseDhikrTitle;

  /// Screen-reader label for the main tasbih bead when no target count is set
  ///
  /// In ar, this message translates to:
  /// **'عداد الذكر، {count} مرة'**
  String misbahaCounterSemanticLabel(int count);

  /// Screen-reader label for the main tasbih bead when a dhikr with a target count is selected
  ///
  /// In ar, this message translates to:
  /// **'عداد الذكر، {count} من {target} مرة'**
  String misbahaCounterWithTargetSemanticLabel(int count, int target);

  /// Screen-reader label for a dhikr row in the picker list
  ///
  /// In ar, this message translates to:
  /// **'{arabic}، {count} مرة'**
  String misbahaDhikrItemSemanticLabel(String arabic, int count);

  /// No description provided for @qiyamCalcLoadError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل الأوقات: {error}'**
  String qiyamCalcLoadError(String error);

  /// No description provided for @qiyamCalcScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'حاسبة الليل'**
  String get qiyamCalcScreenTitle;

  /// No description provided for @qiyamCalcMidnightTitle.
  ///
  /// In ar, this message translates to:
  /// **'منتصف الليل الشرعي'**
  String get qiyamCalcMidnightTitle;

  /// No description provided for @qiyamCalcMidnightSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي فيه وقت العشاء الاختياري'**
  String get qiyamCalcMidnightSubtitle;

  /// No description provided for @qiyamCalcLastThirdTitle.
  ///
  /// In ar, this message translates to:
  /// **'بداية الثلث الأخير'**
  String get qiyamCalcLastThirdTitle;

  /// No description provided for @qiyamCalcLastThirdSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أفضل وقت لصلاة القيام والوتر'**
  String get qiyamCalcLastThirdSubtitle;

  /// No description provided for @qiyamStageIstighfarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاستغفار'**
  String get qiyamStageIstighfarTitle;

  /// No description provided for @qiyamStageIstighfarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تطهير القلب والروح'**
  String get qiyamStageIstighfarSubtitle;

  /// No description provided for @qiyamStageDuaTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعاء'**
  String get qiyamStageDuaTitle;

  /// No description provided for @qiyamStageDuaSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مناجاة الرحمن في السحر'**
  String get qiyamStageDuaSubtitle;

  /// No description provided for @qiyamStageSalahTitle.
  ///
  /// In ar, this message translates to:
  /// **'صلاة القيام'**
  String get qiyamStageSalahTitle;

  /// No description provided for @qiyamStageSalahSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'طول القنوت والركوع'**
  String get qiyamStageSalahSubtitle;

  /// No description provided for @qiyamStageWitrTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوتر'**
  String get qiyamStageWitrTitle;

  /// No description provided for @qiyamStageWitrSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خاتمة صلاة الليل'**
  String get qiyamStageWitrSubtitle;

  /// No description provided for @paymentMethodsScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMethodsScreenTitle;

  /// No description provided for @paymentMethodEdahabiaTitle.
  ///
  /// In ar, this message translates to:
  /// **'الذهبية / CIB'**
  String get paymentMethodEdahabiaTitle;

  /// No description provided for @paymentMethodVisaTitle.
  ///
  /// In ar, this message translates to:
  /// **'فيزا / ماستركارد'**
  String get paymentMethodVisaTitle;

  /// No description provided for @paymentSupportTitle.
  ///
  /// In ar, this message translates to:
  /// **'صدقة جارية'**
  String get paymentSupportTitle;

  /// No description provided for @paymentSupportMessage.
  ///
  /// In ar, this message translates to:
  /// **'بمساهمتك البسيطة، تجعل \"تقوى\" متاحاً لملايين المسلمين كصدقة جارية عنك وعن والديك. 200دج أو 10€  شهرياً تضمن استمرار هذا العمل وتطويره الدائم.'**
  String get paymentSupportMessage;

  /// No description provided for @paymentContinueButton.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة للدفع'**
  String get paymentContinueButton;

  /// No description provided for @paymentComingSoonMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تفعيل الدفع قريباً إن شاء الله'**
  String get paymentComingSoonMessage;

  /// No description provided for @paymentChooseCardSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر شبكة بطاقتك'**
  String get paymentChooseCardSheetTitle;

  /// No description provided for @paymentMethodEdahabiaOnly.
  ///
  /// In ar, this message translates to:
  /// **'الذهبية'**
  String get paymentMethodEdahabiaOnly;

  /// No description provided for @paymentChargilyCibTitle.
  ///
  /// In ar, this message translates to:
  /// **'CIB'**
  String get paymentChargilyCibTitle;

  /// No description provided for @paymentChargilyDescription.
  ///
  /// In ar, this message translates to:
  /// **'تقوى — دعم شهري'**
  String get paymentChargilyDescription;

  /// No description provided for @paymentStillPending.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تأكيد الدفع بعد. نواصل التحقق بينما تُكمّل العملية في المتصفح.'**
  String get paymentStillPending;

  /// No description provided for @paymentCreatingCheckout.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحضير صفحة الدفع…'**
  String get paymentCreatingCheckout;

  /// No description provided for @paymentCreatingCheckoutSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء جلسة دفع آمنة مع Chargily.'**
  String get paymentCreatingCheckoutSubtitle;

  /// No description provided for @paymentAwaitingTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكمل عملية الدفع'**
  String get paymentAwaitingTitle;

  /// No description provided for @paymentAwaitingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ادفع في الصفحة التي فُتحت في المتصفح. نؤكد الدفع هنا تلقائياً بمجرد إشعار Chargily.'**
  String get paymentAwaitingSubtitle;

  /// No description provided for @paymentVerifyingTitle.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من الدفع…'**
  String get paymentVerifyingTitle;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام الدفع'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'جزاكم الله خيراً — دعمكم يبقي تقوى مجانياً للجميع.'**
  String get paymentSuccessSubtitle;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'فشل الدفع'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل الدفع. يمكنك المحاولة مجدداً.'**
  String get paymentFailedSubtitle;

  /// No description provided for @paymentCanceledTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الدفع'**
  String get paymentCanceledTitle;

  /// No description provided for @paymentCanceledSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم خصم أي مبلغ. عُد متى كنت مستعداً.'**
  String get paymentCanceledSubtitle;

  /// No description provided for @paymentErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get paymentErrorTitle;

  /// No description provided for @paymentErrorSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تجهيز جلسة الدفع. حاول مجدداً من فضلك.'**
  String get paymentErrorSubtitle;

  /// No description provided for @paymentOpenCheckoutAgain.
  ///
  /// In ar, this message translates to:
  /// **'فتح صفحة الدفع مجدداً'**
  String get paymentOpenCheckoutAgain;

  /// No description provided for @paymentIAmDone.
  ///
  /// In ar, this message translates to:
  /// **'لقد أكملت الدفع'**
  String get paymentIAmDone;

  /// No description provided for @paymentDoneButton.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get paymentDoneButton;

  /// No description provided for @paymentRetryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get paymentRetryButton;

  /// No description provided for @wiseScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'فيزا / ماستركارد عبر Wise'**
  String get wiseScreenTitle;

  /// No description provided for @wiseIntroMessage.
  ///
  /// In ar, this message translates to:
  /// **'أرسل دعمك الشهري مباشرة إلى حساب المطوّر على Wise من تطبيق Wise أو تطبيق بنكك. استخدم المرجع أدناه حتىتمكن معرفة تحويلك.'**
  String get wiseIntroMessage;

  /// Snack-bar shown after copying a Wise recipient field
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ {label} إلى الحافظة'**
  String wiseCopiedMessage(String label);

  /// No description provided for @wiseHolderLabel.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الحساب'**
  String get wiseHolderLabel;

  /// No description provided for @wiseIbanLabel.
  ///
  /// In ar, this message translates to:
  /// **'الآيبان (IBAN)'**
  String get wiseIbanLabel;

  /// No description provided for @wiseAccountLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحساب'**
  String get wiseAccountLabel;

  /// No description provided for @wiseSortCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز الترتيب'**
  String get wiseSortCodeLabel;

  /// No description provided for @wiseBankLabel.
  ///
  /// In ar, this message translates to:
  /// **'البنك'**
  String get wiseBankLabel;

  /// No description provided for @wiseAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get wiseAmountLabel;

  /// No description provided for @wiseReferenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'مرجع الدفع'**
  String get wiseReferenceLabel;

  /// No description provided for @wiseOpenButton.
  ///
  /// In ar, this message translates to:
  /// **'فتح Wise'**
  String get wiseOpenButton;

  /// No description provided for @wiseSentButton.
  ///
  /// In ar, this message translates to:
  /// **'لقد أرسلت الدفع'**
  String get wiseSentButton;

  /// No description provided for @wiseThanksTitle.
  ///
  /// In ar, this message translates to:
  /// **'جزاكم الله خيراً'**
  String get wiseThanksTitle;

  /// No description provided for @wiseThanksSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل تحويلك هنا. يظهر رسمياً بعد مطابقة كشف الحساب.'**
  String get wiseThanksSubtitle;

  /// No description provided for @qiyamOnboardingTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في قيام الليل'**
  String get qiyamOnboardingTitle;

  /// No description provided for @qiyamOnboardingDescription.
  ///
  /// In ar, this message translates to:
  /// **'رحلة إيمانية هادئة في جوف الليل، تبدأ بالذكر، وتمر بالقرآن، وتكتمل بالصلاة والاستغفار.'**
  String get qiyamOnboardingDescription;

  /// No description provided for @qiyamOnboardingStep1.
  ///
  /// In ar, this message translates to:
  /// **'استعد بالذكر والثناء'**
  String get qiyamOnboardingStep1;

  /// No description provided for @qiyamOnboardingStep2.
  ///
  /// In ar, this message translates to:
  /// **'رتل آيات الله بتدبر'**
  String get qiyamOnboardingStep2;

  /// No description provided for @qiyamOnboardingStep3.
  ///
  /// In ar, this message translates to:
  /// **'ناجِ ربك بالصلاة والدعاء'**
  String get qiyamOnboardingStep3;

  /// No description provided for @qiyamOnboardingStep4.
  ///
  /// In ar, this message translates to:
  /// **'اختم بالاستغفار والأسحار'**
  String get qiyamOnboardingStep4;

  /// No description provided for @qiyamOnboardingStartButton.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الرحلة الآن'**
  String get qiyamOnboardingStartButton;

  /// No description provided for @subscriptionScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscriptionScreenTitle;

  /// No description provided for @subscriptionIntroText.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراكات لاستمرار المشروع.'**
  String get subscriptionIntroText;

  /// No description provided for @subscriptionFreeAccessNote.
  ///
  /// In ar, this message translates to:
  /// **'كل من لا يستطيع سداد الاشتراك مرحب به للاستفادة من التطبيق مجاناً.'**
  String get subscriptionFreeAccessNote;

  /// No description provided for @subscriptionHonorSystemNote.
  ///
  /// In ar, this message translates to:
  /// **'ما لم نعلن على خلاف ذلك، لا نقوم بالتأكد من سداد المستخدم لرسوم الاشتراك. ونقصد ترك ذلك لرغبة المستخدم.'**
  String get subscriptionHonorSystemNote;

  /// No description provided for @subscriptionPayMonthlyButton.
  ///
  /// In ar, this message translates to:
  /// **'بإمكاني الدفع شهرياً'**
  String get subscriptionPayMonthlyButton;

  /// No description provided for @subscriptionUseFreeButton.
  ///
  /// In ar, this message translates to:
  /// **'أريد استخدام التطبيق مجاناً'**
  String get subscriptionUseFreeButton;

  /// No description provided for @aiMemorizeScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحفيظ الذكي'**
  String get aiMemorizeScreenTitle;

  /// No description provided for @aiMemorizeTabPages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get aiMemorizeTabPages;

  /// No description provided for @aiMemorizeTabSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get aiMemorizeTabSurahs;

  /// No description provided for @aiMemorizePageSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الصفحة (1-604)'**
  String get aiMemorizePageSearchHint;

  /// No description provided for @aiMemorizeSurahSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في السور'**
  String get aiMemorizeSurahSearchHint;

  /// No description provided for @khatmaRingOfPagesLabel.
  ///
  /// In ar, this message translates to:
  /// **'من {total} صفحة'**
  String khatmaRingOfPagesLabel(String total);

  /// No description provided for @quranJuzLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {name}'**
  String quranJuzLabel(String name);

  /// No description provided for @quranJuzPercentComplete.
  ///
  /// In ar, this message translates to:
  /// **'{percent}% مكتمل'**
  String quranJuzPercentComplete(String percent);

  /// No description provided for @favoriteDuasScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعيتي المفضلة'**
  String get favoriteDuasScreenTitle;

  /// No description provided for @favoriteDuasCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{دعاء واحد محفوظ} two{دعاءان محفوظان} few{{count} أدعية محفوظة} many{{count} دعاءً محفوظاً} other{{count} دعاء محفوظ}}'**
  String favoriteDuasCountLabel(int count);

  /// No description provided for @favoriteDuasEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أدعية مفضلة بعد'**
  String get favoriteDuasEmptyTitle;

  /// No description provided for @favoriteDuasEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على ❤️ داخل أي دعاء لحفظه هنا'**
  String get favoriteDuasEmptySubtitle;

  /// No description provided for @quranReaderMushafModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get quranReaderMushafModeTitle;

  /// No description provided for @quranReaderMushafModeTooltip.
  ///
  /// In ar, this message translates to:
  /// **'وضع المصحف'**
  String get quranReaderMushafModeTooltip;

  /// No description provided for @customIbadahGroupTitle.
  ///
  /// In ar, this message translates to:
  /// **'عاداتي وإضافاتي'**
  String get customIbadahGroupTitle;

  /// No description provided for @customIbadahAddButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وتخصيص عاداتك'**
  String get customIbadahAddButton;

  /// No description provided for @customIbadahPositiveHeader.
  ///
  /// In ar, this message translates to:
  /// **'العادات الإيجابية'**
  String get customIbadahPositiveHeader;

  /// No description provided for @customIbadahNegativeHeader.
  ///
  /// In ar, this message translates to:
  /// **'العادات السلبية (محظورات مخصصة)'**
  String get customIbadahNegativeHeader;

  /// No description provided for @authChoiceAppName.
  ///
  /// In ar, this message translates to:
  /// **'تقوى'**
  String get authChoiceAppName;

  /// No description provided for @authChoiceTagline.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك نحو حياة مليئة بالإيمان'**
  String get authChoiceTagline;

  /// No description provided for @authChoiceSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authChoiceSignInButton;

  /// No description provided for @authChoiceGuestButton.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة كضيف'**
  String get authChoiceGuestButton;

  /// No description provided for @authChoiceSyncNote.
  ///
  /// In ar, this message translates to:
  /// **'تسجيلك يضمن لك حفظ بياناتك عبر جميع أجهزتك'**
  String get authChoiceSyncNote;

  /// No description provided for @authPasswordStrengthWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة'**
  String get authPasswordStrengthWeak;

  /// No description provided for @authPasswordStrengthMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get authPasswordStrengthMedium;

  /// No description provided for @authPasswordStrengthGood.
  ///
  /// In ar, this message translates to:
  /// **'جيدة'**
  String get authPasswordStrengthGood;

  /// No description provided for @authPasswordStrengthStrong.
  ///
  /// In ar, this message translates to:
  /// **'قوية ✓'**
  String get authPasswordStrengthStrong;

  /// No description provided for @authPasswordStrengthLabel.
  ///
  /// In ar, this message translates to:
  /// **'قوة كلمة المرور: {strength}'**
  String authPasswordStrengthLabel(String strength);

  /// No description provided for @mosqueErrorLocationPermission.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تفعيل صلاحية الموقع لرؤية المساجد القريبة'**
  String get mosqueErrorLocationPermission;

  /// No description provided for @mosqueErrorLocationPermissionForever.
  ///
  /// In ar, this message translates to:
  /// **'يجب تفعيل صلاحيات الموقع من إعدادات الجهاز'**
  String get mosqueErrorLocationPermissionForever;

  /// No description provided for @mosqueFetchError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المساجد (ضغط على السيرفر). يرجى المحاولة لاحقاً'**
  String get mosqueFetchError;

  /// No description provided for @mosqueDefaultName.
  ///
  /// In ar, this message translates to:
  /// **'مسجد قريب'**
  String get mosqueDefaultName;

  /// No description provided for @mosqueDefaultAddress.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان محدد'**
  String get mosqueDefaultAddress;

  /// No description provided for @emailConfirmationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البريد الإلكتروني'**
  String get emailConfirmationTitle;

  /// No description provided for @emailConfirmationLinkSentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط التأكيد إلى:\n{email}'**
  String emailConfirmationLinkSentLabel(String email);

  /// No description provided for @emailConfirmationInstructions.
  ///
  /// In ar, this message translates to:
  /// **'يرجى التحقق من بريدك الإلكتروني والضغط على الرابط لتفعيل حسابك والبدء في رحلتك مع تقوى.'**
  String get emailConfirmationInstructions;

  /// No description provided for @emailConfirmationBackToSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get emailConfirmationBackToSignInButton;

  /// Title of the overlay shown when a guest opens a sync-only feature
  ///
  /// In ar, this message translates to:
  /// **'ميزة سحابية'**
  String get guestGuardTitle;

  /// Explanation shown when a guest opens a sync-only feature
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة (المحاسبة والإحصائيات) تتطلب مزامنة سحابية لحفظ تقدمك. يرجى تسجيل الدخول لتفعيلها.'**
  String get guestGuardMessage;

  /// No description provided for @guestGuardSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دخول / إنشاء حساب'**
  String get guestGuardSignInButton;

  /// No description provided for @guestGuardBackButton.
  ///
  /// In ar, this message translates to:
  /// **'العودة'**
  String get guestGuardBackButton;

  /// No description provided for @customTimePickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الوقت'**
  String get customTimePickerTitle;

  /// No description provided for @customTimePickerConfirmButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get customTimePickerConfirmButton;

  /// No description provided for @quranReaderBookmarkSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العلامة المرجعية'**
  String get quranReaderBookmarkSaved;

  /// No description provided for @achievementPointsRewardLabel.
  ///
  /// In ar, this message translates to:
  /// **'+{points} نقطة'**
  String achievementPointsRewardLabel(int points);

  /// No description provided for @achievementPendingLabel.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get achievementPendingLabel;

  /// No description provided for @khatmaMenuMarkFinished.
  ///
  /// In ar, this message translates to:
  /// **'تحديد كمنتهية'**
  String get khatmaMenuMarkFinished;

  /// No description provided for @khatmaMenuCancelKhatma.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الختمة'**
  String get khatmaMenuCancelKhatma;

  /// No description provided for @khatmaMarkFinishedDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد كمنتهية'**
  String get khatmaMarkFinishedDialogTitle;

  /// No description provided for @khatmaMarkFinishedDialogBody.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من تحديد هذه الختمة كمنتهية؟'**
  String get khatmaMarkFinishedDialogBody;

  /// No description provided for @khatmaMarkFinishedDialogNote.
  ///
  /// In ar, this message translates to:
  /// **'هذا الخيار مناسب إذا كنت قد أنهيت قراءة القرآن من مصدر آخر.'**
  String get khatmaMarkFinishedDialogNote;

  /// No description provided for @khatmaMarkFinishedConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get khatmaMarkFinishedConfirm;

  /// No description provided for @khatmaCancelDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الختمة'**
  String get khatmaCancelDialogTitle;

  /// No description provided for @khatmaCancelDialogBody.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء هذه الختمة؟'**
  String get khatmaCancelDialogBody;

  /// No description provided for @khatmaCancelDialogWarning.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: سيتم حفظ تقدمك في التاريخ ولكن لن تتمكن من استرجاع الختمة الملغاة مرة أخرى.'**
  String get khatmaCancelDialogWarning;

  /// No description provided for @khatmaCancelConfirmFinal.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الختمة نهائياً'**
  String get khatmaCancelConfirmFinal;

  /// No description provided for @khatmaDialogGoBack.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get khatmaDialogGoBack;

  /// No description provided for @khatmaInfoSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الختمة'**
  String get khatmaInfoSectionTitle;

  /// No description provided for @khatmaInfoNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الختمة'**
  String get khatmaInfoNameLabel;

  /// No description provided for @khatmaInfoTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الختمة'**
  String get khatmaInfoTypeLabel;

  /// No description provided for @khatmaInfoStartDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get khatmaInfoStartDateLabel;

  /// No description provided for @khatmaInfoCompletedDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأيام المكتملة'**
  String get khatmaInfoCompletedDaysLabel;

  /// No description provided for @khatmaInfoCompletedDaysValue.
  ///
  /// In ar, this message translates to:
  /// **'{n} يوم'**
  String khatmaInfoCompletedDaysValue(String n);

  /// No description provided for @khatmaInfoEndTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'مدة الختمة'**
  String get khatmaInfoEndTypeLabel;

  /// No description provided for @khatmaInfoEndTypeNoLimit.
  ///
  /// In ar, this message translates to:
  /// **'بدون وقت محدد للانتهاء'**
  String get khatmaInfoEndTypeNoLimit;

  /// No description provided for @khatmaInfoEndTypeTarget.
  ///
  /// In ar, this message translates to:
  /// **'حتى {date}'**
  String khatmaInfoEndTypeTarget(String date);

  /// No description provided for @khatmaTypeMuyassaraLabel.
  ///
  /// In ar, this message translates to:
  /// **'ختمة ميسرة'**
  String get khatmaTypeMuyassaraLabel;

  /// No description provided for @khatmaTypeMultazimaLabel.
  ///
  /// In ar, this message translates to:
  /// **'ختمة ملتزمة'**
  String get khatmaTypeMultazimaLabel;

  /// No description provided for @khatmaOverallProgressTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقدم الإجمالي'**
  String get khatmaOverallProgressTitle;

  /// No description provided for @khatmaReachedPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى صفحة'**
  String get khatmaReachedPageLabel;

  /// No description provided for @khatmaReachedPageValue.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total}'**
  String khatmaReachedPageValue(String current, String total);

  /// No description provided for @khatmaCurrentPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الحالية'**
  String get khatmaCurrentPageLabel;

  /// No description provided for @khatmaCurrentPageValue.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {n}'**
  String khatmaCurrentPageValue(String n);

  /// No description provided for @khatmaRemainingPagesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات المتبقية'**
  String get khatmaRemainingPagesLabel;

  /// No description provided for @khatmaRemainingPagesValue.
  ///
  /// In ar, this message translates to:
  /// **'{n} صفحة'**
  String khatmaRemainingPagesValue(String n);

  /// No description provided for @khatmaEstimatedHasanatLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحسنات المقدرة'**
  String get khatmaEstimatedHasanatLabel;

  /// No description provided for @khatmaEstimatedHasanatValue.
  ///
  /// In ar, this message translates to:
  /// **'{n} حسنة'**
  String khatmaEstimatedHasanatValue(String n);

  /// No description provided for @khatmaStatusMuyassaraBadge.
  ///
  /// In ar, this message translates to:
  /// **'ختمة ميسرة - بدون ضغط زمني'**
  String get khatmaStatusMuyassaraBadge;

  /// No description provided for @khatmaStatusMultazimaBadge.
  ///
  /// In ar, this message translates to:
  /// **'ختمة ملتزمة - {n} صفحة/يوم'**
  String khatmaStatusMultazimaBadge(String n);

  /// No description provided for @khatmaAvgPagesPerDayLabel.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الصفحات/اليوم'**
  String get khatmaAvgPagesPerDayLabel;

  /// No description provided for @khatmaTypeDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الختمة'**
  String get khatmaTypeDescriptionLabel;

  /// No description provided for @khatmaTypeDescriptionFree.
  ///
  /// In ar, this message translates to:
  /// **'بدون ضغط زمني أو ورد يومي محدد'**
  String get khatmaTypeDescriptionFree;

  /// No description provided for @khatmaTypeDescriptionTarget.
  ///
  /// In ar, this message translates to:
  /// **'ورد يومي محدد: {n} صفحة'**
  String khatmaTypeDescriptionTarget(String n);

  /// No description provided for @khatmaExtraStatsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات إضافية'**
  String get khatmaExtraStatsTitle;

  /// No description provided for @khatmaTotalReadingTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي وقت القراءة'**
  String get khatmaTotalReadingTimeLabel;

  /// No description provided for @khatmaAvgReadingTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'متوسط وقت القراءة'**
  String get khatmaAvgReadingTimeLabel;

  /// No description provided for @khatmaCurrentStreakLabel.
  ///
  /// In ar, this message translates to:
  /// **'السلسلة الحالية'**
  String get khatmaCurrentStreakLabel;

  /// No description provided for @khatmaLongestStreakLabel.
  ///
  /// In ar, this message translates to:
  /// **'أطول سلسلة'**
  String get khatmaLongestStreakLabel;

  /// No description provided for @khatmaLastReadLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر قراءة'**
  String get khatmaLastReadLabel;

  /// No description provided for @khatmaStreakDaysValue.
  ///
  /// In ar, this message translates to:
  /// **'{n} أيام'**
  String khatmaStreakDaysValue(String n);

  /// No description provided for @khatmaNoDataValue.
  ///
  /// In ar, this message translates to:
  /// **'—'**
  String get khatmaNoDataValue;

  /// No description provided for @khatmaReadingDaysTitle.
  ///
  /// In ar, this message translates to:
  /// **'أيام القراءة'**
  String get khatmaReadingDaysTitle;

  /// No description provided for @khatmaReadingDaysSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الأيام التي قرأت فيها القرآن الكريم'**
  String get khatmaReadingDaysSubtitle;

  /// No description provided for @khatmaLegendFuture.
  ///
  /// In ar, this message translates to:
  /// **'مستقبلي'**
  String get khatmaLegendFuture;

  /// No description provided for @khatmaLegendMissed.
  ///
  /// In ar, this message translates to:
  /// **'فائت'**
  String get khatmaLegendMissed;

  /// No description provided for @khatmaLegendPartial.
  ///
  /// In ar, this message translates to:
  /// **'ناقص'**
  String get khatmaLegendPartial;

  /// No description provided for @khatmaLegendComplete.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get khatmaLegendComplete;

  /// No description provided for @khatmaDurationHoursMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{hours}س {minutes}د'**
  String khatmaDurationHoursMinutes(String hours, String minutes);

  /// No description provided for @khatmaDurationMinutesSeconds.
  ///
  /// In ar, this message translates to:
  /// **'{minutes}د {seconds}ث'**
  String khatmaDurationMinutesSeconds(String minutes, String seconds);

  /// No description provided for @khatmaDurationSecondsOnly.
  ///
  /// In ar, this message translates to:
  /// **'{seconds}ث'**
  String khatmaDurationSecondsOnly(String seconds);

  /// No description provided for @khatmaHistorySortMenuTooltip.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب وعرض'**
  String get khatmaHistorySortMenuTooltip;

  /// No description provided for @khatmaHistorySortByDate.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب التاريخ'**
  String get khatmaHistorySortByDate;

  /// No description provided for @khatmaHistorySortByName.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب الاسم'**
  String get khatmaHistorySortByName;

  /// No description provided for @khatmaHistorySortByDuration.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب المدة'**
  String get khatmaHistorySortByDuration;

  /// No description provided for @khatmaHistorySortByProgress.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب نسبة الإنجاز'**
  String get khatmaHistorySortByProgress;

  /// No description provided for @khatmaHistoryShowStats.
  ///
  /// In ar, this message translates to:
  /// **'عرض الإحصائيات'**
  String get khatmaHistoryShowStats;

  /// No description provided for @khatmaHistoryViewDetails.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get khatmaHistoryViewDetails;

  /// No description provided for @khatmaHistoryDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الختمة'**
  String get khatmaHistoryDetailsTitle;

  /// No description provided for @khatmaHistoryStatsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات الختمات'**
  String get khatmaHistoryStatsTitle;

  /// No description provided for @khatmaHistoryStatsTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الختمات'**
  String get khatmaHistoryStatsTotal;

  /// No description provided for @khatmaHistoryStatsCompleted.
  ///
  /// In ar, this message translates to:
  /// **'ختمات مكتملة'**
  String get khatmaHistoryStatsCompleted;

  /// No description provided for @khatmaHistoryStatsCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ختمات ملغاة'**
  String get khatmaHistoryStatsCancelled;

  /// No description provided for @khatmaHistoryStatsTotalPages.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الصفحات المقروءة'**
  String get khatmaHistoryStatsTotalPages;

  /// No description provided for @khatmaHistoryCloseButton.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get khatmaHistoryCloseButton;

  /// No description provided for @khatmaProgressEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ختمة نشطة حالياً'**
  String get khatmaProgressEmptyTitle;

  /// No description provided for @khatmaProgressEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة لتتبع تقدمك هنا'**
  String get khatmaProgressEmptySubtitle;

  /// Title of the fallback screen shown for an unknown route
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير متاحة'**
  String get routeNotFoundTitle;

  /// Unknown-route detail line naming the route that failed
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح المسار «{route}».'**
  String routeNotFoundMessage(String route);

  /// Unknown-route action when there is nothing to pop back to
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get routeNotFoundGoHome;

  /// Unknown-route action when the previous screen can be popped back to
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get routeNotFoundGoBack;

  /// Generic word for a prayer, used when no specific prayer is known
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get prayerGenericLabel;

  /// Primary action on the guest-mode overlay
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دخول / إنشاء حساب'**
  String get guestGuardSignIn;

  /// Secondary action on the guest-mode overlay
  ///
  /// In ar, this message translates to:
  /// **'العودة'**
  String get guestGuardBack;

  /// Hadith shown under the app name on the splash screen
  ///
  /// In ar, this message translates to:
  /// **'\"حَاسِبُوا أَنفُسَكُمْ قَبْلَ أَنْ تُحَاسَبُوا\"'**
  String get splashQuote;

  /// Generic fallback error message when a section fails to load
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'**
  String get genericErrorMessage;

  /// Generic retry action button label
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryButtonLabel;

  /// Semantic label for a compact inline retry affordance (a small area that failed to load, e.g. a stat tile)
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحميل، اضغط لإعادة المحاولة'**
  String get inlineErrorRetryLabel;

  /// Screen-reader label for one bar in the weekly/period performance chart
  ///
  /// In ar, this message translates to:
  /// **'{day}: {points} نقطة'**
  String statsChartBarSemanticLabel(String day, int points);

  /// Compact connectivity/sync status label shown in the drawer: no network
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get drawerSyncOffline;

  /// Compact connectivity/sync status label shown in the drawer: idle, up to date
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة'**
  String get drawerSyncSynced;

  /// Shown when a prayer/ibadah status write to the local database fails
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحفظ، حاول مرة أخرى'**
  String get checklistSaveError;

  /// Shown when the local save succeeded but pushing it to the cloud failed
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ محليًا، وستتم المزامنة مع السحابة عند عودة الاتصال'**
  String get checklistSyncError;

  /// Home feature-grid label for the Ramadan tracker, only shown during the Hijri month of Ramadan
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get homeFeatureRamadan;

  /// App bar title of the Ramadan tracker screen
  ///
  /// In ar, this message translates to:
  /// **'متابعة رمضان'**
  String get ramadanTrackerAppBarTitle;

  /// Defensive empty state if the Ramadan tracker screen is somehow opened outside Ramadan
  ///
  /// In ar, this message translates to:
  /// **'لسنا في شهر رمضان الآن'**
  String get ramadanNotRamadanMessage;

  /// Shown in place of the Suhoor/Iftar countdown when prayer times can't be resolved (usually a missing location permission)
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد مواقيت الصلاة — تحقق من إذن الموقع'**
  String get ramadanPrayerTimesUnavailable;

  /// Label before a countdown to Fajr (end of Suhoor) on the Ramadan tracker
  ///
  /// In ar, this message translates to:
  /// **'الإمساك بعد'**
  String get ramadanSuhoorEndsIn;

  /// Label before a countdown to Maghrib (Iftar) on the Ramadan tracker
  ///
  /// In ar, this message translates to:
  /// **'الإفطار بعد'**
  String get ramadanIftarIn;

  /// Shown on the Ramadan tracker once Maghrib has passed for today
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الإفطار! 🌙'**
  String get ramadanIftarTimeReached;

  /// Section title for the curated daily Ramadan dua
  ///
  /// In ar, this message translates to:
  /// **'دعاء اليوم'**
  String get ramadanDuaOfDayTitle;

  /// Toggle label: whether the user performed night prayer (Qiyam) this Ramadan night
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل'**
  String get ramadanIhyaLaylLabel;

  /// Sublabel/explainer for the Qiyam toggle on the Ramadan tracker
  ///
  /// In ar, this message translates to:
  /// **'هل أحييت هذه الليلة بالقيام؟'**
  String get ramadanIhyaLaylSublabel;

  /// Section title for today's fasting status on the Ramadan tracker
  ///
  /// In ar, this message translates to:
  /// **'صيام اليوم'**
  String get ramadanFastingStatusTitle;

  /// Shown when today's fasting type is logged as obligatory (fard)
  ///
  /// In ar, this message translates to:
  /// **'صمت اليوم (فرض) ✅'**
  String get ramadanFastingDoneFard;

  /// Shown when today's fasting type is logged as voluntary (nafl)
  ///
  /// In ar, this message translates to:
  /// **'صمت اليوم (نافلة) ✅'**
  String get ramadanFastingDoneNafl;

  /// Shown when today has no fasting type logged yet
  ///
  /// In ar, this message translates to:
  /// **'لم تسجل صيامك اليوم بعد'**
  String get ramadanFastingNotLogged;

  /// Button on the Ramadan tracker that opens the daily checklist to log today's fast
  ///
  /// In ar, this message translates to:
  /// **'سجّل صيامك'**
  String get ramadanLogFastingButton;

  /// Section title for the 30-day Ramadan fasting progress strip
  ///
  /// In ar, this message translates to:
  /// **'متابعة أيام رمضان'**
  String get ramadanProgressStripTitle;

  /// Home feature-grid label for the Zakat calculator
  ///
  /// In ar, this message translates to:
  /// **'الزكاة'**
  String get homeFeatureZakat;

  /// App bar title of the Zakat calculator screen
  ///
  /// In ar, this message translates to:
  /// **'حاسبة الزكاة'**
  String get zakatCalculatorAppBarTitle;

  /// Disclaimer shown on the Zakat calculator: it's a simplified tool, not a fatwa
  ///
  /// In ar, this message translates to:
  /// **'هذه حاسبة مبسطة للزكاة. لحالتك الخاصة، يُستحسن استشارة عالم شرعي.'**
  String get zakatDisclaimer;

  /// Section title for the assets input fields
  ///
  /// In ar, this message translates to:
  /// **'الأصول الزكوية'**
  String get zakatAssetsSectionTitle;

  /// Input label: cash on hand
  ///
  /// In ar, this message translates to:
  /// **'النقد المتوفر'**
  String get zakatCashLabel;

  /// Input label: bank savings
  ///
  /// In ar, this message translates to:
  /// **'الرصيد البنكي'**
  String get zakatBankLabel;

  /// Input label: gold weight in grams
  ///
  /// In ar, this message translates to:
  /// **'وزن الذهب (جرام)'**
  String get zakatGoldGramsLabel;

  /// Input label: user-supplied current gold price per gram
  ///
  /// In ar, this message translates to:
  /// **'سعر جرام الذهب اليوم'**
  String get zakatGoldPriceLabel;

  /// Input label: silver weight in grams
  ///
  /// In ar, this message translates to:
  /// **'وزن الفضة (جرام)'**
  String get zakatSilverGramsLabel;

  /// Input label: user-supplied current silver price per gram
  ///
  /// In ar, this message translates to:
  /// **'سعر جرام الفضة اليوم'**
  String get zakatSilverPriceLabel;

  /// Helper text explaining the user must supply today's price themselves
  ///
  /// In ar, this message translates to:
  /// **'أدخل السعر الحالي — تحقق من بنكك أو السوق المحلي'**
  String get zakatPriceHelperText;

  /// Input label: trade goods value
  ///
  /// In ar, this message translates to:
  /// **'قيمة عروض التجارة'**
  String get zakatTradeGoodsLabel;

  /// Input label: deductible short-term debt
  ///
  /// In ar, this message translates to:
  /// **'الديون قصيرة الأجل المستحقة'**
  String get zakatDebtLabel;

  /// Input label: free-text currency symbol/code for display only
  ///
  /// In ar, this message translates to:
  /// **'العملة (مثال: MAD، \$، €)'**
  String get zakatCurrencyLabel;

  /// Section title for choosing the Nisab standard
  ///
  /// In ar, this message translates to:
  /// **'معيار النصاب'**
  String get zakatNisabSectionTitle;

  /// Nisab standard option: gold (85g)
  ///
  /// In ar, this message translates to:
  /// **'الذهب (٨٥ جم)'**
  String get zakatNisabGoldOption;

  /// Nisab standard option: silver (595g)
  ///
  /// In ar, this message translates to:
  /// **'الفضة (٥٩٥ جم)'**
  String get zakatNisabSilverOption;

  /// Toggle label: whether the wealth has been held for a full Hijri year
  ///
  /// In ar, this message translates to:
  /// **'مرور الحول'**
  String get zakatHawlLabel;

  /// Explainer for the Hawl toggle
  ///
  /// In ar, this message translates to:
  /// **'هل بقي هذا المال في حوزتك لمدة سنة هجرية كاملة؟'**
  String get zakatHawlSublabel;

  /// Button that runs the Zakat calculation
  ///
  /// In ar, this message translates to:
  /// **'احسب الزكاة'**
  String get zakatCalculateButton;

  /// Button that persists the current calculation locally
  ///
  /// In ar, this message translates to:
  /// **'احفظ هذا الحساب'**
  String get zakatSaveButton;

  /// Confirmation snackbar after saving a calculation
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الحساب'**
  String get zakatSavedMessage;

  /// Result card title
  ///
  /// In ar, this message translates to:
  /// **'النتيجة'**
  String get zakatResultTitle;

  /// Result row label: net zakatable wealth
  ///
  /// In ar, this message translates to:
  /// **'صافي المال الزكوي'**
  String get zakatResultWealthLabel;

  /// Result row label: the Nisab threshold in the chosen currency
  ///
  /// In ar, this message translates to:
  /// **'حد النصاب'**
  String get zakatResultNisabLabel;

  /// Shown when Zakat is due, with the computed amount
  ///
  /// In ar, this message translates to:
  /// **'الزكاة المستحقة: {amount}'**
  String zakatResultDueMessage(String amount);

  /// Shown when wealth is below Nisab
  ///
  /// In ar, this message translates to:
  /// **'لا زكاة مستحقة — لم يبلغ مالك النصاب'**
  String get zakatResultNotDueMessage;

  /// Shown alongside zakatResultNotDueMessage with the exact shortfall
  ///
  /// In ar, this message translates to:
  /// **'تحتاج {amount} إضافية لبلوغ النصاب'**
  String zakatResultShortfallMessage(String amount);

  /// Shown when wealth meets Nisab but the Hawl toggle isn't confirmed yet
  ///
  /// In ar, this message translates to:
  /// **'بلغ مالك النصاب — أكّد مرور الحول أعلاه لحساب المستحق'**
  String get zakatResultHawlPendingMessage;

  /// Shown when the Nisab threshold can't be computed because no price was entered for the selected standard
  ///
  /// In ar, this message translates to:
  /// **'أدخل سعر الجرام لمعيار النصاب المختار لحساب الحد'**
  String get zakatMissingPriceMessage;

  /// Button that opens the add-reminder sheet pre-filled for an annual Zakat reminder
  ///
  /// In ar, this message translates to:
  /// **'ضبط تذكير سنوي بالزكاة'**
  String get zakatSetReminderButton;

  /// Default reminder title pre-filled when creating a Zakat reminder
  ///
  /// In ar, this message translates to:
  /// **'موعد إخراج الزكاة'**
  String get zakatReminderDefaultTitle;

  /// Section heading for the Zakat al-Mal (wealth zakat) form (R2.5)
  ///
  /// In ar, this message translates to:
  /// **'زكاة المال'**
  String get zakatMalSectionHeading;

  /// Section title for the saved calculations history list (R1.1)
  ///
  /// In ar, this message translates to:
  /// **'سجل الحسابات'**
  String get zakatHistorySectionTitle;

  /// Empty-state text shown when there are no saved Zakat calculations (R1.3)
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حسابات محفوظة بعد'**
  String get zakatHistoryEmpty;

  /// Section heading / ExpansionTile title for the Zakat al-Fitr companion section (R2.1)
  ///
  /// In ar, this message translates to:
  /// **'زكاة الفطر'**
  String get zakatFitrahSectionHeading;

  /// Input label for the number of household members in Zakat al-Fitr (R2.2)
  ///
  /// In ar, this message translates to:
  /// **'عدد أفراد الأسرة (١–٩٩)'**
  String get zakatFitrahMembersLabel;

  /// Input label for the local staple-food price per person for Zakat al-Fitr (R2.2)
  ///
  /// In ar, this message translates to:
  /// **'سعر قوت اليوم للشخص الواحد'**
  String get zakatFitrahPricePerPersonLabel;

  /// Input label for the free-text currency label in the Zakat al-Fitr section (R2.2)
  ///
  /// In ar, this message translates to:
  /// **'رمز العملة'**
  String get zakatFitrahCurrencyLabel;

  /// Label displayed next to the computed Zakat al-Fitr total (R2.3)
  ///
  /// In ar, this message translates to:
  /// **'إجمالي زكاة الفطر المستحقة'**
  String get zakatFitrahTotalLabel;

  /// Inline error shown when the members field is invalid in Zakat al-Fitr (R2.4)
  ///
  /// In ar, this message translates to:
  /// **'أدخل عدداً صحيحاً بين ١ و٩٩'**
  String get zakatFitrahInvalidMembers;

  /// Inline error shown when the price-per-person field is invalid in Zakat al-Fitr (R2.4)
  ///
  /// In ar, this message translates to:
  /// **'أدخل قيمة بين ٠٫٠١ و٩٩٩٬٩٩٩٫٩٩'**
  String get zakatFitrahInvalidPrice;

  /// Home feature-grid label for the family/community accountability circles feature
  ///
  /// In ar, this message translates to:
  /// **'دوائر\nالمحاسبة'**
  String get homeFeatureCircles;

  /// App bar title of the circles list screen
  ///
  /// In ar, this message translates to:
  /// **'دوائر المحاسبة'**
  String get circlesAppBarTitle;

  /// Empty state title when the user has no circles
  ///
  /// In ar, this message translates to:
  /// **'لا توجد دوائر بعد'**
  String get circlesEmptyTitle;

  /// Empty state body explaining what circles are
  ///
  /// In ar, this message translates to:
  /// **'أنشئ دائرة لعائلتك أو أصدقائك، أو انضم إلى دائرة موجودة برمز الدعوة'**
  String get circlesEmptyBody;

  /// Button to create a new circle
  ///
  /// In ar, this message translates to:
  /// **'إنشاء دائرة'**
  String get circlesCreateButton;

  /// Button to join an existing circle by invite code
  ///
  /// In ar, this message translates to:
  /// **'الانضمام برمز'**
  String get circlesJoinButton;

  /// Dialog title for creating a circle
  ///
  /// In ar, this message translates to:
  /// **'إنشاء دائرة جديدة'**
  String get circlesCreateDialogTitle;

  /// Input label for the new circle's name
  ///
  /// In ar, this message translates to:
  /// **'اسم الدائرة'**
  String get circlesCreateNameLabel;

  /// Confirm button on the create-circle dialog
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get circlesCreateConfirm;

  /// Dialog title for joining a circle
  ///
  /// In ar, this message translates to:
  /// **'الانضمام إلى دائرة'**
  String get circlesJoinDialogTitle;

  /// Input label for the invite code
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة'**
  String get circlesJoinCodeLabel;

  /// Confirm button on the join-circle dialog
  ///
  /// In ar, this message translates to:
  /// **'انضمام'**
  String get circlesJoinConfirm;

  /// Member count label on a circle card
  ///
  /// In ar, this message translates to:
  /// **'{count} أعضاء'**
  String circlesMemberCount(int count);

  /// Label shown above the circle's invite code on the detail screen
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة'**
  String get circlesInviteCodeLabel;

  /// Button to share the invite code via the system share sheet
  ///
  /// In ar, this message translates to:
  /// **'مشاركة رمز الدعوة'**
  String get circlesShareInviteButton;

  /// Button to leave a circle
  ///
  /// In ar, this message translates to:
  /// **'مغادرة الدائرة'**
  String get circlesLeaveButton;

  /// Confirmation dialog title before leaving a circle
  ///
  /// In ar, this message translates to:
  /// **'مغادرة الدائرة؟'**
  String get circlesLeaveConfirmTitle;

  /// Confirmation dialog body before leaving a circle
  ///
  /// In ar, this message translates to:
  /// **'لن يرى أعضاء هذه الدائرة تقدمك بعد الآن.'**
  String get circlesLeaveConfirmBody;

  /// Section title for the per-circle sharing toggles
  ///
  /// In ar, this message translates to:
  /// **'ما الذي تشاركه في هذه الدائرة'**
  String get circleSharingSectionTitle;

  /// Sharing toggle: current streak
  ///
  /// In ar, this message translates to:
  /// **'سلسلة الأيام'**
  String get circleShareStreakLabel;

  /// Sharing toggle: total points
  ///
  /// In ar, this message translates to:
  /// **'النقاط'**
  String get circleSharePointsLabel;

  /// Sharing toggle: whether today's checklist was completed
  ///
  /// In ar, this message translates to:
  /// **'إنجاز اليوم'**
  String get circleShareChecklistLabel;

  /// Sharing toggle: Quran pages read
  ///
  /// In ar, this message translates to:
  /// **'صفحات القرآن'**
  String get circleShareQuranLabel;

  /// Section title for the member leaderboard
  ///
  /// In ar, this message translates to:
  /// **'الأعضاء'**
  String get circleLeaderboardTitle;

  /// Tooltip/label on the button that opens the encouragement-phrase picker for a member
  ///
  /// In ar, this message translates to:
  /// **'أرسل تشجيعًا'**
  String get circleSendReactionTooltip;

  /// Bottom sheet title for picking an encouragement phrase
  ///
  /// In ar, this message translates to:
  /// **'أرسل تشجيعًا'**
  String get circleReactionSheetTitle;

  /// Confirmation after sending an encouragement reaction
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال 🤍'**
  String get circleReactionSentMessage;

  /// Generic error shown when a circle action fails (invalid code, network error, etc.)
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ، حاول مرة أخرى'**
  String get circleErrorGeneric;

  /// Fixed encouragement phrase
  ///
  /// In ar, this message translates to:
  /// **'دعوت لك 🤲'**
  String get reactionPhraseDuaForYou;

  /// Fixed encouragement phrase
  ///
  /// In ar, this message translates to:
  /// **'واصل! 💪'**
  String get reactionPhraseKeepGoing;

  /// Fixed encouragement phrase
  ///
  /// In ar, this message translates to:
  /// **'فخور بك 🌟'**
  String get reactionPhraseProudOfYou;

  /// Fixed encouragement phrase
  ///
  /// In ar, this message translates to:
  /// **'أنت قادر! 🔥'**
  String get reactionPhraseYouCanDoIt;

  /// Fixed encouragement phrase
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله ✨'**
  String get reactionPhraseMashallah;

  /// Leaderboard sort-metric selector option: sort by points
  ///
  /// In ar, this message translates to:
  /// **'النقاط'**
  String get circleSortByPoints;

  /// Leaderboard sort-metric selector option: sort by streak
  ///
  /// In ar, this message translates to:
  /// **'سلسلة الأيام'**
  String get circleSortByStreak;

  /// Section title listing encouragement reactions this user has received in the circle
  ///
  /// In ar, this message translates to:
  /// **'تشجيع لك 💌'**
  String get circleReactionsReceivedTitle;

  /// Menu item / button label for the owner to rename the circle
  ///
  /// In ar, this message translates to:
  /// **'تغيير اسم الدائرة'**
  String get circleRenameButton;

  /// Menu item / button label for the owner to delete the circle
  ///
  /// In ar, this message translates to:
  /// **'حذف الدائرة'**
  String get circleDeleteButton;

  /// Dialog title when renaming a circle
  ///
  /// In ar, this message translates to:
  /// **'تغيير اسم الدائرة'**
  String get circleRenameDialogTitle;

  /// Input label for the new circle name in the rename dialog
  ///
  /// In ar, this message translates to:
  /// **'اسم الدائرة'**
  String get circleRenameNameLabel;

  /// Confirm button on the rename dialog
  ///
  /// In ar, this message translates to:
  /// **'تغيير الاسم'**
  String get circleRenameConfirm;

  /// Validation error shown when the rename input is blank, whitespace-only, or too long
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون الاسم من 1 إلى 50 حرفًا غير فارغة'**
  String get circleRenameValidationError;

  /// Confirmation dialog title before deleting a circle
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه الدائرة؟'**
  String get circleDeleteConfirmTitle;

  /// Confirmation dialog body before deleting a circle
  ///
  /// In ar, this message translates to:
  /// **'سيؤدي هذا إلى حذف الدائرة نهائيًا وإزالة جميع الأعضاء.'**
  String get circleDeleteConfirmBody;

  /// Confirm button on the delete-circle dialog
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get circleDeleteConfirm;

  /// Confirmation dialog title before removing a circle member
  ///
  /// In ar, this message translates to:
  /// **'إزالة العضو؟'**
  String get circleRemoveMemberConfirmTitle;

  /// Confirmation dialog body before removing a circle member
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إزالة {username} من هذه الدائرة؟'**
  String circleRemoveMemberConfirmBody(String username);

  /// Confirm button on the remove-member dialog
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get circleRemoveMemberConfirm;

  /// Home feature-grid label for the Qada (missed prayers) tracker
  ///
  /// In ar, this message translates to:
  /// **'قضاء\nالصلوات'**
  String get homeFeatureQada;

  /// App bar title of the Qada tracker screen
  ///
  /// In ar, this message translates to:
  /// **'متابعة قضاء الصلوات'**
  String get qadaAppBarTitle;

  /// Short explainer at the top of the Qada tracker
  ///
  /// In ar, this message translates to:
  /// **'سجّل عدد الصلوات الفائتة التي تنوي قضاءها، وتتبّع ما أنجزته'**
  String get qadaIntroText;

  /// Label for the count of prayers still owed for a given prayer
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get qadaOwedLabel;

  /// Label for the lifetime count of completed Qada prayers for a given prayer
  ///
  /// In ar, this message translates to:
  /// **'تم قضاؤها'**
  String get qadaCompletedLabel;

  /// Button that decrements the owed count by one and increments completed
  ///
  /// In ar, this message translates to:
  /// **'قضيت واحدة'**
  String get qadaMarkOneDoneButton;

  /// Button that opens a dialog to set/edit the owed count
  ///
  /// In ar, this message translates to:
  /// **'تعديل العدد'**
  String get qadaSetOwedButton;

  /// Dialog title for setting a prayer's owed count
  ///
  /// In ar, this message translates to:
  /// **'عدد الصلوات الفائتة'**
  String get qadaSetOwedDialogTitle;

  /// Confirm button on the set-owed dialog
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get qadaSetOwedConfirm;

  /// Summary row label showing the total number of missed prayers still owed
  ///
  /// In ar, this message translates to:
  /// **'المتبقي: {count}'**
  String qadaSummaryTotalOwed(int count);

  /// Summary row label showing the total number of Qada prayers completed
  ///
  /// In ar, this message translates to:
  /// **'تم قضاؤها: {count}'**
  String qadaSummaryTotalCompleted(int count);

  /// Validation error shown in the set-owed dialog when the input is non-numeric or negative
  ///
  /// In ar, this message translates to:
  /// **'أدخل عدداً صحيحاً لا يقل عن 0'**
  String get qadaSetOwedErrorInvalid;

  /// Optional amount field shown below the Sadaqah toggle in the daily checklist
  ///
  /// In ar, this message translates to:
  /// **'المبلغ (اختياري)'**
  String get sadaqahAmountFieldLabel;

  /// Inline validation error on the Sadaqah amount field when the value is non-numeric, negative, or out of range
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً بين ٠٫٠١ و٩٩٩٬٩٩٩٬٩٩٩٫٩٩ (حتى خانتين عشريتين)'**
  String get sadaqahAmountInvalidError;

  /// Home feature-grid label for the Sadaqah tracker
  ///
  /// In ar, this message translates to:
  /// **'الصدقات'**
  String get homeFeatureSadaqah;

  /// App bar title of the Sadaqah tracker screen
  ///
  /// In ar, this message translates to:
  /// **'متابعة الصدقات'**
  String get sadaqahTrackerAppBarTitle;

  /// Sadaqah total label: this week
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get sadaqahTotalsWeekLabel;

  /// Sadaqah total label: this month
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get sadaqahTotalsMonthLabel;

  /// Sadaqah total label: all-time
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get sadaqahTotalsAllTimeLabel;

  /// Title for the Sadaqah history list
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get sadaqahHistoryTitle;

  /// Empty state for the Sadaqah history list
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجَّل صدقات بعد'**
  String get sadaqahHistoryEmpty;

  /// Shown for a history entry logged without an amount, distinct from a real zero
  ///
  /// In ar, this message translates to:
  /// **'صدقة (بدون مبلغ)'**
  String get sadaqahLoggedNoAmount;

  /// Home feature-grid label for the Islamic occasions screen
  ///
  /// In ar, this message translates to:
  /// **'مناسبات\nإسلامية'**
  String get homeFeatureOccasions;

  /// App bar title of the Islamic occasions screen
  ///
  /// In ar, this message translates to:
  /// **'مناسبات إسلامية'**
  String get occasionsAppBarTitle;

  /// Section title for this Hijri month's White Days (Ayyam al-Beed)
  ///
  /// In ar, this message translates to:
  /// **'الأيام البيض'**
  String get occasionsWhiteDaysTitle;

  /// Explainer for White Days
  ///
  /// In ar, this message translates to:
  /// **'أيام ١٣، ١٤، ١٥ من الشهر الهجري الحالي — يُستحب صيامها'**
  String get occasionsWhiteDaysSubtitle;

  /// Shown instead of a day count when the occasion is today
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get occasionsDaysUntilToday;

  /// Countdown to an occasion
  ///
  /// In ar, this message translates to:
  /// **'بعد {days} يوم'**
  String occasionsDaysUntil(int days);

  /// Tooltip on the button that opens the add-reminder sheet pre-filled with this occasion
  ///
  /// In ar, this message translates to:
  /// **'أضف تذكيرًا'**
  String get occasionsAddReminderTooltip;

  /// Occasion name
  ///
  /// In ar, this message translates to:
  /// **'عاشوراء'**
  String get occasionAshura;

  /// Occasion name
  ///
  /// In ar, this message translates to:
  /// **'الإسراء والمعراج'**
  String get occasionIsraMiraj;

  /// Occasion name
  ///
  /// In ar, this message translates to:
  /// **'بداية رمضان'**
  String get occasionRamadanStart;

  /// Occasion name
  ///
  /// In ar, this message translates to:
  /// **'عيد الفطر'**
  String get occasionEidAlFitr;

  /// Occasion name
  ///
  /// In ar, this message translates to:
  /// **'المولد النبوي'**
  String get occasionMawlid;

  /// Occasion name
  ///
  /// In ar, this message translates to:
  /// **'عيد الأضحى'**
  String get occasionEidAlAdha;

  /// Occasion name — 1 Muharram
  ///
  /// In ar, this message translates to:
  /// **'رأس السنة الهجرية'**
  String get occasionIslamicNewYear;

  /// Occasion name — 27 Ramadan
  ///
  /// In ar, this message translates to:
  /// **'ليلة القدر'**
  String get occasionLaylatAlQadr;

  /// Occasion name — 9 Dhul Hijjah
  ///
  /// In ar, this message translates to:
  /// **'يوم عرفة'**
  String get occasionDayOfArafah;

  /// Small chip label shown on occasions where voluntary fasting is recommended (Ashura, White Days, Day of Arafah)
  ///
  /// In ar, this message translates to:
  /// **'🌙 صيام مستحب'**
  String get occasionsFastingRecommended;

  /// FAB / button label that opens the log-sadaqah bottom sheet
  ///
  /// In ar, this message translates to:
  /// **'تسجيل صدقة'**
  String get sadaqahLogButton;

  /// Title of the log-sadaqah bottom sheet
  ///
  /// In ar, this message translates to:
  /// **'تسجيل صدقة'**
  String get sadaqahLogSheetTitle;

  /// Label for the date-picker row in the log-sadaqah sheet
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get sadaqahLogDateLabel;

  /// Confirm button in the log-sadaqah bottom sheet
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get sadaqahLogConfirmButton;

  /// Inline error shown in the log-sadaqah sheet when the DAO write fails
  ///
  /// In ar, this message translates to:
  /// **'فشل الحفظ. يرجى المحاولة مجدداً.'**
  String get sadaqahLogErrorText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
