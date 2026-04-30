import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> _write({
    required String stationId,
    required String type,
    required String message,
  }) async {
    if (stationId.isEmpty) return;
    await _db
        .collection('stations')
        .doc(stationId)
        .collection('notifications')
        .add({
      'type': type,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  static Future<void> onStockUpdated({
    required String stationId,
    required String fuelType,
    required String changeType,
    required double amount,
    double? currentStock,
  }) async {
    String msg;
    if (changeType == 'inflow') {
      msg = '📦 Fuel delivery received: ${amount.toStringAsFixed(0)}L of $fuelType added';
    } else if (changeType == 'outflow') {
      msg = '⛽ ${amount.toStringAsFixed(0)}L of $fuelType sold';
    } else {
      msg = '✏️ $fuelType stock manually set to ${amount.toStringAsFixed(0)}L';
    }

    await _write(stationId: stationId, type: 'stock_update', message: msg);

    if (currentStock != null && currentStock > 0 && currentStock < 200) {
      await _write(
        stationId: stationId,
        type: 'low_stock',
        message:
            '⚠️ Low Stock Alert: $fuelType — only ${currentStock.toStringAsFixed(0)}L remaining',
      );
    }
  }

  static Future<void> onNewReview({
    required String stationId,
    required double rating,
    String? comment,
  }) async {
    final stars = '⭐' * rating.round();
    final commentPart =
        (comment != null && comment.isNotEmpty) ? ': "$comment"' : '';
    await _write(
      stationId: stationId,
      type: 'new_review',
      message: 'New customer review $stars$commentPart',
    );
  }

  static Future<void> onFuelPriceChanged({
    required String stationId,
    required String fuelType,
    required double oldPrice,
    required double newPrice,
  }) async {
    final direction = newPrice > oldPrice ? '📈 increased' : '📉 decreased';
    final diff = (newPrice - oldPrice).abs().toStringAsFixed(2);
    await _write(
      stationId: stationId,
      type: 'price_change',
      message:
          '💰 $fuelType price $direction by Rs.$diff (now Rs.${newPrice.toStringAsFixed(2)})',
    );
  }

  static Future<void> broadcastFuelNews({
    required List<String> stationIds,
    required String message,
  }) async {
    final batch = _db.batch();
    for (final id in stationIds) {
      final ref = _db
          .collection('stations')
          .doc(id)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'type': 'fuel_news',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit();
  }

  static Function() listenToGlobalPriceChanges({
    required String stationId,
  }) {
    bool isFirstSnapshot = true;
    final sub = FirebaseFirestore.instance
        .collection('fuel_prices_ceypetco')
        .snapshots()
        .listen((snapshot) {
      if (isFirstSnapshot) {
        isFirstSnapshot = false;
        return; // skip initial load
      }
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;
          final fuelName =
              data['name'] as String? ?? change.doc.id.replaceAll('_', ' ');
          final newPrice = (data['price'] as num?)?.toDouble() ?? 0;
          _write(
            stationId: stationId,
            type: 'price_change',
            message:
                '💰 Government updated $fuelName price to Rs.${newPrice.toStringAsFixed(2)}',
          );
        }
      }
    });
    return () => sub.cancel();
  }
}