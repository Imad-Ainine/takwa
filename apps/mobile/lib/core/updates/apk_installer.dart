import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Why an update could not be handed to the installer. Kept as an enum rather
/// than a message string so the UI owns the wording in every locale.
enum ApkInstallFailure { network, truncated, checksum, noInstaller }

class ApkInstallException implements Exception {
  const ApkInstallException(this.failure);
  final ApkInstallFailure failure;

  @override
  String toString() => 'ApkInstallException: ${failure.name}';
}

/// Downloads a release APK and hands it to the system package installer.
///
/// This is the one place the "tap and it installs" promise is satisfiable: a
/// web page may only launch activities that declare `CATEGORY_BROWSABLE`, and
/// the package installer deliberately does not, so the website can never get
/// past dropping a file in the Downloads folder. A native app holding
/// `REQUEST_INSTALL_PACKAGES` can.
class ApkInstaller {
  ApkInstaller._();

  static const String apkMimeType = 'application/vnd.android.package-archive';

  /// Streams [url] into the cache directory and returns the local path.
  ///
  /// [onProgress] receives a 0..1 fraction, and only when the server actually
  /// sent a content length. The download is deliberately streamed rather than
  /// buffered: a release APK is ~200 MB, which would be enough to kill the
  /// isolate on a low-RAM device.
  static Future<String> download({
    required Uri url,
    required String filename,
    String expectedSha256 = '',
    int expectedSizeBytes = 0,
    void Function(double progress)? onProgress,
  }) async {
    final cache = await getTemporaryDirectory();
    final dir = Directory('${cache.path}/updates');
    await dir.create(recursive: true);

    // A half-written APK from an aborted attempt is the one file shape that
    // must never linger: the installer reports it as a corrupt package, and
    // the user has no way to tell why.
    await for (final stale in dir.list()) {
      if (stale is File) {
        try {
          await stale.delete();
        } catch (_) {
          // A locked sibling is not worth failing an otherwise good update.
        }
      }
    }

    final target = File('${dir.path}/$filename');
    final hasher = expectedSha256.isEmpty ? null : _DigestSink();
    final hashInput = hasher == null
        ? null
        : crypto.sha256.startChunkedConversion(hasher);

    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', url))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw const ApkInstallException(ApkInstallFailure.network);
      }
      final total = response.contentLength ?? 0;

      final sink = target.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          hashInput?.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call(received / total);
        }
      } finally {
        await sink.flush();
        await sink.close();
        hashInput?.close();
      }

      final declaredSize = total > 0 ? total : expectedSizeBytes;
      if (declaredSize > 0 && received != declaredSize) {
        throw const ApkInstallException(ApkInstallFailure.truncated);
      }
      if (hasher?.digest != null &&
          hasher!.digest.toString().toLowerCase() !=
              expectedSha256.toLowerCase()) {
        throw const ApkInstallException(ApkInstallFailure.checksum);
      }

      return target.path;
    } on ApkInstallException {
      await _discard(target);
      rethrow;
    } catch (_) {
      await _discard(target);
      throw const ApkInstallException(ApkInstallFailure.network);
    } finally {
      client.close();
    }
  }

  /// Fires the `ACTION_VIEW` intent that opens the system installer.
  ///
  /// Android prompts for "install unknown apps" for Takwa here if it hasn't
  /// been granted before — that prompt is the system's, not ours, and cannot
  /// be pre-empted from the app.
  static Future<void> launchInstaller(String path) async {
    final result = await OpenFilex.open(path, type: apkMimeType);
    // `open` never returns null; the only success signal is the `done` type.
    if (result.type != ResultType.done) {
      throw const ApkInstallException(ApkInstallFailure.noInstaller);
    }
  }

  static Future<void> _discard(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Nothing useful to do about an undeletable temp file.
    }
  }
}

/// Minimal `Sink<Digest>` so hashing stays incremental — `readAsBytes()` on a
/// 200 MB APK would allocate the whole file in the isolate's heap.
class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;

  @override
  void add(crypto.Digest data) => digest = data;

  @override
  void close() {}
}
