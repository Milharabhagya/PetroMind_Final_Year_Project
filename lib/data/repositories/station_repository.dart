import 'package:cloud_firestore/cloud_firestore.dart';

class StationRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all stations
  static Stream<QuerySnapshot> streamAllStations() {
    return _db.collection('stations').snapshots();
  }

  // Get single station
  static Future<Map<String, dynamic>?> getStation(String stationId) async {
    final doc = await _db.collection('stations').doc(stationId).get();
    return doc.data();
  }

  // Stream single station
  static Stream<DocumentSnapshot> streamStation(String stationId) {
    return _db.collection('stations').doc(stationId).snapshots();
  }

  // Update station settings
  static Future<void> updateStationSettings({
    required String stationId,
    String? stationName,
    String? phone,
    String? address,
    Map<String, String>? operatingHours,
    List<String>? services,
    String? promotionMessage,
    bool? isOpen,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (stationName != null) updates['stationName'] = stationName;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (operatingHours != null) updates['operatingHours'] = operatingHours;
    if (services != null) updates['services'] = services;
    if (promotionMessage != null) updates['promotionMessage'] = promotionMessage;
    if (isOpen != null) updates['isOpen'] = isOpen;

    await _db.collection('stations').doc(stationId).update(updates);
  }

  // Update stock
  static Future<void> updateStock({
    required String stationId,
    required String fuelType,
    required String type, // 'inflow' or 'outflow'
    required double amount,
  }) async {
    final batch = _db.batch();

    final stationRef = _db.collection('stations').doc(stationId);
    batch.update(stationRef, {
      'stock.$fuelType': FieldValue.increment(
          type == 'inflow' ? amount : -amount),
      'stockUpdatedAt': FieldValue.serverTimestamp(),
    });

    final logRef = _db
        .collection('stations')
        .doc(stationId)
        .collection('stock_logs')
        .doc();
    batch.set(logRef, {
      'type': type,
      'fuelType': fuelType,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Record a sale
  static Future<String> recordSale({
    required String stationId,
    required String fuelType,
    required double liters,
    required double pricePerLiter,
    required String customerId,
  }) async {
    final total = liters * pricePerLiter;
    final batch = _db.batch();

    final saleRef = _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .doc();

    batch.set(saleRef, {
      'fuelType': fuelType,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'total': total,
      'customerId': customerId,
      'timestamp': FieldValue.serverTimestamp(),
      'saleId': saleRef.id,
    });

    batch.update(_db.collection('stations').doc(stationId), {
      'stock.$fuelType': FieldValue.increment(-liters),
      'totalRevenue': FieldValue.increment(total),
    });

    await batch.commit();
    return saleRef.id;
  }

  // Stream sales
  static Stream<QuerySnapshot> streamSales(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream stock logs
  static Stream<QuerySnapshot> streamStockLogs(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('stock_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get admin analytics
  static Future<Map<String, dynamic>> getAdminAnalytics(
      String stationId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final todaySales = await _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    final monthlySales = await _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    double todayRevenue = 0;
    double monthRevenue = 0;
    double todayLiters = 0;
    double monthLiters = 0;

    for (final doc in todaySales.docs) {
      todayRevenue += (doc['total'] as num).toDouble();
      todayLiters += (doc['liters'] as num).toDouble();
    }
    for (final doc in monthlySales.docs) {
      monthRevenue += (doc['total'] as num).toDouble();
      monthLiters += (doc['liters'] as num).toDouble();
    }

    final stationDoc =
        await _db.collection('stations').doc(stationId).get();
    final stock = stationDoc.data()?['stock'] ?? {};
    final averageRating =
        stationDoc.data()?['averageRating'] ?? 0.0;

    return {
      'todayRevenue': todayRevenue,
      'todayLiters': todayLiters,
      'todayTransactions': todaySales.docs.length,
      'monthRevenue': monthRevenue,
      'monthLiters': monthLiters,
      'monthTransactions': monthlySales.docs.length,
      'stock': stock,
      'averageRating': averageRating,
    };
  }

  // Submit rating
  static Future<void> submitRating({
    required String stationId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    final batch = _db.batch();

    final ratingRef = _db
        .collection('stations')
        .doc(stationId)
        .collection('ratings')
        .doc(userId);

    batch.set(ratingRef, {
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('stations').doc(stationId), {
      'totalRatings': FieldValue.increment(1),
      'ratingSum': FieldValue.increment(rating),
    });

    await batch.commit();

    final stationDoc =
        await _db.collection('stations').doc(stationId).get();
    final data = stationDoc.data();
    if (data != null) {
      final total = (data['totalRatings'] as num).toDouble();
      final sum = (data['ratingSum'] as num).toDouble();
      await _db.collection('stations').doc(stationId).update({
        'averageRating': sum / total,
      });
    }
  }

  // Stream ratings
  static Stream<QuerySnapshot> streamRatings(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Broadcast notification
  static Future<void> broadcastNotification({
    required String stationId,
    required String title,
    required String message,
    required String type,
  }) async {
    await _db.collection('notifications').add({
      'stationId': stationId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}