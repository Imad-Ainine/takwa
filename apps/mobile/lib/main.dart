import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:takwa/core/utils/app_logger.dart';
import 'package:takwa/l10n/app_localizations.dart';

import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/notifications/push_notification_service.dart';
import 'package:takwa/core/notifications/adhan_auto_trigger.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/providers/theme_provider.dart';
import 'package:takwa/core/providers/locale_provider.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/providers/shared_preferences_provider.dart';
import 'package:takwa/core/routes/app_routes.dart';
import 'package:takwa/core/supabase/supabase_config.dart';
import 'package:takwa/core/supabase/sync_manager.dart';
import 'package:quran_library/quran_library.dart';
import 'package:takwa/features/quran/data/muyassar_tafsir_loader.dart';
import 'package:takwa/features/quran/data/quran_reciters_setup.dart';

import 'package:takwa/core/notifications/overlay_background_service.dart';
import 'package:takwa/core/notifications/location_prayer_update.dart';
import 'package:takwa/core/notifications/overlays/unified_overlay_window.dart';
import 'package:takwa/core/home_widget/prayer_home_widget_service.dart';
import 'package:takwa/core/home_widget/daily_quote_widget_service.dart';

// ────────────────────────────────────────────
//  OVERLAY ENTRY POINT
// ────────────────────────────────────────────
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    debugPrint('Overlay isolate error: ${details.exceptionAsString()}');
  };
  runApp(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // The overlay only ever renders Arabic religious content (adhan/
        // adhkar strings are Arabic literals regardless of the app's UI
        // language — see AdhkarCategory data), so it doesn't need to read
        // the user's locale setting here; fixed Arabic keeps this isolate
        // simple and matches what it actually displays.
        theme: AppTheme.dark(const Locale('ar')),
        home: const UnifiedOverlayWindow(),
      ),
    ),
  );
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationRouter.route(response.payload ?? '');
}

// ─────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e, st) {
    AppLogger.warning('dotenv.load error', e, st);
  }

  // A no-op (no events sent) until SENTRY_DSN is set in .env — see
  // README.md's "Environment variables" section. Crash/error reporting
  // only: no performance tracing and no default PII, since this app
  // handles religious-practice and location data.
  await SentryFlutter.init((options) {
    options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
    options.tracesSampleRate = 0.0;
    options.sendDefaultPii = false;
    options.environment = kReleaseMode ? 'production' : 'development';
  }, appRunner: _runApp);
}

Future<void> _runApp() async {
  try {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);
  } catch (e, st) {
    AppLogger.warning('DateFormatting error', e, st);
  }

  try {
    await SupabaseConfig.initialize();
  } catch (e, st) {
    AppLogger.error('Supabase initialize error', e, st);
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, st) {
    AppLogger.error('SharedPreferences initialize error', e, st);
  }

  try {
    OverlayBackgroundService.init();
  } catch (e, st) {
    AppLogger.error('OverlayBackgroundService error', e, st);
  }

  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // The system bars are NOT styled here: main() runs before any ThemeData
    // exists, so anything set now is a guess that is wrong in one brightness.
    // TakwaApp.builder below derives the real style from the resolved theme.
  } catch (e, st) {
    AppLogger.warning('SystemChrome error', e, st);
  }

  try {
    await NotificationsService.initialize();
  } catch (e, st) {
    AppLogger.error('NotificationsService initialize error', e, st);
  }

  try {
    // Safe no-op until a Firebase project is configured — see
    // docs/specs/release-push-notifications.md.
    await PushNotificationService.initialize();
  } catch (e, st) {
    AppLogger.warning('PushNotificationService initialize error', e, st);
  }

  try {
    await QuranLibrary.init();
  } catch (e, st) {
    AppLogger.error('QuranLibrary init error', e, st);
  }

  try {
    // Registers "التفسير الميسر" as a selectable tafsir — quran_library
    // doesn't bundle it, so this must run after QuranLibrary.init() (which
    // sets up TafsirCtrl) and before the reader screen can be opened.
    await MuyassarTafsirLoader.register();
  } catch (e, st) {
    AppLogger.warning('Muyassar tafsir registration error', e, st);
  }

  try {
    // Makes the reciter picker's 7 reciters (the app's own list, e.g.
    // Alafasy/Saad Al-Ghamdi/Al-Shatri) actually selectable — quran_library's
    // own reader list is missing 3 of them. Synchronous; just needs to run
    // after QuranLibrary.init() so ReadersConstants exists.
    QuranRecitersSetup.register();
  } catch (e, st) {
    AppLogger.warning('Quran reciters setup error', e, st);
  }

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TakwaApp(),
    ),
  );
}

// ─────────────────────────────────────────
class TakwaApp extends ConsumerStatefulWidget {
  const TakwaApp({super.key});
  @override
  ConsumerState<TakwaApp> createState() => _TakwaAppState();
}

class _TakwaAppState extends ConsumerState<TakwaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FlutterForegroundTask.addTaskDataCallback(_onForegroundData);
    // بدء مراقبة أوقات الصلاة لتشغيل الأذان تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdhanAutoTrigger.start(ref, NotificationRouter.navigatorKey);
      LocationPrayerManager.initialize(ref);
      PrayerHomeWidgetService.init();
      DailyQuoteWidgetService.updateAll(locale: ref.read(localeProvider));
      _setupAuthListener();
      _checkNotificationLaunch();
      _checkForAppUpdate();
    });
  }

  /// See docs/specs/release-push-notifications.md — the "works today, no
  /// Firebase project needed" half of the release-notification feature.
  /// Fire-and-forget: never blocks startup, and any failure (offline,
  /// endpoint down) is swallowed inside the service itself.
  void _checkForAppUpdate() {
    ref.read(updateCheckServiceProvider).checkForUpdate();
  }

  Future<void> _checkNotificationLaunch() async {
    try {
      final response =
          await NotificationsService.getLaunchNotificationResponse();
      if (response != null && response.payload != null) {
        final payload = response.payload!;
        Future.delayed(const Duration(milliseconds: 300), () {
          NotificationRouter.route(payload);
        });
      }
    } catch (e) {
      debugPrint('Launch notification check error: $e');
    }
  }

  void _setupAuthListener() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.passwordRecovery) {
          debugPrint('Auth: Password Recovery mode detected');
          NotificationRouter.navigatorKey.currentState?.pushNamed(
            Routes.updatePassword,
          );
        } else if (event == AuthChangeEvent.signedIn) {
          debugPrint('Auth: User signed in. Triggering fullSync...');
          ref.read(syncManagerProvider).fullSync();
        }
      });
    } catch (e) {
      debugPrint('Auth listener setup error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundData);
    AdhanAutoTrigger.stop();
    super.dispose();
  }

  /// A paused-then-resumed process can have slept through a prayer
  /// transition, a midnight date change, or a device timezone/DST shift —
  /// and the background isolate may have been killed while suspended.
  /// Recompute both sides' prayer lists on resume so the screen countdown
  /// and the ongoing notification re-sync immediately instead of waiting
  /// for the next settings change or midnight refresh.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(prayerTimesProvider);
    ref.invalidate(tomorrowPrayerTimesProvider);
    OverlayBackgroundService.requestPrayerTimesRefresh();
  }

  void _onForegroundData(Object data) {
    if (data is! Map) return;
    final action = data['action'];

    switch (action) {
      case 'show_adhan':
        AdhanAutoTrigger.handleForegroundData(
          data,
          NotificationRouter.navigatorKey,
          ref,
        );
        break;
      case 'refresh_location':
        LocationPrayerManager.refreshLocation(ref);
        break;
      case 'location_updated':
        _syncLocationFromBackground(data);
        break;
    }
  }

  Future<void> _syncLocationFromBackground(Map data) async {
    final lat = data['latitude']?.toString();
    final lng = data['longitude']?.toString();
    final cityName = data['cityName']?.toString();
    if (lat != null && lng != null) {
      final settings = ref.read(settingsDaoProvider);
      await settings.set('latitude', lat);
      await settings.set('longitude', lng);
      if (cityName != null) await settings.set('cityName', cityName);
      // Force prayerTimesProvider to recompute with the new coordinates
      // immediately. The provider already watches settingStreamProvider(
      // 'latitude'/'longitude') reactively, but invalidating guarantees a
      // synchronous rebuild even if the SQLite stream debounces.
      ref.invalidate(prayerTimesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    // Driven by the language switcher in Settings (persisted via
    // localeProvider); defaults to Arabic, matching today's behavior. Also
    // picks the theme's font — Amiri/NotoNaskhArabic for Arabic (unchanged),
    // Poppins for English — see appFontFamily()/appBodyFontFamily().
    final locale = ref.watch(localeProvider);

    // Keep the home-screen prayer widget in step with whichever changed:
    // new prayer times (location/settings) or just the display language.
    // Both listeners resolve the *other* half from `ref.read` so a locale
    // switch alone (no new prayer computation) still refreshes the labels.
    ref.listen(prayerTimesProvider, (_, next) {
      next.whenData(
        (prayers) => PrayerHomeWidgetService.update(
          prayers: prayers,
          locale: ref.read(localeProvider),
        ),
      );
    });
    ref.listen(localeProvider, (_, nextLocale) {
      final prayers = ref.read(prayerTimesProvider).value;
      if (prayers != null) {
        PrayerHomeWidgetService.update(prayers: prayers, locale: nextLocale);
      }
      DailyQuoteWidgetService.updateAll(locale: nextLocale);
    });

    return WithForegroundTask(
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        navigatorKey: NotificationRouter.navigatorKey,
        themeMode: ref.watch(themeModeProvider),
        theme: isRamadan ? RamadanTheme.light(locale) : AppTheme.light(locale),
        darkTheme: isRamadan
            ? RamadanTheme.dark(locale)
            : AppTheme.dark(locale),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        // No manual Directionality override — MaterialApp's own
        // Localizations widget already derives it from `locale:` above
        // (WidgetsLocalizationAr resolves to TextDirection.rtl for 'ar'),
        // so this follows the active locale automatically in both
        // directions as the user switches language.
        initialRoute: Routes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        // Single source of truth for the system bars. Screens must NOT
        // re-assert their own AnnotatedRegion: 16 of them used to hardcode
        // SystemUiOverlayStyle.light, which put white status-bar icons on the
        // near-white light-theme background. Where a screen has an AppBar,
        // appBarTheme.systemOverlayStyle refines this per-screen.
        builder: (context, child) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final surface =
              theme.extension<AppColorsExtension>()?.background ??
              theme.scaffoldBackgroundColor;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              // Android
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              // iOS uses the inverse convention
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: surface,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
