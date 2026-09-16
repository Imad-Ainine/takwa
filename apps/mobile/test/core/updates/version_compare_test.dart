import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/updates/version_compare.dart';

void main() {
  group('isNewerVersion', () {
    test('detects a patch bump', () {
      expect(isNewerVersion('1.4.9', '1.4.8'), isTrue);
    });

    test('detects a minor rollover (matches the app\'s own bump scheme)', () {
      expect(isNewerVersion('1.5.0', '1.4.9'), isTrue);
    });

    test('is false for the same version', () {
      expect(isNewerVersion('1.5.0', '1.5.0'), isFalse);
    });

    test('is false for an older version', () {
      expect(isNewerVersion('1.4.8', '1.5.0'), isFalse);
    });

    test('compares numerically, not lexicographically', () {
      // A plain string compare would get this backwards.
      expect(isNewerVersion('1.10.0', '1.9.0'), isTrue);
    });

    test('handles a missing/malformed version defensively', () {
      expect(isNewerVersion('', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0', ''), isTrue);
    });
  });
}
