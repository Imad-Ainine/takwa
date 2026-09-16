/// Compares two dotted version strings (e.g. "1.4.9" vs "1.5.0") part by
/// part as integers — a plain string compare gets multi-digit parts wrong
/// ("1.10.0" < "1.9.0" lexicographically, but not numerically), and this
/// app's own version scheme (see .github/workflows/auto-version-bump.yml)
/// keeps parts single-digit anyway, so this only needs to be correct, not
/// handle arbitrary semver extras (pre-release tags, build metadata).
///
/// Returns a positive number if [a] > [b], negative if [a] < [b], 0 if equal.
int compareVersions(String a, String b) {
  final partsA = _parts(a);
  final partsB = _parts(b);
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < length; i++) {
    final va = i < partsA.length ? partsA[i] : 0;
    final vb = i < partsB.length ? partsB[i] : 0;
    if (va != vb) return va - vb;
  }
  return 0;
}

bool isNewerVersion(String candidate, String current) =>
    compareVersions(candidate, current) > 0;

List<int> _parts(String version) => version
    .split('.')
    .map((p) => int.tryParse(p.trim()) ?? 0)
    .toList();
