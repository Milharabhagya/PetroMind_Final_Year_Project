import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPriceScreen extends StatefulWidget {
  const AdminPriceScreen({super.key});

  @override
  State<AdminPriceScreen> createState() =>
      _AdminPriceScreenState();
}

class _AdminPriceScreenState extends State<AdminPriceScreen> {
  static const _collection = 'fuel_prices_ceypetco';

  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _globalDateController =
      TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _globalDateController.dispose();
    super.dispose();
  }

  Future<void> _saveAll(List<QueryDocumentSnapshot> docs) async {
    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final globalDate = _globalDateController.text.trim();

      for (final doc in docs) {
        final priceText =
            _controllers[doc.id]?.text.trim() ?? '';
        if (priceText.isEmpty) continue;
        final price = double.tryParse(priceText);
        if (price == null) continue;

        final updateData = <String, dynamic>{
          'price': price,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (globalDate.isNotEmpty) {
          updateData['effectiveDate'] = globalDate;
        }

        batch.update(
          FirebaseFirestore.instance
              .collection(_collection)
              .doc(doc.id),
          updateData,
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Prices updated! Customers see new prices now.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _saveSingle(String docId) async {
    final priceText = _controllers[docId]?.text.trim() ?? '';
    if (priceText.isEmpty) return;
    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid price value')),
      );
      return;
    }

    try {
      final updateData = <String, dynamic>{
        'price': price,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final globalDate = _globalDateController.text.trim();
      if (globalDate.isNotEmpty) {
        updateData['effectiveDate'] = globalDate;
      }

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(docId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Price saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        // ✅ Fixes burger menu showing
        automaticallyImplyLeading: false,
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
        title: const Text('Update Fuel Prices',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(_collection)
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF8B0000)),
            );
          }

          final docs = snapshot.data!.docs;

          // ✅ Initialize controllers with current values
          for (final doc in docs) {
            if (!_controllers.containsKey(doc.id)) {
              final data =
                  doc.data() as Map<String, dynamic>;
              _controllers[doc.id] =
                  TextEditingController(
                text: (data['price'] as num)
                    .toStringAsFixed(2),
              );
            }
          }

          final retailDocs = docs
              .where((d) =>
                  (d.data() as Map)['category'] ==
                  'retail')
              .toList();
          final industrialDocs = docs
              .where((d) =>
                  (d.data() as Map)['category'] ==
                  'industrial')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ── INFO BANNER ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius:
                        BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Changes are instant — all customers see updated prices immediately.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── EFFECTIVE DATE ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('Effective Date',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text(
                          'Applied to all prices when saved',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _globalDateController,
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Effective Midnight, Mar 1, 2026',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10),
                          prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── RETAIL PRICES ──
                const Text('Retail Fuel Prices',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...retailDocs
                    .map((doc) => _priceRow(doc)),

                const SizedBox(height: 16),

                // ── INDUSTRIAL PRICES ──
                if (industrialDocs.isNotEmpty) ...[
                  const Text('Industrial Fuel',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...industrialDocs
                      .map((doc) => _priceRow(doc)),
                  const SizedBox(height: 16),
                ],

                // ── SAVE ALL ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF8B0000),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                          )
                        : const Icon(Icons.save,
                            color: Colors.white),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : 'Save All Prices',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    onPressed: _saving
                        ? null
                        : () => _saveAll(docs),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _priceRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentPrice =
        (data['price'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          // Fuel name + current price
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  'Current: Rs. ${currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // New price input
          Expanded(
            flex: 2,
            child: TextField(
              controller: _controllers[doc.id],
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration: InputDecoration(
                labelText: 'New Rs.',
                labelStyle:
                    const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ✅ Quick save single price
          GestureDetector(
            onTap: () => _saveSingle(doc.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}