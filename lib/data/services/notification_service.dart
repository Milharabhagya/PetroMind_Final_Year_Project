import 'package:cloud_firestore/cloud_firestore.dart';

/// NotificationService
/// -------------------
/// Writes real-time notifications to each station's
/// `stations/{uid}/notifications` subcollection.
///
/// Call these methods from wherever the relevant event occurs:
///   - Stock update  → NotificationService.onStockUpdated(...)
///   - Low stock     → (auto-called inside onStockUpdated)
///   - New review    → NotificationService.onNewReview(...)
///   - Price change  → NotificationService.onFuelPriceChanged(...)
///
/// The StationNotificationsScreen streams this collection live.

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  // ─── Core writer ───────────────────────────────────────────────
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

  // ─── 1. Stock updated (inflow / outflow / edit) ────────────────
  /// Call this after any stock change in stock_management_screen.dart
  static Future<void> onStockUpdated({
    required String stationId,
    required String fuelType,
    required String changeType, // 'inflow', 'outflow', 'edit'
    required double amount,
    double? currentStock,       // pass new stock level to auto-check low stock
  }) async {
    String msg;
    if (changeType == 'inflow') {
      msg = '📦 Fuel delivery received: ${amount.toStringAsFixed(0)}L of $fuelType added';
    } else if (changeType == 'outflow') {
      msg = '⛽ ${amount.toStringAsFixed(0)}L of $fuelType sold';
    } else {
      msg = '✏️ $fuelType stock manually set to ${amount.toStringAsFixed(0)}L';
    }

    await _write(
      stationId: stationId,
      type: 'stock_update',
      message: msg,
    );

    // Auto low-stock alert
    if (currentStock != null && currentStock > 0 && currentStock < 200) {
      await _write(
        stationId: stationId,
        type: 'low_stock',
        message: '⚠️ Low Stock Alert: $fuelType — only ${currentStock.toStringAsFixed(0)}L remaining',
      );
    }
  }

  // ─── 2. New customer review ─────────────────────────────────────
  /// Call this when a review is submitted for this station
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

  // ─── 3. Fuel price changed (call from admin/price update) ───────
  /// Call this when a fuel price is updated in fuel_prices_ceypetco
  /// You can trigger this from your admin price screen or a Cloud Function
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

  // ─── 4. General fuel news ───────────────────────────────────────
  /// Broadcast a news/announcement to all stations
  /// Call from an admin panel or Cloud Function
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

  // ─── 5. Listen to global price changes & auto-notify ───────────
  /// Call this once at app startup (e.g. in main.dart or station dashboard)
  /// It watches fuel_prices_ceypetco and writes a notification when any
  /// price document changes.
  ///
  /// Pass [stationId] of the currently logged-in station.
  /// Returns a cancel function — call it when the station logs out.
  static Function() listenToGlobalPriceChanges({
    required String stationId,
  }) {
    final sub = FirebaseFirestore.instance
        .collection('fuel_prices_ceypetco')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        // Only react to modifications (not initial load)
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;

          final fuelName = data['name'] as String? ??
              change.doc.id.replaceAll('_', ' ');
          final newPrice =
              (data['price'] as num?)?.toDouble() ?? 0;

          // We don't have oldPrice here — just notify price changed
          _write(
            stationId: stationId,
            type: 'price_change',
            message:
                '💰 Government updated $fuelName price to Rs.${newPrice.toStringAsFixed(2)}',
          );
        }
      }
    });

    // Return cancel function
    return () => sub.cancel();
  }
}