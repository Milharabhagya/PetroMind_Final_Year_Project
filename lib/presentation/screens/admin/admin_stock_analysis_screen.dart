import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _T {
  static const primary       = Color(0xFFAD2831);
  static const dark          = Color(0xFF38040E);
  static const bg            = Color(0xFFF8F4F1);
  static const surface       = Color(0xFFFFFFFF);
  static const muted         = Color(0xFFF2EBE7);
  static const textPrimary   = Color(0xFF1A0A0C);
  static const textSecondary = Color(0xFF7A5C60);
  static const border        = Color(0xFFEADDDA);

  static const h1 = TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.4);
  static const h2 = TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.2);
  static const label = TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary, letterSpacing: 0.6);
  static const body = TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary);

  static BoxDecoration card({Color? color, bool hasBorder = true}) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(16),
    border: hasBorder ? Border.all(color: border, width: 1) : null,
    boxShadow: [BoxShadow(color: dark.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}

class AdminStockAnalysisScreen extends StatefulWidget {
  const AdminStockAnalysisScreen({super.key});

  @override
  State<AdminStockAnalysisScreen> createState() => _AdminStockAnalysisScreenState();
}

class _AdminStockAnalysisScreenState extends State<AdminStockAnalysisScreen> {
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
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text('Stock Analysis', style: _T.h2.copyWith(fontSize: 18, color: _T.textPrimary)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('stations').snapshots(),
        builder: (context, stationsSnap) {
          if (!stationsSnap.hasData) {
            return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
          }

          final stations = stationsSnap.data!.docs;
          if (stations.isEmpty) {
            return Center(child: Text('No stations found', style: _T.body));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [

              // ── NETWORK SUMMARY ──
              Text('Network Stock Summary', style: _T.h1.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Total stock across all registered stations', style: _T.body.copyWith(fontSize: 12)),
              const SizedBox(height: 16),

              FutureBuilder<Map<String, double>>(
                future: _aggregateStock(stations),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3));
                  }
                  final totals = snap.data!;
                  return Container(
                    decoration: _T.card(),
                    child: Column(
                      children: _fuelTypes.asMap().entries.map((entry) {
                        final isLast = entry.key == _fuelTypes.length - 1;
                        final fuel  = entry.value;
                        final total = totals[fuel] ?? 0;
                        final color = _stockColor(total);
                        final label = _stockLabel(total);

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Color bar indicator
                                  Container(
                                    width: 4, height: 36,
                                    decoration: BoxDecoration(
                                      color: color, borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(fuel, style: _T.h2.copyWith(fontSize: 13)),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${total.toStringAsFixed(0)} L',
                                        style: _T.h2.copyWith(color: color, fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(label,
                                            style: _T.label.copyWith(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) Divider(height: 1, color: _T.border, indent: 34),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── PER STATION BREAKDOWN ──
              Text('Per Station Breakdown', style: _T.h1.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text('Individual fuel levels at each station', style: _T.body.copyWith(fontSize: 12)),
              const SizedBox(height: 16),

              ...stations.map((stationDoc) {
                final stationData = stationDoc.data() as Map<String, dynamic>;
                final stationName = stationData['stationName'] as String? ?? stationData['name'] as String? ?? 'Unknown';
                final brand = stationData['brand'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: _T.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Station header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_gas_station_rounded,
                                  color: Color(0xFFF59E0B), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$stationName${brand.isNotEmpty ? ' ($brand)' : ''}',
                              style: _T.h2.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 20, color: _T.border, indent: 16, endIndent: 16),

                      // Stock chips
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _db
                              .collection('stations')
                              .doc(stationDoc.id)
                              .collection('stock')
                              .snapshots(),
                          builder: (context, stockSnap) {
                            if (!stockSnap.hasData) {
                              return Text('Loading...', style: _T.body.copyWith(fontSize: 12));
                            }
                            final stockDocs = stockSnap.data!.docs
                                .where((d) => (d.data() as Map)['fuelType'] != 'Air Pump')
                                .toList();

                            if (stockDocs.isEmpty) {
                              return Text('No stock data', style: _T.body.copyWith(fontSize: 12));
                            }

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: stockDocs.map((d) {
                                final data   = d.data() as Map<String, dynamic>;
                                final fuel   = data['fuelType'] as String? ?? '';
                                final litres = (data['stockLitres'] as num?)?.toDouble() ?? 0;
                                final color  = _stockColor(litres);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '${_shortFuelName(fuel)}: ${litres.toStringAsFixed(0)}L',
                                    style: _T.label.copyWith(
                                        color: color, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
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

  Future<Map<String, double>> _aggregateStock(List<QueryDocumentSnapshot> stations) async {
    final totals = <String, double>{for (final f in _fuelTypes) f: 0};
    for (final station in stations) {
      final stockSnap = await _db.collection('stations').doc(station.id).collection('stock').get();
      for (final doc in stockSnap.docs) {
        final data  = doc.data() as Map<String, dynamic>;
        final fuel  = data['fuelType'] as String? ?? '';
        final litres = (data['stockLitres'] as num?)?.toDouble() ?? 0;
        if (totals.containsKey(fuel)) totals[fuel] = (totals[fuel] ?? 0) + litres;
      }
    }
    return totals;
  }

  Color _stockColor(double litres) {
    if (litres <= 0)     return const Color(0xFFDC2626);
    if (litres < 500)    return const Color(0xFFF59E0B);
    if (litres < 2000)   return const Color(0xFF2563EB);
    return const Color(0xFF16A34A);
  }

  String _stockLabel(double litres) {
    if (litres <= 0)   return 'Empty';
    if (litres < 500)  return 'Critical';
    if (litres < 2000) return 'Low';
    return 'Good';
  }

  String _shortFuelName(String fuel) {
    return fuel
        .replaceAll('Octane', '').replaceAll('Petrol', 'P')
        .replaceAll('Auto Diesel', 'ADsl').replaceAll('Super Diesel', 'SDsl')
        .replaceAll('Lanka Kerosene', 'LKer').replaceAll('Industrial Kerosene', 'IKer')
        .trim();
  }
}