import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream avg crowd data
  static Stream<QuerySnapshot> streamTodayCrowdData() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _db
        .collection('crowd_data')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp')
        .snapshots();
  }

  // Log crowd count for current hour (called by station)
  static Future<void> logCrowdCount({
    required String stationId,
    required int crowdCount,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;
    await _db
        .collection('crowd_data')
        .doc('${stationId}_$hour')
        .set({
      'stationId': stationId,
      'hour': hour,
      'crowdCount': crowdCount,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get aggregated hourly crowd across all stations
  static Future<Map<int, int>> getHourlyCrowdAggregated() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection('crowd_data')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    final Map<int, int> hourlyData = {};
    for (int i = 6; i <= 23; i++) {
      hourlyData[i] = 0;
    }

    for (final doc in snapshot.docs) {
      final hour = doc['hour'] as int;
      final count = doc['crowdCount'] as int;
      if (hourlyData.containsKey(hour)) {
        hourlyData[hour] = (hourlyData[hour] ?? 0) + count;
      }
    }

    return hourlyData;
  }
}