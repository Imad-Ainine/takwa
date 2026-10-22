/// One published Android build, as described by apps/web's
/// `/api/releases/latest` route (which reads Supabase's `manifest.json`).
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.apkUrl,
    required this.sha256,
    required this.sizeBytes,
  });

  /// Returns null unless the payload carries both a version and a URL. A
  /// half-populated manifest must not render an install button that has
  /// nothing to download.
  static ReleaseInfo? tryParse(Map<String, dynamic> json) {
    final version = '${json['version'] ?? ''}'.trim();
    final apkUrl = '${json['apkUrl'] ?? ''}'.trim();
    if (version.isEmpty || apkUrl.isEmpty) return null;
    return ReleaseInfo(
      version: version,
      apkUrl: apkUrl,
      sha256: '${json['sha256'] ?? ''}'.trim(),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }

  final String version;
  final String apkUrl;

  /// Empty when the release predates checksum publishing — the installer then
  /// falls back to comparing the byte count alone.
  final String sha256;

  /// 0 when the manifest omitted it.
  final int sizeBytes;

  Uri get apkUri => Uri.parse(apkUrl);

  String get filename => 'takwa-v$version.apk';
}
