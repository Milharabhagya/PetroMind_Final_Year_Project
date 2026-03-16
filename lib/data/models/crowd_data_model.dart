import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdDataModel {
  final String stationId;
  final int hour;
  final int crowdCount;
  final DateTime timestamp;

  CrowdDataModel({
    required this.stationId,
    required this.hour,
    required this.crowdCount,
    required this.timestamp,
  });

  factory CrowdDataModel.fromMap(Map<String, dynamic> map) {
    return CrowdDataModel(
      stationId: map['stationId'] ?? '',
      hour: map['hour'] ?? 0,
      crowdCount: map['crowdCount'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'stationId': stationId,
        'hour': hour,
        'crowdCount': crowdCount,
        'timestamp': FieldValue.serverTimestamp(),
      };
}