import 'package:flutter/material.dart';

class UserPreferences {
  final String madhab;
  final String calcMethod;
  final String language;

  final bool prayerReminder;
  final bool preAdhanNotif;
  final bool iqamaNotif;

  final bool wakeUpBeforeFajr;
  final TimeOfDay wakeUpTime;

  final bool morningAdhkarReminder;
  final bool eveningAdhkarReminder;

  final bool adhkarNotifEnabled;
  final TimeOfDay morningAdhkarTime;
  final TimeOfDay eveningAdhkarTime;
  final TimeOfDay sleepAdhkarTime;
  final bool afterFajrAdhkar;
  final bool afterAsrAdhkar;

  final bool muhasabaReminder;
  final TimeOfDay muhasabaTime;

  final bool dailyDuasOn;
  final bool specialRemindersOn;
  final bool fastingRemindersOn;

  final bool ramadanMode;
  final String themeMode; // "system", "light", "dark"
  final String adhanSound;

  // ── Overlay / in-screen settings ──
  final bool overlayEnabled;
  // `adhanSoundEnabled` was removed here too (see the note below on
  // `adhanInSilentEnabled`/`notifsInSilentEnabled`): the background isolate
  // used to gate its adhan sound notification on this separate flag
  // instead of `adhanMode`, so a user setting `adhanMode` to silent/vibrate
  // could still get a sound notification from it — a real bug, not just a
  // naming overlap (fixed by making the background isolate check
  // `adhanMode == 'sound'` directly). Once that consumer was gone, this
  // field had no reachable UI control and nothing left reading it. See
  // docs/specs/settings-notifications-improvements.md R1.
  final bool adhanScreenEnabled;
  final int popupIntervalMins;
  final double adhanVolumeLevel;

  /// 'sound' | 'vibrate' | 'silent'
  final String adhanMode;

  final bool silentModeEnabled;
  final int silentDurationMins;
  final String silentModeAlertStyle;
  final bool silentVibrationEnabled;
  final String silentAdhanPrayers;
  final String silentNotifPrayers;

  final bool autoSilentAfterAdhan;

  // `adhanInSilentEnabled`/`notifsInSilentEnabled` (blanket "allow during
  // silent mode" bools) were removed here — they had no reachable UI
  // control and nothing read them; `silentAdhanPrayers`/
  // `silentNotifPrayers` (the per-prayer allow-lists below) are the only
  // storage for that decision now. See
  // docs/specs/settings-notifications-improvements.md R3/R5.
  final bool flipToSilenceEnabled;
  final bool wakeScreenEnabled;
  final bool vibrateWithAdhan;
  final bool adhanAlarmEnabled;
  final bool ongoingNotifEnabled;

  // ── Calculation adjustments ──
  final String highLatitudeRule;
  final int fajrOffset;
  final int sunriseOffset;
  final int dhuhrOffset;
  final int asrOffset;
  final int maghribOffset;
  final int ishaOffset;

  const UserPreferences({
    this.madhab = 'shafi',
    this.calcMethod = 'MWL',
    this.language = 'ar',
    this.prayerReminder = true,
    this.preAdhanNotif = true,
    this.iqamaNotif = true,
    this.wakeUpBeforeFajr = false,
    this.wakeUpTime = const TimeOfDay(hour: 4, minute: 30),
    this.morningAdhkarReminder = true,
    this.eveningAdhkarReminder = true,
    this.adhkarNotifEnabled = true,
    this.morningAdhkarTime = const TimeOfDay(hour: 6, minute: 30),
    this.eveningAdhkarTime = const TimeOfDay(hour: 17, minute: 0),
    this.sleepAdhkarTime = const TimeOfDay(hour: 22, minute: 0),
    this.afterFajrAdhkar = true,
    this.afterAsrAdhkar = true,
    this.muhasabaReminder = true,
    this.muhasabaTime = const TimeOfDay(hour: 21, minute: 0),
    this.dailyDuasOn = true,
    this.specialRemindersOn = true,
    this.fastingRemindersOn = true,
    this.ramadanMode = false,
    this.themeMode = 'system',
    this.adhanSound = 'Adhan-Makkah.mp3',
    this.overlayEnabled = true,
    this.adhanScreenEnabled = true,
    this.popupIntervalMins = 24,
    this.adhanMode = 'sound',
    this.adhanVolumeLevel = 1.0,
    this.silentModeEnabled = false,
    this.silentDurationMins = 20,
    this.silentModeAlertStyle = 'vibrate',
    this.silentVibrationEnabled = true,
    this.silentAdhanPrayers = 'fajr,dhuhr,asr,maghrib,isha,jumuah',
    this.silentNotifPrayers = 'fajr,sunrise,dhuhr,asr,maghrib,isha,jumuah',
    this.autoSilentAfterAdhan = false,
    this.flipToSilenceEnabled = true,
    this.wakeScreenEnabled = true,
    this.vibrateWithAdhan = true,
    this.adhanAlarmEnabled = true,
    this.ongoingNotifEnabled = true,
    this.highLatitudeRule = 'middle_of_the_night',
    this.fajrOffset = 0,
    this.sunriseOffset = 0,
    this.dhuhrOffset = 0,
    this.asrOffset = 0,
    this.maghribOffset = 0,
    this.ishaOffset = 0,
  });

  UserPreferences copyWith({
    String? madhab,
    String? calcMethod,
    String? language,
    bool? prayerReminder,
    bool? preAdhanNotif,
    bool? iqamaNotif,
    bool? wakeUpBeforeFajr,
    TimeOfDay? wakeUpTime,
    bool? morningAdhkarReminder,
    bool? eveningAdhkarReminder,
    bool? adhkarNotifEnabled,
    TimeOfDay? morningAdhkarTime,
    TimeOfDay? eveningAdhkarTime,
    TimeOfDay? sleepAdhkarTime,
    bool? afterFajrAdhkar,
    bool? afterAsrAdhkar,
    bool? muhasabaReminder,
    TimeOfDay? muhasabaTime,
    bool? dailyDuasOn,
    bool? specialRemindersOn,
    bool? fastingRemindersOn,
    bool? ramadanMode,
    String? themeMode,
    String? adhanSound,
    bool? overlayEnabled,
    bool? adhanScreenEnabled,
    int? popupIntervalMins,
    String? adhanMode,
    double? adhanVolumeLevel,
    bool? silentModeEnabled,
    int? silentDurationMins,
    String? silentModeAlertStyle,
    bool? silentVibrationEnabled,
    String? silentAdhanPrayers,
    String? silentNotifPrayers,
    bool? autoSilentAfterAdhan,
    bool? flipToSilenceEnabled,
    bool? wakeScreenEnabled,
    bool? vibrateWithAdhan,
    bool? adhanAlarmEnabled,
    bool? ongoingNotifEnabled,
    String? highLatitudeRule,
    int? fajrOffset,
    int? sunriseOffset,
    int? dhuhrOffset,
    int? asrOffset,
    int? maghribOffset,
    int? ishaOffset,
  }) {
    return UserPreferences(
      madhab: madhab ?? this.madhab,
      calcMethod: calcMethod ?? this.calcMethod,
      language: language ?? this.language,
      prayerReminder: prayerReminder ?? this.prayerReminder,
      preAdhanNotif: preAdhanNotif ?? this.preAdhanNotif,
      iqamaNotif: iqamaNotif ?? this.iqamaNotif,
      wakeUpBeforeFajr: wakeUpBeforeFajr ?? this.wakeUpBeforeFajr,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      morningAdhkarReminder:
          morningAdhkarReminder ?? this.morningAdhkarReminder,
      eveningAdhkarReminder:
          eveningAdhkarReminder ?? this.eveningAdhkarReminder,
      adhkarNotifEnabled: adhkarNotifEnabled ?? this.adhkarNotifEnabled,
      morningAdhkarTime: morningAdhkarTime ?? this.morningAdhkarTime,
      eveningAdhkarTime: eveningAdhkarTime ?? this.eveningAdhkarTime,
      sleepAdhkarTime: sleepAdhkarTime ?? this.sleepAdhkarTime,
      afterFajrAdhkar: afterFajrAdhkar ?? this.afterFajrAdhkar,
      afterAsrAdhkar: afterAsrAdhkar ?? this.afterAsrAdhkar,
      muhasabaReminder: muhasabaReminder ?? this.muhasabaReminder,
      muhasabaTime: muhasabaTime ?? this.muhasabaTime,
      dailyDuasOn: dailyDuasOn ?? this.dailyDuasOn,
      specialRemindersOn: specialRemindersOn ?? this.specialRemindersOn,
      fastingRemindersOn: fastingRemindersOn ?? this.fastingRemindersOn,
      ramadanMode: ramadanMode ?? this.ramadanMode,
      themeMode: themeMode ?? this.themeMode,
      adhanSound: adhanSound ?? this.adhanSound,
      overlayEnabled: overlayEnabled ?? this.overlayEnabled,
      adhanScreenEnabled: adhanScreenEnabled ?? this.adhanScreenEnabled,
      popupIntervalMins: popupIntervalMins ?? this.popupIntervalMins,
      adhanMode: adhanMode ?? this.adhanMode,
      adhanVolumeLevel: adhanVolumeLevel ?? this.adhanVolumeLevel,
      silentModeEnabled: silentModeEnabled ?? this.silentModeEnabled,
      silentDurationMins: silentDurationMins ?? this.silentDurationMins,
      silentModeAlertStyle: silentModeAlertStyle ?? this.silentModeAlertStyle,
      silentVibrationEnabled:
          silentVibrationEnabled ?? this.silentVibrationEnabled,
      silentAdhanPrayers: silentAdhanPrayers ?? this.silentAdhanPrayers,
      silentNotifPrayers: silentNotifPrayers ?? this.silentNotifPrayers,
      autoSilentAfterAdhan: autoSilentAfterAdhan ?? this.autoSilentAfterAdhan,
      flipToSilenceEnabled: flipToSilenceEnabled ?? this.flipToSilenceEnabled,
      wakeScreenEnabled: wakeScreenEnabled ?? this.wakeScreenEnabled,
      vibrateWithAdhan: vibrateWithAdhan ?? this.vibrateWithAdhan,
      adhanAlarmEnabled: adhanAlarmEnabled ?? this.adhanAlarmEnabled,
      ongoingNotifEnabled: ongoingNotifEnabled ?? this.ongoingNotifEnabled,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      fajrOffset: fajrOffset ?? this.fajrOffset,
      sunriseOffset: sunriseOffset ?? this.sunriseOffset,
      dhuhrOffset: dhuhrOffset ?? this.dhuhrOffset,
      asrOffset: asrOffset ?? this.asrOffset,
      maghribOffset: maghribOffset ?? this.maghribOffset,
      ishaOffset: ishaOffset ?? this.ishaOffset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'madhab': madhab,
      'calc_method': calcMethod,
      'language': language,
      'prayer_reminder': prayerReminder,
      'pre_adhan_notif': preAdhanNotif,
      'iqama_notif': iqamaNotif,
      'wake_up_before_fajr': wakeUpBeforeFajr,
      'wake_up_time':
          '${wakeUpTime.hour.toString().padLeft(2, '0')}:${wakeUpTime.minute.toString().padLeft(2, '0')}',
      'morning_adhkar_reminder': morningAdhkarReminder,
      'evening_adhkar_reminder': eveningAdhkarReminder,
      'adhkar_notif_enabled': adhkarNotifEnabled,
      'morning_adhkar_time':
          '${morningAdhkarTime.hour.toString().padLeft(2, '0')}:${morningAdhkarTime.minute.toString().padLeft(2, '0')}',
      'evening_adhkar_time':
          '${eveningAdhkarTime.hour.toString().padLeft(2, '0')}:${eveningAdhkarTime.minute.toString().padLeft(2, '0')}',
      'sleep_adhkar_time':
          '${sleepAdhkarTime.hour.toString().padLeft(2, '0')}:${sleepAdhkarTime.minute.toString().padLeft(2, '0')}',
      'after_fajr_adhkar': afterFajrAdhkar,
      'after_asr_adhkar': afterAsrAdhkar,
      'muhasaba_reminder': muhasabaReminder,
      'evening_reminder_time':
          '${muhasabaTime.hour.toString().padLeft(2, '0')}:${muhasabaTime.minute.toString().padLeft(2, '0')}',
      'daily_duas_on': dailyDuasOn,
      'special_reminders_on': specialRemindersOn,
      'fasting_reminders_on': fastingRemindersOn,
      'ramadan_mode': ramadanMode,
      'theme_mode': themeMode,
      'adhan_sound': adhanSound,
      'overlay_popups_enabled': overlayEnabled,
      'adhan_screen_enabled': adhanScreenEnabled,
      'popup_interval_minutes': popupIntervalMins,
      'adhan_mode': adhanMode,
      'adhan_volume_level': adhanVolumeLevel,
      'silent_mode_enabled': silentModeEnabled,
      'silent_duration_mins': silentDurationMins,
      'silent_mode_alert_style': silentModeAlertStyle,
      'silent_vibration_enabled': silentVibrationEnabled,
      'silent_adhan_prayers': silentAdhanPrayers,
      'silent_notif_prayers': silentNotifPrayers,
      'auto_silent_after_adhan': autoSilentAfterAdhan,
      'flip_to_silence_enabled': flipToSilenceEnabled,
      'wake_screen_enabled': wakeScreenEnabled,
      'vibrate_with_adhan': vibrateWithAdhan,
      'adhan_alarm_enabled': adhanAlarmEnabled,
      'ongoing_notif_enabled': ongoingNotifEnabled,
      'high_latitude_rule': highLatitudeRule,
      'fajr_offset': fajrOffset,
      'sunrise_offset': sunriseOffset,
      'dhuhr_offset': dhuhrOffset,
      'asr_offset': asrOffset,
      'maghrib_offset': maghribOffset,
      'isha_offset': ishaOffset,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic val, {bool defaultVal = false}) {
      if (val == null) return defaultVal;
      if (val is bool) return val;
      if (val is String) {
        return val.toLowerCase() == 'true' || val == '1';
      }
      if (val is int) return val == 1;
      return defaultVal;
    }

    TimeOfDay parseTime(dynamic val, {required TimeOfDay defaultVal}) {
      if (val == null || val is! String || !val.contains(':')) {
        return defaultVal;
      }
      final parts = val.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      return defaultVal;
    }

    int parseInt(dynamic val, {int defaultVal = 0}) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? defaultVal;
    }

    double parseDouble(dynamic val, {double defaultVal = 0.0}) {
      if (val == null) return defaultVal;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? defaultVal;
    }

    return UserPreferences(
      madhab: map['madhab'] as String? ?? 'shafi',
      calcMethod: (map['calc_method'] ?? map['calcMethod']) as String? ?? 'MWL',
      language: map['language'] as String? ?? 'ar',
      prayerReminder: parseBool(
        map['prayer_reminder'] ?? map['prayerReminder'],
        defaultVal: true,
      ),
      preAdhanNotif: parseBool(
        map['pre_adhan_notif'] ?? map['preAdhanNotif'],
        defaultVal: true,
      ),
      iqamaNotif: parseBool(
        map['iqama_notif'] ?? map['iqamaNotif'],
        defaultVal: true,
      ),
      wakeUpBeforeFajr: parseBool(
        map['wake_up_before_fajr'] ?? map['wakeUpBeforeFajr'],
      ),
      wakeUpTime: parseTime(
        map['wake_up_time'] ?? map['wakeUpTime'],
        defaultVal: const TimeOfDay(hour: 4, minute: 30),
      ),
      morningAdhkarReminder: parseBool(
        map['morning_adhkar_reminder'] ?? map['morningAdhkarReminder'],
        defaultVal: true,
      ),
      eveningAdhkarReminder: parseBool(
        map['evening_adhkar_reminder'] ?? map['eveningAdhkarReminder'],
        defaultVal: true,
      ),
      adhkarNotifEnabled: parseBool(
        map['adhkar_notif_enabled'] ?? map['adhkarNotifEnabled'],
        defaultVal: true,
      ),
      morningAdhkarTime: parseTime(
        map['morning_adhkar_time'] ?? map['morningAdhkarTime'],
        defaultVal: const TimeOfDay(hour: 6, minute: 30),
      ),
      eveningAdhkarTime: parseTime(
        map['evening_adhkar_time'] ?? map['eveningAdhkarTime'],
        defaultVal: const TimeOfDay(hour: 17, minute: 0),
      ),
      sleepAdhkarTime: parseTime(
        map['sleep_adhkar_time'] ?? map['sleepAdhkarTime'],
        defaultVal: const TimeOfDay(hour: 22, minute: 0),
      ),
      afterFajrAdhkar: parseBool(
        map['after_fajr_adhkar'] ?? map['afterFajrAdhkar'],
        defaultVal: true,
      ),
      afterAsrAdhkar: parseBool(
        map['after_asr_adhkar'] ?? map['afterAsrAdhkar'],
        defaultVal: true,
      ),
      muhasabaReminder: parseBool(
        map['muhasaba_reminder'] ?? map['muhasabaReminder'],
        defaultVal: true,
      ),
      muhasabaTime: parseTime(
        map['evening_reminder_time'] ?? map['muhasabaTime'],
        defaultVal: const TimeOfDay(hour: 21, minute: 0),
      ),
      dailyDuasOn: parseBool(
        map['daily_duas_on'] ?? map['dailyDuasOn'],
        defaultVal: true,
      ),
      specialRemindersOn: parseBool(
        map['special_reminders_on'] ?? map['specialRemindersOn'],
        defaultVal: true,
      ),
      fastingRemindersOn: parseBool(
        map['fasting_reminders_on'] ?? map['fastingRemindersOn'],
        defaultVal: true,
      ),
      ramadanMode: parseBool(map['ramadan_mode'] ?? map['ramadanMode']),
      themeMode: map['theme_mode'] ?? map['themeMode'] ?? 'system',
      adhanSound: map['adhan_sound'] ?? map['adhanSound'] ?? 'Adhan-Makkah.mp3',
      overlayEnabled: parseBool(
        map['overlay_popups_enabled'] ?? map['overlayEnabled'],
        defaultVal: true,
      ),
      adhanScreenEnabled: parseBool(
        map['adhan_screen_enabled'] ?? map['adhanScreenEnabled'],
        defaultVal: true,
      ),
      popupIntervalMins: parseInt(
        map['popup_interval_minutes'] ?? map['popupIntervalMins'],
        defaultVal: 24,
      ),
      adhanMode: map['adhan_mode'] ?? map['adhanMode'] ?? 'sound',
      adhanVolumeLevel: parseDouble(
        map['adhan_volume_level'] ?? map['adhanVolume'],
        defaultVal: 1.0,
      ),
      silentModeEnabled: parseBool(
        map['silent_mode_enabled'] ?? map['silentModeEnabled'],
      ),
      silentDurationMins: parseInt(
        map['silent_duration_mins'] ?? map['silentDurationMins'],
        defaultVal: 20,
      ),
      silentModeAlertStyle:
          map['silent_mode_alert_style'] ??
          map['silentModeAlertStyle'] ??
          'vibrate',
      silentVibrationEnabled: parseBool(
        map['silent_vibration_enabled'] ?? map['silentVibrationEnabled'],
        defaultVal: true,
      ),
      silentAdhanPrayers:
          map['silent_adhan_prayers'] ??
          map['silentAdhanPrayers'] ??
          'fajr,dhuhr,asr,maghrib,isha,jumuah',
      silentNotifPrayers:
          map['silent_notif_prayers'] ??
          map['silentNotifPrayers'] ??
          'fajr,sunrise,dhuhr,asr,maghrib,isha,jumuah',
      autoSilentAfterAdhan: parseBool(
        map['auto_silent_after_adhan'] ?? map['autoSilentAfterAdhan'],
      ),
      flipToSilenceEnabled: parseBool(
        map['flip_to_silence_enabled'] ?? map['flipToSilenceEnabled'],
        defaultVal: true,
      ),
      wakeScreenEnabled: parseBool(
        map['wake_screen_enabled'] ?? map['wakeScreenEnabled'],
        defaultVal: true,
      ),
      vibrateWithAdhan: parseBool(
        map['vibrate_with_adhan'] ?? map['vibrateWithAdhan'],
        defaultVal: true,
      ),
      adhanAlarmEnabled: parseBool(
        map['adhan_alarm_enabled'] ?? map['adhanAlarmEnabled'],
        defaultVal: true,
      ),
      ongoingNotifEnabled: parseBool(
        map['ongoing_notif_enabled'] ?? map['ongoingNotifEnabled'],
        defaultVal: true,
      ),
      highLatitudeRule:
          map['high_latitude_rule'] ??
          map['highLatitudeRule'] ??
          'middle_of_the_night',
      fajrOffset: parseInt(map['fajr_offset'] ?? map['fajrOffset'], defaultVal: 0),
      sunriseOffset: parseInt(
        map['sunrise_offset'] ?? map['sunriseOffset'],
        defaultVal: 0,
      ),
      dhuhrOffset: parseInt(
        map['dhuhr_offset'] ?? map['dhuhrOffset'],
        defaultVal: 0,
      ),
      asrOffset: parseInt(map['asr_offset'] ?? map['asrOffset'], defaultVal: 0),
      maghribOffset: parseInt(
        map['maghrib_offset'] ?? map['maghribOffset'],
        defaultVal: 0,
      ),
      ishaOffset: parseInt(map['isha_offset'] ?? map['ishaOffset'], defaultVal: 0),
    );
  }
}
