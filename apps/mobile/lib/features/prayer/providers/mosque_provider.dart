import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:takwa/core/providers/locale_provider.dart';
import 'package:takwa/features/prayer/data/mosque_repository.dart';
import 'package:takwa/l10n/app_localizations.dart';

final mosqueRepositoryProvider = Provider<MosqueRepository>((ref) {
  return MosqueRepository();
});

final nearbyMosquesProvider = FutureProvider.autoDispose<List<Mosque>>((
  ref,
) async {
  // No BuildContext is available inside a provider, so the active locale is
  // read via localeProvider and resolved to AppLocalizations directly
  // (same lookupAppLocalizations pattern used for context-free lookups
  // elsewhere, e.g. the background overlay service).
  final locale = ref.watch(localeProvider);
  final l10n = lookupAppLocalizations(locale);

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(l10n.mosqueErrorLocationPermission);
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(l10n.mosqueErrorLocationPermissionForever);
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
    ),
  );
  final repo = ref.read(mosqueRepositoryProvider);
  return repo.fetchNearbyMosques(position, radius: 5000, l10n: l10n);
});
