// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DailyRecordsTable extends DailyRecords
    with TableInfo<$DailyRecordsTable, DailyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PrayerStatus, int> fajrStatus =
      GeneratedColumn<int>(
        'fajr_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PrayerStatus>($DailyRecordsTable.$converterfajrStatus);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerStatus, int> dhuhrStatus =
      GeneratedColumn<int>(
        'dhuhr_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PrayerStatus>($DailyRecordsTable.$converterdhuhrStatus);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerStatus, int> asrStatus =
      GeneratedColumn<int>(
        'asr_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PrayerStatus>($DailyRecordsTable.$converterasrStatus);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerStatus, int> maghribStatus =
      GeneratedColumn<int>(
        'maghrib_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PrayerStatus>($DailyRecordsTable.$convertermaghribStatus);
  @override
  late final GeneratedColumnWithTypeConverter<PrayerStatus, int> ishaStatus =
      GeneratedColumn<int>(
        'isha_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<PrayerStatus>($DailyRecordsTable.$converterishaStatus);
  static const VerificationMeta _nightPrayerMeta = const VerificationMeta(
    'nightPrayer',
  );
  @override
  late final GeneratedColumn<bool> nightPrayer = GeneratedColumn<bool>(
    'night_prayer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("night_prayer" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _witrMeta = const VerificationMeta('witr');
  @override
  late final GeneratedColumn<bool> witr = GeneratedColumn<bool>(
    'witr',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("witr" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rawatibMeta = const VerificationMeta(
    'rawatib',
  );
  @override
  late final GeneratedColumn<int> rawatib = GeneratedColumn<int>(
    'rawatib',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quranPagesMeta = const VerificationMeta(
    'quranPages',
  );
  @override
  late final GeneratedColumn<int> quranPages = GeneratedColumn<int>(
    'quran_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quranVersesMeta = const VerificationMeta(
    'quranVerses',
  );
  @override
  late final GeneratedColumn<int> quranVerses = GeneratedColumn<int>(
    'quran_verses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quranJuzaaMeta = const VerificationMeta(
    'quranJuzaa',
  );
  @override
  late final GeneratedColumn<double> quranJuzaa = GeneratedColumn<double>(
    'quran_juzaa',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _morningAdhkarMeta = const VerificationMeta(
    'morningAdhkar',
  );
  @override
  late final GeneratedColumn<bool> morningAdhkar = GeneratedColumn<bool>(
    'morning_adhkar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("morning_adhkar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _eveningAdhkarMeta = const VerificationMeta(
    'eveningAdhkar',
  );
  @override
  late final GeneratedColumn<bool> eveningAdhkar = GeneratedColumn<bool>(
    'evening_adhkar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("evening_adhkar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _afterPrayerAdhkarMeta = const VerificationMeta(
    'afterPrayerAdhkar',
  );
  @override
  late final GeneratedColumn<bool> afterPrayerAdhkar = GeneratedColumn<bool>(
    'after_prayer_adhkar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("after_prayer_adhkar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tasbeehCountMeta = const VerificationMeta(
    'tasbeehCount',
  );
  @override
  late final GeneratedColumn<int> tasbeehCount = GeneratedColumn<int>(
    'tasbeeh_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FastingType, int> fastingType =
      GeneratedColumn<int>(
        'fasting_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<FastingType>($DailyRecordsTable.$converterfastingType);
  static const VerificationMeta _sadaqahMeta = const VerificationMeta(
    'sadaqah',
  );
  @override
  late final GeneratedColumn<bool> sadaqah = GeneratedColumn<bool>(
    'sadaqah',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sadaqah" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sadaqahAmountMeta = const VerificationMeta(
    'sadaqahAmount',
  );
  @override
  late final GeneratedColumn<double> sadaqahAmount = GeneratedColumn<double>(
    'sadaqah_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _ghadhBasarMeta = const VerificationMeta(
    'ghadhBasar',
  );
  @override
  late final GeneratedColumn<bool> ghadhBasar = GeneratedColumn<bool>(
    'ghadh_basar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ghadh_basar" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taqwaPointsMeta = const VerificationMeta(
    'taqwaPoints',
  );
  @override
  late final GeneratedColumn<int> taqwaPoints = GeneratedColumn<int>(
    'taqwa_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deductedPointsMeta = const VerificationMeta(
    'deductedPoints',
  );
  @override
  late final GeneratedColumn<int> deductedPoints = GeneratedColumn<int>(
    'deducted_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _netPointsMeta = const VerificationMeta(
    'netPoints',
  );
  @override
  late final GeneratedColumn<int> netPoints = GeneratedColumn<int>(
    'net_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 50),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    fajrStatus,
    dhuhrStatus,
    asrStatus,
    maghribStatus,
    ishaStatus,
    nightPrayer,
    witr,
    rawatib,
    quranPages,
    quranVerses,
    quranJuzaa,
    morningAdhkar,
    eveningAdhkar,
    afterPrayerAdhkar,
    tasbeehCount,
    fastingType,
    sadaqah,
    sadaqahAmount,
    ghadhBasar,
    taqwaPoints,
    deductedPoints,
    netPoints,
    notes,
    mood,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('night_prayer')) {
      context.handle(
        _nightPrayerMeta,
        nightPrayer.isAcceptableOrUnknown(
          data['night_prayer']!,
          _nightPrayerMeta,
        ),
      );
    }
    if (data.containsKey('witr')) {
      context.handle(
        _witrMeta,
        witr.isAcceptableOrUnknown(data['witr']!, _witrMeta),
      );
    }
    if (data.containsKey('rawatib')) {
      context.handle(
        _rawatibMeta,
        rawatib.isAcceptableOrUnknown(data['rawatib']!, _rawatibMeta),
      );
    }
    if (data.containsKey('quran_pages')) {
      context.handle(
        _quranPagesMeta,
        quranPages.isAcceptableOrUnknown(data['quran_pages']!, _quranPagesMeta),
      );
    }
    if (data.containsKey('quran_verses')) {
      context.handle(
        _quranVersesMeta,
        quranVerses.isAcceptableOrUnknown(
          data['quran_verses']!,
          _quranVersesMeta,
        ),
      );
    }
    if (data.containsKey('quran_juzaa')) {
      context.handle(
        _quranJuzaaMeta,
        quranJuzaa.isAcceptableOrUnknown(data['quran_juzaa']!, _quranJuzaaMeta),
      );
    }
    if (data.containsKey('morning_adhkar')) {
      context.handle(
        _morningAdhkarMeta,
        morningAdhkar.isAcceptableOrUnknown(
          data['morning_adhkar']!,
          _morningAdhkarMeta,
        ),
      );
    }
    if (data.containsKey('evening_adhkar')) {
      context.handle(
        _eveningAdhkarMeta,
        eveningAdhkar.isAcceptableOrUnknown(
          data['evening_adhkar']!,
          _eveningAdhkarMeta,
        ),
      );
    }
    if (data.containsKey('after_prayer_adhkar')) {
      context.handle(
        _afterPrayerAdhkarMeta,
        afterPrayerAdhkar.isAcceptableOrUnknown(
          data['after_prayer_adhkar']!,
          _afterPrayerAdhkarMeta,
        ),
      );
    }
    if (data.containsKey('tasbeeh_count')) {
      context.handle(
        _tasbeehCountMeta,
        tasbeehCount.isAcceptableOrUnknown(
          data['tasbeeh_count']!,
          _tasbeehCountMeta,
        ),
      );
    }
    if (data.containsKey('sadaqah')) {
      context.handle(
        _sadaqahMeta,
        sadaqah.isAcceptableOrUnknown(data['sadaqah']!, _sadaqahMeta),
      );
    }
    if (data.containsKey('sadaqah_amount')) {
      context.handle(
        _sadaqahAmountMeta,
        sadaqahAmount.isAcceptableOrUnknown(
          data['sadaqah_amount']!,
          _sadaqahAmountMeta,
        ),
      );
    }
    if (data.containsKey('ghadh_basar')) {
      context.handle(
        _ghadhBasarMeta,
        ghadhBasar.isAcceptableOrUnknown(data['ghadh_basar']!, _ghadhBasarMeta),
      );
    }
    if (data.containsKey('taqwa_points')) {
      context.handle(
        _taqwaPointsMeta,
        taqwaPoints.isAcceptableOrUnknown(
          data['taqwa_points']!,
          _taqwaPointsMeta,
        ),
      );
    }
    if (data.containsKey('deducted_points')) {
      context.handle(
        _deductedPointsMeta,
        deductedPoints.isAcceptableOrUnknown(
          data['deducted_points']!,
          _deductedPointsMeta,
        ),
      );
    }
    if (data.containsKey('net_points')) {
      context.handle(
        _netPointsMeta,
        netPoints.isAcceptableOrUnknown(data['net_points']!, _netPointsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      fajrStatus: $DailyRecordsTable.$converterfajrStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}fajr_status'],
        )!,
      ),
      dhuhrStatus: $DailyRecordsTable.$converterdhuhrStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}dhuhr_status'],
        )!,
      ),
      asrStatus: $DailyRecordsTable.$converterasrStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}asr_status'],
        )!,
      ),
      maghribStatus: $DailyRecordsTable.$convertermaghribStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}maghrib_status'],
        )!,
      ),
      ishaStatus: $DailyRecordsTable.$converterishaStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}isha_status'],
        )!,
      ),
      nightPrayer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}night_prayer'],
      )!,
      witr: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}witr'],
      )!,
      rawatib: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rawatib'],
      )!,
      quranPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quran_pages'],
      )!,
      quranVerses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quran_verses'],
      )!,
      quranJuzaa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quran_juzaa'],
      )!,
      morningAdhkar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}morning_adhkar'],
      )!,
      eveningAdhkar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}evening_adhkar'],
      )!,
      afterPrayerAdhkar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}after_prayer_adhkar'],
      )!,
      tasbeehCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasbeeh_count'],
      )!,
      fastingType: $DailyRecordsTable.$converterfastingType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}fasting_type'],
        )!,
      ),
      sadaqah: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sadaqah'],
      )!,
      sadaqahAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sadaqah_amount'],
      )!,
      ghadhBasar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ghadh_basar'],
      )!,
      taqwaPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taqwa_points'],
      )!,
      deductedPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deducted_points'],
      )!,
      netPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_points'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyRecordsTable createAlias(String alias) {
    return $DailyRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PrayerStatus, int, int> $converterfajrStatus =
      const EnumIndexConverter<PrayerStatus>(PrayerStatus.values);
  static JsonTypeConverter2<PrayerStatus, int, int> $converterdhuhrStatus =
      const EnumIndexConverter<PrayerStatus>(PrayerStatus.values);
  static JsonTypeConverter2<PrayerStatus, int, int> $converterasrStatus =
      const EnumIndexConverter<PrayerStatus>(PrayerStatus.values);
  static JsonTypeConverter2<PrayerStatus, int, int> $convertermaghribStatus =
      const EnumIndexConverter<PrayerStatus>(PrayerStatus.values);
  static JsonTypeConverter2<PrayerStatus, int, int> $converterishaStatus =
      const EnumIndexConverter<PrayerStatus>(PrayerStatus.values);
  static JsonTypeConverter2<FastingType, int, int> $converterfastingType =
      const EnumIndexConverter<FastingType>(FastingType.values);
}

class DailyRecord extends DataClass implements Insertable<DailyRecord> {
  final int id;
  final DateTime date;
  final PrayerStatus fajrStatus;
  final PrayerStatus dhuhrStatus;
  final PrayerStatus asrStatus;
  final PrayerStatus maghribStatus;
  final PrayerStatus ishaStatus;
  final bool nightPrayer;
  final bool witr;
  final int rawatib;
  final int quranPages;
  final int quranVerses;
  final double quranJuzaa;
  final bool morningAdhkar;
  final bool eveningAdhkar;
  final bool afterPrayerAdhkar;
  final int tasbeehCount;
  final FastingType fastingType;
  final bool sadaqah;
  final double sadaqahAmount;
  final bool ghadhBasar;
  final int taqwaPoints;
  final int deductedPoints;
  final int netPoints;
  final String? notes;
  final String? mood;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyRecord({
    required this.id,
    required this.date,
    required this.fajrStatus,
    required this.dhuhrStatus,
    required this.asrStatus,
    required this.maghribStatus,
    required this.ishaStatus,
    required this.nightPrayer,
    required this.witr,
    required this.rawatib,
    required this.quranPages,
    required this.quranVerses,
    required this.quranJuzaa,
    required this.morningAdhkar,
    required this.eveningAdhkar,
    required this.afterPrayerAdhkar,
    required this.tasbeehCount,
    required this.fastingType,
    required this.sadaqah,
    required this.sadaqahAmount,
    required this.ghadhBasar,
    required this.taqwaPoints,
    required this.deductedPoints,
    required this.netPoints,
    this.notes,
    this.mood,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['fajr_status'] = Variable<int>(
        $DailyRecordsTable.$converterfajrStatus.toSql(fajrStatus),
      );
    }
    {
      map['dhuhr_status'] = Variable<int>(
        $DailyRecordsTable.$converterdhuhrStatus.toSql(dhuhrStatus),
      );
    }
    {
      map['asr_status'] = Variable<int>(
        $DailyRecordsTable.$converterasrStatus.toSql(asrStatus),
      );
    }
    {
      map['maghrib_status'] = Variable<int>(
        $DailyRecordsTable.$convertermaghribStatus.toSql(maghribStatus),
      );
    }
    {
      map['isha_status'] = Variable<int>(
        $DailyRecordsTable.$converterishaStatus.toSql(ishaStatus),
      );
    }
    map['night_prayer'] = Variable<bool>(nightPrayer);
    map['witr'] = Variable<bool>(witr);
    map['rawatib'] = Variable<int>(rawatib);
    map['quran_pages'] = Variable<int>(quranPages);
    map['quran_verses'] = Variable<int>(quranVerses);
    map['quran_juzaa'] = Variable<double>(quranJuzaa);
    map['morning_adhkar'] = Variable<bool>(morningAdhkar);
    map['evening_adhkar'] = Variable<bool>(eveningAdhkar);
    map['after_prayer_adhkar'] = Variable<bool>(afterPrayerAdhkar);
    map['tasbeeh_count'] = Variable<int>(tasbeehCount);
    {
      map['fasting_type'] = Variable<int>(
        $DailyRecordsTable.$converterfastingType.toSql(fastingType),
      );
    }
    map['sadaqah'] = Variable<bool>(sadaqah);
    map['sadaqah_amount'] = Variable<double>(sadaqahAmount);
    map['ghadh_basar'] = Variable<bool>(ghadhBasar);
    map['taqwa_points'] = Variable<int>(taqwaPoints);
    map['deducted_points'] = Variable<int>(deductedPoints);
    map['net_points'] = Variable<int>(netPoints);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyRecordsCompanion(
      id: Value(id),
      date: Value(date),
      fajrStatus: Value(fajrStatus),
      dhuhrStatus: Value(dhuhrStatus),
      asrStatus: Value(asrStatus),
      maghribStatus: Value(maghribStatus),
      ishaStatus: Value(ishaStatus),
      nightPrayer: Value(nightPrayer),
      witr: Value(witr),
      rawatib: Value(rawatib),
      quranPages: Value(quranPages),
      quranVerses: Value(quranVerses),
      quranJuzaa: Value(quranJuzaa),
      morningAdhkar: Value(morningAdhkar),
      eveningAdhkar: Value(eveningAdhkar),
      afterPrayerAdhkar: Value(afterPrayerAdhkar),
      tasbeehCount: Value(tasbeehCount),
      fastingType: Value(fastingType),
      sadaqah: Value(sadaqah),
      sadaqahAmount: Value(sadaqahAmount),
      ghadhBasar: Value(ghadhBasar),
      taqwaPoints: Value(taqwaPoints),
      deductedPoints: Value(deductedPoints),
      netPoints: Value(netPoints),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRecord(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      fajrStatus: $DailyRecordsTable.$converterfajrStatus.fromJson(
        serializer.fromJson<int>(json['fajrStatus']),
      ),
      dhuhrStatus: $DailyRecordsTable.$converterdhuhrStatus.fromJson(
        serializer.fromJson<int>(json['dhuhrStatus']),
      ),
      asrStatus: $DailyRecordsTable.$converterasrStatus.fromJson(
        serializer.fromJson<int>(json['asrStatus']),
      ),
      maghribStatus: $DailyRecordsTable.$convertermaghribStatus.fromJson(
        serializer.fromJson<int>(json['maghribStatus']),
      ),
      ishaStatus: $DailyRecordsTable.$converterishaStatus.fromJson(
        serializer.fromJson<int>(json['ishaStatus']),
      ),
      nightPrayer: serializer.fromJson<bool>(json['nightPrayer']),
      witr: serializer.fromJson<bool>(json['witr']),
      rawatib: serializer.fromJson<int>(json['rawatib']),
      quranPages: serializer.fromJson<int>(json['quranPages']),
      quranVerses: serializer.fromJson<int>(json['quranVerses']),
      quranJuzaa: serializer.fromJson<double>(json['quranJuzaa']),
      morningAdhkar: serializer.fromJson<bool>(json['morningAdhkar']),
      eveningAdhkar: serializer.fromJson<bool>(json['eveningAdhkar']),
      afterPrayerAdhkar: serializer.fromJson<bool>(json['afterPrayerAdhkar']),
      tasbeehCount: serializer.fromJson<int>(json['tasbeehCount']),
      fastingType: $DailyRecordsTable.$converterfastingType.fromJson(
        serializer.fromJson<int>(json['fastingType']),
      ),
      sadaqah: serializer.fromJson<bool>(json['sadaqah']),
      sadaqahAmount: serializer.fromJson<double>(json['sadaqahAmount']),
      ghadhBasar: serializer.fromJson<bool>(json['ghadhBasar']),
      taqwaPoints: serializer.fromJson<int>(json['taqwaPoints']),
      deductedPoints: serializer.fromJson<int>(json['deductedPoints']),
      netPoints: serializer.fromJson<int>(json['netPoints']),
      notes: serializer.fromJson<String?>(json['notes']),
      mood: serializer.fromJson<String?>(json['mood']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'fajrStatus': serializer.toJson<int>(
        $DailyRecordsTable.$converterfajrStatus.toJson(fajrStatus),
      ),
      'dhuhrStatus': serializer.toJson<int>(
        $DailyRecordsTable.$converterdhuhrStatus.toJson(dhuhrStatus),
      ),
      'asrStatus': serializer.toJson<int>(
        $DailyRecordsTable.$converterasrStatus.toJson(asrStatus),
      ),
      'maghribStatus': serializer.toJson<int>(
        $DailyRecordsTable.$convertermaghribStatus.toJson(maghribStatus),
      ),
      'ishaStatus': serializer.toJson<int>(
        $DailyRecordsTable.$converterishaStatus.toJson(ishaStatus),
      ),
      'nightPrayer': serializer.toJson<bool>(nightPrayer),
      'witr': serializer.toJson<bool>(witr),
      'rawatib': serializer.toJson<int>(rawatib),
      'quranPages': serializer.toJson<int>(quranPages),
      'quranVerses': serializer.toJson<int>(quranVerses),
      'quranJuzaa': serializer.toJson<double>(quranJuzaa),
      'morningAdhkar': serializer.toJson<bool>(morningAdhkar),
      'eveningAdhkar': serializer.toJson<bool>(eveningAdhkar),
      'afterPrayerAdhkar': serializer.toJson<bool>(afterPrayerAdhkar),
      'tasbeehCount': serializer.toJson<int>(tasbeehCount),
      'fastingType': serializer.toJson<int>(
        $DailyRecordsTable.$converterfastingType.toJson(fastingType),
      ),
      'sadaqah': serializer.toJson<bool>(sadaqah),
      'sadaqahAmount': serializer.toJson<double>(sadaqahAmount),
      'ghadhBasar': serializer.toJson<bool>(ghadhBasar),
      'taqwaPoints': serializer.toJson<int>(taqwaPoints),
      'deductedPoints': serializer.toJson<int>(deductedPoints),
      'netPoints': serializer.toJson<int>(netPoints),
      'notes': serializer.toJson<String?>(notes),
      'mood': serializer.toJson<String?>(mood),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyRecord copyWith({
    int? id,
    DateTime? date,
    PrayerStatus? fajrStatus,
    PrayerStatus? dhuhrStatus,
    PrayerStatus? asrStatus,
    PrayerStatus? maghribStatus,
    PrayerStatus? ishaStatus,
    bool? nightPrayer,
    bool? witr,
    int? rawatib,
    int? quranPages,
    int? quranVerses,
    double? quranJuzaa,
    bool? morningAdhkar,
    bool? eveningAdhkar,
    bool? afterPrayerAdhkar,
    int? tasbeehCount,
    FastingType? fastingType,
    bool? sadaqah,
    double? sadaqahAmount,
    bool? ghadhBasar,
    int? taqwaPoints,
    int? deductedPoints,
    int? netPoints,
    Value<String?> notes = const Value.absent(),
    Value<String?> mood = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DailyRecord(
    id: id ?? this.id,
    date: date ?? this.date,
    fajrStatus: fajrStatus ?? this.fajrStatus,
    dhuhrStatus: dhuhrStatus ?? this.dhuhrStatus,
    asrStatus: asrStatus ?? this.asrStatus,
    maghribStatus: maghribStatus ?? this.maghribStatus,
    ishaStatus: ishaStatus ?? this.ishaStatus,
    nightPrayer: nightPrayer ?? this.nightPrayer,
    witr: witr ?? this.witr,
    rawatib: rawatib ?? this.rawatib,
    quranPages: quranPages ?? this.quranPages,
    quranVerses: quranVerses ?? this.quranVerses,
    quranJuzaa: quranJuzaa ?? this.quranJuzaa,
    morningAdhkar: morningAdhkar ?? this.morningAdhkar,
    eveningAdhkar: eveningAdhkar ?? this.eveningAdhkar,
    afterPrayerAdhkar: afterPrayerAdhkar ?? this.afterPrayerAdhkar,
    tasbeehCount: tasbeehCount ?? this.tasbeehCount,
    fastingType: fastingType ?? this.fastingType,
    sadaqah: sadaqah ?? this.sadaqah,
    sadaqahAmount: sadaqahAmount ?? this.sadaqahAmount,
    ghadhBasar: ghadhBasar ?? this.ghadhBasar,
    taqwaPoints: taqwaPoints ?? this.taqwaPoints,
    deductedPoints: deductedPoints ?? this.deductedPoints,
    netPoints: netPoints ?? this.netPoints,
    notes: notes.present ? notes.value : this.notes,
    mood: mood.present ? mood.value : this.mood,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyRecord copyWithCompanion(DailyRecordsCompanion data) {
    return DailyRecord(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      fajrStatus: data.fajrStatus.present
          ? data.fajrStatus.value
          : this.fajrStatus,
      dhuhrStatus: data.dhuhrStatus.present
          ? data.dhuhrStatus.value
          : this.dhuhrStatus,
      asrStatus: data.asrStatus.present ? data.asrStatus.value : this.asrStatus,
      maghribStatus: data.maghribStatus.present
          ? data.maghribStatus.value
          : this.maghribStatus,
      ishaStatus: data.ishaStatus.present
          ? data.ishaStatus.value
          : this.ishaStatus,
      nightPrayer: data.nightPrayer.present
          ? data.nightPrayer.value
          : this.nightPrayer,
      witr: data.witr.present ? data.witr.value : this.witr,
      rawatib: data.rawatib.present ? data.rawatib.value : this.rawatib,
      quranPages: data.quranPages.present
          ? data.quranPages.value
          : this.quranPages,
      quranVerses: data.quranVerses.present
          ? data.quranVerses.value
          : this.quranVerses,
      quranJuzaa: data.quranJuzaa.present
          ? data.quranJuzaa.value
          : this.quranJuzaa,
      morningAdhkar: data.morningAdhkar.present
          ? data.morningAdhkar.value
          : this.morningAdhkar,
      eveningAdhkar: data.eveningAdhkar.present
          ? data.eveningAdhkar.value
          : this.eveningAdhkar,
      afterPrayerAdhkar: data.afterPrayerAdhkar.present
          ? data.afterPrayerAdhkar.value
          : this.afterPrayerAdhkar,
      tasbeehCount: data.tasbeehCount.present
          ? data.tasbeehCount.value
          : this.tasbeehCount,
      fastingType: data.fastingType.present
          ? data.fastingType.value
          : this.fastingType,
      sadaqah: data.sadaqah.present ? data.sadaqah.value : this.sadaqah,
      sadaqahAmount: data.sadaqahAmount.present
          ? data.sadaqahAmount.value
          : this.sadaqahAmount,
      ghadhBasar: data.ghadhBasar.present
          ? data.ghadhBasar.value
          : this.ghadhBasar,
      taqwaPoints: data.taqwaPoints.present
          ? data.taqwaPoints.value
          : this.taqwaPoints,
      deductedPoints: data.deductedPoints.present
          ? data.deductedPoints.value
          : this.deductedPoints,
      netPoints: data.netPoints.present ? data.netPoints.value : this.netPoints,
      notes: data.notes.present ? data.notes.value : this.notes,
      mood: data.mood.present ? data.mood.value : this.mood,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecord(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('fajrStatus: $fajrStatus, ')
          ..write('dhuhrStatus: $dhuhrStatus, ')
          ..write('asrStatus: $asrStatus, ')
          ..write('maghribStatus: $maghribStatus, ')
          ..write('ishaStatus: $ishaStatus, ')
          ..write('nightPrayer: $nightPrayer, ')
          ..write('witr: $witr, ')
          ..write('rawatib: $rawatib, ')
          ..write('quranPages: $quranPages, ')
          ..write('quranVerses: $quranVerses, ')
          ..write('quranJuzaa: $quranJuzaa, ')
          ..write('morningAdhkar: $morningAdhkar, ')
          ..write('eveningAdhkar: $eveningAdhkar, ')
          ..write('afterPrayerAdhkar: $afterPrayerAdhkar, ')
          ..write('tasbeehCount: $tasbeehCount, ')
          ..write('fastingType: $fastingType, ')
          ..write('sadaqah: $sadaqah, ')
          ..write('sadaqahAmount: $sadaqahAmount, ')
          ..write('ghadhBasar: $ghadhBasar, ')
          ..write('taqwaPoints: $taqwaPoints, ')
          ..write('deductedPoints: $deductedPoints, ')
          ..write('netPoints: $netPoints, ')
          ..write('notes: $notes, ')
          ..write('mood: $mood, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    date,
    fajrStatus,
    dhuhrStatus,
    asrStatus,
    maghribStatus,
    ishaStatus,
    nightPrayer,
    witr,
    rawatib,
    quranPages,
    quranVerses,
    quranJuzaa,
    morningAdhkar,
    eveningAdhkar,
    afterPrayerAdhkar,
    tasbeehCount,
    fastingType,
    sadaqah,
    sadaqahAmount,
    ghadhBasar,
    taqwaPoints,
    deductedPoints,
    netPoints,
    notes,
    mood,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRecord &&
          other.id == this.id &&
          other.date == this.date &&
          other.fajrStatus == this.fajrStatus &&
          other.dhuhrStatus == this.dhuhrStatus &&
          other.asrStatus == this.asrStatus &&
          other.maghribStatus == this.maghribStatus &&
          other.ishaStatus == this.ishaStatus &&
          other.nightPrayer == this.nightPrayer &&
          other.witr == this.witr &&
          other.rawatib == this.rawatib &&
          other.quranPages == this.quranPages &&
          other.quranVerses == this.quranVerses &&
          other.quranJuzaa == this.quranJuzaa &&
          other.morningAdhkar == this.morningAdhkar &&
          other.eveningAdhkar == this.eveningAdhkar &&
          other.afterPrayerAdhkar == this.afterPrayerAdhkar &&
          other.tasbeehCount == this.tasbeehCount &&
          other.fastingType == this.fastingType &&
          other.sadaqah == this.sadaqah &&
          other.sadaqahAmount == this.sadaqahAmount &&
          other.ghadhBasar == this.ghadhBasar &&
          other.taqwaPoints == this.taqwaPoints &&
          other.deductedPoints == this.deductedPoints &&
          other.netPoints == this.netPoints &&
          other.notes == this.notes &&
          other.mood == this.mood &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyRecordsCompanion extends UpdateCompanion<DailyRecord> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<PrayerStatus> fajrStatus;
  final Value<PrayerStatus> dhuhrStatus;
  final Value<PrayerStatus> asrStatus;
  final Value<PrayerStatus> maghribStatus;
  final Value<PrayerStatus> ishaStatus;
  final Value<bool> nightPrayer;
  final Value<bool> witr;
  final Value<int> rawatib;
  final Value<int> quranPages;
  final Value<int> quranVerses;
  final Value<double> quranJuzaa;
  final Value<bool> morningAdhkar;
  final Value<bool> eveningAdhkar;
  final Value<bool> afterPrayerAdhkar;
  final Value<int> tasbeehCount;
  final Value<FastingType> fastingType;
  final Value<bool> sadaqah;
  final Value<double> sadaqahAmount;
  final Value<bool> ghadhBasar;
  final Value<int> taqwaPoints;
  final Value<int> deductedPoints;
  final Value<int> netPoints;
  final Value<String?> notes;
  final Value<String?> mood;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DailyRecordsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.fajrStatus = const Value.absent(),
    this.dhuhrStatus = const Value.absent(),
    this.asrStatus = const Value.absent(),
    this.maghribStatus = const Value.absent(),
    this.ishaStatus = const Value.absent(),
    this.nightPrayer = const Value.absent(),
    this.witr = const Value.absent(),
    this.rawatib = const Value.absent(),
    this.quranPages = const Value.absent(),
    this.quranVerses = const Value.absent(),
    this.quranJuzaa = const Value.absent(),
    this.morningAdhkar = const Value.absent(),
    this.eveningAdhkar = const Value.absent(),
    this.afterPrayerAdhkar = const Value.absent(),
    this.tasbeehCount = const Value.absent(),
    this.fastingType = const Value.absent(),
    this.sadaqah = const Value.absent(),
    this.sadaqahAmount = const Value.absent(),
    this.ghadhBasar = const Value.absent(),
    this.taqwaPoints = const Value.absent(),
    this.deductedPoints = const Value.absent(),
    this.netPoints = const Value.absent(),
    this.notes = const Value.absent(),
    this.mood = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyRecordsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.fajrStatus = const Value.absent(),
    this.dhuhrStatus = const Value.absent(),
    this.asrStatus = const Value.absent(),
    this.maghribStatus = const Value.absent(),
    this.ishaStatus = const Value.absent(),
    this.nightPrayer = const Value.absent(),
    this.witr = const Value.absent(),
    this.rawatib = const Value.absent(),
    this.quranPages = const Value.absent(),
    this.quranVerses = const Value.absent(),
    this.quranJuzaa = const Value.absent(),
    this.morningAdhkar = const Value.absent(),
    this.eveningAdhkar = const Value.absent(),
    this.afterPrayerAdhkar = const Value.absent(),
    this.tasbeehCount = const Value.absent(),
    this.fastingType = const Value.absent(),
    this.sadaqah = const Value.absent(),
    this.sadaqahAmount = const Value.absent(),
    this.ghadhBasar = const Value.absent(),
    this.taqwaPoints = const Value.absent(),
    this.deductedPoints = const Value.absent(),
    this.netPoints = const Value.absent(),
    this.notes = const Value.absent(),
    this.mood = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyRecord> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? fajrStatus,
    Expression<int>? dhuhrStatus,
    Expression<int>? asrStatus,
    Expression<int>? maghribStatus,
    Expression<int>? ishaStatus,
    Expression<bool>? nightPrayer,
    Expression<bool>? witr,
    Expression<int>? rawatib,
    Expression<int>? quranPages,
    Expression<int>? quranVerses,
    Expression<double>? quranJuzaa,
    Expression<bool>? morningAdhkar,
    Expression<bool>? eveningAdhkar,
    Expression<bool>? afterPrayerAdhkar,
    Expression<int>? tasbeehCount,
    Expression<int>? fastingType,
    Expression<bool>? sadaqah,
    Expression<double>? sadaqahAmount,
    Expression<bool>? ghadhBasar,
    Expression<int>? taqwaPoints,
    Expression<int>? deductedPoints,
    Expression<int>? netPoints,
    Expression<String>? notes,
    Expression<String>? mood,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (fajrStatus != null) 'fajr_status': fajrStatus,
      if (dhuhrStatus != null) 'dhuhr_status': dhuhrStatus,
      if (asrStatus != null) 'asr_status': asrStatus,
      if (maghribStatus != null) 'maghrib_status': maghribStatus,
      if (ishaStatus != null) 'isha_status': ishaStatus,
      if (nightPrayer != null) 'night_prayer': nightPrayer,
      if (witr != null) 'witr': witr,
      if (rawatib != null) 'rawatib': rawatib,
      if (quranPages != null) 'quran_pages': quranPages,
      if (quranVerses != null) 'quran_verses': quranVerses,
      if (quranJuzaa != null) 'quran_juzaa': quranJuzaa,
      if (morningAdhkar != null) 'morning_adhkar': morningAdhkar,
      if (eveningAdhkar != null) 'evening_adhkar': eveningAdhkar,
      if (afterPrayerAdhkar != null) 'after_prayer_adhkar': afterPrayerAdhkar,
      if (tasbeehCount != null) 'tasbeeh_count': tasbeehCount,
      if (fastingType != null) 'fasting_type': fastingType,
      if (sadaqah != null) 'sadaqah': sadaqah,
      if (sadaqahAmount != null) 'sadaqah_amount': sadaqahAmount,
      if (ghadhBasar != null) 'ghadh_basar': ghadhBasar,
      if (taqwaPoints != null) 'taqwa_points': taqwaPoints,
      if (deductedPoints != null) 'deducted_points': deductedPoints,
      if (netPoints != null) 'net_points': netPoints,
      if (notes != null) 'notes': notes,
      if (mood != null) 'mood': mood,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyRecordsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<PrayerStatus>? fajrStatus,
    Value<PrayerStatus>? dhuhrStatus,
    Value<PrayerStatus>? asrStatus,
    Value<PrayerStatus>? maghribStatus,
    Value<PrayerStatus>? ishaStatus,
    Value<bool>? nightPrayer,
    Value<bool>? witr,
    Value<int>? rawatib,
    Value<int>? quranPages,
    Value<int>? quranVerses,
    Value<double>? quranJuzaa,
    Value<bool>? morningAdhkar,
    Value<bool>? eveningAdhkar,
    Value<bool>? afterPrayerAdhkar,
    Value<int>? tasbeehCount,
    Value<FastingType>? fastingType,
    Value<bool>? sadaqah,
    Value<double>? sadaqahAmount,
    Value<bool>? ghadhBasar,
    Value<int>? taqwaPoints,
    Value<int>? deductedPoints,
    Value<int>? netPoints,
    Value<String?>? notes,
    Value<String?>? mood,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DailyRecordsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      fajrStatus: fajrStatus ?? this.fajrStatus,
      dhuhrStatus: dhuhrStatus ?? this.dhuhrStatus,
      asrStatus: asrStatus ?? this.asrStatus,
      maghribStatus: maghribStatus ?? this.maghribStatus,
      ishaStatus: ishaStatus ?? this.ishaStatus,
      nightPrayer: nightPrayer ?? this.nightPrayer,
      witr: witr ?? this.witr,
      rawatib: rawatib ?? this.rawatib,
      quranPages: quranPages ?? this.quranPages,
      quranVerses: quranVerses ?? this.quranVerses,
      quranJuzaa: quranJuzaa ?? this.quranJuzaa,
      morningAdhkar: morningAdhkar ?? this.morningAdhkar,
      eveningAdhkar: eveningAdhkar ?? this.eveningAdhkar,
      afterPrayerAdhkar: afterPrayerAdhkar ?? this.afterPrayerAdhkar,
      tasbeehCount: tasbeehCount ?? this.tasbeehCount,
      fastingType: fastingType ?? this.fastingType,
      sadaqah: sadaqah ?? this.sadaqah,
      sadaqahAmount: sadaqahAmount ?? this.sadaqahAmount,
      ghadhBasar: ghadhBasar ?? this.ghadhBasar,
      taqwaPoints: taqwaPoints ?? this.taqwaPoints,
      deductedPoints: deductedPoints ?? this.deductedPoints,
      netPoints: netPoints ?? this.netPoints,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (fajrStatus.present) {
      map['fajr_status'] = Variable<int>(
        $DailyRecordsTable.$converterfajrStatus.toSql(fajrStatus.value),
      );
    }
    if (dhuhrStatus.present) {
      map['dhuhr_status'] = Variable<int>(
        $DailyRecordsTable.$converterdhuhrStatus.toSql(dhuhrStatus.value),
      );
    }
    if (asrStatus.present) {
      map['asr_status'] = Variable<int>(
        $DailyRecordsTable.$converterasrStatus.toSql(asrStatus.value),
      );
    }
    if (maghribStatus.present) {
      map['maghrib_status'] = Variable<int>(
        $DailyRecordsTable.$convertermaghribStatus.toSql(maghribStatus.value),
      );
    }
    if (ishaStatus.present) {
      map['isha_status'] = Variable<int>(
        $DailyRecordsTable.$converterishaStatus.toSql(ishaStatus.value),
      );
    }
    if (nightPrayer.present) {
      map['night_prayer'] = Variable<bool>(nightPrayer.value);
    }
    if (witr.present) {
      map['witr'] = Variable<bool>(witr.value);
    }
    if (rawatib.present) {
      map['rawatib'] = Variable<int>(rawatib.value);
    }
    if (quranPages.present) {
      map['quran_pages'] = Variable<int>(quranPages.value);
    }
    if (quranVerses.present) {
      map['quran_verses'] = Variable<int>(quranVerses.value);
    }
    if (quranJuzaa.present) {
      map['quran_juzaa'] = Variable<double>(quranJuzaa.value);
    }
    if (morningAdhkar.present) {
      map['morning_adhkar'] = Variable<bool>(morningAdhkar.value);
    }
    if (eveningAdhkar.present) {
      map['evening_adhkar'] = Variable<bool>(eveningAdhkar.value);
    }
    if (afterPrayerAdhkar.present) {
      map['after_prayer_adhkar'] = Variable<bool>(afterPrayerAdhkar.value);
    }
    if (tasbeehCount.present) {
      map['tasbeeh_count'] = Variable<int>(tasbeehCount.value);
    }
    if (fastingType.present) {
      map['fasting_type'] = Variable<int>(
        $DailyRecordsTable.$converterfastingType.toSql(fastingType.value),
      );
    }
    if (sadaqah.present) {
      map['sadaqah'] = Variable<bool>(sadaqah.value);
    }
    if (sadaqahAmount.present) {
      map['sadaqah_amount'] = Variable<double>(sadaqahAmount.value);
    }
    if (ghadhBasar.present) {
      map['ghadh_basar'] = Variable<bool>(ghadhBasar.value);
    }
    if (taqwaPoints.present) {
      map['taqwa_points'] = Variable<int>(taqwaPoints.value);
    }
    if (deductedPoints.present) {
      map['deducted_points'] = Variable<int>(deductedPoints.value);
    }
    if (netPoints.present) {
      map['net_points'] = Variable<int>(netPoints.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('fajrStatus: $fajrStatus, ')
          ..write('dhuhrStatus: $dhuhrStatus, ')
          ..write('asrStatus: $asrStatus, ')
          ..write('maghribStatus: $maghribStatus, ')
          ..write('ishaStatus: $ishaStatus, ')
          ..write('nightPrayer: $nightPrayer, ')
          ..write('witr: $witr, ')
          ..write('rawatib: $rawatib, ')
          ..write('quranPages: $quranPages, ')
          ..write('quranVerses: $quranVerses, ')
          ..write('quranJuzaa: $quranJuzaa, ')
          ..write('morningAdhkar: $morningAdhkar, ')
          ..write('eveningAdhkar: $eveningAdhkar, ')
          ..write('afterPrayerAdhkar: $afterPrayerAdhkar, ')
          ..write('tasbeehCount: $tasbeehCount, ')
          ..write('fastingType: $fastingType, ')
          ..write('sadaqah: $sadaqah, ')
          ..write('sadaqahAmount: $sadaqahAmount, ')
          ..write('ghadhBasar: $ghadhBasar, ')
          ..write('taqwaPoints: $taqwaPoints, ')
          ..write('deductedPoints: $deductedPoints, ')
          ..write('netPoints: $netPoints, ')
          ..write('notes: $notes, ')
          ..write('mood: $mood, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProhibitionsLogTable extends ProhibitionsLog
    with TableInfo<$ProhibitionsLogTable, ProhibitionsLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProhibitionsLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES daily_records (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProhibitionCategory, int>
  category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ProhibitionCategory>(
        $ProhibitionsLogTable.$convertercategory,
      );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _committedMeta = const VerificationMeta(
    'committed',
  );
  @override
  late final GeneratedColumn<bool> committed = GeneratedColumn<bool>(
    'committed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("committed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timesCountMeta = const VerificationMeta(
    'timesCount',
  );
  @override
  late final GeneratedColumn<int> timesCount = GeneratedColumn<int>(
    'times_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deductPointsMeta = const VerificationMeta(
    'deductPoints',
  );
  @override
  late final GeneratedColumn<int> deductPoints = GeneratedColumn<int>(
    'deduct_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordId,
    date,
    category,
    customName,
    committed,
    timesCount,
    deductPoints,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prohibitions_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProhibitionsLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('committed')) {
      context.handle(
        _committedMeta,
        committed.isAcceptableOrUnknown(data['committed']!, _committedMeta),
      );
    }
    if (data.containsKey('times_count')) {
      context.handle(
        _timesCountMeta,
        timesCount.isAcceptableOrUnknown(data['times_count']!, _timesCountMeta),
      );
    }
    if (data.containsKey('deduct_points')) {
      context.handle(
        _deductPointsMeta,
        deductPoints.isAcceptableOrUnknown(
          data['deduct_points']!,
          _deductPointsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProhibitionsLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProhibitionsLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      category: $ProhibitionsLogTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      committed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}committed'],
      )!,
      timesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_count'],
      )!,
      deductPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deduct_points'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $ProhibitionsLogTable createAlias(String alias) {
    return $ProhibitionsLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProhibitionCategory, int, int> $convertercategory =
      const EnumIndexConverter<ProhibitionCategory>(ProhibitionCategory.values);
}

class ProhibitionsLogData extends DataClass
    implements Insertable<ProhibitionsLogData> {
  final int id;
  final int recordId;
  final DateTime date;
  final ProhibitionCategory category;
  final String? customName;
  final bool committed;
  final int timesCount;
  final int deductPoints;
  final String? notes;
  const ProhibitionsLogData({
    required this.id,
    required this.recordId,
    required this.date,
    required this.category,
    this.customName,
    required this.committed,
    required this.timesCount,
    required this.deductPoints,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['record_id'] = Variable<int>(recordId);
    map['date'] = Variable<DateTime>(date);
    {
      map['category'] = Variable<int>(
        $ProhibitionsLogTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    map['committed'] = Variable<bool>(committed);
    map['times_count'] = Variable<int>(timesCount);
    map['deduct_points'] = Variable<int>(deductPoints);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ProhibitionsLogCompanion toCompanion(bool nullToAbsent) {
    return ProhibitionsLogCompanion(
      id: Value(id),
      recordId: Value(recordId),
      date: Value(date),
      category: Value(category),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      committed: Value(committed),
      timesCount: Value(timesCount),
      deductPoints: Value(deductPoints),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory ProhibitionsLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProhibitionsLogData(
      id: serializer.fromJson<int>(json['id']),
      recordId: serializer.fromJson<int>(json['recordId']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: $ProhibitionsLogTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      customName: serializer.fromJson<String?>(json['customName']),
      committed: serializer.fromJson<bool>(json['committed']),
      timesCount: serializer.fromJson<int>(json['timesCount']),
      deductPoints: serializer.fromJson<int>(json['deductPoints']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordId': serializer.toJson<int>(recordId),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<int>(
        $ProhibitionsLogTable.$convertercategory.toJson(category),
      ),
      'customName': serializer.toJson<String?>(customName),
      'committed': serializer.toJson<bool>(committed),
      'timesCount': serializer.toJson<int>(timesCount),
      'deductPoints': serializer.toJson<int>(deductPoints),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  ProhibitionsLogData copyWith({
    int? id,
    int? recordId,
    DateTime? date,
    ProhibitionCategory? category,
    Value<String?> customName = const Value.absent(),
    bool? committed,
    int? timesCount,
    int? deductPoints,
    Value<String?> notes = const Value.absent(),
  }) => ProhibitionsLogData(
    id: id ?? this.id,
    recordId: recordId ?? this.recordId,
    date: date ?? this.date,
    category: category ?? this.category,
    customName: customName.present ? customName.value : this.customName,
    committed: committed ?? this.committed,
    timesCount: timesCount ?? this.timesCount,
    deductPoints: deductPoints ?? this.deductPoints,
    notes: notes.present ? notes.value : this.notes,
  );
  ProhibitionsLogData copyWithCompanion(ProhibitionsLogCompanion data) {
    return ProhibitionsLogData(
      id: data.id.present ? data.id.value : this.id,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      committed: data.committed.present ? data.committed.value : this.committed,
      timesCount: data.timesCount.present
          ? data.timesCount.value
          : this.timesCount,
      deductPoints: data.deductPoints.present
          ? data.deductPoints.value
          : this.deductPoints,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProhibitionsLogData(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('customName: $customName, ')
          ..write('committed: $committed, ')
          ..write('timesCount: $timesCount, ')
          ..write('deductPoints: $deductPoints, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordId,
    date,
    category,
    customName,
    committed,
    timesCount,
    deductPoints,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProhibitionsLogData &&
          other.id == this.id &&
          other.recordId == this.recordId &&
          other.date == this.date &&
          other.category == this.category &&
          other.customName == this.customName &&
          other.committed == this.committed &&
          other.timesCount == this.timesCount &&
          other.deductPoints == this.deductPoints &&
          other.notes == this.notes);
}

class ProhibitionsLogCompanion extends UpdateCompanion<ProhibitionsLogData> {
  final Value<int> id;
  final Value<int> recordId;
  final Value<DateTime> date;
  final Value<ProhibitionCategory> category;
  final Value<String?> customName;
  final Value<bool> committed;
  final Value<int> timesCount;
  final Value<int> deductPoints;
  final Value<String?> notes;
  const ProhibitionsLogCompanion({
    this.id = const Value.absent(),
    this.recordId = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.customName = const Value.absent(),
    this.committed = const Value.absent(),
    this.timesCount = const Value.absent(),
    this.deductPoints = const Value.absent(),
    this.notes = const Value.absent(),
  });
  ProhibitionsLogCompanion.insert({
    this.id = const Value.absent(),
    required int recordId,
    required DateTime date,
    required ProhibitionCategory category,
    this.customName = const Value.absent(),
    this.committed = const Value.absent(),
    this.timesCount = const Value.absent(),
    this.deductPoints = const Value.absent(),
    this.notes = const Value.absent(),
  }) : recordId = Value(recordId),
       date = Value(date),
       category = Value(category);
  static Insertable<ProhibitionsLogData> custom({
    Expression<int>? id,
    Expression<int>? recordId,
    Expression<DateTime>? date,
    Expression<int>? category,
    Expression<String>? customName,
    Expression<bool>? committed,
    Expression<int>? timesCount,
    Expression<int>? deductPoints,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordId != null) 'record_id': recordId,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (customName != null) 'custom_name': customName,
      if (committed != null) 'committed': committed,
      if (timesCount != null) 'times_count': timesCount,
      if (deductPoints != null) 'deduct_points': deductPoints,
      if (notes != null) 'notes': notes,
    });
  }

  ProhibitionsLogCompanion copyWith({
    Value<int>? id,
    Value<int>? recordId,
    Value<DateTime>? date,
    Value<ProhibitionCategory>? category,
    Value<String?>? customName,
    Value<bool>? committed,
    Value<int>? timesCount,
    Value<int>? deductPoints,
    Value<String?>? notes,
  }) {
    return ProhibitionsLogCompanion(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      date: date ?? this.date,
      category: category ?? this.category,
      customName: customName ?? this.customName,
      committed: committed ?? this.committed,
      timesCount: timesCount ?? this.timesCount,
      deductPoints: deductPoints ?? this.deductPoints,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $ProhibitionsLogTable.$convertercategory.toSql(category.value),
      );
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (committed.present) {
      map['committed'] = Variable<bool>(committed.value);
    }
    if (timesCount.present) {
      map['times_count'] = Variable<int>(timesCount.value);
    }
    if (deductPoints.present) {
      map['deduct_points'] = Variable<int>(deductPoints.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProhibitionsLogCompanion(')
          ..write('id: $id, ')
          ..write('recordId: $recordId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('customName: $customName, ')
          ..write('committed: $committed, ')
          ..write('timesCount: $timesCount, ')
          ..write('deductPoints: $deductPoints, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $PrayerTimesCacheTable extends PrayerTimesCache
    with TableInfo<$PrayerTimesCacheTable, PrayerTimesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerTimesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fajrMeta = const VerificationMeta('fajr');
  @override
  late final GeneratedColumn<String> fajr = GeneratedColumn<String>(
    'fajr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sunriseMeta = const VerificationMeta(
    'sunrise',
  );
  @override
  late final GeneratedColumn<String> sunrise = GeneratedColumn<String>(
    'sunrise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dhuhrMeta = const VerificationMeta('dhuhr');
  @override
  late final GeneratedColumn<String> dhuhr = GeneratedColumn<String>(
    'dhuhr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _asrMeta = const VerificationMeta('asr');
  @override
  late final GeneratedColumn<String> asr = GeneratedColumn<String>(
    'asr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maghribMeta = const VerificationMeta(
    'maghrib',
  );
  @override
  late final GeneratedColumn<String> maghrib = GeneratedColumn<String>(
    'maghrib',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ishaMeta = const VerificationMeta('isha');
  @override
  late final GeneratedColumn<String> isha = GeneratedColumn<String>(
    'isha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MWL'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    latitude,
    longitude,
    method,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_times_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerTimesCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('fajr')) {
      context.handle(
        _fajrMeta,
        fajr.isAcceptableOrUnknown(data['fajr']!, _fajrMeta),
      );
    } else if (isInserting) {
      context.missing(_fajrMeta);
    }
    if (data.containsKey('sunrise')) {
      context.handle(
        _sunriseMeta,
        sunrise.isAcceptableOrUnknown(data['sunrise']!, _sunriseMeta),
      );
    } else if (isInserting) {
      context.missing(_sunriseMeta);
    }
    if (data.containsKey('dhuhr')) {
      context.handle(
        _dhuhrMeta,
        dhuhr.isAcceptableOrUnknown(data['dhuhr']!, _dhuhrMeta),
      );
    } else if (isInserting) {
      context.missing(_dhuhrMeta);
    }
    if (data.containsKey('asr')) {
      context.handle(
        _asrMeta,
        asr.isAcceptableOrUnknown(data['asr']!, _asrMeta),
      );
    } else if (isInserting) {
      context.missing(_asrMeta);
    }
    if (data.containsKey('maghrib')) {
      context.handle(
        _maghribMeta,
        maghrib.isAcceptableOrUnknown(data['maghrib']!, _maghribMeta),
      );
    } else if (isInserting) {
      context.missing(_maghribMeta);
    }
    if (data.containsKey('isha')) {
      context.handle(
        _ishaMeta,
        isha.isAcceptableOrUnknown(data['isha']!, _ishaMeta),
      );
    } else if (isInserting) {
      context.missing(_ishaMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerTimesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerTimesCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      fajr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fajr'],
      )!,
      sunrise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sunrise'],
      )!,
      dhuhr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dhuhr'],
      )!,
      asr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asr'],
      )!,
      maghrib: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maghrib'],
      )!,
      isha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isha'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
    );
  }

  @override
  $PrayerTimesCacheTable createAlias(String alias) {
    return $PrayerTimesCacheTable(attachedDatabase, alias);
  }
}

class PrayerTimesCacheData extends DataClass
    implements Insertable<PrayerTimesCacheData> {
  final int id;
  final DateTime date;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final double latitude;
  final double longitude;
  final String method;
  const PrayerTimesCacheData({
    required this.id,
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.latitude,
    required this.longitude,
    required this.method,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['fajr'] = Variable<String>(fajr);
    map['sunrise'] = Variable<String>(sunrise);
    map['dhuhr'] = Variable<String>(dhuhr);
    map['asr'] = Variable<String>(asr);
    map['maghrib'] = Variable<String>(maghrib);
    map['isha'] = Variable<String>(isha);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['method'] = Variable<String>(method);
    return map;
  }

  PrayerTimesCacheCompanion toCompanion(bool nullToAbsent) {
    return PrayerTimesCacheCompanion(
      id: Value(id),
      date: Value(date),
      fajr: Value(fajr),
      sunrise: Value(sunrise),
      dhuhr: Value(dhuhr),
      asr: Value(asr),
      maghrib: Value(maghrib),
      isha: Value(isha),
      latitude: Value(latitude),
      longitude: Value(longitude),
      method: Value(method),
    );
  }

  factory PrayerTimesCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerTimesCacheData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      fajr: serializer.fromJson<String>(json['fajr']),
      sunrise: serializer.fromJson<String>(json['sunrise']),
      dhuhr: serializer.fromJson<String>(json['dhuhr']),
      asr: serializer.fromJson<String>(json['asr']),
      maghrib: serializer.fromJson<String>(json['maghrib']),
      isha: serializer.fromJson<String>(json['isha']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      method: serializer.fromJson<String>(json['method']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'fajr': serializer.toJson<String>(fajr),
      'sunrise': serializer.toJson<String>(sunrise),
      'dhuhr': serializer.toJson<String>(dhuhr),
      'asr': serializer.toJson<String>(asr),
      'maghrib': serializer.toJson<String>(maghrib),
      'isha': serializer.toJson<String>(isha),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'method': serializer.toJson<String>(method),
    };
  }

  PrayerTimesCacheData copyWith({
    int? id,
    DateTime? date,
    String? fajr,
    String? sunrise,
    String? dhuhr,
    String? asr,
    String? maghrib,
    String? isha,
    double? latitude,
    double? longitude,
    String? method,
  }) => PrayerTimesCacheData(
    id: id ?? this.id,
    date: date ?? this.date,
    fajr: fajr ?? this.fajr,
    sunrise: sunrise ?? this.sunrise,
    dhuhr: dhuhr ?? this.dhuhr,
    asr: asr ?? this.asr,
    maghrib: maghrib ?? this.maghrib,
    isha: isha ?? this.isha,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    method: method ?? this.method,
  );
  PrayerTimesCacheData copyWithCompanion(PrayerTimesCacheCompanion data) {
    return PrayerTimesCacheData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      fajr: data.fajr.present ? data.fajr.value : this.fajr,
      sunrise: data.sunrise.present ? data.sunrise.value : this.sunrise,
      dhuhr: data.dhuhr.present ? data.dhuhr.value : this.dhuhr,
      asr: data.asr.present ? data.asr.value : this.asr,
      maghrib: data.maghrib.present ? data.maghrib.value : this.maghrib,
      isha: data.isha.present ? data.isha.value : this.isha,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      method: data.method.present ? data.method.value : this.method,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerTimesCacheData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('fajr: $fajr, ')
          ..write('sunrise: $sunrise, ')
          ..write('dhuhr: $dhuhr, ')
          ..write('asr: $asr, ')
          ..write('maghrib: $maghrib, ')
          ..write('isha: $isha, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    latitude,
    longitude,
    method,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerTimesCacheData &&
          other.id == this.id &&
          other.date == this.date &&
          other.fajr == this.fajr &&
          other.sunrise == this.sunrise &&
          other.dhuhr == this.dhuhr &&
          other.asr == this.asr &&
          other.maghrib == this.maghrib &&
          other.isha == this.isha &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.method == this.method);
}

class PrayerTimesCacheCompanion extends UpdateCompanion<PrayerTimesCacheData> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> fajr;
  final Value<String> sunrise;
  final Value<String> dhuhr;
  final Value<String> asr;
  final Value<String> maghrib;
  final Value<String> isha;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> method;
  const PrayerTimesCacheCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.fajr = const Value.absent(),
    this.sunrise = const Value.absent(),
    this.dhuhr = const Value.absent(),
    this.asr = const Value.absent(),
    this.maghrib = const Value.absent(),
    this.isha = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.method = const Value.absent(),
  });
  PrayerTimesCacheCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String fajr,
    required String sunrise,
    required String dhuhr,
    required String asr,
    required String maghrib,
    required String isha,
    required double latitude,
    required double longitude,
    this.method = const Value.absent(),
  }) : date = Value(date),
       fajr = Value(fajr),
       sunrise = Value(sunrise),
       dhuhr = Value(dhuhr),
       asr = Value(asr),
       maghrib = Value(maghrib),
       isha = Value(isha),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<PrayerTimesCacheData> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? fajr,
    Expression<String>? sunrise,
    Expression<String>? dhuhr,
    Expression<String>? asr,
    Expression<String>? maghrib,
    Expression<String>? isha,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? method,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (fajr != null) 'fajr': fajr,
      if (sunrise != null) 'sunrise': sunrise,
      if (dhuhr != null) 'dhuhr': dhuhr,
      if (asr != null) 'asr': asr,
      if (maghrib != null) 'maghrib': maghrib,
      if (isha != null) 'isha': isha,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (method != null) 'method': method,
    });
  }

  PrayerTimesCacheCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? fajr,
    Value<String>? sunrise,
    Value<String>? dhuhr,
    Value<String>? asr,
    Value<String>? maghrib,
    Value<String>? isha,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? method,
  }) {
    return PrayerTimesCacheCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      method: method ?? this.method,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (fajr.present) {
      map['fajr'] = Variable<String>(fajr.value);
    }
    if (sunrise.present) {
      map['sunrise'] = Variable<String>(sunrise.value);
    }
    if (dhuhr.present) {
      map['dhuhr'] = Variable<String>(dhuhr.value);
    }
    if (asr.present) {
      map['asr'] = Variable<String>(asr.value);
    }
    if (maghrib.present) {
      map['maghrib'] = Variable<String>(maghrib.value);
    }
    if (isha.present) {
      map['isha'] = Variable<String>(isha.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerTimesCacheCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('fajr: $fajr, ')
          ..write('sunrise: $sunrise, ')
          ..write('dhuhr: $dhuhr, ')
          ..write('asr: $asr, ')
          ..write('maghrib: $maghrib, ')
          ..write('isha: $isha, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleArMeta = const VerificationMeta(
    'titleAr',
  );
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descArMeta = const VerificationMeta('descAr');
  @override
  late final GeneratedColumn<String> descAr = GeneratedColumn<String>(
    'desc_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsRewardMeta = const VerificationMeta(
    'pointsReward',
  );
  @override
  late final GeneratedColumn<int> pointsReward = GeneratedColumn<int>(
    'points_reward',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<bool> seen = GeneratedColumn<bool>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    titleAr,
    descAr,
    emoji,
    pointsReward,
    earnedAt,
    seen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(
        _titleArMeta,
        titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta),
      );
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('desc_ar')) {
      context.handle(
        _descArMeta,
        descAr.isAcceptableOrUnknown(data['desc_ar']!, _descArMeta),
      );
    } else if (isInserting) {
      context.missing(_descArMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('points_reward')) {
      context.handle(
        _pointsRewardMeta,
        pointsReward.isAcceptableOrUnknown(
          data['points_reward']!,
          _pointsRewardMeta,
        ),
      );
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      titleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_ar'],
      )!,
      descAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}desc_ar'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      pointsReward: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_reward'],
      )!,
      earnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}earned_at'],
      )!,
      seen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seen'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final int id;
  final String type;
  final String titleAr;
  final String descAr;
  final String emoji;
  final int pointsReward;
  final DateTime earnedAt;
  final bool seen;
  const Achievement({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.descAr,
    required this.emoji,
    required this.pointsReward,
    required this.earnedAt,
    required this.seen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['title_ar'] = Variable<String>(titleAr);
    map['desc_ar'] = Variable<String>(descAr);
    map['emoji'] = Variable<String>(emoji);
    map['points_reward'] = Variable<int>(pointsReward);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    map['seen'] = Variable<bool>(seen);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      type: Value(type),
      titleAr: Value(titleAr),
      descAr: Value(descAr),
      emoji: Value(emoji),
      pointsReward: Value(pointsReward),
      earnedAt: Value(earnedAt),
      seen: Value(seen),
    );
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      descAr: serializer.fromJson<String>(json['descAr']),
      emoji: serializer.fromJson<String>(json['emoji']),
      pointsReward: serializer.fromJson<int>(json['pointsReward']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
      seen: serializer.fromJson<bool>(json['seen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'titleAr': serializer.toJson<String>(titleAr),
      'descAr': serializer.toJson<String>(descAr),
      'emoji': serializer.toJson<String>(emoji),
      'pointsReward': serializer.toJson<int>(pointsReward),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
      'seen': serializer.toJson<bool>(seen),
    };
  }

  Achievement copyWith({
    int? id,
    String? type,
    String? titleAr,
    String? descAr,
    String? emoji,
    int? pointsReward,
    DateTime? earnedAt,
    bool? seen,
  }) => Achievement(
    id: id ?? this.id,
    type: type ?? this.type,
    titleAr: titleAr ?? this.titleAr,
    descAr: descAr ?? this.descAr,
    emoji: emoji ?? this.emoji,
    pointsReward: pointsReward ?? this.pointsReward,
    earnedAt: earnedAt ?? this.earnedAt,
    seen: seen ?? this.seen,
  );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      descAr: data.descAr.present ? data.descAr.value : this.descAr,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      pointsReward: data.pointsReward.present
          ? data.pointsReward.value
          : this.pointsReward,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
      seen: data.seen.present ? data.seen.value : this.seen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('titleAr: $titleAr, ')
          ..write('descAr: $descAr, ')
          ..write('emoji: $emoji, ')
          ..write('pointsReward: $pointsReward, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    titleAr,
    descAr,
    emoji,
    pointsReward,
    earnedAt,
    seen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.type == this.type &&
          other.titleAr == this.titleAr &&
          other.descAr == this.descAr &&
          other.emoji == this.emoji &&
          other.pointsReward == this.pointsReward &&
          other.earnedAt == this.earnedAt &&
          other.seen == this.seen);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> titleAr;
  final Value<String> descAr;
  final Value<String> emoji;
  final Value<int> pointsReward;
  final Value<DateTime> earnedAt;
  final Value<bool> seen;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.descAr = const Value.absent(),
    this.emoji = const Value.absent(),
    this.pointsReward = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.seen = const Value.absent(),
  });
  AchievementsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String titleAr,
    required String descAr,
    required String emoji,
    this.pointsReward = const Value.absent(),
    required DateTime earnedAt,
    this.seen = const Value.absent(),
  }) : type = Value(type),
       titleAr = Value(titleAr),
       descAr = Value(descAr),
       emoji = Value(emoji),
       earnedAt = Value(earnedAt);
  static Insertable<Achievement> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? titleAr,
    Expression<String>? descAr,
    Expression<String>? emoji,
    Expression<int>? pointsReward,
    Expression<DateTime>? earnedAt,
    Expression<bool>? seen,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (titleAr != null) 'title_ar': titleAr,
      if (descAr != null) 'desc_ar': descAr,
      if (emoji != null) 'emoji': emoji,
      if (pointsReward != null) 'points_reward': pointsReward,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (seen != null) 'seen': seen,
    });
  }

  AchievementsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? titleAr,
    Value<String>? descAr,
    Value<String>? emoji,
    Value<int>? pointsReward,
    Value<DateTime>? earnedAt,
    Value<bool>? seen,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      titleAr: titleAr ?? this.titleAr,
      descAr: descAr ?? this.descAr,
      emoji: emoji ?? this.emoji,
      pointsReward: pointsReward ?? this.pointsReward,
      earnedAt: earnedAt ?? this.earnedAt,
      seen: seen ?? this.seen,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (descAr.present) {
      map['desc_ar'] = Variable<String>(descAr.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (pointsReward.present) {
      map['points_reward'] = Variable<int>(pointsReward.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    if (seen.present) {
      map['seen'] = Variable<bool>(seen.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('titleAr: $titleAr, ')
          ..write('descAr: $descAr, ')
          ..write('emoji: $emoji, ')
          ..write('pointsReward: $pointsReward, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }
}

class $CustomIbadahTable extends CustomIbadah
    with TableInfo<$CustomIbadahTable, CustomIbadahData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomIbadahTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('⭐'),
  );
  static const VerificationMeta _isPositiveMeta = const VerificationMeta(
    'isPositive',
  );
  @override
  late final GeneratedColumn<bool> isPositive = GeneratedColumn<bool>(
    'is_positive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_positive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameAr,
    emoji,
    isPositive,
    points,
    isActive,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_ibadah';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomIbadahData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('is_positive')) {
      context.handle(
        _isPositiveMeta,
        isPositive.isAcceptableOrUnknown(data['is_positive']!, _isPositiveMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomIbadahData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomIbadahData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      isPositive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_positive'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CustomIbadahTable createAlias(String alias) {
    return $CustomIbadahTable(attachedDatabase, alias);
  }
}

class CustomIbadahData extends DataClass
    implements Insertable<CustomIbadahData> {
  final int id;
  final String nameAr;
  final String emoji;
  final bool isPositive;
  final int points;
  final bool isActive;
  final int sortOrder;
  const CustomIbadahData({
    required this.id,
    required this.nameAr,
    required this.emoji,
    required this.isPositive,
    required this.points,
    required this.isActive,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['emoji'] = Variable<String>(emoji);
    map['is_positive'] = Variable<bool>(isPositive);
    map['points'] = Variable<int>(points);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CustomIbadahCompanion toCompanion(bool nullToAbsent) {
    return CustomIbadahCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      emoji: Value(emoji),
      isPositive: Value(isPositive),
      points: Value(points),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
    );
  }

  factory CustomIbadahData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomIbadahData(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      emoji: serializer.fromJson<String>(json['emoji']),
      isPositive: serializer.fromJson<bool>(json['isPositive']),
      points: serializer.fromJson<int>(json['points']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'emoji': serializer.toJson<String>(emoji),
      'isPositive': serializer.toJson<bool>(isPositive),
      'points': serializer.toJson<int>(points),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CustomIbadahData copyWith({
    int? id,
    String? nameAr,
    String? emoji,
    bool? isPositive,
    int? points,
    bool? isActive,
    int? sortOrder,
  }) => CustomIbadahData(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    emoji: emoji ?? this.emoji,
    isPositive: isPositive ?? this.isPositive,
    points: points ?? this.points,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CustomIbadahData copyWithCompanion(CustomIbadahCompanion data) {
    return CustomIbadahData(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      isPositive: data.isPositive.present
          ? data.isPositive.value
          : this.isPositive,
      points: data.points.present ? data.points.value : this.points,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomIbadahData(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('emoji: $emoji, ')
          ..write('isPositive: $isPositive, ')
          ..write('points: $points, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameAr, emoji, isPositive, points, isActive, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomIbadahData &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.emoji == this.emoji &&
          other.isPositive == this.isPositive &&
          other.points == this.points &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder);
}

class CustomIbadahCompanion extends UpdateCompanion<CustomIbadahData> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> emoji;
  final Value<bool> isPositive;
  final Value<int> points;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  const CustomIbadahCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.emoji = const Value.absent(),
    this.isPositive = const Value.absent(),
    this.points = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CustomIbadahCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    this.emoji = const Value.absent(),
    this.isPositive = const Value.absent(),
    this.points = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : nameAr = Value(nameAr);
  static Insertable<CustomIbadahData> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? emoji,
    Expression<bool>? isPositive,
    Expression<int>? points,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (emoji != null) 'emoji': emoji,
      if (isPositive != null) 'is_positive': isPositive,
      if (points != null) 'points': points,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CustomIbadahCompanion copyWith({
    Value<int>? id,
    Value<String>? nameAr,
    Value<String>? emoji,
    Value<bool>? isPositive,
    Value<int>? points,
    Value<bool>? isActive,
    Value<int>? sortOrder,
  }) {
    return CustomIbadahCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      emoji: emoji ?? this.emoji,
      isPositive: isPositive ?? this.isPositive,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (isPositive.present) {
      map['is_positive'] = Variable<bool>(isPositive.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomIbadahCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('emoji: $emoji, ')
          ..write('isPositive: $isPositive, ')
          ..write('points: $points, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CustomIbadahLogTable extends CustomIbadahLog
    with TableInfo<$CustomIbadahLogTable, CustomIbadahLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomIbadahLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ibadahIdMeta = const VerificationMeta(
    'ibadahId',
  );
  @override
  late final GeneratedColumn<int> ibadahId = GeneratedColumn<int>(
    'ibadah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_ibadah (id)',
    ),
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES daily_records (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ibadahId,
    recordId,
    date,
    done,
    count,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_ibadah_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomIbadahLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ibadah_id')) {
      context.handle(
        _ibadahIdMeta,
        ibadahId.isAcceptableOrUnknown(data['ibadah_id']!, _ibadahIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ibadahIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomIbadahLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomIbadahLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ibadahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ibadah_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $CustomIbadahLogTable createAlias(String alias) {
    return $CustomIbadahLogTable(attachedDatabase, alias);
  }
}

class CustomIbadahLogData extends DataClass
    implements Insertable<CustomIbadahLogData> {
  final int id;
  final int ibadahId;
  final int recordId;
  final DateTime date;
  final bool done;
  final int count;
  const CustomIbadahLogData({
    required this.id,
    required this.ibadahId,
    required this.recordId,
    required this.date,
    required this.done,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ibadah_id'] = Variable<int>(ibadahId);
    map['record_id'] = Variable<int>(recordId);
    map['date'] = Variable<DateTime>(date);
    map['done'] = Variable<bool>(done);
    map['count'] = Variable<int>(count);
    return map;
  }

  CustomIbadahLogCompanion toCompanion(bool nullToAbsent) {
    return CustomIbadahLogCompanion(
      id: Value(id),
      ibadahId: Value(ibadahId),
      recordId: Value(recordId),
      date: Value(date),
      done: Value(done),
      count: Value(count),
    );
  }

  factory CustomIbadahLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomIbadahLogData(
      id: serializer.fromJson<int>(json['id']),
      ibadahId: serializer.fromJson<int>(json['ibadahId']),
      recordId: serializer.fromJson<int>(json['recordId']),
      date: serializer.fromJson<DateTime>(json['date']),
      done: serializer.fromJson<bool>(json['done']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ibadahId': serializer.toJson<int>(ibadahId),
      'recordId': serializer.toJson<int>(recordId),
      'date': serializer.toJson<DateTime>(date),
      'done': serializer.toJson<bool>(done),
      'count': serializer.toJson<int>(count),
    };
  }

  CustomIbadahLogData copyWith({
    int? id,
    int? ibadahId,
    int? recordId,
    DateTime? date,
    bool? done,
    int? count,
  }) => CustomIbadahLogData(
    id: id ?? this.id,
    ibadahId: ibadahId ?? this.ibadahId,
    recordId: recordId ?? this.recordId,
    date: date ?? this.date,
    done: done ?? this.done,
    count: count ?? this.count,
  );
  CustomIbadahLogData copyWithCompanion(CustomIbadahLogCompanion data) {
    return CustomIbadahLogData(
      id: data.id.present ? data.id.value : this.id,
      ibadahId: data.ibadahId.present ? data.ibadahId.value : this.ibadahId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      date: data.date.present ? data.date.value : this.date,
      done: data.done.present ? data.done.value : this.done,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomIbadahLogData(')
          ..write('id: $id, ')
          ..write('ibadahId: $ibadahId, ')
          ..write('recordId: $recordId, ')
          ..write('date: $date, ')
          ..write('done: $done, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ibadahId, recordId, date, done, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomIbadahLogData &&
          other.id == this.id &&
          other.ibadahId == this.ibadahId &&
          other.recordId == this.recordId &&
          other.date == this.date &&
          other.done == this.done &&
          other.count == this.count);
}

class CustomIbadahLogCompanion extends UpdateCompanion<CustomIbadahLogData> {
  final Value<int> id;
  final Value<int> ibadahId;
  final Value<int> recordId;
  final Value<DateTime> date;
  final Value<bool> done;
  final Value<int> count;
  const CustomIbadahLogCompanion({
    this.id = const Value.absent(),
    this.ibadahId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.date = const Value.absent(),
    this.done = const Value.absent(),
    this.count = const Value.absent(),
  });
  CustomIbadahLogCompanion.insert({
    this.id = const Value.absent(),
    required int ibadahId,
    required int recordId,
    required DateTime date,
    this.done = const Value.absent(),
    this.count = const Value.absent(),
  }) : ibadahId = Value(ibadahId),
       recordId = Value(recordId),
       date = Value(date);
  static Insertable<CustomIbadahLogData> custom({
    Expression<int>? id,
    Expression<int>? ibadahId,
    Expression<int>? recordId,
    Expression<DateTime>? date,
    Expression<bool>? done,
    Expression<int>? count,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ibadahId != null) 'ibadah_id': ibadahId,
      if (recordId != null) 'record_id': recordId,
      if (date != null) 'date': date,
      if (done != null) 'done': done,
      if (count != null) 'count': count,
    });
  }

  CustomIbadahLogCompanion copyWith({
    Value<int>? id,
    Value<int>? ibadahId,
    Value<int>? recordId,
    Value<DateTime>? date,
    Value<bool>? done,
    Value<int>? count,
  }) {
    return CustomIbadahLogCompanion(
      id: id ?? this.id,
      ibadahId: ibadahId ?? this.ibadahId,
      recordId: recordId ?? this.recordId,
      date: date ?? this.date,
      done: done ?? this.done,
      count: count ?? this.count,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ibadahId.present) {
      map['ibadah_id'] = Variable<int>(ibadahId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomIbadahLogCompanion(')
          ..write('id: $id, ')
          ..write('ibadahId: $ibadahId, ')
          ..write('recordId: $recordId, ')
          ..write('date: $date, ')
          ..write('done: $done, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final String key;
  final String value;
  const UserSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserSetting copyWith({String? key, String? value}) =>
      UserSetting(key: key ?? this.key, value: value ?? this.value);
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UserSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<UserSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return UserSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RamadanProgressTable extends RamadanProgress
    with TableInfo<$RamadanProgressTable, RamadanProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RamadanProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
    'record_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES daily_records (id)',
    ),
  );
  static const VerificationMeta _duaOfDayMeta = const VerificationMeta(
    'duaOfDay',
  );
  @override
  late final GeneratedColumn<String> duaOfDay = GeneratedColumn<String>(
    'dua_of_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iHyaLaylMeta = const VerificationMeta(
    'iHyaLayl',
  );
  @override
  late final GeneratedColumn<bool> iHyaLayl = GeneratedColumn<bool>(
    'i_hya_layl',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("i_hya_layl" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _totalPointsMeta = const VerificationMeta(
    'totalPoints',
  );
  @override
  late final GeneratedColumn<int> totalPoints = GeneratedColumn<int>(
    'total_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    year,
    dayNumber,
    recordId,
    duaOfDay,
    iHyaLayl,
    totalPoints,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ramadan_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<RamadanProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    }
    if (data.containsKey('dua_of_day')) {
      context.handle(
        _duaOfDayMeta,
        duaOfDay.isAcceptableOrUnknown(data['dua_of_day']!, _duaOfDayMeta),
      );
    }
    if (data.containsKey('i_hya_layl')) {
      context.handle(
        _iHyaLaylMeta,
        iHyaLayl.isAcceptableOrUnknown(data['i_hya_layl']!, _iHyaLaylMeta),
      );
    }
    if (data.containsKey('total_points')) {
      context.handle(
        _totalPointsMeta,
        totalPoints.isAcceptableOrUnknown(
          data['total_points']!,
          _totalPointsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {year, dayNumber},
  ];
  @override
  RamadanProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RamadanProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_id'],
      ),
      duaOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dua_of_day'],
      ),
      iHyaLayl: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}i_hya_layl'],
      )!,
      totalPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_points'],
      )!,
    );
  }

  @override
  $RamadanProgressTable createAlias(String alias) {
    return $RamadanProgressTable(attachedDatabase, alias);
  }
}

class RamadanProgressData extends DataClass
    implements Insertable<RamadanProgressData> {
  final int id;
  final int year;
  final int dayNumber;
  final int? recordId;
  final String? duaOfDay;
  final bool iHyaLayl;
  final int totalPoints;
  const RamadanProgressData({
    required this.id,
    required this.year,
    required this.dayNumber,
    this.recordId,
    this.duaOfDay,
    required this.iHyaLayl,
    required this.totalPoints,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['day_number'] = Variable<int>(dayNumber);
    if (!nullToAbsent || recordId != null) {
      map['record_id'] = Variable<int>(recordId);
    }
    if (!nullToAbsent || duaOfDay != null) {
      map['dua_of_day'] = Variable<String>(duaOfDay);
    }
    map['i_hya_layl'] = Variable<bool>(iHyaLayl);
    map['total_points'] = Variable<int>(totalPoints);
    return map;
  }

  RamadanProgressCompanion toCompanion(bool nullToAbsent) {
    return RamadanProgressCompanion(
      id: Value(id),
      year: Value(year),
      dayNumber: Value(dayNumber),
      recordId: recordId == null && nullToAbsent
          ? const Value.absent()
          : Value(recordId),
      duaOfDay: duaOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(duaOfDay),
      iHyaLayl: Value(iHyaLayl),
      totalPoints: Value(totalPoints),
    );
  }

  factory RamadanProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RamadanProgressData(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      recordId: serializer.fromJson<int?>(json['recordId']),
      duaOfDay: serializer.fromJson<String?>(json['duaOfDay']),
      iHyaLayl: serializer.fromJson<bool>(json['iHyaLayl']),
      totalPoints: serializer.fromJson<int>(json['totalPoints']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'recordId': serializer.toJson<int?>(recordId),
      'duaOfDay': serializer.toJson<String?>(duaOfDay),
      'iHyaLayl': serializer.toJson<bool>(iHyaLayl),
      'totalPoints': serializer.toJson<int>(totalPoints),
    };
  }

  RamadanProgressData copyWith({
    int? id,
    int? year,
    int? dayNumber,
    Value<int?> recordId = const Value.absent(),
    Value<String?> duaOfDay = const Value.absent(),
    bool? iHyaLayl,
    int? totalPoints,
  }) => RamadanProgressData(
    id: id ?? this.id,
    year: year ?? this.year,
    dayNumber: dayNumber ?? this.dayNumber,
    recordId: recordId.present ? recordId.value : this.recordId,
    duaOfDay: duaOfDay.present ? duaOfDay.value : this.duaOfDay,
    iHyaLayl: iHyaLayl ?? this.iHyaLayl,
    totalPoints: totalPoints ?? this.totalPoints,
  );
  RamadanProgressData copyWithCompanion(RamadanProgressCompanion data) {
    return RamadanProgressData(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      duaOfDay: data.duaOfDay.present ? data.duaOfDay.value : this.duaOfDay,
      iHyaLayl: data.iHyaLayl.present ? data.iHyaLayl.value : this.iHyaLayl,
      totalPoints: data.totalPoints.present
          ? data.totalPoints.value
          : this.totalPoints,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RamadanProgressData(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('recordId: $recordId, ')
          ..write('duaOfDay: $duaOfDay, ')
          ..write('iHyaLayl: $iHyaLayl, ')
          ..write('totalPoints: $totalPoints')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    year,
    dayNumber,
    recordId,
    duaOfDay,
    iHyaLayl,
    totalPoints,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RamadanProgressData &&
          other.id == this.id &&
          other.year == this.year &&
          other.dayNumber == this.dayNumber &&
          other.recordId == this.recordId &&
          other.duaOfDay == this.duaOfDay &&
          other.iHyaLayl == this.iHyaLayl &&
          other.totalPoints == this.totalPoints);
}

class RamadanProgressCompanion extends UpdateCompanion<RamadanProgressData> {
  final Value<int> id;
  final Value<int> year;
  final Value<int> dayNumber;
  final Value<int?> recordId;
  final Value<String?> duaOfDay;
  final Value<bool> iHyaLayl;
  final Value<int> totalPoints;
  const RamadanProgressCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.recordId = const Value.absent(),
    this.duaOfDay = const Value.absent(),
    this.iHyaLayl = const Value.absent(),
    this.totalPoints = const Value.absent(),
  });
  RamadanProgressCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required int dayNumber,
    this.recordId = const Value.absent(),
    this.duaOfDay = const Value.absent(),
    this.iHyaLayl = const Value.absent(),
    this.totalPoints = const Value.absent(),
  }) : year = Value(year),
       dayNumber = Value(dayNumber);
  static Insertable<RamadanProgressData> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? dayNumber,
    Expression<int>? recordId,
    Expression<String>? duaOfDay,
    Expression<bool>? iHyaLayl,
    Expression<int>? totalPoints,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (dayNumber != null) 'day_number': dayNumber,
      if (recordId != null) 'record_id': recordId,
      if (duaOfDay != null) 'dua_of_day': duaOfDay,
      if (iHyaLayl != null) 'i_hya_layl': iHyaLayl,
      if (totalPoints != null) 'total_points': totalPoints,
    });
  }

  RamadanProgressCompanion copyWith({
    Value<int>? id,
    Value<int>? year,
    Value<int>? dayNumber,
    Value<int?>? recordId,
    Value<String?>? duaOfDay,
    Value<bool>? iHyaLayl,
    Value<int>? totalPoints,
  }) {
    return RamadanProgressCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      dayNumber: dayNumber ?? this.dayNumber,
      recordId: recordId ?? this.recordId,
      duaOfDay: duaOfDay ?? this.duaOfDay,
      iHyaLayl: iHyaLayl ?? this.iHyaLayl,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (duaOfDay.present) {
      map['dua_of_day'] = Variable<String>(duaOfDay.value);
    }
    if (iHyaLayl.present) {
      map['i_hya_layl'] = Variable<bool>(iHyaLayl.value);
    }
    if (totalPoints.present) {
      map['total_points'] = Variable<int>(totalPoints.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RamadanProgressCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('recordId: $recordId, ')
          ..write('duaOfDay: $duaOfDay, ')
          ..write('iHyaLayl: $iHyaLayl, ')
          ..write('totalPoints: $totalPoints')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('favorite_rounded'),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    iconName,
    time,
    isEnabled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String title;
  final String iconName;
  final String time;
  final bool isEnabled;
  final DateTime createdAt;
  const Reminder({
    required this.id,
    required this.title,
    required this.iconName,
    required this.time,
    required this.isEnabled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['icon_name'] = Variable<String>(iconName);
    map['time'] = Variable<String>(time);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      iconName: Value(iconName),
      time: Value(time),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      iconName: serializer.fromJson<String>(json['iconName']),
      time: serializer.fromJson<String>(json['time']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'iconName': serializer.toJson<String>(iconName),
      'time': serializer.toJson<String>(time),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? iconName,
    String? time,
    bool? isEnabled,
    DateTime? createdAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    iconName: iconName ?? this.iconName,
    time: time ?? this.time,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      time: data.time.present ? data.time.value : this.time,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconName: $iconName, ')
          ..write('time: $time, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, iconName, time, isEnabled, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.iconName == this.iconName &&
          other.time == this.time &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> iconName;
  final Value<String> time;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconName = const Value.absent(),
    this.time = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.iconName = const Value.absent(),
    required String time,
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       time = Value(time);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? iconName,
    Expression<String>? time,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (iconName != null) 'icon_name': iconName,
      if (time != null) 'time': time,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? iconName,
    Value<String>? time,
    Value<bool>? isEnabled,
    Value<DateTime>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      iconName: iconName ?? this.iconName,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconName: $iconName, ')
          ..write('time: $time, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserAdhkarTable extends UserAdhkar
    with TableInfo<$UserAdhkarTable, UserAdhkarData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAdhkarTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textArMeta = const VerificationMeta('textAr');
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _categoryHintMeta = const VerificationMeta(
    'categoryHint',
  );
  @override
  late final GeneratedColumn<String> categoryHint = GeneratedColumn<String>(
    'category_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    textAr,
    count,
    categoryHint,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_adhkar';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserAdhkarData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text_ar')) {
      context.handle(
        _textArMeta,
        textAr.isAcceptableOrUnknown(data['text_ar']!, _textArMeta),
      );
    } else if (isInserting) {
      context.missing(_textArMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('category_hint')) {
      context.handle(
        _categoryHintMeta,
        categoryHint.isAcceptableOrUnknown(
          data['category_hint']!,
          _categoryHintMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserAdhkarData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAdhkarData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      categoryHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_hint'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserAdhkarTable createAlias(String alias) {
    return $UserAdhkarTable(attachedDatabase, alias);
  }
}

class UserAdhkarData extends DataClass implements Insertable<UserAdhkarData> {
  final String id;
  final String textAr;
  final int count;
  final String? categoryHint;
  final DateTime createdAt;
  const UserAdhkarData({
    required this.id,
    required this.textAr,
    required this.count,
    this.categoryHint,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text_ar'] = Variable<String>(textAr);
    map['count'] = Variable<int>(count);
    if (!nullToAbsent || categoryHint != null) {
      map['category_hint'] = Variable<String>(categoryHint);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserAdhkarCompanion toCompanion(bool nullToAbsent) {
    return UserAdhkarCompanion(
      id: Value(id),
      textAr: Value(textAr),
      count: Value(count),
      categoryHint: categoryHint == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryHint),
      createdAt: Value(createdAt),
    );
  }

  factory UserAdhkarData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAdhkarData(
      id: serializer.fromJson<String>(json['id']),
      textAr: serializer.fromJson<String>(json['textAr']),
      count: serializer.fromJson<int>(json['count']),
      categoryHint: serializer.fromJson<String?>(json['categoryHint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'textAr': serializer.toJson<String>(textAr),
      'count': serializer.toJson<int>(count),
      'categoryHint': serializer.toJson<String?>(categoryHint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserAdhkarData copyWith({
    String? id,
    String? textAr,
    int? count,
    Value<String?> categoryHint = const Value.absent(),
    DateTime? createdAt,
  }) => UserAdhkarData(
    id: id ?? this.id,
    textAr: textAr ?? this.textAr,
    count: count ?? this.count,
    categoryHint: categoryHint.present ? categoryHint.value : this.categoryHint,
    createdAt: createdAt ?? this.createdAt,
  );
  UserAdhkarData copyWithCompanion(UserAdhkarCompanion data) {
    return UserAdhkarData(
      id: data.id.present ? data.id.value : this.id,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      count: data.count.present ? data.count.value : this.count,
      categoryHint: data.categoryHint.present
          ? data.categoryHint.value
          : this.categoryHint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAdhkarData(')
          ..write('id: $id, ')
          ..write('textAr: $textAr, ')
          ..write('count: $count, ')
          ..write('categoryHint: $categoryHint, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, textAr, count, categoryHint, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAdhkarData &&
          other.id == this.id &&
          other.textAr == this.textAr &&
          other.count == this.count &&
          other.categoryHint == this.categoryHint &&
          other.createdAt == this.createdAt);
}

class UserAdhkarCompanion extends UpdateCompanion<UserAdhkarData> {
  final Value<String> id;
  final Value<String> textAr;
  final Value<int> count;
  final Value<String?> categoryHint;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserAdhkarCompanion({
    this.id = const Value.absent(),
    this.textAr = const Value.absent(),
    this.count = const Value.absent(),
    this.categoryHint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserAdhkarCompanion.insert({
    required String id,
    required String textAr,
    this.count = const Value.absent(),
    this.categoryHint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       textAr = Value(textAr);
  static Insertable<UserAdhkarData> custom({
    Expression<String>? id,
    Expression<String>? textAr,
    Expression<int>? count,
    Expression<String>? categoryHint,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textAr != null) 'text_ar': textAr,
      if (count != null) 'count': count,
      if (categoryHint != null) 'category_hint': categoryHint,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserAdhkarCompanion copyWith({
    Value<String>? id,
    Value<String>? textAr,
    Value<int>? count,
    Value<String?>? categoryHint,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UserAdhkarCompanion(
      id: id ?? this.id,
      textAr: textAr ?? this.textAr,
      count: count ?? this.count,
      categoryHint: categoryHint ?? this.categoryHint,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (categoryHint.present) {
      map['category_hint'] = Variable<String>(categoryHint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAdhkarCompanion(')
          ..write('id: $id, ')
          ..write('textAr: $textAr, ')
          ..write('count: $count, ')
          ..write('categoryHint: $categoryHint, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserDuasTable extends UserDuas with TableInfo<$UserDuasTable, UserDua> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDuasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleArMeta = const VerificationMeta(
    'titleAr',
  );
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textArMeta = const VerificationMeta('textAr');
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occasionMeta = const VerificationMeta(
    'occasion',
  );
  @override
  late final GeneratedColumn<String> occasion = GeneratedColumn<String>(
    'occasion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    titleAr,
    textAr,
    occasion,
    source,
    emoji,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_duas';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserDua> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(
        _titleArMeta,
        titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta),
      );
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('text_ar')) {
      context.handle(
        _textArMeta,
        textAr.isAcceptableOrUnknown(data['text_ar']!, _textArMeta),
      );
    } else if (isInserting) {
      context.missing(_textArMeta);
    }
    if (data.containsKey('occasion')) {
      context.handle(
        _occasionMeta,
        occasion.isAcceptableOrUnknown(data['occasion']!, _occasionMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserDua map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserDua(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      titleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_ar'],
      )!,
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      occasion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occasion'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserDuasTable createAlias(String alias) {
    return $UserDuasTable(attachedDatabase, alias);
  }
}

class UserDua extends DataClass implements Insertable<UserDua> {
  final String id;
  final String titleAr;
  final String textAr;
  final String? occasion;
  final String? source;
  final String? emoji;
  final DateTime createdAt;
  const UserDua({
    required this.id,
    required this.titleAr,
    required this.textAr,
    this.occasion,
    this.source,
    this.emoji,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title_ar'] = Variable<String>(titleAr);
    map['text_ar'] = Variable<String>(textAr);
    if (!nullToAbsent || occasion != null) {
      map['occasion'] = Variable<String>(occasion);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserDuasCompanion toCompanion(bool nullToAbsent) {
    return UserDuasCompanion(
      id: Value(id),
      titleAr: Value(titleAr),
      textAr: Value(textAr),
      occasion: occasion == null && nullToAbsent
          ? const Value.absent()
          : Value(occasion),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      createdAt: Value(createdAt),
    );
  }

  factory UserDua.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserDua(
      id: serializer.fromJson<String>(json['id']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      textAr: serializer.fromJson<String>(json['textAr']),
      occasion: serializer.fromJson<String?>(json['occasion']),
      source: serializer.fromJson<String?>(json['source']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'titleAr': serializer.toJson<String>(titleAr),
      'textAr': serializer.toJson<String>(textAr),
      'occasion': serializer.toJson<String?>(occasion),
      'source': serializer.toJson<String?>(source),
      'emoji': serializer.toJson<String?>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserDua copyWith({
    String? id,
    String? titleAr,
    String? textAr,
    Value<String?> occasion = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> emoji = const Value.absent(),
    DateTime? createdAt,
  }) => UserDua(
    id: id ?? this.id,
    titleAr: titleAr ?? this.titleAr,
    textAr: textAr ?? this.textAr,
    occasion: occasion.present ? occasion.value : this.occasion,
    source: source.present ? source.value : this.source,
    emoji: emoji.present ? emoji.value : this.emoji,
    createdAt: createdAt ?? this.createdAt,
  );
  UserDua copyWithCompanion(UserDuasCompanion data) {
    return UserDua(
      id: data.id.present ? data.id.value : this.id,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      occasion: data.occasion.present ? data.occasion.value : this.occasion,
      source: data.source.present ? data.source.value : this.source,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserDua(')
          ..write('id: $id, ')
          ..write('titleAr: $titleAr, ')
          ..write('textAr: $textAr, ')
          ..write('occasion: $occasion, ')
          ..write('source: $source, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, titleAr, textAr, occasion, source, emoji, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserDua &&
          other.id == this.id &&
          other.titleAr == this.titleAr &&
          other.textAr == this.textAr &&
          other.occasion == this.occasion &&
          other.source == this.source &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt);
}

class UserDuasCompanion extends UpdateCompanion<UserDua> {
  final Value<String> id;
  final Value<String> titleAr;
  final Value<String> textAr;
  final Value<String?> occasion;
  final Value<String?> source;
  final Value<String?> emoji;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserDuasCompanion({
    this.id = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.textAr = const Value.absent(),
    this.occasion = const Value.absent(),
    this.source = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserDuasCompanion.insert({
    required String id,
    required String titleAr,
    required String textAr,
    this.occasion = const Value.absent(),
    this.source = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       titleAr = Value(titleAr),
       textAr = Value(textAr);
  static Insertable<UserDua> custom({
    Expression<String>? id,
    Expression<String>? titleAr,
    Expression<String>? textAr,
    Expression<String>? occasion,
    Expression<String>? source,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titleAr != null) 'title_ar': titleAr,
      if (textAr != null) 'text_ar': textAr,
      if (occasion != null) 'occasion': occasion,
      if (source != null) 'source': source,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserDuasCompanion copyWith({
    Value<String>? id,
    Value<String>? titleAr,
    Value<String>? textAr,
    Value<String?>? occasion,
    Value<String?>? source,
    Value<String?>? emoji,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UserDuasCompanion(
      id: id ?? this.id,
      titleAr: titleAr ?? this.titleAr,
      textAr: textAr ?? this.textAr,
      occasion: occasion ?? this.occasion,
      source: source ?? this.source,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (occasion.present) {
      map['occasion'] = Variable<String>(occasion.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDuasCompanion(')
          ..write('id: $id, ')
          ..write('titleAr: $titleAr, ')
          ..write('textAr: $textAr, ')
          ..write('occasion: $occasion, ')
          ..write('source: $source, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookReadingProgressTable extends BookReadingProgress
    with TableInfo<$BookReadingProgressTable, BookReadingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readPagesMeta = const VerificationMeta(
    'readPages',
  );
  @override
  late final GeneratedColumn<String> readPages = GeneratedColumn<String>(
    'read_pages',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pdfPageMeta = const VerificationMeta(
    'pdfPage',
  );
  @override
  late final GeneratedColumn<int> pdfPage = GeneratedColumn<int>(
    'pdf_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPdfPagesMeta = const VerificationMeta(
    'totalPdfPages',
  );
  @override
  late final GeneratedColumn<int> totalPdfPages = GeneratedColumn<int>(
    'total_pdf_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readingSecondsMeta = const VerificationMeta(
    'readingSeconds',
  );
  @override
  late final GeneratedColumn<int> readingSeconds = GeneratedColumn<int>(
    'reading_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    chapterIndex,
    pageIndex,
    readPages,
    pdfPage,
    totalPdfPages,
    readingSeconds,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookReadingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    }
    if (data.containsKey('read_pages')) {
      context.handle(
        _readPagesMeta,
        readPages.isAcceptableOrUnknown(data['read_pages']!, _readPagesMeta),
      );
    }
    if (data.containsKey('pdf_page')) {
      context.handle(
        _pdfPageMeta,
        pdfPage.isAcceptableOrUnknown(data['pdf_page']!, _pdfPageMeta),
      );
    }
    if (data.containsKey('total_pdf_pages')) {
      context.handle(
        _totalPdfPagesMeta,
        totalPdfPages.isAcceptableOrUnknown(
          data['total_pdf_pages']!,
          _totalPdfPagesMeta,
        ),
      );
    }
    if (data.containsKey('reading_seconds')) {
      context.handle(
        _readingSecondsMeta,
        readingSeconds.isAcceptableOrUnknown(
          data['reading_seconds']!,
          _readingSecondsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  BookReadingProgressData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookReadingProgressData(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      )!,
      readPages: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}read_pages'],
      )!,
      pdfPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pdf_page'],
      )!,
      totalPdfPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pdf_pages'],
      )!,
      readingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_seconds'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BookReadingProgressTable createAlias(String alias) {
    return $BookReadingProgressTable(attachedDatabase, alias);
  }
}

class BookReadingProgressData extends DataClass
    implements Insertable<BookReadingProgressData> {
  final String bookId;
  final int chapterIndex;
  final int pageIndex;

  /// Comma-separated list of read page indices, e.g. "0,1,3,7"
  final String readPages;

  /// PDF page (if applicable)
  final int pdfPage;
  final int totalPdfPages;
  final int readingSeconds;
  final DateTime updatedAt;
  const BookReadingProgressData({
    required this.bookId,
    required this.chapterIndex,
    required this.pageIndex,
    required this.readPages,
    required this.pdfPage,
    required this.totalPdfPages,
    required this.readingSeconds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['page_index'] = Variable<int>(pageIndex);
    map['read_pages'] = Variable<String>(readPages);
    map['pdf_page'] = Variable<int>(pdfPage);
    map['total_pdf_pages'] = Variable<int>(totalPdfPages);
    map['reading_seconds'] = Variable<int>(readingSeconds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BookReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return BookReadingProgressCompanion(
      bookId: Value(bookId),
      chapterIndex: Value(chapterIndex),
      pageIndex: Value(pageIndex),
      readPages: Value(readPages),
      pdfPage: Value(pdfPage),
      totalPdfPages: Value(totalPdfPages),
      readingSeconds: Value(readingSeconds),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookReadingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookReadingProgressData(
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      readPages: serializer.fromJson<String>(json['readPages']),
      pdfPage: serializer.fromJson<int>(json['pdfPage']),
      totalPdfPages: serializer.fromJson<int>(json['totalPdfPages']),
      readingSeconds: serializer.fromJson<int>(json['readingSeconds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'readPages': serializer.toJson<String>(readPages),
      'pdfPage': serializer.toJson<int>(pdfPage),
      'totalPdfPages': serializer.toJson<int>(totalPdfPages),
      'readingSeconds': serializer.toJson<int>(readingSeconds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BookReadingProgressData copyWith({
    String? bookId,
    int? chapterIndex,
    int? pageIndex,
    String? readPages,
    int? pdfPage,
    int? totalPdfPages,
    int? readingSeconds,
    DateTime? updatedAt,
  }) => BookReadingProgressData(
    bookId: bookId ?? this.bookId,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    pageIndex: pageIndex ?? this.pageIndex,
    readPages: readPages ?? this.readPages,
    pdfPage: pdfPage ?? this.pdfPage,
    totalPdfPages: totalPdfPages ?? this.totalPdfPages,
    readingSeconds: readingSeconds ?? this.readingSeconds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BookReadingProgressData copyWithCompanion(BookReadingProgressCompanion data) {
    return BookReadingProgressData(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      readPages: data.readPages.present ? data.readPages.value : this.readPages,
      pdfPage: data.pdfPage.present ? data.pdfPage.value : this.pdfPage,
      totalPdfPages: data.totalPdfPages.present
          ? data.totalPdfPages.value
          : this.totalPdfPages,
      readingSeconds: data.readingSeconds.present
          ? data.readingSeconds.value
          : this.readingSeconds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookReadingProgressData(')
          ..write('bookId: $bookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('readPages: $readPages, ')
          ..write('pdfPage: $pdfPage, ')
          ..write('totalPdfPages: $totalPdfPages, ')
          ..write('readingSeconds: $readingSeconds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    chapterIndex,
    pageIndex,
    readPages,
    pdfPage,
    totalPdfPages,
    readingSeconds,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookReadingProgressData &&
          other.bookId == this.bookId &&
          other.chapterIndex == this.chapterIndex &&
          other.pageIndex == this.pageIndex &&
          other.readPages == this.readPages &&
          other.pdfPage == this.pdfPage &&
          other.totalPdfPages == this.totalPdfPages &&
          other.readingSeconds == this.readingSeconds &&
          other.updatedAt == this.updatedAt);
}

class BookReadingProgressCompanion
    extends UpdateCompanion<BookReadingProgressData> {
  final Value<String> bookId;
  final Value<int> chapterIndex;
  final Value<int> pageIndex;
  final Value<String> readPages;
  final Value<int> pdfPage;
  final Value<int> totalPdfPages;
  final Value<int> readingSeconds;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BookReadingProgressCompanion({
    this.bookId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.readPages = const Value.absent(),
    this.pdfPage = const Value.absent(),
    this.totalPdfPages = const Value.absent(),
    this.readingSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookReadingProgressCompanion.insert({
    required String bookId,
    this.chapterIndex = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.readPages = const Value.absent(),
    this.pdfPage = const Value.absent(),
    this.totalPdfPages = const Value.absent(),
    this.readingSeconds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId);
  static Insertable<BookReadingProgressData> custom({
    Expression<String>? bookId,
    Expression<int>? chapterIndex,
    Expression<int>? pageIndex,
    Expression<String>? readPages,
    Expression<int>? pdfPage,
    Expression<int>? totalPdfPages,
    Expression<int>? readingSeconds,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (pageIndex != null) 'page_index': pageIndex,
      if (readPages != null) 'read_pages': readPages,
      if (pdfPage != null) 'pdf_page': pdfPage,
      if (totalPdfPages != null) 'total_pdf_pages': totalPdfPages,
      if (readingSeconds != null) 'reading_seconds': readingSeconds,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookReadingProgressCompanion copyWith({
    Value<String>? bookId,
    Value<int>? chapterIndex,
    Value<int>? pageIndex,
    Value<String>? readPages,
    Value<int>? pdfPage,
    Value<int>? totalPdfPages,
    Value<int>? readingSeconds,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BookReadingProgressCompanion(
      bookId: bookId ?? this.bookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      pageIndex: pageIndex ?? this.pageIndex,
      readPages: readPages ?? this.readPages,
      pdfPage: pdfPage ?? this.pdfPage,
      totalPdfPages: totalPdfPages ?? this.totalPdfPages,
      readingSeconds: readingSeconds ?? this.readingSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (readPages.present) {
      map['read_pages'] = Variable<String>(readPages.value);
    }
    if (pdfPage.present) {
      map['pdf_page'] = Variable<int>(pdfPage.value);
    }
    if (totalPdfPages.present) {
      map['total_pdf_pages'] = Variable<int>(totalPdfPages.value);
    }
    if (readingSeconds.present) {
      map['reading_seconds'] = Variable<int>(readingSeconds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookReadingProgressCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('readPages: $readPages, ')
          ..write('pdfPage: $pdfPage, ')
          ..write('totalPdfPages: $totalPdfPages, ')
          ..write('readingSeconds: $readingSeconds, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityKeyMeta = const VerificationMeta(
    'entityKey',
  );
  @override
  late final GeneratedColumn<String> entityKey = GeneratedColumn<String>(
    'entity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityTable,
    entityKey,
    lastError,
    attempts,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_key')) {
      context.handle(
        _entityKeyMeta,
        entityKey.isAcceptableOrUnknown(data['entity_key']!, _entityKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKeyMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entityTable, entityKey},
  ];
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      entityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_key'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int id;
  final String entityTable;
  final String entityKey;
  final String? lastError;
  final int attempts;
  final DateTime updatedAt;
  const SyncOutboxData({
    required this.id,
    required this.entityTable,
    required this.entityKey,
    this.lastError,
    required this.attempts,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_key'] = Variable<String>(entityKey);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['attempts'] = Variable<int>(attempts);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      entityKey: Value(entityKey),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      attempts: Value(attempts),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityKey: serializer.fromJson<String>(json['entityKey']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      attempts: serializer.fromJson<int>(json['attempts']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityKey': serializer.toJson<String>(entityKey),
      'lastError': serializer.toJson<String?>(lastError),
      'attempts': serializer.toJson<int>(attempts),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncOutboxData copyWith({
    int? id,
    String? entityTable,
    String? entityKey,
    Value<String?> lastError = const Value.absent(),
    int? attempts,
    DateTime? updatedAt,
  }) => SyncOutboxData(
    id: id ?? this.id,
    entityTable: entityTable ?? this.entityTable,
    entityKey: entityKey ?? this.entityKey,
    lastError: lastError.present ? lastError.value : this.lastError,
    attempts: attempts ?? this.attempts,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      entityKey: data.entityKey.present ? data.entityKey.value : this.entityKey,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityKey: $entityKey, ')
          ..write('lastError: $lastError, ')
          ..write('attempts: $attempts, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityTable, entityKey, lastError, attempts, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.entityKey == this.entityKey &&
          other.lastError == this.lastError &&
          other.attempts == this.attempts &&
          other.updatedAt == this.updatedAt);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<String> entityKey;
  final Value<String?> lastError;
  final Value<int> attempts;
  final Value<DateTime> updatedAt;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityKey = const Value.absent(),
    this.lastError = const Value.absent(),
    this.attempts = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    required String entityKey,
    this.lastError = const Value.absent(),
    this.attempts = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : entityTable = Value(entityTable),
       entityKey = Value(entityKey);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<String>? entityKey,
    Expression<String>? lastError,
    Expression<int>? attempts,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityKey != null) 'entity_key': entityKey,
      if (lastError != null) 'last_error': lastError,
      if (attempts != null) 'attempts': attempts,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? entityTable,
    Value<String>? entityKey,
    Value<String?>? lastError,
    Value<int>? attempts,
    Value<DateTime>? updatedAt,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      entityKey: entityKey ?? this.entityKey,
      lastError: lastError ?? this.lastError,
      attempts: attempts ?? this.attempts,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityKey.present) {
      map['entity_key'] = Variable<String>(entityKey.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityKey: $entityKey, ')
          ..write('lastError: $lastError, ')
          ..write('attempts: $attempts, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyRecordsTable dailyRecords = $DailyRecordsTable(this);
  late final $ProhibitionsLogTable prohibitionsLog = $ProhibitionsLogTable(
    this,
  );
  late final $PrayerTimesCacheTable prayerTimesCache = $PrayerTimesCacheTable(
    this,
  );
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $CustomIbadahTable customIbadah = $CustomIbadahTable(this);
  late final $CustomIbadahLogTable customIbadahLog = $CustomIbadahLogTable(
    this,
  );
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $RamadanProgressTable ramadanProgress = $RamadanProgressTable(
    this,
  );
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $UserAdhkarTable userAdhkar = $UserAdhkarTable(this);
  late final $UserDuasTable userDuas = $UserDuasTable(this);
  late final $BookReadingProgressTable bookReadingProgress =
      $BookReadingProgressTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final Index idxProhibitionsLogRecord = Index(
    'idx_prohibitions_log_record',
    'CREATE INDEX idx_prohibitions_log_record ON prohibitions_log (record_id)',
  );
  late final Index idxCustomIbadahLogRecordIbadah = Index(
    'idx_custom_ibadah_log_record_ibadah',
    'CREATE INDEX idx_custom_ibadah_log_record_ibadah ON custom_ibadah_log (record_id, ibadah_id)',
  );
  late final Index idxRamadanProgressRecord = Index(
    'idx_ramadan_progress_record',
    'CREATE INDEX idx_ramadan_progress_record ON ramadan_progress (record_id)',
  );
  late final Index idxSyncOutboxTableKey = Index(
    'idx_sync_outbox_table_key',
    'CREATE INDEX idx_sync_outbox_table_key ON sync_outbox (entity_table, entity_key)',
  );
  late final DailyRecordDao dailyRecordDao = DailyRecordDao(
    this as AppDatabase,
  );
  late final StatsDao statsDao = StatsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final RemindersDao remindersDao = RemindersDao(this as AppDatabase);
  late final CustomIbadahDao customIbadahDao = CustomIbadahDao(
    this as AppDatabase,
  );
  late final PrayerTimesCacheDao prayerTimesCacheDao = PrayerTimesCacheDao(
    this as AppDatabase,
  );
  late final RamadanProgressDao ramadanProgressDao = RamadanProgressDao(
    this as AppDatabase,
  );
  late final UserAdhkarDao userAdhkarDao = UserAdhkarDao(this as AppDatabase);
  late final UserDuasDao userDuasDao = UserDuasDao(this as AppDatabase);
  late final BookProgressDao bookProgressDao = BookProgressDao(
    this as AppDatabase,
  );
  late final SyncOutboxDao syncOutboxDao = SyncOutboxDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dailyRecords,
    prohibitionsLog,
    prayerTimesCache,
    achievements,
    customIbadah,
    customIbadahLog,
    userSettings,
    ramadanProgress,
    reminders,
    userAdhkar,
    userDuas,
    bookReadingProgress,
    syncOutbox,
    idxProhibitionsLogRecord,
    idxCustomIbadahLogRecordIbadah,
    idxRamadanProgressRecord,
    idxSyncOutboxTableKey,
  ];
}

typedef $$DailyRecordsTableCreateCompanionBuilder =
    DailyRecordsCompanion Function({
      Value<int> id,
      required DateTime date,
      Value<PrayerStatus> fajrStatus,
      Value<PrayerStatus> dhuhrStatus,
      Value<PrayerStatus> asrStatus,
      Value<PrayerStatus> maghribStatus,
      Value<PrayerStatus> ishaStatus,
      Value<bool> nightPrayer,
      Value<bool> witr,
      Value<int> rawatib,
      Value<int> quranPages,
      Value<int> quranVerses,
      Value<double> quranJuzaa,
      Value<bool> morningAdhkar,
      Value<bool> eveningAdhkar,
      Value<bool> afterPrayerAdhkar,
      Value<int> tasbeehCount,
      Value<FastingType> fastingType,
      Value<bool> sadaqah,
      Value<double> sadaqahAmount,
      Value<bool> ghadhBasar,
      Value<int> taqwaPoints,
      Value<int> deductedPoints,
      Value<int> netPoints,
      Value<String?> notes,
      Value<String?> mood,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DailyRecordsTableUpdateCompanionBuilder =
    DailyRecordsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<PrayerStatus> fajrStatus,
      Value<PrayerStatus> dhuhrStatus,
      Value<PrayerStatus> asrStatus,
      Value<PrayerStatus> maghribStatus,
      Value<PrayerStatus> ishaStatus,
      Value<bool> nightPrayer,
      Value<bool> witr,
      Value<int> rawatib,
      Value<int> quranPages,
      Value<int> quranVerses,
      Value<double> quranJuzaa,
      Value<bool> morningAdhkar,
      Value<bool> eveningAdhkar,
      Value<bool> afterPrayerAdhkar,
      Value<int> tasbeehCount,
      Value<FastingType> fastingType,
      Value<bool> sadaqah,
      Value<double> sadaqahAmount,
      Value<bool> ghadhBasar,
      Value<int> taqwaPoints,
      Value<int> deductedPoints,
      Value<int> netPoints,
      Value<String?> notes,
      Value<String?> mood,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DailyRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecord> {
  $$DailyRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProhibitionsLogTable, List<ProhibitionsLogData>>
  _prohibitionsLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.prohibitionsLog,
    aliasName: 'daily_records__id__prohibitions_log__record_id',
  );

  $$ProhibitionsLogTableProcessedTableManager get prohibitionsLogRefs {
    final manager = $$ProhibitionsLogTableTableManager(
      $_db,
      $_db.prohibitionsLog,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _prohibitionsLogRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CustomIbadahLogTable, List<CustomIbadahLogData>>
  _customIbadahLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customIbadahLog,
    aliasName: 'daily_records__id__custom_ibadah_log__record_id',
  );

  $$CustomIbadahLogTableProcessedTableManager get customIbadahLogRefs {
    final manager = $$CustomIbadahLogTableTableManager(
      $_db,
      $_db.customIbadahLog,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customIbadahLogRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RamadanProgressTable, List<RamadanProgressData>>
  _ramadanProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ramadanProgress,
    aliasName: 'daily_records__id__ramadan_progress__record_id',
  );

  $$RamadanProgressTableProcessedTableManager get ramadanProgressRefs {
    final manager = $$RamadanProgressTableTableManager(
      $_db,
      $_db.ramadanProgress,
    ).filter((f) => f.recordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ramadanProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DailyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerStatus, PrayerStatus, int>
  get fajrStatus => $composableBuilder(
    column: $table.fajrStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerStatus, PrayerStatus, int>
  get dhuhrStatus => $composableBuilder(
    column: $table.dhuhrStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerStatus, PrayerStatus, int>
  get asrStatus => $composableBuilder(
    column: $table.asrStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerStatus, PrayerStatus, int>
  get maghribStatus => $composableBuilder(
    column: $table.maghribStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<PrayerStatus, PrayerStatus, int>
  get ishaStatus => $composableBuilder(
    column: $table.ishaStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get nightPrayer => $composableBuilder(
    column: $table.nightPrayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get witr => $composableBuilder(
    column: $table.witr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawatib => $composableBuilder(
    column: $table.rawatib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quranPages => $composableBuilder(
    column: $table.quranPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quranVerses => $composableBuilder(
    column: $table.quranVerses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quranJuzaa => $composableBuilder(
    column: $table.quranJuzaa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get morningAdhkar => $composableBuilder(
    column: $table.morningAdhkar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eveningAdhkar => $composableBuilder(
    column: $table.eveningAdhkar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get afterPrayerAdhkar => $composableBuilder(
    column: $table.afterPrayerAdhkar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasbeehCount => $composableBuilder(
    column: $table.tasbeehCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FastingType, FastingType, int>
  get fastingType => $composableBuilder(
    column: $table.fastingType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get sadaqah => $composableBuilder(
    column: $table.sadaqah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sadaqahAmount => $composableBuilder(
    column: $table.sadaqahAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ghadhBasar => $composableBuilder(
    column: $table.ghadhBasar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taqwaPoints => $composableBuilder(
    column: $table.taqwaPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deductedPoints => $composableBuilder(
    column: $table.deductedPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netPoints => $composableBuilder(
    column: $table.netPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> prohibitionsLogRefs(
    Expression<bool> Function($$ProhibitionsLogTableFilterComposer f) f,
  ) {
    final $$ProhibitionsLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prohibitionsLog,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProhibitionsLogTableFilterComposer(
            $db: $db,
            $table: $db.prohibitionsLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customIbadahLogRefs(
    Expression<bool> Function($$CustomIbadahLogTableFilterComposer f) f,
  ) {
    final $$CustomIbadahLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customIbadahLog,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahLogTableFilterComposer(
            $db: $db,
            $table: $db.customIbadahLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ramadanProgressRefs(
    Expression<bool> Function($$RamadanProgressTableFilterComposer f) f,
  ) {
    final $$RamadanProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ramadanProgress,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RamadanProgressTableFilterComposer(
            $db: $db,
            $table: $db.ramadanProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DailyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fajrStatus => $composableBuilder(
    column: $table.fajrStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dhuhrStatus => $composableBuilder(
    column: $table.dhuhrStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get asrStatus => $composableBuilder(
    column: $table.asrStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maghribStatus => $composableBuilder(
    column: $table.maghribStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ishaStatus => $composableBuilder(
    column: $table.ishaStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nightPrayer => $composableBuilder(
    column: $table.nightPrayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get witr => $composableBuilder(
    column: $table.witr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawatib => $composableBuilder(
    column: $table.rawatib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quranPages => $composableBuilder(
    column: $table.quranPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quranVerses => $composableBuilder(
    column: $table.quranVerses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quranJuzaa => $composableBuilder(
    column: $table.quranJuzaa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get morningAdhkar => $composableBuilder(
    column: $table.morningAdhkar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eveningAdhkar => $composableBuilder(
    column: $table.eveningAdhkar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get afterPrayerAdhkar => $composableBuilder(
    column: $table.afterPrayerAdhkar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasbeehCount => $composableBuilder(
    column: $table.tasbeehCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fastingType => $composableBuilder(
    column: $table.fastingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sadaqah => $composableBuilder(
    column: $table.sadaqah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sadaqahAmount => $composableBuilder(
    column: $table.sadaqahAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ghadhBasar => $composableBuilder(
    column: $table.ghadhBasar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taqwaPoints => $composableBuilder(
    column: $table.taqwaPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deductedPoints => $composableBuilder(
    column: $table.deductedPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netPoints => $composableBuilder(
    column: $table.netPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerStatus, int> get fajrStatus =>
      $composableBuilder(
        column: $table.fajrStatus,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PrayerStatus, int> get dhuhrStatus =>
      $composableBuilder(
        column: $table.dhuhrStatus,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PrayerStatus, int> get asrStatus =>
      $composableBuilder(column: $table.asrStatus, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PrayerStatus, int> get maghribStatus =>
      $composableBuilder(
        column: $table.maghribStatus,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<PrayerStatus, int> get ishaStatus =>
      $composableBuilder(
        column: $table.ishaStatus,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get nightPrayer => $composableBuilder(
    column: $table.nightPrayer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get witr =>
      $composableBuilder(column: $table.witr, builder: (column) => column);

  GeneratedColumn<int> get rawatib =>
      $composableBuilder(column: $table.rawatib, builder: (column) => column);

  GeneratedColumn<int> get quranPages => $composableBuilder(
    column: $table.quranPages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quranVerses => $composableBuilder(
    column: $table.quranVerses,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quranJuzaa => $composableBuilder(
    column: $table.quranJuzaa,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get morningAdhkar => $composableBuilder(
    column: $table.morningAdhkar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get eveningAdhkar => $composableBuilder(
    column: $table.eveningAdhkar,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get afterPrayerAdhkar => $composableBuilder(
    column: $table.afterPrayerAdhkar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tasbeehCount => $composableBuilder(
    column: $table.tasbeehCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FastingType, int> get fastingType =>
      $composableBuilder(
        column: $table.fastingType,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get sadaqah =>
      $composableBuilder(column: $table.sadaqah, builder: (column) => column);

  GeneratedColumn<double> get sadaqahAmount => $composableBuilder(
    column: $table.sadaqahAmount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ghadhBasar => $composableBuilder(
    column: $table.ghadhBasar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taqwaPoints => $composableBuilder(
    column: $table.taqwaPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deductedPoints => $composableBuilder(
    column: $table.deductedPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get netPoints =>
      $composableBuilder(column: $table.netPoints, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> prohibitionsLogRefs<T extends Object>(
    Expression<T> Function($$ProhibitionsLogTableAnnotationComposer a) f,
  ) {
    final $$ProhibitionsLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prohibitionsLog,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProhibitionsLogTableAnnotationComposer(
            $db: $db,
            $table: $db.prohibitionsLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customIbadahLogRefs<T extends Object>(
    Expression<T> Function($$CustomIbadahLogTableAnnotationComposer a) f,
  ) {
    final $$CustomIbadahLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customIbadahLog,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahLogTableAnnotationComposer(
            $db: $db,
            $table: $db.customIbadahLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ramadanProgressRefs<T extends Object>(
    Expression<T> Function($$RamadanProgressTableAnnotationComposer a) f,
  ) {
    final $$RamadanProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ramadanProgress,
      getReferencedColumn: (t) => t.recordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RamadanProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.ramadanProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DailyRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyRecordsTable,
          DailyRecord,
          $$DailyRecordsTableFilterComposer,
          $$DailyRecordsTableOrderingComposer,
          $$DailyRecordsTableAnnotationComposer,
          $$DailyRecordsTableCreateCompanionBuilder,
          $$DailyRecordsTableUpdateCompanionBuilder,
          (DailyRecord, $$DailyRecordsTableReferences),
          DailyRecord,
          PrefetchHooks Function({
            bool prohibitionsLogRefs,
            bool customIbadahLogRefs,
            bool ramadanProgressRefs,
          })
        > {
  $$DailyRecordsTableTableManager(_$AppDatabase db, $DailyRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<PrayerStatus> fajrStatus = const Value.absent(),
                Value<PrayerStatus> dhuhrStatus = const Value.absent(),
                Value<PrayerStatus> asrStatus = const Value.absent(),
                Value<PrayerStatus> maghribStatus = const Value.absent(),
                Value<PrayerStatus> ishaStatus = const Value.absent(),
                Value<bool> nightPrayer = const Value.absent(),
                Value<bool> witr = const Value.absent(),
                Value<int> rawatib = const Value.absent(),
                Value<int> quranPages = const Value.absent(),
                Value<int> quranVerses = const Value.absent(),
                Value<double> quranJuzaa = const Value.absent(),
                Value<bool> morningAdhkar = const Value.absent(),
                Value<bool> eveningAdhkar = const Value.absent(),
                Value<bool> afterPrayerAdhkar = const Value.absent(),
                Value<int> tasbeehCount = const Value.absent(),
                Value<FastingType> fastingType = const Value.absent(),
                Value<bool> sadaqah = const Value.absent(),
                Value<double> sadaqahAmount = const Value.absent(),
                Value<bool> ghadhBasar = const Value.absent(),
                Value<int> taqwaPoints = const Value.absent(),
                Value<int> deductedPoints = const Value.absent(),
                Value<int> netPoints = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyRecordsCompanion(
                id: id,
                date: date,
                fajrStatus: fajrStatus,
                dhuhrStatus: dhuhrStatus,
                asrStatus: asrStatus,
                maghribStatus: maghribStatus,
                ishaStatus: ishaStatus,
                nightPrayer: nightPrayer,
                witr: witr,
                rawatib: rawatib,
                quranPages: quranPages,
                quranVerses: quranVerses,
                quranJuzaa: quranJuzaa,
                morningAdhkar: morningAdhkar,
                eveningAdhkar: eveningAdhkar,
                afterPrayerAdhkar: afterPrayerAdhkar,
                tasbeehCount: tasbeehCount,
                fastingType: fastingType,
                sadaqah: sadaqah,
                sadaqahAmount: sadaqahAmount,
                ghadhBasar: ghadhBasar,
                taqwaPoints: taqwaPoints,
                deductedPoints: deductedPoints,
                netPoints: netPoints,
                notes: notes,
                mood: mood,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                Value<PrayerStatus> fajrStatus = const Value.absent(),
                Value<PrayerStatus> dhuhrStatus = const Value.absent(),
                Value<PrayerStatus> asrStatus = const Value.absent(),
                Value<PrayerStatus> maghribStatus = const Value.absent(),
                Value<PrayerStatus> ishaStatus = const Value.absent(),
                Value<bool> nightPrayer = const Value.absent(),
                Value<bool> witr = const Value.absent(),
                Value<int> rawatib = const Value.absent(),
                Value<int> quranPages = const Value.absent(),
                Value<int> quranVerses = const Value.absent(),
                Value<double> quranJuzaa = const Value.absent(),
                Value<bool> morningAdhkar = const Value.absent(),
                Value<bool> eveningAdhkar = const Value.absent(),
                Value<bool> afterPrayerAdhkar = const Value.absent(),
                Value<int> tasbeehCount = const Value.absent(),
                Value<FastingType> fastingType = const Value.absent(),
                Value<bool> sadaqah = const Value.absent(),
                Value<double> sadaqahAmount = const Value.absent(),
                Value<bool> ghadhBasar = const Value.absent(),
                Value<int> taqwaPoints = const Value.absent(),
                Value<int> deductedPoints = const Value.absent(),
                Value<int> netPoints = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyRecordsCompanion.insert(
                id: id,
                date: date,
                fajrStatus: fajrStatus,
                dhuhrStatus: dhuhrStatus,
                asrStatus: asrStatus,
                maghribStatus: maghribStatus,
                ishaStatus: ishaStatus,
                nightPrayer: nightPrayer,
                witr: witr,
                rawatib: rawatib,
                quranPages: quranPages,
                quranVerses: quranVerses,
                quranJuzaa: quranJuzaa,
                morningAdhkar: morningAdhkar,
                eveningAdhkar: eveningAdhkar,
                afterPrayerAdhkar: afterPrayerAdhkar,
                tasbeehCount: tasbeehCount,
                fastingType: fastingType,
                sadaqah: sadaqah,
                sadaqahAmount: sadaqahAmount,
                ghadhBasar: ghadhBasar,
                taqwaPoints: taqwaPoints,
                deductedPoints: deductedPoints,
                netPoints: netPoints,
                notes: notes,
                mood: mood,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyRecordsTable, DailyRecord>(table),
                  $$DailyRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                prohibitionsLogRefs = false,
                customIbadahLogRefs = false,
                ramadanProgressRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (prohibitionsLogRefs) db.prohibitionsLog,
                    if (customIbadahLogRefs) db.customIbadahLog,
                    if (ramadanProgressRefs) db.ramadanProgress,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (prohibitionsLogRefs)
                        await $_getPrefetchedData<
                          DailyRecord,
                          $DailyRecordsTable,
                          ProhibitionsLogData
                        >(
                          currentTable: table,
                          referencedTable: $$DailyRecordsTableReferences
                              ._prohibitionsLogRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DailyRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).prohibitionsLogRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customIbadahLogRefs)
                        await $_getPrefetchedData<
                          DailyRecord,
                          $DailyRecordsTable,
                          CustomIbadahLogData
                        >(
                          currentTable: table,
                          referencedTable: $$DailyRecordsTableReferences
                              ._customIbadahLogRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DailyRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).customIbadahLogRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ramadanProgressRefs)
                        await $_getPrefetchedData<
                          DailyRecord,
                          $DailyRecordsTable,
                          RamadanProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$DailyRecordsTableReferences
                              ._ramadanProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DailyRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).ramadanProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DailyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyRecordsTable,
      DailyRecord,
      $$DailyRecordsTableFilterComposer,
      $$DailyRecordsTableOrderingComposer,
      $$DailyRecordsTableAnnotationComposer,
      $$DailyRecordsTableCreateCompanionBuilder,
      $$DailyRecordsTableUpdateCompanionBuilder,
      (DailyRecord, $$DailyRecordsTableReferences),
      DailyRecord,
      PrefetchHooks Function({
        bool prohibitionsLogRefs,
        bool customIbadahLogRefs,
        bool ramadanProgressRefs,
      })
    >;
typedef $$ProhibitionsLogTableCreateCompanionBuilder =
    ProhibitionsLogCompanion Function({
      Value<int> id,
      required int recordId,
      required DateTime date,
      required ProhibitionCategory category,
      Value<String?> customName,
      Value<bool> committed,
      Value<int> timesCount,
      Value<int> deductPoints,
      Value<String?> notes,
    });
typedef $$ProhibitionsLogTableUpdateCompanionBuilder =
    ProhibitionsLogCompanion Function({
      Value<int> id,
      Value<int> recordId,
      Value<DateTime> date,
      Value<ProhibitionCategory> category,
      Value<String?> customName,
      Value<bool> committed,
      Value<int> timesCount,
      Value<int> deductPoints,
      Value<String?> notes,
    });

final class $$ProhibitionsLogTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProhibitionsLogTable,
          ProhibitionsLogData
        > {
  $$ProhibitionsLogTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DailyRecordsTable _recordIdTable(_$AppDatabase db) => db.dailyRecords
      .createAlias('prohibitions_log__record_id__daily_records__id');

  $$DailyRecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<int>('record_id')!;

    final manager = $$DailyRecordsTableTableManager(
      $_db,
      $_db.dailyRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProhibitionsLogTableFilterComposer
    extends Composer<_$AppDatabase, $ProhibitionsLogTable> {
  $$ProhibitionsLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProhibitionCategory, ProhibitionCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get committed => $composableBuilder(
    column: $table.committed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesCount => $composableBuilder(
    column: $table.timesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deductPoints => $composableBuilder(
    column: $table.deductPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$DailyRecordsTableFilterComposer get recordId {
    final $$DailyRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProhibitionsLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ProhibitionsLogTable> {
  $$ProhibitionsLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get committed => $composableBuilder(
    column: $table.committed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesCount => $composableBuilder(
    column: $table.timesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deductPoints => $composableBuilder(
    column: $table.deductPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$DailyRecordsTableOrderingComposer get recordId {
    final $$DailyRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProhibitionsLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProhibitionsLogTable> {
  $$ProhibitionsLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProhibitionCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get committed =>
      $composableBuilder(column: $table.committed, builder: (column) => column);

  GeneratedColumn<int> get timesCount => $composableBuilder(
    column: $table.timesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deductPoints => $composableBuilder(
    column: $table.deductPoints,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$DailyRecordsTableAnnotationComposer get recordId {
    final $$DailyRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProhibitionsLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProhibitionsLogTable,
          ProhibitionsLogData,
          $$ProhibitionsLogTableFilterComposer,
          $$ProhibitionsLogTableOrderingComposer,
          $$ProhibitionsLogTableAnnotationComposer,
          $$ProhibitionsLogTableCreateCompanionBuilder,
          $$ProhibitionsLogTableUpdateCompanionBuilder,
          (ProhibitionsLogData, $$ProhibitionsLogTableReferences),
          ProhibitionsLogData,
          PrefetchHooks Function({bool recordId})
        > {
  $$ProhibitionsLogTableTableManager(
    _$AppDatabase db,
    $ProhibitionsLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProhibitionsLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProhibitionsLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProhibitionsLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> recordId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<ProhibitionCategory> category = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<bool> committed = const Value.absent(),
                Value<int> timesCount = const Value.absent(),
                Value<int> deductPoints = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => ProhibitionsLogCompanion(
                id: id,
                recordId: recordId,
                date: date,
                category: category,
                customName: customName,
                committed: committed,
                timesCount: timesCount,
                deductPoints: deductPoints,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int recordId,
                required DateTime date,
                required ProhibitionCategory category,
                Value<String?> customName = const Value.absent(),
                Value<bool> committed = const Value.absent(),
                Value<int> timesCount = const Value.absent(),
                Value<int> deductPoints = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => ProhibitionsLogCompanion.insert(
                id: id,
                recordId: recordId,
                date: date,
                category: category,
                customName: customName,
                committed: committed,
                timesCount: timesCount,
                deductPoints: deductPoints,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProhibitionsLogTable, ProhibitionsLogData>(
                    table,
                  ),
                  $$ProhibitionsLogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable:
                                    $$ProhibitionsLogTableReferences
                                        ._recordIdTable(db),
                                referencedColumn:
                                    $$ProhibitionsLogTableReferences
                                        ._recordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProhibitionsLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProhibitionsLogTable,
      ProhibitionsLogData,
      $$ProhibitionsLogTableFilterComposer,
      $$ProhibitionsLogTableOrderingComposer,
      $$ProhibitionsLogTableAnnotationComposer,
      $$ProhibitionsLogTableCreateCompanionBuilder,
      $$ProhibitionsLogTableUpdateCompanionBuilder,
      (ProhibitionsLogData, $$ProhibitionsLogTableReferences),
      ProhibitionsLogData,
      PrefetchHooks Function({bool recordId})
    >;
typedef $$PrayerTimesCacheTableCreateCompanionBuilder =
    PrayerTimesCacheCompanion Function({
      Value<int> id,
      required DateTime date,
      required String fajr,
      required String sunrise,
      required String dhuhr,
      required String asr,
      required String maghrib,
      required String isha,
      required double latitude,
      required double longitude,
      Value<String> method,
    });
typedef $$PrayerTimesCacheTableUpdateCompanionBuilder =
    PrayerTimesCacheCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> fajr,
      Value<String> sunrise,
      Value<String> dhuhr,
      Value<String> asr,
      Value<String> maghrib,
      Value<String> isha,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> method,
    });

class $$PrayerTimesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerTimesCacheTable> {
  $$PrayerTimesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fajr => $composableBuilder(
    column: $table.fajr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sunrise => $composableBuilder(
    column: $table.sunrise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dhuhr => $composableBuilder(
    column: $table.dhuhr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asr => $composableBuilder(
    column: $table.asr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maghrib => $composableBuilder(
    column: $table.maghrib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isha => $composableBuilder(
    column: $table.isha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerTimesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerTimesCacheTable> {
  $$PrayerTimesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fajr => $composableBuilder(
    column: $table.fajr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sunrise => $composableBuilder(
    column: $table.sunrise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dhuhr => $composableBuilder(
    column: $table.dhuhr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asr => $composableBuilder(
    column: $table.asr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maghrib => $composableBuilder(
    column: $table.maghrib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isha => $composableBuilder(
    column: $table.isha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerTimesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerTimesCacheTable> {
  $$PrayerTimesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get fajr =>
      $composableBuilder(column: $table.fajr, builder: (column) => column);

  GeneratedColumn<String> get sunrise =>
      $composableBuilder(column: $table.sunrise, builder: (column) => column);

  GeneratedColumn<String> get dhuhr =>
      $composableBuilder(column: $table.dhuhr, builder: (column) => column);

  GeneratedColumn<String> get asr =>
      $composableBuilder(column: $table.asr, builder: (column) => column);

  GeneratedColumn<String> get maghrib =>
      $composableBuilder(column: $table.maghrib, builder: (column) => column);

  GeneratedColumn<String> get isha =>
      $composableBuilder(column: $table.isha, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);
}

class $$PrayerTimesCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerTimesCacheTable,
          PrayerTimesCacheData,
          $$PrayerTimesCacheTableFilterComposer,
          $$PrayerTimesCacheTableOrderingComposer,
          $$PrayerTimesCacheTableAnnotationComposer,
          $$PrayerTimesCacheTableCreateCompanionBuilder,
          $$PrayerTimesCacheTableUpdateCompanionBuilder,
          (
            PrayerTimesCacheData,
            BaseReferences<
              _$AppDatabase,
              $PrayerTimesCacheTable,
              PrayerTimesCacheData
            >,
          ),
          PrayerTimesCacheData,
          PrefetchHooks Function()
        > {
  $$PrayerTimesCacheTableTableManager(
    _$AppDatabase db,
    $PrayerTimesCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerTimesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerTimesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerTimesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> fajr = const Value.absent(),
                Value<String> sunrise = const Value.absent(),
                Value<String> dhuhr = const Value.absent(),
                Value<String> asr = const Value.absent(),
                Value<String> maghrib = const Value.absent(),
                Value<String> isha = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> method = const Value.absent(),
              }) => PrayerTimesCacheCompanion(
                id: id,
                date: date,
                fajr: fajr,
                sunrise: sunrise,
                dhuhr: dhuhr,
                asr: asr,
                maghrib: maghrib,
                isha: isha,
                latitude: latitude,
                longitude: longitude,
                method: method,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String fajr,
                required String sunrise,
                required String dhuhr,
                required String asr,
                required String maghrib,
                required String isha,
                required double latitude,
                required double longitude,
                Value<String> method = const Value.absent(),
              }) => PrayerTimesCacheCompanion.insert(
                id: id,
                date: date,
                fajr: fajr,
                sunrise: sunrise,
                dhuhr: dhuhr,
                asr: asr,
                maghrib: maghrib,
                isha: isha,
                latitude: latitude,
                longitude: longitude,
                method: method,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerTimesCacheTable, PrayerTimesCacheData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PrayerTimesCacheTable,
                    PrayerTimesCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerTimesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerTimesCacheTable,
      PrayerTimesCacheData,
      $$PrayerTimesCacheTableFilterComposer,
      $$PrayerTimesCacheTableOrderingComposer,
      $$PrayerTimesCacheTableAnnotationComposer,
      $$PrayerTimesCacheTableCreateCompanionBuilder,
      $$PrayerTimesCacheTableUpdateCompanionBuilder,
      (
        PrayerTimesCacheData,
        BaseReferences<
          _$AppDatabase,
          $PrayerTimesCacheTable,
          PrayerTimesCacheData
        >,
      ),
      PrayerTimesCacheData,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      Value<int> id,
      required String type,
      required String titleAr,
      required String descAr,
      required String emoji,
      Value<int> pointsReward,
      required DateTime earnedAt,
      Value<bool> seen,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> titleAr,
      Value<String> descAr,
      Value<String> emoji,
      Value<int> pointsReward,
      Value<DateTime> earnedAt,
      Value<bool> seen,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descAr => $composableBuilder(
    column: $table.descAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointsReward => $composableBuilder(
    column: $table.pointsReward,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descAr => $composableBuilder(
    column: $table.descAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsReward => $composableBuilder(
    column: $table.pointsReward,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get descAr =>
      $composableBuilder(column: $table.descAr, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get pointsReward => $composableBuilder(
    column: $table.pointsReward,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

  GeneratedColumn<bool> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            Achievement,
            BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
          ),
          Achievement,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<String> descAr = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> pointsReward = const Value.absent(),
                Value<DateTime> earnedAt = const Value.absent(),
                Value<bool> seen = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                type: type,
                titleAr: titleAr,
                descAr: descAr,
                emoji: emoji,
                pointsReward: pointsReward,
                earnedAt: earnedAt,
                seen: seen,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String titleAr,
                required String descAr,
                required String emoji,
                Value<int> pointsReward = const Value.absent(),
                required DateTime earnedAt,
                Value<bool> seen = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                type: type,
                titleAr: titleAr,
                descAr: descAr,
                emoji: emoji,
                pointsReward: pointsReward,
                earnedAt: earnedAt,
                seen: seen,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AchievementsTable, Achievement>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AchievementsTable,
                    Achievement
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        Achievement,
        BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
      ),
      Achievement,
      PrefetchHooks Function()
    >;
typedef $$CustomIbadahTableCreateCompanionBuilder =
    CustomIbadahCompanion Function({
      Value<int> id,
      required String nameAr,
      Value<String> emoji,
      Value<bool> isPositive,
      Value<int> points,
      Value<bool> isActive,
      Value<int> sortOrder,
    });
typedef $$CustomIbadahTableUpdateCompanionBuilder =
    CustomIbadahCompanion Function({
      Value<int> id,
      Value<String> nameAr,
      Value<String> emoji,
      Value<bool> isPositive,
      Value<int> points,
      Value<bool> isActive,
      Value<int> sortOrder,
    });

final class $$CustomIbadahTableReferences
    extends
        BaseReferences<_$AppDatabase, $CustomIbadahTable, CustomIbadahData> {
  $$CustomIbadahTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CustomIbadahLogTable, List<CustomIbadahLogData>>
  _customIbadahLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customIbadahLog,
    aliasName: 'custom_ibadah__id__custom_ibadah_log__ibadah_id',
  );

  $$CustomIbadahLogTableProcessedTableManager get customIbadahLogRefs {
    final manager = $$CustomIbadahLogTableTableManager(
      $_db,
      $_db.customIbadahLog,
    ).filter((f) => f.ibadahId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customIbadahLogRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomIbadahTableFilterComposer
    extends Composer<_$AppDatabase, $CustomIbadahTable> {
  $$CustomIbadahTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPositive => $composableBuilder(
    column: $table.isPositive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customIbadahLogRefs(
    Expression<bool> Function($$CustomIbadahLogTableFilterComposer f) f,
  ) {
    final $$CustomIbadahLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customIbadahLog,
      getReferencedColumn: (t) => t.ibadahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahLogTableFilterComposer(
            $db: $db,
            $table: $db.customIbadahLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomIbadahTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomIbadahTable> {
  $$CustomIbadahTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPositive => $composableBuilder(
    column: $table.isPositive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomIbadahTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomIbadahTable> {
  $$CustomIbadahTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<bool> get isPositive => $composableBuilder(
    column: $table.isPositive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> customIbadahLogRefs<T extends Object>(
    Expression<T> Function($$CustomIbadahLogTableAnnotationComposer a) f,
  ) {
    final $$CustomIbadahLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customIbadahLog,
      getReferencedColumn: (t) => t.ibadahId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahLogTableAnnotationComposer(
            $db: $db,
            $table: $db.customIbadahLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomIbadahTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomIbadahTable,
          CustomIbadahData,
          $$CustomIbadahTableFilterComposer,
          $$CustomIbadahTableOrderingComposer,
          $$CustomIbadahTableAnnotationComposer,
          $$CustomIbadahTableCreateCompanionBuilder,
          $$CustomIbadahTableUpdateCompanionBuilder,
          (CustomIbadahData, $$CustomIbadahTableReferences),
          CustomIbadahData,
          PrefetchHooks Function({bool customIbadahLogRefs})
        > {
  $$CustomIbadahTableTableManager(_$AppDatabase db, $CustomIbadahTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomIbadahTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomIbadahTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomIbadahTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<bool> isPositive = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CustomIbadahCompanion(
                id: id,
                nameAr: nameAr,
                emoji: emoji,
                isPositive: isPositive,
                points: points,
                isActive: isActive,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameAr,
                Value<String> emoji = const Value.absent(),
                Value<bool> isPositive = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CustomIbadahCompanion.insert(
                id: id,
                nameAr: nameAr,
                emoji: emoji,
                isPositive: isPositive,
                points: points,
                isActive: isActive,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomIbadahTable, CustomIbadahData>(table),
                  $$CustomIbadahTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customIbadahLogRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (customIbadahLogRefs) db.customIbadahLog,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (customIbadahLogRefs)
                    await $_getPrefetchedData<
                      CustomIbadahData,
                      $CustomIbadahTable,
                      CustomIbadahLogData
                    >(
                      currentTable: table,
                      referencedTable: $$CustomIbadahTableReferences
                          ._customIbadahLogRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomIbadahTableReferences(
                            db,
                            table,
                            p0,
                          ).customIbadahLogRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.ibadahId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomIbadahTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomIbadahTable,
      CustomIbadahData,
      $$CustomIbadahTableFilterComposer,
      $$CustomIbadahTableOrderingComposer,
      $$CustomIbadahTableAnnotationComposer,
      $$CustomIbadahTableCreateCompanionBuilder,
      $$CustomIbadahTableUpdateCompanionBuilder,
      (CustomIbadahData, $$CustomIbadahTableReferences),
      CustomIbadahData,
      PrefetchHooks Function({bool customIbadahLogRefs})
    >;
typedef $$CustomIbadahLogTableCreateCompanionBuilder =
    CustomIbadahLogCompanion Function({
      Value<int> id,
      required int ibadahId,
      required int recordId,
      required DateTime date,
      Value<bool> done,
      Value<int> count,
    });
typedef $$CustomIbadahLogTableUpdateCompanionBuilder =
    CustomIbadahLogCompanion Function({
      Value<int> id,
      Value<int> ibadahId,
      Value<int> recordId,
      Value<DateTime> date,
      Value<bool> done,
      Value<int> count,
    });

final class $$CustomIbadahLogTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomIbadahLogTable,
          CustomIbadahLogData
        > {
  $$CustomIbadahLogTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomIbadahTable _ibadahIdTable(_$AppDatabase db) => db.customIbadah
      .createAlias('custom_ibadah_log__ibadah_id__custom_ibadah__id');

  $$CustomIbadahTableProcessedTableManager get ibadahId {
    final $_column = $_itemColumn<int>('ibadah_id')!;

    final manager = $$CustomIbadahTableTableManager(
      $_db,
      $_db.customIbadah,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ibadahIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DailyRecordsTable _recordIdTable(_$AppDatabase db) => db.dailyRecords
      .createAlias('custom_ibadah_log__record_id__daily_records__id');

  $$DailyRecordsTableProcessedTableManager get recordId {
    final $_column = $_itemColumn<int>('record_id')!;

    final manager = $$DailyRecordsTableTableManager(
      $_db,
      $_db.dailyRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomIbadahLogTableFilterComposer
    extends Composer<_$AppDatabase, $CustomIbadahLogTable> {
  $$CustomIbadahLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  $$CustomIbadahTableFilterComposer get ibadahId {
    final $$CustomIbadahTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ibadahId,
      referencedTable: $db.customIbadah,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahTableFilterComposer(
            $db: $db,
            $table: $db.customIbadah,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DailyRecordsTableFilterComposer get recordId {
    final $$DailyRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomIbadahLogTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomIbadahLogTable> {
  $$CustomIbadahLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  $$CustomIbadahTableOrderingComposer get ibadahId {
    final $$CustomIbadahTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ibadahId,
      referencedTable: $db.customIbadah,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahTableOrderingComposer(
            $db: $db,
            $table: $db.customIbadah,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DailyRecordsTableOrderingComposer get recordId {
    final $$DailyRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomIbadahLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomIbadahLogTable> {
  $$CustomIbadahLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  $$CustomIbadahTableAnnotationComposer get ibadahId {
    final $$CustomIbadahTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ibadahId,
      referencedTable: $db.customIbadah,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomIbadahTableAnnotationComposer(
            $db: $db,
            $table: $db.customIbadah,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DailyRecordsTableAnnotationComposer get recordId {
    final $$DailyRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomIbadahLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomIbadahLogTable,
          CustomIbadahLogData,
          $$CustomIbadahLogTableFilterComposer,
          $$CustomIbadahLogTableOrderingComposer,
          $$CustomIbadahLogTableAnnotationComposer,
          $$CustomIbadahLogTableCreateCompanionBuilder,
          $$CustomIbadahLogTableUpdateCompanionBuilder,
          (CustomIbadahLogData, $$CustomIbadahLogTableReferences),
          CustomIbadahLogData,
          PrefetchHooks Function({bool ibadahId, bool recordId})
        > {
  $$CustomIbadahLogTableTableManager(
    _$AppDatabase db,
    $CustomIbadahLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomIbadahLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomIbadahLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomIbadahLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ibadahId = const Value.absent(),
                Value<int> recordId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => CustomIbadahLogCompanion(
                id: id,
                ibadahId: ibadahId,
                recordId: recordId,
                date: date,
                done: done,
                count: count,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ibadahId,
                required int recordId,
                required DateTime date,
                Value<bool> done = const Value.absent(),
                Value<int> count = const Value.absent(),
              }) => CustomIbadahLogCompanion.insert(
                id: id,
                ibadahId: ibadahId,
                recordId: recordId,
                date: date,
                done: done,
                count: count,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomIbadahLogTable, CustomIbadahLogData>(
                    table,
                  ),
                  $$CustomIbadahLogTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ibadahId = false, recordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ibadahId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ibadahId,
                                referencedTable:
                                    $$CustomIbadahLogTableReferences
                                        ._ibadahIdTable(db),
                                referencedColumn:
                                    $$CustomIbadahLogTableReferences
                                        ._ibadahIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable:
                                    $$CustomIbadahLogTableReferences
                                        ._recordIdTable(db),
                                referencedColumn:
                                    $$CustomIbadahLogTableReferences
                                        ._recordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomIbadahLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomIbadahLogTable,
      CustomIbadahLogData,
      $$CustomIbadahLogTableFilterComposer,
      $$CustomIbadahLogTableOrderingComposer,
      $$CustomIbadahLogTableAnnotationComposer,
      $$CustomIbadahLogTableCreateCompanionBuilder,
      $$CustomIbadahLogTableUpdateCompanionBuilder,
      (CustomIbadahLogData, $$CustomIbadahLogTableReferences),
      CustomIbadahLogData,
      PrefetchHooks Function({bool ibadahId, bool recordId})
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserSettingsTable, UserSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserSettingsTable,
                    UserSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSetting,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
      ),
      UserSetting,
      PrefetchHooks Function()
    >;
typedef $$RamadanProgressTableCreateCompanionBuilder =
    RamadanProgressCompanion Function({
      Value<int> id,
      required int year,
      required int dayNumber,
      Value<int?> recordId,
      Value<String?> duaOfDay,
      Value<bool> iHyaLayl,
      Value<int> totalPoints,
    });
typedef $$RamadanProgressTableUpdateCompanionBuilder =
    RamadanProgressCompanion Function({
      Value<int> id,
      Value<int> year,
      Value<int> dayNumber,
      Value<int?> recordId,
      Value<String?> duaOfDay,
      Value<bool> iHyaLayl,
      Value<int> totalPoints,
    });

final class $$RamadanProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RamadanProgressTable,
          RamadanProgressData
        > {
  $$RamadanProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DailyRecordsTable _recordIdTable(_$AppDatabase db) => db.dailyRecords
      .createAlias('ramadan_progress__record_id__daily_records__id');

  $$DailyRecordsTableProcessedTableManager? get recordId {
    final $_column = $_itemColumn<int>('record_id');
    if ($_column == null) return null;
    final manager = $$DailyRecordsTableTableManager(
      $_db,
      $_db.dailyRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RamadanProgressTableFilterComposer
    extends Composer<_$AppDatabase, $RamadanProgressTable> {
  $$RamadanProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duaOfDay => $composableBuilder(
    column: $table.duaOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get iHyaLayl => $composableBuilder(
    column: $table.iHyaLayl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => ColumnFilters(column),
  );

  $$DailyRecordsTableFilterComposer get recordId {
    final $$DailyRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RamadanProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $RamadanProgressTable> {
  $$RamadanProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duaOfDay => $composableBuilder(
    column: $table.duaOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get iHyaLayl => $composableBuilder(
    column: $table.iHyaLayl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => ColumnOrderings(column),
  );

  $$DailyRecordsTableOrderingComposer get recordId {
    final $$DailyRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RamadanProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $RamadanProgressTable> {
  $$RamadanProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<String> get duaOfDay =>
      $composableBuilder(column: $table.duaOfDay, builder: (column) => column);

  GeneratedColumn<bool> get iHyaLayl =>
      $composableBuilder(column: $table.iHyaLayl, builder: (column) => column);

  GeneratedColumn<int> get totalPoints => $composableBuilder(
    column: $table.totalPoints,
    builder: (column) => column,
  );

  $$DailyRecordsTableAnnotationComposer get recordId {
    final $$DailyRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordId,
      referencedTable: $db.dailyRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dailyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RamadanProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RamadanProgressTable,
          RamadanProgressData,
          $$RamadanProgressTableFilterComposer,
          $$RamadanProgressTableOrderingComposer,
          $$RamadanProgressTableAnnotationComposer,
          $$RamadanProgressTableCreateCompanionBuilder,
          $$RamadanProgressTableUpdateCompanionBuilder,
          (RamadanProgressData, $$RamadanProgressTableReferences),
          RamadanProgressData,
          PrefetchHooks Function({bool recordId})
        > {
  $$RamadanProgressTableTableManager(
    _$AppDatabase db,
    $RamadanProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RamadanProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RamadanProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RamadanProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<int?> recordId = const Value.absent(),
                Value<String?> duaOfDay = const Value.absent(),
                Value<bool> iHyaLayl = const Value.absent(),
                Value<int> totalPoints = const Value.absent(),
              }) => RamadanProgressCompanion(
                id: id,
                year: year,
                dayNumber: dayNumber,
                recordId: recordId,
                duaOfDay: duaOfDay,
                iHyaLayl: iHyaLayl,
                totalPoints: totalPoints,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int year,
                required int dayNumber,
                Value<int?> recordId = const Value.absent(),
                Value<String?> duaOfDay = const Value.absent(),
                Value<bool> iHyaLayl = const Value.absent(),
                Value<int> totalPoints = const Value.absent(),
              }) => RamadanProgressCompanion.insert(
                id: id,
                year: year,
                dayNumber: dayNumber,
                recordId: recordId,
                duaOfDay: duaOfDay,
                iHyaLayl: iHyaLayl,
                totalPoints: totalPoints,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RamadanProgressTable, RamadanProgressData>(
                    table,
                  ),
                  $$RamadanProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordId,
                                referencedTable:
                                    $$RamadanProgressTableReferences
                                        ._recordIdTable(db),
                                referencedColumn:
                                    $$RamadanProgressTableReferences
                                        ._recordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RamadanProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RamadanProgressTable,
      RamadanProgressData,
      $$RamadanProgressTableFilterComposer,
      $$RamadanProgressTableOrderingComposer,
      $$RamadanProgressTableAnnotationComposer,
      $$RamadanProgressTableCreateCompanionBuilder,
      $$RamadanProgressTableUpdateCompanionBuilder,
      (RamadanProgressData, $$RamadanProgressTableReferences),
      RamadanProgressData,
      PrefetchHooks Function({bool recordId})
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      required String title,
      Value<String> iconName,
      required String time,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> iconName,
      Value<String> time,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                iconName: iconName,
                time: time,
                isEnabled: isEnabled,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> iconName = const Value.absent(),
                required String time,
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                iconName: iconName,
                time: time,
                isEnabled: isEnabled,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RemindersTable, Reminder>(table),
                  BaseReferences<_$AppDatabase, $RemindersTable, Reminder>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;
typedef $$UserAdhkarTableCreateCompanionBuilder =
    UserAdhkarCompanion Function({
      required String id,
      required String textAr,
      Value<int> count,
      Value<String?> categoryHint,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UserAdhkarTableUpdateCompanionBuilder =
    UserAdhkarCompanion Function({
      Value<String> id,
      Value<String> textAr,
      Value<int> count,
      Value<String?> categoryHint,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$UserAdhkarTableFilterComposer
    extends Composer<_$AppDatabase, $UserAdhkarTable> {
  $$UserAdhkarTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textAr => $composableBuilder(
    column: $table.textAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryHint => $composableBuilder(
    column: $table.categoryHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserAdhkarTableOrderingComposer
    extends Composer<_$AppDatabase, $UserAdhkarTable> {
  $$UserAdhkarTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textAr => $composableBuilder(
    column: $table.textAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryHint => $composableBuilder(
    column: $table.categoryHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserAdhkarTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserAdhkarTable> {
  $$UserAdhkarTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get textAr =>
      $composableBuilder(column: $table.textAr, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get categoryHint => $composableBuilder(
    column: $table.categoryHint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserAdhkarTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserAdhkarTable,
          UserAdhkarData,
          $$UserAdhkarTableFilterComposer,
          $$UserAdhkarTableOrderingComposer,
          $$UserAdhkarTableAnnotationComposer,
          $$UserAdhkarTableCreateCompanionBuilder,
          $$UserAdhkarTableUpdateCompanionBuilder,
          (
            UserAdhkarData,
            BaseReferences<_$AppDatabase, $UserAdhkarTable, UserAdhkarData>,
          ),
          UserAdhkarData,
          PrefetchHooks Function()
        > {
  $$UserAdhkarTableTableManager(_$AppDatabase db, $UserAdhkarTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserAdhkarTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserAdhkarTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserAdhkarTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> textAr = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<String?> categoryHint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserAdhkarCompanion(
                id: id,
                textAr: textAr,
                count: count,
                categoryHint: categoryHint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String textAr,
                Value<int> count = const Value.absent(),
                Value<String?> categoryHint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserAdhkarCompanion.insert(
                id: id,
                textAr: textAr,
                count: count,
                categoryHint: categoryHint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserAdhkarTable, UserAdhkarData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserAdhkarTable,
                    UserAdhkarData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserAdhkarTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserAdhkarTable,
      UserAdhkarData,
      $$UserAdhkarTableFilterComposer,
      $$UserAdhkarTableOrderingComposer,
      $$UserAdhkarTableAnnotationComposer,
      $$UserAdhkarTableCreateCompanionBuilder,
      $$UserAdhkarTableUpdateCompanionBuilder,
      (
        UserAdhkarData,
        BaseReferences<_$AppDatabase, $UserAdhkarTable, UserAdhkarData>,
      ),
      UserAdhkarData,
      PrefetchHooks Function()
    >;
typedef $$UserDuasTableCreateCompanionBuilder =
    UserDuasCompanion Function({
      required String id,
      required String titleAr,
      required String textAr,
      Value<String?> occasion,
      Value<String?> source,
      Value<String?> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UserDuasTableUpdateCompanionBuilder =
    UserDuasCompanion Function({
      Value<String> id,
      Value<String> titleAr,
      Value<String> textAr,
      Value<String?> occasion,
      Value<String?> source,
      Value<String?> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$UserDuasTableFilterComposer
    extends Composer<_$AppDatabase, $UserDuasTable> {
  $$UserDuasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textAr => $composableBuilder(
    column: $table.textAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occasion => $composableBuilder(
    column: $table.occasion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserDuasTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDuasTable> {
  $$UserDuasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textAr => $composableBuilder(
    column: $table.textAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occasion => $composableBuilder(
    column: $table.occasion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserDuasTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDuasTable> {
  $$UserDuasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get textAr =>
      $composableBuilder(column: $table.textAr, builder: (column) => column);

  GeneratedColumn<String> get occasion =>
      $composableBuilder(column: $table.occasion, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserDuasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserDuasTable,
          UserDua,
          $$UserDuasTableFilterComposer,
          $$UserDuasTableOrderingComposer,
          $$UserDuasTableAnnotationComposer,
          $$UserDuasTableCreateCompanionBuilder,
          $$UserDuasTableUpdateCompanionBuilder,
          (UserDua, BaseReferences<_$AppDatabase, $UserDuasTable, UserDua>),
          UserDua,
          PrefetchHooks Function()
        > {
  $$UserDuasTableTableManager(_$AppDatabase db, $UserDuasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserDuasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserDuasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserDuasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<String> textAr = const Value.absent(),
                Value<String?> occasion = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDuasCompanion(
                id: id,
                titleAr: titleAr,
                textAr: textAr,
                occasion: occasion,
                source: source,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String titleAr,
                required String textAr,
                Value<String?> occasion = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDuasCompanion.insert(
                id: id,
                titleAr: titleAr,
                textAr: textAr,
                occasion: occasion,
                source: source,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserDuasTable, UserDua>(table),
                  BaseReferences<_$AppDatabase, $UserDuasTable, UserDua>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserDuasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserDuasTable,
      UserDua,
      $$UserDuasTableFilterComposer,
      $$UserDuasTableOrderingComposer,
      $$UserDuasTableAnnotationComposer,
      $$UserDuasTableCreateCompanionBuilder,
      $$UserDuasTableUpdateCompanionBuilder,
      (UserDua, BaseReferences<_$AppDatabase, $UserDuasTable, UserDua>),
      UserDua,
      PrefetchHooks Function()
    >;
typedef $$BookReadingProgressTableCreateCompanionBuilder =
    BookReadingProgressCompanion Function({
      required String bookId,
      Value<int> chapterIndex,
      Value<int> pageIndex,
      Value<String> readPages,
      Value<int> pdfPage,
      Value<int> totalPdfPages,
      Value<int> readingSeconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BookReadingProgressTableUpdateCompanionBuilder =
    BookReadingProgressCompanion Function({
      Value<String> bookId,
      Value<int> chapterIndex,
      Value<int> pageIndex,
      Value<String> readPages,
      Value<int> pdfPage,
      Value<int> totalPdfPages,
      Value<int> readingSeconds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BookReadingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $BookReadingProgressTable> {
  $$BookReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readPages => $composableBuilder(
    column: $table.readPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pdfPage => $composableBuilder(
    column: $table.pdfPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPdfPages => $composableBuilder(
    column: $table.totalPdfPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookReadingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $BookReadingProgressTable> {
  $$BookReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readPages => $composableBuilder(
    column: $table.readPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pdfPage => $composableBuilder(
    column: $table.pdfPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPdfPages => $composableBuilder(
    column: $table.totalPdfPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookReadingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookReadingProgressTable> {
  $$BookReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<String> get readPages =>
      $composableBuilder(column: $table.readPages, builder: (column) => column);

  GeneratedColumn<int> get pdfPage =>
      $composableBuilder(column: $table.pdfPage, builder: (column) => column);

  GeneratedColumn<int> get totalPdfPages => $composableBuilder(
    column: $table.totalPdfPages,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BookReadingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookReadingProgressTable,
          BookReadingProgressData,
          $$BookReadingProgressTableFilterComposer,
          $$BookReadingProgressTableOrderingComposer,
          $$BookReadingProgressTableAnnotationComposer,
          $$BookReadingProgressTableCreateCompanionBuilder,
          $$BookReadingProgressTableUpdateCompanionBuilder,
          (
            BookReadingProgressData,
            BaseReferences<
              _$AppDatabase,
              $BookReadingProgressTable,
              BookReadingProgressData
            >,
          ),
          BookReadingProgressData,
          PrefetchHooks Function()
        > {
  $$BookReadingProgressTableTableManager(
    _$AppDatabase db,
    $BookReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookReadingProgressTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BookReadingProgressTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<int> pageIndex = const Value.absent(),
                Value<String> readPages = const Value.absent(),
                Value<int> pdfPage = const Value.absent(),
                Value<int> totalPdfPages = const Value.absent(),
                Value<int> readingSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookReadingProgressCompanion(
                bookId: bookId,
                chapterIndex: chapterIndex,
                pageIndex: pageIndex,
                readPages: readPages,
                pdfPage: pdfPage,
                totalPdfPages: totalPdfPages,
                readingSeconds: readingSeconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                Value<int> chapterIndex = const Value.absent(),
                Value<int> pageIndex = const Value.absent(),
                Value<String> readPages = const Value.absent(),
                Value<int> pdfPage = const Value.absent(),
                Value<int> totalPdfPages = const Value.absent(),
                Value<int> readingSeconds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookReadingProgressCompanion.insert(
                bookId: bookId,
                chapterIndex: chapterIndex,
                pageIndex: pageIndex,
                readPages: readPages,
                pdfPage: pdfPage,
                totalPdfPages: totalPdfPages,
                readingSeconds: readingSeconds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $BookReadingProgressTable,
                    BookReadingProgressData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $BookReadingProgressTable,
                    BookReadingProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookReadingProgressTable,
      BookReadingProgressData,
      $$BookReadingProgressTableFilterComposer,
      $$BookReadingProgressTableOrderingComposer,
      $$BookReadingProgressTableAnnotationComposer,
      $$BookReadingProgressTableCreateCompanionBuilder,
      $$BookReadingProgressTableUpdateCompanionBuilder,
      (
        BookReadingProgressData,
        BaseReferences<
          _$AppDatabase,
          $BookReadingProgressTable,
          BookReadingProgressData
        >,
      ),
      BookReadingProgressData,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      required String entityTable,
      required String entityKey,
      Value<String?> lastError,
      Value<int> attempts,
      Value<DateTime> updatedAt,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      Value<String> entityTable,
      Value<String> entityKey,
      Value<String?> lastError,
      Value<int> attempts,
      Value<DateTime> updatedAt,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityKey =>
      $composableBuilder(column: $table.entityKey, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<String> entityKey = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                entityTable: entityTable,
                entityKey: entityKey,
                lastError: lastError,
                attempts: attempts,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityTable,
                required String entityKey,
                Value<String?> lastError = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                entityTable: entityTable,
                entityKey: entityKey,
                lastError: lastError,
                attempts: attempts,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxTable, SyncOutboxData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncOutboxTable,
                    SyncOutboxData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db, _db.dailyRecords);
  $$ProhibitionsLogTableTableManager get prohibitionsLog =>
      $$ProhibitionsLogTableTableManager(_db, _db.prohibitionsLog);
  $$PrayerTimesCacheTableTableManager get prayerTimesCache =>
      $$PrayerTimesCacheTableTableManager(_db, _db.prayerTimesCache);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$CustomIbadahTableTableManager get customIbadah =>
      $$CustomIbadahTableTableManager(_db, _db.customIbadah);
  $$CustomIbadahLogTableTableManager get customIbadahLog =>
      $$CustomIbadahLogTableTableManager(_db, _db.customIbadahLog);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$RamadanProgressTableTableManager get ramadanProgress =>
      $$RamadanProgressTableTableManager(_db, _db.ramadanProgress);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$UserAdhkarTableTableManager get userAdhkar =>
      $$UserAdhkarTableTableManager(_db, _db.userAdhkar);
  $$UserDuasTableTableManager get userDuas =>
      $$UserDuasTableTableManager(_db, _db.userDuas);
  $$BookReadingProgressTableTableManager get bookReadingProgress =>
      $$BookReadingProgressTableTableManager(_db, _db.bookReadingProgress);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
}
