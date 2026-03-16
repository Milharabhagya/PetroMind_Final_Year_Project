import 'package:cloud_firestore/cloud_firestore.dart';

class AlertRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create price alert
  static Future<void> createAlert({
    required String userId,
    required String fuelType,
    required double targetPrice,
    required String stationId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .add({
      'fuelType': fuelType,
      'targetPrice': targetPrice,
      'stationId': stationId,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream alerts for a user
  static Stream<QuerySnapshot> streamAlerts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete alert
  static Future<void> deleteAlert({
    required String userId,
    required String alertId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc(alertId)
        .delete();
  }

  // Toggle alert active/inactive
  static Future<void> toggleAlert({
    required String userId,
    required String alertId,
    required bool isActive,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc(alertId)
        .update({'isActive': isActive});
  }

  // Stream global notifications
  static Stream<QuerySnapshot> streamNotifications() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification read
  static Future<void> markRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}