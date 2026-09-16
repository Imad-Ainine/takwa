import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';

import 'package:geocoding/geocoding.dart';
import '../providers/database_providers.dart';
import 'notifications_service.dart';
import '../utils/timezone_resolver.dart';
import '../../features/settings/providers/user_preferences_provider.dart';
import '../../features/settings/presentation/widgets/location_picker_sheet.dart';
import 'package:takwa/core/providers/locale_provider.dart';
import 'package:takwa/l10n/app_localizations.dart';

class LocationPrayerManager {
  /// التهيئة الكاملة عند بدء التطبيق
  static Future<void> initialize(dynamic ref) async {
    TimezoneResolver.ensureInitialized();

    final settings = ref.read(settingsDaoProvider);
    final savedLat = await settings.get('latitude');
    final savedLng = await settings.get('longitude');
    final savedTz = await settings.get('timezone');

    if (savedTz != null) {
      TimezoneResolver.setLocalTimezone(savedTz);
    }

    // تحديث إذا مضى أكثر من ساعة أو لا يوجد موقع محفوظ
    final lastUpdateStr = await settings.get('lastLocationUpdate');
    final lastUpdate = lastUpdateStr != null
        ? DateTime.tryParse(lastUpdateStr)
        : null;
    final needsUpdate =
        lastUpdate == null ||
        DateTime.now().difference(lastUpdate).inHours >= 1;

    if (needsUpdate || savedLat == null) {
      await refreshLocation(ref);
    } else {
      // استخدم المحفوظ وجدول الإشعارات
      final lat = double.tryParse(savedLat) ?? 36.7;
      final lng = double.tryParse(savedLng ?? '') ?? 3.0;
      await _scheduleForLocation(ref, lat, lng);
    }

    scheduleMidnightReschedule(ref);
  }

  /// طلب وتحديث الموقع بتجربة مستخدم مثالية تشمل معالجة التعطيل والأذونات
  static Future<LocationResult> requestAndUpdateLocation(
    BuildContext context,
    dynamic ref, {
    bool showFeedbackSnackBar = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // 1. التحقق من تفعيل خدمة تحديد الموقع (GPS)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return LocationResult.serviceDisabled;

      final shouldOpen = await showEnableGpsDialog(context);
      if (shouldOpen) {
        await Geolocator.openLocationSettings();

        // فحص دوري خفيف عند عودة المستخدم من الإعدادات
        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!context.mounted) break;
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) break;
        }
      }

      if (!serviceEnabled) {
        if (context.mounted && showFeedbackSnackBar) {
          _showLocationSnackBar(
            context,
            message: l10n.locationResultServiceDisabled,
            isSuccess: false,
            actionLabel: l10n.locationEnableAction,
            onAction: () => Geolocator.openLocationSettings(),
          );
        }
        return LocationResult.serviceDisabled;
      }
    }

    // 2. التحقق من إذن الوصول للموقع
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted && showFeedbackSnackBar) {
          _showLocationSnackBar(
            context,
            message: l10n.locationResultPermissionDenied,
            isSuccess: false,
          );
        }
        return LocationResult.permissionDenied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return LocationResult.permissionDeniedForever;

      final shouldOpen = await showPermissionSettingsDialog(context);
      if (shouldOpen) {
        await Geolocator.openAppSettings();

        for (int i = 0; i < 20; i++) {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!context.mounted) break;
          final p = await Geolocator.checkPermission();
          if (p == LocationPermission.always ||
              p == LocationPermission.whileInUse) {
            permission = p;
            break;
          }
        }
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (context.mounted && showFeedbackSnackBar) {
          _showLocationSnackBar(
            context,
            message: l10n.locationResultPermissionDeniedForever,
            isSuccess: false,
            actionLabel: isArabic ? 'الإعدادات' : 'Settings',
            onAction: () => Geolocator.openAppSettings(),
          );
        }
        return LocationResult.permissionDeniedForever;
      }
    }

    // 3. تحديث الموقع وحساب الأوقات
    final result = await refreshLocation(ref);

    if (!context.mounted) return result;

    if (showFeedbackSnackBar) {
      if (result == LocationResult.cachedLocation) {
        // GPS لم يجد إشارة جديدة لكن الإحداثيات المخزّنة تعمل بدقة — نُظهر نجاح استخدام الموقع المحفوظ
        final settings = ref.read(settingsDaoProvider);
        final city = await settings.get('cityName');
        if (!context.mounted) return result;
        final cachedMsg = (city != null && city.isNotEmpty)
            ? (isArabic
                ? 'تم استخدام الموقع المحفوظ: $city'
                : 'Using saved location: $city')
            : l10n.locationResultCachedLocation;

        _showLocationSnackBar(
          context,
          message: cachedMsg,
          isSuccess: true,
          actionLabel: isArabic ? 'اختيار يدوي' : 'Choose manually',
          onAction: () => LocationPickerSheet.show(context),
        );
      } else if (result.isSuccess) {
        HapticFeedback.lightImpact();
        final settings = ref.read(settingsDaoProvider);
        final city = await settings.get('cityName');
        if (!context.mounted) return result;
        final successMsg = (city != null && city.isNotEmpty)
            ? (isArabic
                  ? 'تم تحديث الموقع بنجاح: $city ✓'
                  : 'Location updated: $city ✓')
            : l10n.locationResultSuccess;

        _showLocationSnackBar(context, message: successMsg, isSuccess: true);
      } else if (result == LocationResult.error) {
        // A blind retry here just repeats the exact same GPS/network fix
        // that already failed (often: no fix at all indoors, and no cached
        // coordinates yet on a fresh install) — offering it as the only way
        // forward left the user stuck retrying the same failure with no
        // escape. Open the manual location picker instead, which itself has
        // an "auto-detect" retry option *plus* a curated city list, so
        // nothing is lost versus the old retry-only action.
        _showLocationSnackBar(
          context,
          message: result.message(l10n),
          isSuccess: false,
          actionLabel: isArabic ? 'اختيار يدوي' : 'Choose manually',
          onAction: () => LocationPickerSheet.show(context),
        );
      } else {
        _showLocationSnackBar(
          context,
          message: result.message(l10n),
          isSuccess: false,
          actionLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
          onAction: () => requestAndUpdateLocation(
            context,
            ref,
            showFeedbackSnackBar: showFeedbackSnackBar,
          ),
        );
      }
    }

    return result;
  }

  /// نافذة حوار راقية لتفعيل الـ GPS
  static Future<bool> showEnableGpsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: ctx.colors.border),
        ),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ctx.colors.gold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_off_rounded,
            color: ctx.colors.gold,
            size: 28,
          ),
        ),
        title: Text(
          isArabic ? 'تفعيل خدمة تحديد الموقع' : 'Enable Location Services',
          textAlign: TextAlign.center,
          style: ctx.typography.headingMedium.copyWith(
            fontSize: 18,
            color: ctx.colors.textPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'خدمة تحديد الموقع (GPS) مغلقة على هاتفك. يُرجى تفعيلها ليتمكن تطبيق تقوى من معرفة موقعك بدقة وحساب أوقات الصلاة واتجاه القبلة.'
              : 'GPS is disabled on your device. Please enable it so Takwa can determine your location and calculate accurate prayer times.',
          textAlign: TextAlign.center,
          style: ctx.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: ctx.colors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ctx.colors.textSecondary,
                    side: BorderSide(color: ctx.colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l10n?.commonCancel ?? (isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctx.colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    isArabic ? 'تفعيل الموقع' : 'Enable GPS',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// نافذة حوار راقية لفتح إعدادات إذن الموقع
  static Future<bool> showPermissionSettingsDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: ctx.colors.border),
        ),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ctx.colors.danger.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_disabled_rounded,
            color: ctx.colors.danger,
            size: 28,
          ),
        ),
        title: Text(
          isArabic ? 'إذن الموقع مطلوب' : 'Location Permission Required',
          textAlign: TextAlign.center,
          style: ctx.typography.headingMedium.copyWith(
            fontSize: 18,
            color: ctx.colors.textPrimary,
          ),
        ),
        content: Text(
          isArabic
              ? 'تم رفض إذن تحديد الموقع لتطبيق تقوى. يُرجى تفعيل الإذن من إعدادات التطبيق لتتمكن من تحديث موقعك ومواقيت الصلاة.'
              : 'Location permission is disabled for Takwa. Please enable it in App Settings to update your location and prayer times.',
          textAlign: TextAlign.center,
          style: ctx.typography.bodyMedium.copyWith(
            fontSize: 13,
            color: ctx.colors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ctx.colors.textSecondary,
                    side: BorderSide(color: ctx.colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l10n?.commonCancel ?? (isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctx.colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    isArabic ? 'فتح الإعدادات' : 'Open Settings',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void _showLocationSnackBar(
    BuildContext context, {
    required String message,
    required bool isSuccess,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        backgroundColor: isSuccess
            ? context.colors.success
            : context.colors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isSuccess ? 3 : 5),
      ),
    );
  }

  /// تحديث الموقع يدوياً مع أقصى قدر من المرونة للأجهزة الحقيقية
  static Future<LocationResult> refreshLocation(dynamic ref) async {
    final Geocoding geocoding = Geocoding();

    try {
      // تحقق من تفعيل الخدمة
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final fallback = await _fallbackToCachedCoordinates(ref);
        if (fallback != null) return fallback;
        return LocationResult.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final fallback = await _fallbackToCachedCoordinates(ref);
          if (fallback != null) return fallback;
          return LocationResult.permissionDenied;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        final fallback = await _fallbackToCachedCoordinates(ref);
        if (fallback != null) return fallback;
        return LocationResult.permissionDeniedForever;
      }

      // الحصول على الموقع (مع آليات استباقية واحتياطية لتفادي أخطاء الأماكن المغلقة)
      //
      // ملاحظة مهمة: على تثبيت جديد تماماً للتطبيق (مثل APK الإصدار الذي
      // يُثبّت لأول مرة على جهاز حقيقي) لا توجد أي إحداثيات مخزّنة بعد،
      // لذا فشل أول محاولة GPS (شائع جداً داخل المباني عند أول إصلاح بارد)
      // يؤدي مباشرة لخطأ صريح دون أي شبكة أمان — بعكس بيئة التطوير حيث تكون
      // هناك إحداثيات محفوظة من جلسات سابقة تُستخدم كبديل صامت. لتفادي هذا
      // نُجرّب أولاً الموقع الأخير المعروف (فوري) ثم إصلاحاً سريعاً منخفض
      // الدقة (يعتمد على الشبكة/الواي فاي ويعمل عادة داخل المباني) قبل
      // الانتقال إلى إصلاح GPS أدق وأطول انتظاراً.
      Position? pos = await Geolocator.getLastKnownPosition();

      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 6),
            ),
          );
        } catch (e) {
          debugPrint('[LocationPrayerManager] low-accuracy fix failed: $e');
        }
      }

      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15),
            ),
          );
        } catch (e) {
          debugPrint(
            '[LocationPrayerManager] medium-accuracy fix failed: $e',
          );
        }
      }

      // A genuinely cold GPS fix (no A-GPS assistance data yet, e.g. right
      // after a fresh install) can legitimately take longer than the 6+15=21s
      // budget above, especially indoors with no Wi-Fi/network-based fix
      // available either. One last, more patient attempt before giving up —
      // still bounded, so a device with location truly unavailable doesn't
      // hang indefinitely.
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 25),
            ),
          );
        } catch (e) {
          debugPrint(
            '[LocationPrayerManager] high-accuracy fix failed: $e',
          );
        }
      }

      // إذا فشل الـ GPS تماماً، نحاول استخدام الإحداثيات المحفوظة مسبقاً
      if (pos == null) {
        final fallback = await _fallbackToCachedCoordinates(ref);
        if (fallback != null) return fallback;
        return LocationResult.error;
      }

      final lat = pos.latitude;
      final lng = pos.longitude;

      // حل الـ timezone
      final tzName = TimezoneResolver.resolveFromCoordinates(lat, lng);
      TimezoneResolver.setLocalTimezone(tzName);

      // حل اسم المدينة (Reverse Geocoding)
      final settings = ref.read(settingsDaoProvider);
      final unknownCity = lookupAppLocalizations(
        const Locale('ar'),
      ).overlayServiceUnknownCity;
      String cityName = '';
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final locality = (p.locality != null && p.locality!.trim().isNotEmpty)
              ? p.locality!.trim()
              : (p.subAdministrativeArea != null &&
                    p.subAdministrativeArea!.trim().isNotEmpty)
              ? p.subAdministrativeArea!.trim()
              : (p.administrativeArea != null &&
                    p.administrativeArea!.trim().isNotEmpty)
              ? p.administrativeArea!.trim()
              : '';
          final country = p.country?.trim() ?? '';
          if (locality.isNotEmpty && country.isNotEmpty) {
            cityName = '$locality, $country';
          } else if (locality.isNotEmpty) {
            cityName = locality;
          } else {
            cityName = country;
          }
        }
      } catch (_) {}

      if (cityName.isEmpty) {
        final savedCity = await settings.get('cityName');
        cityName = (savedCity != null && savedCity.isNotEmpty)
            ? savedCity
            : unknownCity;
      }

      // حفظ في الإعدادات
      await settings.set('latitude', lat.toString());
      await settings.set('longitude', lng.toString());
      await settings.set('timezone', tzName);
      await settings.set('cityName', cityName);
      await settings.set(
        'lastLocationUpdate',
        DateTime.now().toIso8601String(),
      );

      // إعادة تقييم موفر أوقات الصلاة فوراً لتحديث الواجهات
      ref.invalidate(prayerTimesProvider);

      // جدولة الإشعارات بالموقع الجديد (فشل الجدولة لا يجب أن يُفشل نجاح تحديد الموقع)
      try {
        await _scheduleForLocation(ref, lat, lng);
      } catch (e) {
        debugPrint('[LocationPrayerManager] notification scheduling failed: $e');
      }

      return LocationResult.success;
    } on LocationServiceDisabledException catch (e) {
      debugPrint('[LocationPrayerManager] service disabled: $e');
      final fallback = await _fallbackToCachedCoordinates(ref);
      return fallback ?? LocationResult.serviceDisabled;
    } on PermissionDeniedException catch (e) {
      debugPrint('[LocationPrayerManager] permission denied: $e');
      final fallback = await _fallbackToCachedCoordinates(ref);
      return fallback ?? LocationResult.permissionDenied;
    } catch (e, st) {
      // مهم: كانت هذه الاستثناءات تُبتلع بصمت تام سابقاً، مما جعل تشخيص
      // فشل الموقع في بنية الإصدار (release/minified) على جهاز حقيقي
      // مستحيلاً. الآن تظهر في adb logcat لتشخيص أي مشكلة مشابهة لاحقاً.
      debugPrint('[LocationPrayerManager] refreshLocation failed: $e\n$st');
      final fallback = await _fallbackToCachedCoordinates(ref);
      return fallback ?? LocationResult.error;
    }
  }

  /// تعيين الموقع يدوياً لمدينة محددة وتحديث أوقات الصلاة والإشعارات
  static Future<void> setManualLocation(
    dynamic ref, {
    required double latitude,
    required double longitude,
    required String timezone,
    required String cityName,
  }) async {
    final settings = ref.read(settingsDaoProvider);
    await settings.set('latitude', latitude.toString());
    await settings.set('longitude', longitude.toString());
    await settings.set('timezone', timezone);
    await settings.set('cityName', cityName);
    await settings.set(
      'lastLocationUpdate',
      DateTime.now().toIso8601String(),
    );

    TimezoneResolver.setLocalTimezone(timezone);
    ref.invalidate(prayerTimesProvider);
    try {
      await _scheduleForLocation(ref, latitude, longitude);
    } catch (e) {
      debugPrint('[LocationPrayerManager] setManualLocation schedule failed: $e');
    }
  }

  /// محاولة استخدام الإحداثيات المحفوظة مسبقاً لحساب أوقات الصلاة في حال تعذر GPS
  static Future<LocationResult?> _fallbackToCachedCoordinates(
    dynamic ref,
  ) async {
    try {
      final settings = ref.read(settingsDaoProvider);
      final cachedLat = await settings.get('latitude');
      final cachedLng = await settings.get('longitude');
      final cachedTz = await settings.get('timezone');
      if (cachedLat != null && cachedLng != null) {
        final lat = double.tryParse(cachedLat);
        final lng = double.tryParse(cachedLng);
        if (lat != null && lng != null) {
          if (cachedTz != null && cachedTz.isNotEmpty) {
            TimezoneResolver.setLocalTimezone(cachedTz);
          }
          ref.invalidate(prayerTimesProvider);
          try {
            await _scheduleForLocation(ref, lat, lng);
          } catch (e) {
            debugPrint('[LocationPrayerManager] _scheduleForLocation in fallback failed: $e');
          }
          return LocationResult.cachedLocation;
        }
      }
    } catch (e) {
      // Previously swallowed with no trace at all — if this genuinely has
      // cached coordinates and still fails here, it was invisible even in
      // logcat. Now at least diagnosable.
      debugPrint('[LocationPrayerManager] _fallbackToCachedCoordinates failed: $e');
    }
    return null;
  }

  /// جدولة إشعارات الصلاة لموقع محدد
  static Future<void> _scheduleForLocation(
    dynamic ref,
    double lat,
    double lng,
  ) async {
    try {
      final prefs = await ref.read(userPreferencesProvider.future);

      if (!prefs.prayerReminder) return;

      // حساب الأوقات بالـ timezone الصحيح والمعاملات الكاملة الموحدة
      final prayers = await PrayerTimesService.calculate(
        latitude: lat,
        longitude: lng,
        madhab: prefs.madhab,
        method: prefs.calcMethod,
        highLatitudeRule: prefs.highLatitudeRule,
        fajrOffset: prefs.fajrOffset,
        sunriseOffset: prefs.sunriseOffset,
        dhuhrOffset: prefs.dhuhrOffset,
        asrOffset: prefs.asrOffset,
        maghribOffset: prefs.maghribOffset,
        ishaOffset: prefs.ishaOffset,
      );

      await NotificationsService.schedulePrayerNotifications(
        prayers: prayers,
        l10n: lookupAppLocalizations(ref.read(localeProvider)),
        preAdhanEnabled: prefs.preAdhanNotif,
        iqamaEnabled: prefs.iqamaNotif,
        adhanMode: prefs.adhanMode,
        adhanScreenEnabled: prefs.adhanScreenEnabled,
      );
    } catch (e, st) {
      debugPrint('[LocationPrayerManager] _scheduleForLocation failed: $e\n$st');
    }
  }

  /// إعادة الجدولة عند منتصف الليل (لليوم الجديد)
  static Future<void> scheduleMidnightReschedule(dynamic ref) async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);

    Future.delayed(diff, () async {
      await refreshLocation(ref);
      // إعادة الجدولة كل يوم
      scheduleMidnightReschedule(ref);
    });
  }
}

class PrayerTimesWithTimezone {
  /// حساب الأوقات مع مراعاة الـ timezone المحلي والتحويل الدقيق
  static Future<List<PrayerTimeInfo>> calculate({
    required double latitude,
    required double longitude,
    required String madhab,
    required String method,
    String? highLatitudeRule,
    int fajrOffset = 0,
    int sunriseOffset = 0,
    int dhuhrOffset = 0,
    int asrOffset = 0,
    int maghribOffset = 0,
    int ishaOffset = 0,
    DateTime? date,
    String? timezone,
  }) {
    return PrayerTimesService.calculate(
      latitude: latitude,
      longitude: longitude,
      madhab: madhab,
      method: method,
      highLatitudeRule: highLatitudeRule,
      fajrOffset: fajrOffset,
      sunriseOffset: sunriseOffset,
      dhuhrOffset: dhuhrOffset,
      asrOffset: asrOffset,
      maghribOffset: maghribOffset,
      ishaOffset: ishaOffset,
      date: date,
      timezone: timezone,
    );
  }

  /// اسم الـ timezone المترجم لواجهة المستخدم
  static String timezoneDisplayName(AppLocalizations l10n, String tzName) {
    final map = {
      'Africa/Algiers': l10n.timezoneAlgiers,
      'Africa/Tunis': l10n.timezoneTunis,
      'Africa/Cairo': l10n.timezoneEgypt,
      'Asia/Riyadh': l10n.timezoneRiyadh,
      'Asia/Dubai': l10n.timezoneDubai,
      'Asia/Kuwait': l10n.timezoneKuwait,
      'Asia/Beirut': l10n.timezoneBeirut,
      'Asia/Jerusalem': l10n.timezoneJerusalem,
    };
    return map[tzName] ?? tzName;
  }
}

enum LocationResult {
  success,

  /// GPS فشل لكن تم استخدام الإحداثيات المخزّنة مسبقاً — النتيجة مقبولة
  cachedLocation,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error;

  String message(AppLocalizations l10n) => switch (this) {
    LocationResult.success => l10n.locationResultSuccess,
    LocationResult.cachedLocation => l10n.locationResultCachedLocation,
    LocationResult.serviceDisabled => l10n.locationResultServiceDisabled,
    LocationResult.permissionDenied => l10n.locationResultPermissionDenied,
    LocationResult.permissionDeniedForever =>
      l10n.locationResultPermissionDeniedForever,
    LocationResult.error => l10n.locationResultError,
  };

  bool get isSuccess =>
      this == LocationResult.success || this == LocationResult.cachedLocation;
}

class LocationUpdateTile extends ConsumerStatefulWidget {
  const LocationUpdateTile({super.key});

  @override
  ConsumerState<LocationUpdateTile> createState() => _LocationUpdateTileState();
}

class _LocationUpdateTileState extends ConsumerState<LocationUpdateTile> {
  bool _loading = false;
  String? _lastCity;
  String? _lastTimezone;
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      _loadSaved();
    }
  }

  Future<void> _loadSaved() async {
    final s = ref.read(settingsDaoProvider);
    final l10n = AppLocalizations.of(context)!;
    final city = await s.get('cityName') ?? l10n.overlayServiceUnknownCity;
    final tz = await s.get('timezone') ?? '';
    final tzDisplay = tz.isNotEmpty
        ? PrayerTimesWithTimezone.timezoneDisplayName(l10n, tz)
        : null;

    if (mounted) {
      setState(() {
        _lastCity = city;
        _lastTimezone = tzDisplay;
      });
    }
  }

  Future<void> _update() async {
    setState(() => _loading = true);
    final result = await LocationPrayerManager.requestAndUpdateLocation(
      context,
      ref,
    );
    setState(() => _loading = false);

    if (result.isSuccess) _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _loading ? null : _update,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: TakwaLoadingIndicator(
                          color: context.colors.teal,
                          strokeWidth: 2,
                          size: 18,
                        ),
                      )
                    : const Text('📍', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.locationUpdateTileLabel,
                    style: TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (_lastCity != null)
                    Text(
                      '$_lastCity${_lastTimezone != null ? " · $_lastTimezone" : ""}',
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 10,
                        color: context.colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.refresh_rounded,
              size: 18,
              color: context.colors.teal.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
