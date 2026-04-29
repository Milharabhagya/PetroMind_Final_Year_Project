import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class FuelStockWidget extends StatelessWidget {
  final double userLat;
  final double userLng;
  final double radiusKm;

  const FuelStockWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    this.radiusKm = 5.0,
  });

  static const List<Map<String, String>> _fuelKeys = [
    {'label': 'Petrol 92', 'docId': 'petrol_92_octane', 'fuelType': 'Petrol 92 Octane'},
    {'label': 'Petrol 95', 'docId': 'petrol_95_octane', 'fuelType': 'Petrol 95 Octane'},
    {'label': 'Auto Diesel', 'docId': 'auto_diesel', 'fuelType': 'Auto Diesel'},
    {'label': 'Super Diesel', 'docId': 'super_diesel', 'fuelType': 'Super Diesel'},
  ];

  static const double _maxLitres = 5000;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stations')
          .snapshots(),
      builder: (context, stationsSnap) {
        if (!stationsSnap.hasData) {
          return const SizedBox.shrink();
        }

        final nearbyStations = stationsSnap
            .data!.docs
            .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat =
              (data['latitude'] as num?)?.toDouble();
          final lng =
              (data['longitude'] as num?)?.toDouble();
          if (lat == null || lng == null) return false;
          final dist = Geolocator.distanceBetween(
                  userLat, userLng, lat, lng) /
              1000;
          return dist <= radiusKm;
        }).toList();

        if (nearbyStations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fuel Stock Nearby',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text('Live',
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11)),
                  ]),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Stations within ${radiusKm.toInt()} km of you',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12),
              ),
              const SizedBox(height: 12),

              ...nearbyStations.map((stationDoc) {
                final stationData = stationDoc.data()
                    as Map<String, dynamic>;
                final stationName =
                    stationData['stationName']
                            as String? ??
                        'Fuel Station';
                final stationId = stationDoc.id;

                return _StationStockCard(
                  stationId: stationId,
                  stationName: stationName,
                  fuelKeys: _fuelKeys,
                  maxLitres: _maxLitres,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── SINGLE STATION STOCK CARD ──
class _StationStockCard extends StatelessWidget {
  final String stationId;
  final String stationName;
  final List<Map<String, String>> fuelKeys;
  final double maxLitres;

  const _StationStockCard({
    required this.stationId,
    required this.stationName,
    required this.fuelKeys,
    required this.maxLitres,
  });

  Color _barColor(double litres) {
    if (litres <= 0) return Colors.red;
    if (litres < 200) return Colors.red;
    if (litres < 500) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(double litres) {
    if (litres <= 0) return 'Out of Stock';
    if (litres < 200) return 'Critical';
    if (litres < 500) return 'Low';
    if (litres < 1500) return 'Moderate';
    return 'Good';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stations')
          .doc(stationId)
          .collection('stock')
          .snapshots(),
      builder: (context, stockSnap) {
        if (!stockSnap.hasData) {
          return const SizedBox.shrink();
        }

        final Map<String, double> stockMap = {};
        for (final doc in stockSnap.data!.docs) {
          final data =
              doc.data() as Map<String, dynamic>;
          final fuelType =
              data['fuelType'] as String? ?? '';
          final litres =
              (data['stockLitres'] as num?)
                      ?.toDouble() ??
                  0;
          stockMap[fuelType] = litres;
        }

        final hasAnyData = fuelKeys.any((f) =>
            stockMap.containsKey(f['fuelType']));
        if (!hasAnyData) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white
                    .withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // Station name
              Row(children: [
                const Icon(Icons.local_gas_station,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stationName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // ✅ Fuel rows with progress bars
              ...fuelKeys.map((fuel) {
                final litres =
                    stockMap[fuel['fuelType']] ?? 0;
                final pct =
                    (litres / maxLitres).clamp(0.0, 1.0);
                final color = _barColor(litres);
                final hasData = stockMap
                    .containsKey(fuel['fuelType']);

                return Padding(
                  padding: const EdgeInsets.only(
                      bottom: 8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            fuel['label']!,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: hasData
                                  ? color.withValues(
                                      alpha: 0.2)
                                  : Colors.grey
                                      .withValues(
                                          alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(
                                      4),
                            ),
                            child: Text(
                              hasData
                                  ? _stockLabel(litres)
                                  : 'No data',
                              style: TextStyle(
                                color: hasData
                                    ? color
                                    : Colors.grey,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // ✅ FIXED LinearProgressIndicator
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hasData ? pct : 0,
                          minHeight: 8,
                          backgroundColor: Colors.white
                              .withValues(alpha: 0.15),
                          color: hasData
                              ? color
                              : Colors.grey
                                  .withValues(alpha: 0.4),
                        ),
                      ),

                      if (hasData && litres > 0)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  top: 2),
                          child: Text(
                            '${litres.toStringAsFixed(0)} L available',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // ✅ Last updated time
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stations')
                    .doc(stationId)
                    .collection('stock')
                    .orderBy('updatedAt',
                        descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, timeSnap) {
                  if (!timeSnap.hasData ||
                      timeSnap.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final ts = (timeSnap
                          .data!.docs.first
                          .data() as Map)['updatedAt']
                      as Timestamp?;
                  if (ts == null) {
                    return const SizedBox.shrink();
                  }
                  final diff = DateTime.now()
                      .difference(ts.toDate());
                  String timeStr;
                  if (diff.inMinutes < 1) {
                    timeStr = 'Just now';
                  } else if (diff.inMinutes < 60) {
                    timeStr = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeStr = '${diff.inHours}h ago';
                  } else {
                    timeStr = '${diff.inDays}d ago';
                  }
                  return Row(children: [
                    const Icon(Icons.update,
                        size: 10,
                        color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(
                      'Updated $timeStr by station owner',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9),
                    ),
                  ]);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}