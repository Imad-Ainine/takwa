import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Converts a URL into a safe flat filename,
/// e.g. "https://…supabase.co/storage/v1/object/public/book-pdfs/file.pdf"
/// → "…supabase.co_storage_v1_object_public_book-pdfs_file.pdf"
String _urlToFilename(String url) {
  try {
    final uri = Uri.parse(url);
    // host + path segments joined by underscore, drop leading slash
    final slug = '${uri.host}${uri.path}'
        .replaceAll(RegExp(r'[/\\?#&=]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    // Keep extension
    final ext = p.extension(uri.path);
    if (!slug.endsWith(ext) && ext.isNotEmpty) return '$slug$ext';
    return slug;
  } catch (_) {
    return '${url.hashCode}.pdf';
  }
}

/// Maximum age before a cached PDF is considered stale and re-downloaded.
const _kCacheMaxAge = Duration(days: 7);

/// Number of download attempts before surfacing an error.
const _kMaxRetries = 3;

/// Book PDFs are now served from the app's own Supabase Storage bucket
/// (see the Security & Privacy audit, 2026-09-06) instead of scraped from
/// islamhouse.com, so the spoofed desktop User-Agent/Referer that bypass
/// once needed to get past its anti-bot checks are gone — a plain request
/// is all a public Storage object needs.
const _kHeaders = <String, String>{'Accept': 'application/pdf,*/*;q=0.8'};

/// A singleton-style service that downloads a PDF, caches it on disk, and
/// exposes download progress via an optional [StreamController<double>].
class PdfDownloadService {
  PdfDownloadService._();

  // ── Cache directory (lazy) ─────────────────────────────────────

  static Directory? _cacheDir;

  static Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationCacheDirectory();
    final dir = Directory(p.join(base.path, 'pdf_cache'));
    await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  // ── Public API ─────────────────────────────────────────────────

  /// Returns a local [File] for [url].
  ///
  /// • If a fresh cached file exists → returns it immediately.
  /// • Otherwise → downloads with progress & retry, caches, returns.
  ///
  /// [progressController] receives values from 0.0 (started) to 1.0 (done).
  /// It is NOT closed by this service — the caller owns it.
  static Future<File> getOrDownload(
    String url, {
    StreamController<double>? progressController,
  }) async {
    final cacheDir = await _getCacheDir();
    final filename = _urlToFilename(url);
    final cacheFile = File(p.join(cacheDir.path, filename));

    // Cache hit — check freshness
    if (await cacheFile.exists()) {
      final stat = await cacheFile.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age < _kCacheMaxAge) {
        progressController?.add(1.0);
        return cacheFile;
      }
    }

    // Download with retries
    Exception? lastError;
    for (int attempt = 1; attempt <= _kMaxRetries; attempt++) {
      try {
        final file = await _download(
          url,
          cacheFile,
          progressController: progressController,
        );
        return file;
      } on Exception catch (e) {
        lastError = e;
        if (attempt < _kMaxRetries) {
          // Exponential back-off: 1s, 2s, 4s
          await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
        }
      }
    }
    throw lastError ?? Exception('Unknown error downloading PDF');
  }

  // ── Internal download ──────────────────────────────────────────

  static Future<File> _download(
    String url,
    File destination, {
    StreamController<double>? progressController,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(_kHeaders);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode} for $url');
      }

      final total = response.contentLength ?? -1;
      int received = 0;

      // Write to a temp file first to prevent corrupt partial writes
      final tmpFile = File('${destination.path}.tmp');
      final sink = tmpFile.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0 && progressController != null) {
            progressController.add((received / total).clamp(0.0, 1.0));
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // Atomic rename
      await tmpFile.rename(destination.path);
      progressController?.add(1.0);
      return destination;
    } finally {
      client.close();
    }
  }

  // ── Cache management ───────────────────────────────────────────

  /// Delete the cached file for [url] (forces re-download next time).
  static Future<void> invalidate(String url) async {
    final cacheDir = await _getCacheDir();
    final filename = _urlToFilename(url);
    final cacheFile = File(p.join(cacheDir.path, filename));
    if (await cacheFile.exists()) await cacheFile.delete();
  }

  /// Clear the entire PDF cache.
  static Future<void> clearAll() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      _cacheDir = null;
    }
  }
}
