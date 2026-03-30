import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdRepository {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  static Stream<QuerySnapshot> streamTodayCrowdData() {
    try {
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day);
      return _db
          .collection('crowd_data')
          .where('timestamp',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(startOfDay))
          .orderBy('timestamp')
          .snapshots()
          .handleError((error) {
        // ✅ Silently handle Firestore errors
        print('Firestore stream error (handled): $error');
      });
    } catch (e) {
      // Return empty stream on error
      return const Stream.empty();
    }
  }

  static Future<void> logCrowdCount({
    required String stationId,
    required int crowdCount,
    required double stationLat,
    required double stationLng,
  }) async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      await _db
          .collection('crowd_data')
          .doc('${stationId}_$hour')
          .set({
        'stationId': stationId,
        'hour': hour,
        'crowdCount': crowdCount,
        'stationLat': stationLat,
        'stationLng': stationLng,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('logCrowdCount error (handled): $e');
    }
  }

  static Future<Map<int, int>>
      getHourlyCrowdAggregated() async {
    final Map<int, int> hourlyData = {};
    for (int i = 6; i <= 23; i++) {
      hourlyData[i] = 0;
    }

    try {
      final now = DateTime.now();
      final startOfDay =
          DateTime(now.year, now.month, now.day);

      final snapshot = await _db
          .collection('crowd_data')
          .where('timestamp',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(startOfDay))
          .get();

      for (final doc in snapshot.docs) {
        final hour = doc['hour'] as int? ?? 0;
        final count = doc['crowdCount'] as int? ?? 0;
        if (hourlyData.containsKey(hour)) {
          hourlyData[hour] =
              (hourlyData[hour] ?? 0) + count;
        }
      }
    } catch (e) {
      print('getHourlyCrowdAggregated error (handled): $e');
      // Returns default empty data — chart uses fallback pattern
    }

    return hourlyData;
  }
}