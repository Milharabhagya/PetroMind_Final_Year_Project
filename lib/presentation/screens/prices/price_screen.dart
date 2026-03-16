import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/fuel_price_repository.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  @override
  void initState() {
    super.initState();
    FuelPriceRepository.initializeDefaultPrices();
  }

  String _formatUpdated(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Price',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fuel_prices_ceypetco')
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
              child: CircularProgressIndicator(
                  color: Color(0xFF8B0000)),
            );
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

          final firstData =
              docs.first.data() as Map<String, dynamic>;
          final effectiveDate =
              firstData['effectiveDate'] as String? ?? '';
          final lastUpdated = _formatUpdated(
              firstData['updatedAt'] as Timestamp?);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ── RETAIL HEADER ──
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fuel Prices',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    _liveChip(),
                  ],
                ),
                Text(effectiveDate,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                if (lastUpdated.isNotEmpty)
                  Text('Updated: $lastUpdated',
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11)),
                const SizedBox(height: 16),

                // ── RETAIL GRID ──
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.88,
                  children: retailDocs
                      .map((doc) => _priceCard(
                          doc.data()
                              as Map<String, dynamic>))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // ── INDUSTRIAL HEADER ──
                if (industrialDocs.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Industrial Fuel',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      _liveChip(),
                    ],
                  ),
                  Text(effectiveDate,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12)),
                  const SizedBox(height: 16),
                  ...industrialDocs.map((doc) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: _industrialCard(doc.data()
                            as Map<String, dynamic>),
                      )),
                ],

                const SizedBox(height: 16),

                // ── INFO BOX ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orange[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[700],
                          size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Prices are official CPC rates for Sri Lanka. Updated automatically when CPC announces new rates.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _liveChip() {
    return Row(children: [
      Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            color: Colors.green, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      const Text('Live',
          style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _priceCard(Map<String, dynamic> data) {
    final price = (data['price'] as num).toDouble();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data['name'] ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rs. ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const Text('per liter',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _industrialCard(Map<String, dynamic> data) {
    final price = (data['price'] as num).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(data['name'] ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const Text('per liter',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}