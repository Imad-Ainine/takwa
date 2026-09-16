import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoData {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const AppInfoData({
    this.appName = 'Takwa',
    this.packageName = 'com.takwa',
    this.version = '1.0.5',
    this.buildNumber = '1',
  });

  String get formattedVersion => 'v$version';
}

class AppInfoNotifier extends StateNotifier<AppInfoData> {
  AppInfoNotifier() : super(const AppInfoData()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        state = AppInfoData(
          appName: info.appName.isNotEmpty ? info.appName : state.appName,
          packageName:
              info.packageName.isNotEmpty ? info.packageName : state.packageName,
          version: info.version,
          buildNumber:
              info.buildNumber.isNotEmpty ? info.buildNumber : state.buildNumber,
        );
      }
    } catch (_) {
      // Platform channels may not be available during testing or headless execution.
    }
  }
}

final appInfoProvider =
    StateNotifierProvider<AppInfoNotifier, AppInfoData>((ref) {
  return AppInfoNotifier();
});

final appVersionProvider = Provider<String>((ref) {
  return ref.watch(appInfoProvider).version;
});
