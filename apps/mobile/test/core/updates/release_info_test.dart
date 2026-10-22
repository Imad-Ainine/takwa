import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/updates/release_info.dart';

/// The manifest `/api/releases/latest` actually serves today. Kept verbatim
/// (minus the keys ReleaseInfo ignores) because this whole feature is gated on
/// parsing it: a rename here silently disables in-app updates.
const _livePayload = <String, dynamic>{
  'version': '1.8.9',
  'apkUrl':
      'https://github.com/Imad-Ainine/takwa/releases/download/v1.8.9/takwa-v1.8.9.apk',
  'size': '207.17 MB',
  'sizeBytes': 217232043,
  'sha256': 'ce8a93cb743a245c995a9ae67987cd5bca5d4c4bcc8fb154ec03723007d6edd2',
  'releasedAt': '2026-10-10T19:33:40Z',
};

void main() {
  group('ReleaseInfo.tryParse', () {
    test('reads the live manifest shape', () {
      final release = ReleaseInfo.tryParse(_livePayload);
      expect(release, isNotNull);
      expect(release!.version, '1.8.9');
      expect(release.sizeBytes, 217232043);
      expect(release.sha256.length, 64);
      expect(release.filename, 'takwa-v1.8.9.apk');
      expect(release.apkUri.path, endsWith('takwa-v1.8.9.apk'));
    });

    test('refuses a payload with no version', () {
      expect(
        ReleaseInfo.tryParse({'apkUrl': 'https://x.test/a.apk'}),
        isNull,
      );
    });

    test('refuses a payload with no download URL', () {
      // Without this the sheet would render an install button with nothing to
      // download, and the failure would land on the user's mobile data.
      expect(ReleaseInfo.tryParse({'version': '1.9.0'}), isNull);
    });

    test('treats blank strings as absent', () {
      expect(
        ReleaseInfo.tryParse({'version': '  ', 'apkUrl': 'https://x.test/a.apk'}),
        isNull,
      );
    });

    test('still parses when the checksum is missing', () {
      // Older releases predate checksum publishing; the installer then falls
      // back to the byte count rather than refusing to download.
      final release = ReleaseInfo.tryParse({
        'version': '1.2.0',
        'apkUrl': 'https://x.test/takwa-v1.2.0.apk',
      });
      expect(release, isNotNull);
      expect(release!.sha256, isEmpty);
      expect(release.sizeBytes, 0);
    });
  });
}
