import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FuelPriceManagementScreen extends StatefulWidget {
  const FuelPriceManagementScreen({super.key});

  @override
  State<FuelPriceManagementScreen> createState() =>
      _FuelPriceManagementScreenState();
}

class _FuelPriceManagementScreenState
    extends State<FuelPriceManagementScreen> {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'fuel_prices_ceypetco';

  // Track edited prices — docId -> new price string
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _editing = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ✅ Save all edited prices to Firestore at once
  Future<void> _saveAll(List<QueryDocumentSnapshot> docs) async {
    setState(() => _isSaving = true);

    try {
      final batch = _db.batch();
      bool anyEdit = false;

      for (final doc in docs) {
        final controller = _controllers[doc.id];
        if (controller == null) continue;
        final newPrice = double.tryParse(controller.text);
        if (newPrice == null) continue;
        final oldPrice =
            (doc.data() as Map<String, dynamic>)['price'] as num;
        if (newPrice == oldPrice.toDouble()) continue;

        // ✅ Update price + track change direction
        batch.update(_db.collection(_collection).doc(doc.id), {
          'price': newPrice,
          'previousPrice': oldPrice,
          'priceChanged': true,
          'priceUp': newPrice > oldPrice.toDouble(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        anyEdit = true;
      }

      if (anyEdit) {
        await batch.commit();
      }

      if (!mounted) return;
      setState(() => _editing.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Prices updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update prices: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fuel Price Management',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection(_collection)
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF8B0000)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
                child: Text('Error loading prices'));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No prices found.'));
          }

          // ✅ Initialize controllers for any new docs
          for (final doc in docs) {
            if (!_controllers.containsKey(doc.id)) {
              final data =
                  doc.data() as Map<String, dynamic>;
              final price =
                  (data['price'] as num).toDouble();
              _controllers[doc.id] =
                  TextEditingController(
                      text: price.toStringAsFixed(2));
            }
          }

          final retailDocs = docs
              .where((d) =>
                  (d.data()
                      as Map<String, dynamic>)['category'] ==
                  'retail')
              .toList();
          final changedDocs = docs
              .where((d) =>
                  (d.data() as Map<String,
                      dynamic>)['priceChanged'] ==
                  true)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── FUEL PRICE LIST ──
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ...docs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final doc = entry.value;
                        final data = doc.data()
                            as Map<String, dynamic>;
                        final isLast =
                            i == docs.length - 1;
                        final isEditing =
                            _editing[doc.id] == true;

                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: isEditing
                                        ? TextField(
                                            controller:
                                                _controllers[
                                                    doc.id],
                                            autofocus: true,
                                            keyboardType:
                                                const TextInputType
                                                    .numberWithOptions(
                                                        decimal:
                                                            true),
                                            style: const TextStyle(
                                                color: Color(
                                                    0xFF8B0000),
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 12),
                                            decoration:
                                                const InputDecoration(
                                              border:
                                                  OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal:
                                                          8,
                                                      vertical:
                                                          6),
                                              prefixText:
                                                  'Rs. ',
                                              prefixStyle: TextStyle(
                                                  color: Color(
                                                      0xFF8B0000),
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                  fontSize: 12),
                                            ),
                                          )
                                        : Text(
                                            'Rs. ${(data['price'] as num).toStringAsFixed(2)} per liter',
                                            style: const TextStyle(
                                                color: Color(
                                                    0xFF8B0000),
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 12),
                                          ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _editing[doc.id] =
                                            !isEditing;
                                      });
                                    },
                                    child: Text(
                                      isEditing
                                          ? 'Done'
                                          : 'Edit',
                                      style: TextStyle(
                                        color: isEditing
                                            ? Colors.green
                                            : Colors.grey,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                  height: 1,
                                  color:
                                      Color(0xFFEEEEEE)),
                          ],
                        );
                      }),

                      // ✅ Single Update button — saves to Firestore
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () => _saveAll(docs),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF8B0000),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8)),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                            color:
                                                Colors.white,
                                            strokeWidth: 2),
                                  )
                                : const Text('Update',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── PRICE CHANGED FUELS ──
                if (changedDocs.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Price Changed Fuels',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                        const Divider(
                            height: 1,
                            color: Color(0xFFEEEEEE)),
                        ...changedDocs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          final priceUp =
                              data['priceUp'] == true;
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight
                                                    .w500),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Rs. ${(data['price'] as num).toStringAsFixed(2)} per liter',
                                        style: const TextStyle(
                                            color: Color(
                                                0xFF8B0000),
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                    Icon(
                                      priceUp
                                          ? Icons.arrow_upward
                                          : Icons
                                              .arrow_downward,
                                      color: priceUp
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                  height: 1,
                                  color: Color(0xFFEEEEEE)),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}