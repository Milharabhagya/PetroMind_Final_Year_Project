import 'dart:convert';
import 'package:http/http.dart' as http;
import 'location_service.dart';
import '../data/repositories/crowd_repository.dart';

class AutoCrowdService {
  static Future<void> autoLogCrowdOnLogin() async {
    try {
      final position =
          await LocationService.getCurrentLocation();
      if (position == null) return;

      final stations = await _getNearbyStations(
        position.latitude,
        position.longitude,
        radiusMeters: 5000,
      );
      if (stations.isEmpty) return;

      final crowdLevel = _estimateCrowdLevel();
      for (final station in stations) {
        await CrowdRepository.logCrowdCount(
          stationId: station['id'] as String,
          crowdCount: crowdLevel,
          stationLat: station['lat'] as double,
          stationLng: station['lng'] as double,
        );
      }
    } catch (e) {
      // Silently fail — crowd logging is non-critical
    }
  }

  static Future<List<Map<String, dynamic>>>
      _getNearbyStations(
    double lat,
    double lng, {
    int radiusMeters = 5000,
  }) async {
    final query = '''
[out:json][timeout:10];
node["amenity"="fuel"](around:$radiusMeters,$lat,$lng);
out body;
''';
    final url = Uri.parse(
        'https://overpass-api.de/api/interpreter');
    final response = await http
        .post(url, body: {'data': query})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final elements =
        data['elements'] as List<dynamic>? ?? [];

    return elements.map((e) {
      final tags =
          e['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String? ??
          tags['brand'] as String? ??
          'Fuel Station';
      return {
        'id': 'osm_${e['id']}',
        'name': name,
        'lat': (e['lat'] as num).toDouble(),
        'lng': (e['lon'] as num).toDouble(),
      };
    }).toList();
  }

  static int _estimateCrowdLevel() {
    final hour = DateTime.now().hour;
    const Map<int, int> hourlyPattern = {
      0: 1,  1: 1,  2: 1,  3: 1,  4: 1,
      5: 2,  6: 4,  7: 6,
      8: 10, 9: 12,
      10: 8, 11: 7,
      12: 9, 13: 11,
      14: 8, 15: 6,
      16: 7, 17: 9,
      18: 13, 19: 15,
      20: 11, 21: 7,
      22: 4,  23: 2,
    };
    return hourlyPattern[hour] ?? 5;
  }
}
