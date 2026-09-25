import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:takwa/core/database/daos.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:takwa/core/updates/version_compare.dart';
import 'package:takwa/core/utils/app_logger.dart';
import 'package:takwa/l10n/app_localizations.dart';

/// Where a user lands after tapping the "new release" notification. Keep
/// this in sync with the CI-side push notification payload's `url` field
/// in .github/workflows/release-apk.yml (search for "release_update") —
/// there is no single source of truth shareable between Dart and YAML
/// across this monorepo, so both were set by hand to the same value.
const String kReleaseDownloadUrl = 'https://takwa-web.vercel.app/#download';

/// The JSON behind that page, served by apps/web's route handler
/// (`src/app/api/releases/latest/route.ts`) as `{version, apkUrl, …}`. This
/// used to point at github.com/…/releases/latest, which is an HTML page that
/// answers 200 — so `jsonDecode` threw on `<!DOCTYPE html>` and the check
/// never ran.
const String _kLatestReleaseUrl =
    'https://takwa-web.vercel.app/api/releases/latest';

const String _kLastNotifiedVersionKey = 'last_notified_release_version';

/// The "works today, no external service" half of
/// docs/specs/release-push-notifications.md: checks the public
/// `/api/releases/latest` endpoint once per app launch and shows a local
/// notification if a newer version exists. Reaches only users who actually
/// open the app — PushNotificationService is the real-push counterpart for
/// reaching everyone, once a Firebase project is configured.
class UpdateCheckService {
  final SettingsDao _settingsDao;
  final http.Client _client;

  UpdateCheckService(this._settingsDao, {http.Client? client})
    : _client = client ?? http.Client();

  Future<void> checkForUpdate() async {
    try {
      // Fetched fresh here rather than accepted as a parameter/read from a
      // provider — PackageInfo's own provider (appVersionProvider) starts
      // at a hardcoded placeholder until its async init resolves, and this
      // runs right at app launch, exactly when that race is most likely.
      final installedVersion = (await PackageInfo.fromPlatform()).version;

      final response = await _client
          .get(Uri.parse(_kLatestReleaseUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = body['version'] as String?;
      if (latestVersion == null || latestVersion.isEmpty) return;

      if (!isNewerVersion(latestVersion, installedVersion)) return;

      final alreadyNotified = await _settingsDao.get(_kLastNotifiedVersionKey);
      if (alreadyNotified == latestVersion) return;

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await NotificationsService.showNotification(
        id: NotifIds.appUpdate,
        title: l10n.updateAvailableNotifTitle,
        body: l10n.updateAvailableNotifBody(latestVersion),
        payload: 'release_update:$kReleaseDownloadUrl',
        channel: NotifChannels.appUpdates,
      );
      await _settingsDao.set(_kLastNotifiedVersionKey, latestVersion);
    } catch (e, st) {
      // Never let a flaky network call disrupt app startup — this is a
      // best-effort courtesy check, not a critical path.
      AppLogger.warning('Update check failed', e, st);
    }
  }
}
