import 'package:cloud_firestore/cloud_firestore.dart';

class AlertRepository {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ── USER PRICE ALERTS ──
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

  static Stream<QuerySnapshot> streamAlerts(
      String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

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

  // ── GLOBAL NOTIFICATIONS (live feed) ──
  static Stream<QuerySnapshot> streamNotifications() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .handleError((e) {
      print('Notification stream error: $e');
    });
  }

  static Future<void> markRead(
      String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // ✅ AUTO-PUBLISH ALERT — called by station actions
  static Future<void> publishAlert({
    required String type,
    required String title,
    required String message,
    required String stationId,
    required String stationName,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _db.collection('notifications').add({
        'type': type,
        // Types: price_update, low_stock,
        // out_of_stock, peak_hour,
        // new_station, maintenance, stock_restored
        'title': title,
        'message': message,
        'stationId': stationId,
        'stationName': stationName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extraData,
      });
    } catch (e) {
      print('publishAlert error: $e');
    }
  }

  // ✅ AUTO-DETECT: Check stock and publish if low
  static Future<void> checkAndAlertStock({
    required String stationId,
    required String stationName,
    required String fuelType,
    required double stockLiters,
  }) async {
    try {
      if (stockLiters <= 0) {
        await publishAlert(
          type: 'out_of_stock',
          title: '⛽ Out of Stock',
          message:
              '$fuelType is now OUT OF STOCK at $stationName.',
          stationId: stationId,
          stationName: stationName,
          extraData: {
            'fuelType': fuelType,
            'stockLiters': stockLiters,
          },
        );
      } else if (stockLiters <= 200) {
        await publishAlert(
          type: 'low_stock',
          title: '⚠️ Low Stock Alert',
          message:
              '$fuelType is running LOW at $stationName — only ${stockLiters.toInt()}L remaining.',
          stationId: stationId,
          stationName: stationName,
          extraData: {
            'fuelType': fuelType,
            'stockLiters': stockLiters,
          },
        );
      } else if (stockLiters >= 1000) {
        // Stock restored
        await publishAlert(
          type: 'stock_restored',
          title: '✅ Stock Restored',
          message:
              '$fuelType is now AVAILABLE again at $stationName.',
          stationId: stationId,
          stationName: stationName,
          extraData: {
            'fuelType': fuelType,
            'stockLiters': stockLiters,
          },
        );
      }
    } catch (e) {
      print('checkAndAlertStock error: $e');
    }
  }

  // ✅ AUTO-DETECT: Publish price change alert
  static Future<void> alertPriceUpdate({
    required String stationId,
    required String stationName,
    required Map<String, double> newPrices,
  }) async {
    try {
      final priceLines = newPrices.entries
          .map((e) =>
              '${e.key}: Rs.${e.value.toStringAsFixed(0)}')
          .join(', ');
      await publishAlert(
        type: 'price_update',
        title: '💰 Fuel Price Update',
        message:
            '$stationName updated prices: $priceLines',
        stationId: stationId,
        stationName: stationName,
        extraData: {'prices': newPrices},
      );
    } catch (e) {
      print('alertPriceUpdate error: $e');
    }
  }

  // ✅ AUTO-DETECT: Peak hour alert
  static Future<void> alertPeakHour({
    required String stationId,
    required String stationName,
    required int crowdCount,
  }) async {
    try {
      await publishAlert(
        type: 'peak_hour',
        title: '🕐 Peak Hour at $stationName',
        message:
            'High crowd detected at $stationName — consider visiting later.',
        stationId: stationId,
        stationName: stationName,
        extraData: {'crowdCount': crowdCount},
      );
    } catch (e) {
      print('alertPeakHour error: $e');
    }
  }

  // ✅ AUTO-DETECT: Maintenance alert
  static Future<void> alertMaintenance({
    required String stationId,
    required String stationName,
    required bool isClosed,
    String? reason,
  }) async {
    try {
      await publishAlert(
        type: 'maintenance',
        title: isClosed
            ? '🔧 Station Temporarily Closed'
            : '✅ Station Reopened',
        message: isClosed
            ? '$stationName is temporarily closed${reason != null ? ' — $reason' : ''}.'
            : '$stationName is now open again!',
        stationId: stationId,
        stationName: stationName,
        extraData: {
          'isClosed': isClosed,
          if (reason != null) 'reason': reason,
        },
      );
    } catch (e) {
      print('alertMaintenance error: $e');
    }
  }
}