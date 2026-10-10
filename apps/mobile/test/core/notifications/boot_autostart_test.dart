// Boot-autostart contract tests.
//
// A BOOT_COMPLETED receiver runs with no Flutter engine attached, so the only
// thing it can consult is the flag Dart mirrors into native storage
// (`TakwaBootReceiver.kt` reads it, `MainActivity.kt` writes it). These tests
// pin that hand-off: the value the receiver sees must be the app's own
// ongoing-notification setting, including the string form the SQLite settings
// bridge mirrors, and nothing may be written on platforms that have no such
// receiver.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:takwa/core/notifications/overlay_background_service.dart';

const _channel = MethodChannel('com.takwa/permissions');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  void mockNative({bool armed = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          if (call.method == 'isBootAutostartArmed') return armed;
          return null;
        });
  }

  setUp(() {
    calls = [];
    mockNative();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'mirrors the ongoing-notification setting to the boot receiver',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues({'ongoing_notif_enabled': true});

      await OverlayBackgroundService.syncBootAutostart();

      final mirrored = calls.where((c) => c.method == 'setBootAutostart');
      expect(mirrored, hasLength(1));
      expect(mirrored.first.arguments, isTrue);
    },
  );

  test(
    'a string "false" disarms boot, matching the service start gate',
    () async {
      // `SettingsPrefsBridge.mirror` can store a bool as text, and
      // SharedPreferences' own getBool would then read null (= "on"), so the
      // boot flag has to follow the lenient read the service uses.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues({
        'ongoing_notif_enabled': 'false',
      });

      await OverlayBackgroundService.syncBootAutostart();

      expect(
        calls.lastWhere((c) => c.method == 'setBootAutostart').arguments,
        isFalse,
      );
    },
  );

  test(
    'a missing setting leaves boot armed, the same default start() uses',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await OverlayBackgroundService.syncBootAutostart();

      expect(calls.last.arguments, isTrue);
    },
  );

  test('non-Android platforms never write the flag', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await OverlayBackgroundService.syncBootAutostart();

    expect(calls, isEmpty);
  });

  test('status reports native arming without a live service', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockNative(armed: true);

    final status = await OverlayBackgroundService.autostartStatus();

    expect(status.armed, isTrue);
    // No plugin on the test host; the read must degrade rather than throw.
    expect(status.serviceRunning, isFalse);
  });

  test('status degrades to disarmed when native is unreachable', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          throw PlatformException(code: 'not_found');
        });

    final status = await OverlayBackgroundService.autostartStatus();

    expect(status.armed, isFalse);
    expect(status.serviceRunning, isFalse);
  });
}
