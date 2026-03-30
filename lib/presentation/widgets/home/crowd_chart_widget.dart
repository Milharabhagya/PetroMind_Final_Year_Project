import 'package:flutter/material.dart';
import '../../../data/repositories/crowd_repository.dart';
import '../../../services/location_service.dart';

class CrowdChartWidget extends StatefulWidget {
  final double userLat;
  final double userLng;
  final double radiusKm;

  const CrowdChartWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    this.radiusKm = 5.0,
  });

  @override
  State<CrowdChartWidget> createState() =>
      _CrowdChartWidgetState();
}

class _CrowdChartWidgetState
    extends State<CrowdChartWidget> {
  Map<int, int> _hourlyData = {};
  bool _isLoading = true;
  int _maxCount = 1;
  final int _currentHour = DateTime.now().hour;

  final Map<int, double> _defaultData = {
    6: 0.25, 7: 0.2,  8: 0.35, 9: 0.45, 10: 0.5,
    11: 0.65, 12: 0.8, 13: 1.0, 14: 0.9, 15: 0.7,
    16: 0.5,  17: 0.6, 18: 0.8, 19: 0.9, 20: 0.7,
    21: 0.5,  22: 0.3, 23: 0.2,
  };

  @override
  void initState() {
    super.initState();
    _loadCrowdData();
    _listenToRealtime();
  }

  bool _isNearby(Map<String, dynamic> data) {
    final lat = (data['stationLat'] as num?)?.toDouble();
    final lng = (data['stationLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return true;
    final dist = LocationService.distanceKm(
        widget.userLat, widget.userLng, lat, lng);
    return dist <= widget.radiusKm;
  }

  Future<void> _loadCrowdData() async {
    try {
      final data =
          await CrowdRepository.getHourlyCrowdAggregated();
      final maxVal = data.values.isEmpty
          ? 1
          : data.values.reduce((a, b) => a > b ? a : b);
      if (mounted) {
        setState(() {
          _hourlyData = data;
          _maxCount = maxVal == 0 ? 1 : maxVal;
          _isLoading = false;
        });
      }
    } catch (e) {
      // ✅ Silently fall back to default pattern
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _listenToRealtime() {
    CrowdRepository.streamTodayCrowdData().listen(
      (snapshot) {
        final Map<int, int> updated = {};
        for (int i = 6; i <= 23; i++) updated[i] = 0;

        for (final doc in snapshot.docs) {
          final data =
              doc.data() as Map<String, dynamic>;
          if (!_isNearby(data)) continue;
          final hour = data['hour'] as int? ?? 0;
          final count =
              data['crowdCount'] as int? ?? 0;
          if (updated.containsKey(hour)) {
            updated[hour] =
                (updated[hour] ?? 0) + count;
          }
        }

        final maxVal = updated.values.isEmpty
            ? 1
            : updated.values
                .reduce((a, b) => a > b ? a : b);

        if (mounted) {
          setState(() {
            _hourlyData = updated;
            _maxCount = maxVal == 0 ? 1 : maxVal;
          });
        }
      },
      // ✅ Handle Firestore errors — don't crash
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      // ✅ Keep stream alive even after errors
      cancelOnError: false,
    );
  }

  double _getBarHeight(int hour) {
    if (_hourlyData.isEmpty ||
        (_hourlyData[hour] ?? 0) == 0) {
      return _defaultData[hour] ?? 0.2;
    }
    return (_hourlyData[hour] ?? 0) / _maxCount;
  }

  Color _getBarColor(int hour) {
    final factor = _getBarHeight(hour);
    if (factor < 0.4) return Colors.green;
    if (factor < 0.7) return Colors.orange;
    return Colors.red;
  }

  String _getBestTime() {
    if (_hourlyData.isEmpty ||
        _hourlyData.values.every((v) => v == 0)) {
      return '8 AM - 10 AM';
    }
    int minHour = 6;
    int minCount = _hourlyData[6] ?? 0;
    for (final entry in _hourlyData.entries) {
      if (entry.value < minCount) {
        minCount = entry.value;
        minHour = entry.key;
      }
    }
    return '${_formatHour(minHour)} - ${_formatHour(minHour + 2)}';
  }

  String _getWorstTime() {
    if (_hourlyData.isEmpty ||
        _hourlyData.values.every((v) => v == 0)) {
      return '6 PM - 8 PM';
    }
    int maxHour = 18;
    int maxCount = _hourlyData[18] ?? 0;
    for (final entry in _hourlyData.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxHour = entry.key;
      }
    }
    return '${_formatHour(maxHour)} - ${_formatHour(maxHour + 2)}';
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── HEADER ──
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'When to Fill Your Tank?',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Row(children: [
                Container(
                  width: 8, height: 8,
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
          const SizedBox(height: 2),
          Text(
            'Stations within ${widget.radiusKm.toInt()} km of you',
            style: const TextStyle(
                color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // ── CHART OR LOADING ──
          if (_isLoading)
            const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2),
              ),
            )
          else
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$_maxCount',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8)),
                    const SizedBox(height: 10),
                    Text(
                        '${(_maxCount * 0.75).toInt()}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8)),
                    const SizedBox(height: 10),
                    Text(
                        '${(_maxCount * 0.5).toInt()}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8)),
                    const SizedBox(height: 10),
                    Text(
                        '${(_maxCount * 0.25).toInt()}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8)),
                  ],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(children: [
                    // Legend
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        _legendDot(Colors.green,
                            'Best  ${_getBestTime()}'),
                        const SizedBox(width: 10),
                        _legendDot(Colors.red,
                            'Busy  ${_getWorstTime()}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bars
                    SizedBox(
                      height: 100,
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: _defaultData.keys
                            .map((hour) {
                          final isNow =
                              hour == _currentHour;
                          return Stack(
                            alignment:
                                Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: isNow ? 18 : 14,
                                height: 100 *
                                    _getBarHeight(hour),
                                decoration:
                                    BoxDecoration(
                                  color: _getBarColor(
                                      hour),
                                  borderRadius:
                                      BorderRadius
                                          .circular(4),
                                  border: isNow
                                      ? Border.all(
                                          color: Colors
                                              .white,
                                          width: 1.5)
                                      : null,
                                ),
                              ),
                              if (isNow)
                                const Positioned(
                                  top: -14,
                                  child: Text('Now',
                                      style: TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize: 7,
                                          fontWeight:
                                              FontWeight
                                                  .bold)),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ),
              ],
            ),

          const SizedBox(height: 6),

          // ── X-AXIS LABELS ──
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: const [
                Text('6AM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('8AM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('10AM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('12PM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('2PM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('4PM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('6PM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('8PM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('10PM', style: TextStyle(color: Colors.white70, fontSize: 7)),
                Text('12AM', style: TextStyle(color: Colors.white70, fontSize: 7)),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.only(top: 4, left: 20),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: const [
                Text('Low Crowd',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9)),
                Text('Peak Crowd',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
            color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 9)),
    ]);
  }
}