import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:takwa/l10n/app_localizations.dart';

class Mosque {
  final int id;
  final String name;
  final double lat;
  final double lon;
  final double distance;
  final String address;
  final String phone;

  Mosque({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.distance,
    required this.address,
    this.phone = '',
  });
}

class MosqueRepository {
  static const List<String> _overpassUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  Future<List<Mosque>> fetchNearbyMosques(
    Position position, {
    double radius = 5000,
    required AppLocalizations l10n,
  }) async {
    // Failsafe: Prevent querying the ocean if GPS defaults to 0.0
    if (position.latitude == 0 && position.longitude == 0) {
      return [];
    }

    // Broadened query to catch all variations of mosque tags in OpenStreetMap
    final query =
        '''
      [out:json][timeout:25];
      (
        nwr["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${position.latitude},${position.longitude});
        nwr["amenity"="mosque"](around:$radius,${position.latitude},${position.longitude});
        nwr["building"="mosque"](around:$radius,${position.latitude},${position.longitude});
      );
      out center;
    ''';

    for (final url in _overpassUrls) {
      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                // Overpass often drops anonymous requests. Always provide a User-Agent.
                'User-Agent': 'Takwa_App_Flutter/1.0',
              },
              body: 'data=${Uri.encodeQueryComponent(query)}',
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final decoded = json.decode(utf8.decode(response.bodyBytes));
          final elements = decoded['elements'] as List;

          List<Mosque> mosques = elements
              .map<Mosque?>((e) {
                final lat = e['lat'] ?? e['center']?['lat'];
                final lon = e['lon'] ?? e['center']?['lon'];

                if (lat == null || lon == null) return null;

                final tags = e['tags'] ?? {};
                final name =
                    tags['name'] ?? tags['name:ar'] ?? l10n.mosqueDefaultName;
                final address =
                    tags['addr:full'] ??
                    tags['addr:street'] ??
                    l10n.mosqueDefaultAddress;
                final phone = tags['contact:phone'] ?? tags['phone'] ?? '';

                final distance = Geolocator.distanceBetween(
                  position.latitude,
                  position.longitude,
                  lat,
                  lon,
                );

                return Mosque(
                  id: e['id'],
                  name: name,
                  lat: lat,
                  lon: lon,
                  distance: distance,
                  address: address,
                  phone: phone,
                );
              })
              .whereType<Mosque>()
              .toList();

          mosques.sort((a, b) => a.distance.compareTo(b.distance));
          return mosques;
        }
      } catch (e) {
        // Silently skip to the next mirror if one fails
        continue;
      }
    }

    throw Exception(l10n.mosqueFetchError);
  }
}
