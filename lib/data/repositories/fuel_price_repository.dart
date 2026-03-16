import 'package:cloud_firestore/cloud_firestore.dart';

class FuelPriceRepository {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'fuel_prices_ceypetco';

  // Stream all prices in real-time
  static Stream<List<Map<String, dynamic>>> streamAllPrices() {
    return _db
        .collection(_collection)
        .orderBy('category')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Initialize default prices if collection is empty
  static Future<void> initializeDefaultPrices() async {
    final snap =
        await _db.collection(_collection).limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    final defaults = [
      {
        'id': 'petrol_92',
        'name': 'Petrol 92 Octane',
        'price': 292.0,
        'category': 'retail',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'petrol_95',
        'name': 'Petrol 95 Octane',
        'price': 340.0,
        'category': 'retail',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'auto_diesel',
        'name': 'Auto Diesel',
        'price': 277.0,
        'category': 'retail',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'super_diesel',
        'name': 'Super Diesel',
        'price': 323.0,
        'category': 'retail',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'lanka_kerosene',
        'name': 'Lanka Kerosene',
        'price': 182.0,
        'category': 'retail',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'industrial_kerosene',
        'name': 'Industrial Kerosene',
        'price': 193.0,
        'category': 'retail',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'fuel_oil_super',
        'name': 'Lanka Fuel Oil Super',
        'price': 194.0,
        'category': 'industrial',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
      {
        'id': 'fuel_oil_1500',
        'name': 'Lanka Fuel Oil 1500 Sec (High/Low Sulphur)',
        'price': 250.0,
        'category': 'industrial',
        'effectiveDate':
            'Effective Midnight, Jan 31/Feb 1, 2026',
      },
    ];

    for (final item in defaults) {
      final ref = _db
          .collection(_collection)
          .doc(item['id'] as String);
      batch.set(ref, {
        'name': item['name'],
        'price': item['price'],
        'category': item['category'],
        'effectiveDate': item['effectiveDate'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Update a single price
  static Future<void> updatePrice({
    required String id,
    required double price,
    required String effectiveDate,
  }) async {
    await _db.collection(_collection).doc(id).update({
      'price': price,
      'effectiveDate': effectiveDate,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}