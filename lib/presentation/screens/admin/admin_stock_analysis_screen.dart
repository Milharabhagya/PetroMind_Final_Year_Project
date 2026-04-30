import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStockAnalysisScreen extends StatefulWidget {
  const AdminStockAnalysisScreen({super.key});

  @override
  State<AdminStockAnalysisScreen> createState() =>
      _AdminStockAnalysisScreenState();
}

class _AdminStockAnalysisScreenState
    extends State<AdminStockAnalysisScreen> {
  final _db = FirebaseFirestore.instance;

  final List<String> _fuelTypes = [
    'Petrol 92 Octane',
    'Petrol 95 Octane',
    'Auto Diesel',
    'Super Diesel',
    'Lanka Kerosene',
    'Industrial Kerosene',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Stock Analysis',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('stations').snapshots(),
        builder: (context, stationsSnap) {
          if (!stationsSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.amber));
          }

          final stations = stationsSnap.data!.docs;

          if (stations.isEmpty) {
            return const Center(
              child: Text('No stations found',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── FUEL SUMMARY ACROSS ALL STATIONS ──
              const Text(
                'Network Stock Summary',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Total stock across all registered stations',
                style: TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Aggregate stock per fuel type
              FutureBuilder<Map<String, double>>(
                future: _aggregateStock(stations),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.amber));
                  }
                  final totals = snap.data!;
                  return Column(
                    children: _fuelTypes.map((fuel) {
                      final total = totals[fuel] ?? 0;
                      final color = _fuelColor(total);
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  color.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(fuel,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w500)),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${total.toStringAsFixed(0)} L',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  _stockLabel(total),
                                  style: TextStyle(
                                      color: color
                                          .withOpacity(0.7),
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── PER STATION BREAKDOWN ──
              const Text(
                'Per Station Breakdown',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...stations.map((stationDoc) {
                final stationData = stationDoc.data()
                    as Map<String, dynamic>;
                final stationName =
                    stationData['stationName'] as String? ??
                        stationData['name'] as String? ??
                        'Unknown';
                final brand =
                    stationData['brand'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orangeAccent
                            .withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                              Icons.local_gas_station,
                              color: Colors.orangeAccent,
                              size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '$stationName${brand.isNotEmpty ? ' ($brand)' : ''}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('stations')
                            .doc(stationDoc.id)
                            .collection('stock')
                            .snapshots(),
                        builder: (context, stockSnap) {
                          if (!stockSnap.hasData) {
                            return const Text(
                                'Loading...',
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12));
                          }
                          final stockDocs =
                              stockSnap.data!.docs;
                          if (stockDocs.isEmpty) {
                            return const Text(
                                'No stock data',
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12));
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: stockDocs
                                .where((d) {
                              final data = d.data()
                                  as Map<String, dynamic>;
                              return data['fuelType'] !=
                                  'Air Pump';
                            })
                                .map((d) {
                              final data = d.data()
                                  as Map<String, dynamic>;
                              final fuel =
                                  data['fuelType']
                                      as String? ??
                                      '';
                              final litres =
                                  (data['stockLitres']
                                              as num?)
                                          ?.toDouble() ??
                                      0;
                              final color =
                                  _fuelColor(litres);
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: color
                                      .withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(
                                          6),
                                  border: Border.all(
                                      color: color
                                          .withOpacity(
                                              0.3)),
                                ),
                                child: Text(
                                  '${_shortFuelName(fuel)}: ${litres.toStringAsFixed(0)}L',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, double>> _aggregateStock(
      List<QueryDocumentSnapshot> stations) async {
    final totals = <String, double>{};
    for (final fuel in _fuelTypes) {
      totals[fuel] = 0;
    }
    for (final station in stations) {
      final stockSnap = await _db
          .collection('stations')
          .doc(station.id)
          .collection('stock')
          .get();
      for (final doc in stockSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final fuel = data['fuelType'] as String? ?? '';
        final litres =
            (data['stockLitres'] as num?)?.toDouble() ?? 0;
        if (totals.containsKey(fuel)) {
          totals[fuel] = (totals[fuel] ?? 0) + litres;
        }
      }
    }
    return totals;
  }

  Color _fuelColor(double litres) {
    if (litres <= 0) return Colors.red;
    if (litres < 500) return Colors.orangeAccent;
    if (litres < 2000) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  String _stockLabel(double litres) {
    if (litres <= 0) return 'Empty';
    if (litres < 500) return 'Critical';
    if (litres < 2000) return 'Low';
    return 'Good';
  }

  String _shortFuelName(String fuel) {
    return fuel
        .replaceAll('Octane', '')
        .replaceAll('Petrol', 'P')
        .replaceAll('Auto Diesel', 'ADsl')
        .replaceAll('Super Diesel', 'SDsl')
        .replaceAll('Lanka Kerosene', 'LKer')
        .replaceAll('Industrial Kerosene', 'IKer')
        .trim();
  }
}