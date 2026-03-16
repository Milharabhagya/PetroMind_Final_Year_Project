import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  // ════════════════════════════════════════
  // OUTCOME 1 — LIVE FUEL PRICE MANAGEMENT
  // ════════════════════════════════════════

  // Station updates its fuel prices
  static Future<void> updateFuelPrices({
    required String stationId,
    required Map<String, double> prices, // e.g. {'petrol': 322.0, 'diesel': 295.0}
  }) async {
    await _db.collection('stations').doc(stationId).update({
      'fuelPrices': prices,
      'pricesUpdatedAt': FieldValue.serverTimestamp(),
    });
    // Also write to global fuel_prices collection for easy querying
    await _db.collection('fuel_prices').doc(stationId).set({
      'stationId': stationId,
      'prices': prices,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get live fuel prices for all stations (stream)
  static Stream<QuerySnapshot> streamAllFuelPrices() {
    return _db.collection('fuel_prices')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Get fuel prices for a specific station (stream)
  static Stream<DocumentSnapshot> streamStationFuelPrices(String stationId) {
    return _db.collection('fuel_prices').doc(stationId).snapshots();
  }

  // ════════════════════════════════════════
  // OUTCOME 2 — FUEL STOCK & SALES ANALYTICS
  // ════════════════════════════════════════

  // Update stock levels
  static Future<void> updateStock({
    required String stationId,
    required Map<String, double> stockLiters, // e.g. {'petrol': 5000.0}
    required String type, // 'inflow' or 'outflow'
    required double amount,
    required String fuelType,
  }) async {
    final batch = _db.batch();

    // Update station stock
    final stationRef = _db.collection('stations').doc(stationId);
    batch.update(stationRef, {
      'stock.$fuelType': FieldValue.increment(
          type == 'inflow' ? amount : -amount),
      'stockUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Log stock movement
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
  static Future<void> recordSale({
    required String stationId,
    required String fuelType,
    required double liters,
    required double pricePerLiter,
    required String customerId,
  }) async {
    final total = liters * pricePerLiter;
    final batch = _db.batch();

    // Add to station sales
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
      'receiptId': saleRef.id,
    });

    // Deduct stock
    final stationRef = _db.collection('stations').doc(stationId);
    batch.update(stationRef, {
      'stock.$fuelType': FieldValue.increment(-liters),
      'totalRevenue': FieldValue.increment(total),
    });

    // Add to customer receipts
    final receiptRef = _db
        .collection('users')
        .doc(customerId)
        .collection('receipts')
        .doc(saleRef.id);
    batch.set(receiptRef, {
      'stationId': stationId,
      'fuelType': fuelType,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
      'receiptId': saleRef.id,
    });

    await batch.commit();
  }

  // Get sales analytics for a station
  static Stream<QuerySnapshot> streamStationSales(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get stock logs
  static Stream<QuerySnapshot> streamStockLogs(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('stock_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get station stock data
  static Future<Map<String, dynamic>?> getStationStock(String stationId) async {
    final doc = await _db.collection('stations').doc(stationId).get();
    return doc.data()?['stock'] as Map<String, dynamic>?;
  }

  // ════════════════════════════════════════
  // OUTCOME 3 — DIGITAL RECEIPTS & CUSTOMER DASHBOARD
  // ════════════════════════════════════════

  // Get customer receipts (stream)
  static Stream<QuerySnapshot> streamCustomerReceipts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('receipts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get single receipt
  static Future<DocumentSnapshot> getReceipt({
    required String userId,
    required String receiptId,
  }) async {
    return await _db
        .collection('users')
        .doc(userId)
        .collection('receipts')
        .doc(receiptId)
        .get();
  }

  // Get customer dashboard summary
  static Future<Map<String, dynamic>> getCustomerDashboard(String userId) async {
    final receipts = await _db
        .collection('users')
        .doc(userId)
        .collection('receipts')
        .orderBy('timestamp', descending: true)
        .get();

    double totalSpent = 0;
    double totalLiters = 0;
    for (final doc in receipts.docs) {
      totalSpent += (doc['total'] as num).toDouble();
      totalLiters += (doc['liters'] as num).toDouble();
    }

    return {
      'totalTransactions': receipts.docs.length,
      'totalSpent': totalSpent,
      'totalLiters': totalLiters,
      'recentReceipts': receipts.docs.take(5).map((d) => d.data()).toList(),
    };
  }

  // ════════════════════════════════════════
  // OUTCOME 4 — PRICE ALERTS & NOTIFICATIONS
  // ════════════════════════════════════════

  // Create a price alert for a customer
  static Future<void> createPriceAlert({
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

  // Get customer alerts (stream)
  static Stream<QuerySnapshot> streamCustomerAlerts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Send a notification to all customers (station broadcasts)
  static Future<void> broadcastNotification({
    required String stationId,
    required String title,
    required String message,
    required String type, // 'price_change', 'fuel_available', 'promotion'
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

  // Get notifications for customer (stream)
  static Stream<QuerySnapshot> streamNotifications() {
    return _db
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  static Future<void> markNotificationRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // ════════════════════════════════════════
  // OUTCOME 5 — AI CHATBOT SUPPORT
  // ════════════════════════════════════════

  // Save chatbot conversation
  static Future<void> saveChatMessage({
    required String userId,
    required String message,
    required String sender, // 'user' or 'bot'
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .add({
      'message': message,
      'sender': sender,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get chat history (stream)
  static Stream<QuerySnapshot> streamChatHistory(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .orderBy('timestamp')
        .snapshots();
  }

  // ════════════════════════════════════════
  // OUTCOME 6 — RATINGS & FEEDBACK
  // ════════════════════════════════════════

  // Submit a rating
  static Future<void> submitRating({
    required String stationId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    final batch = _db.batch();

    // Add rating document
    final ratingRef = _db
        .collection('stations')
        .doc(stationId)
        .collection('ratings')
        .doc(userId); // one rating per user per station
    batch.set(ratingRef, {
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update station average rating
    final stationRef = _db.collection('stations').doc(stationId);
    batch.update(stationRef, {
      'totalRatings': FieldValue.increment(1),
      'ratingSum': FieldValue.increment(rating),
    });

    await batch.commit();

    // Recalculate average
    final stationDoc = await _db.collection('stations').doc(stationId).get();
    final data = stationDoc.data();
    if (data != null) {
      final total = (data['totalRatings'] as num).toDouble();
      final sum = (data['ratingSum'] as num).toDouble();
      await _db.collection('stations').doc(stationId).update({
        'averageRating': sum / total,
      });
    }
  }

  // Get station ratings (stream)
  static Stream<QuerySnapshot> streamStationRatings(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ════════════════════════════════════════
  // OUTCOME 7 — ADMIN DASHBOARD ANALYTICS
  // ════════════════════════════════════════

  // Get full admin analytics for a station
  static Future<Map<String, dynamic>> getAdminAnalytics(String stationId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Today's sales
    final todaySales = await _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    // This month's sales
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

    // Get stock
    final stationDoc = await _db.collection('stations').doc(stationId).get();
    final stock = stationDoc.data()?['stock'] ?? {};
    final averageRating = stationDoc.data()?['averageRating'] ?? 0.0;

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

  // Stream admin dashboard sales (real-time)
  static Stream<QuerySnapshot> streamAdminSales(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // ════════════════════════════════════════
  // OUTCOME 8 — STATION SELF-CARE & ACCOUNT MANAGEMENT
  // ════════════════════════════════════════

  // Update station profile/settings
  static Future<void> updateStationSettings({
    required String stationId,
    String? stationName,
    String? phone,
    String? address,
    Map<String, String>? operatingHours, // e.g. {'mon': '6am-10pm'}
    List<String>? services, // e.g. ['car_wash', 'air_pump']
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

  // Get station profile (stream)
  static Stream<DocumentSnapshot> streamStationProfile(String stationId) {
    return _db.collection('stations').doc(stationId).snapshots();
  }

  // Update staff/access roles
  static Future<void> addStaffMember({
    required String stationId,
    required String staffEmail,
    required String role, // 'manager' or 'staff'
  }) async {
    await _db
        .collection('stations')
        .doc(stationId)
        .collection('staff')
        .add({
      'email': staffEmail,
      'role': role,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get staff list
  static Stream<QuerySnapshot> streamStaffList(String stationId) {
    return _db
        .collection('stations')
        .doc(stationId)
        .collection('staff')
        .snapshots();
  }

  // ════════════════════════════════════════
  // SHARED UTILITIES
  // ════════════════════════════════════════

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    if (_uid == null) return null;
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data();
  }

  // Get station data
  static Future<Map<String, dynamic>?> getStationData() async {
    if (_uid == null) return null;
    final doc = await _db.collection('stations').doc(_uid).get();
    return doc.data();
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    await _db.collection('users').doc(userId).update(updates);
  }

  // Get all stations (for customer to browse)
  static Stream<QuerySnapshot> streamAllStations() {
    return _db.collection('stations').snapshots();
  }

  // Get single station
  static Future<Map<String, dynamic>?> getStation(String stationId) async {
    final doc = await _db.collection('stations').doc(stationId).get();
    return doc.data();
  }
}