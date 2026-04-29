import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // ✅ Stores average crowd level per hour
  // from TODAY's real reports only
  Map<int, double> _hourlyAvg = {};
  Map<int, int> _hourlyCount = {};
  bool _isLoading = true;
  int _totalReportsToday = 0;
  final int _currentHour = DateTime.now().hour;

  // ✅ Fallback pattern when no real data exists
  final Map<int, double> _defaultData = {
    6: 0.25, 7: 0.2,  8: 0.35, 9: 0.45, 10: 0.5,
    11: 0.65, 12: 0.8, 13: 1.0, 14: 0.9, 15: 0.7,
    16: 0.5,  17: 0.6, 18: 0.8, 19: 0.9, 20: 0.7,
    21: 0.5,  22: 0.3, 23: 0.2,
  };

  @override
  void initState() {
    super.initState();
    _listenToTodayReports();
  }

  bool _isNearby(Map<String, dynamic> data) {
    final lat =
        (data['stationLat'] as num?)?.toDouble();
    final lng =
        (data['stationLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return true;
    final dist = LocationService.distanceKm(
        widget.userLat, widget.userLng, lat, lng);
    return dist <= widget.radiusKm;
  }

  // ✅ Listen to today's crowd reports in real time
  // Groups by hour and averages the crowd levels
  void _listenToTodayReports() {
    CrowdRepository.streamTodayCrowdData().listen(
      (snapshot) {
        // hour -> list of crowd counts reported
        final Map<int, List<int>> hourlyRaw = {};
        for (int i = 6; i <= 23; i++) {
          hourlyRaw[i] = [];
        }

        for (final doc in snapshot.docs) {
          final data =
              doc.data() as Map<String, dynamic>;
          if (!_isNearby(data)) continue;
          final hour = data['hour'] as int? ?? 0;
          final count =
              data['crowdCount'] as int? ?? 0;
          if (hourlyRaw.containsKey(hour)) {
            hourlyRaw[hour]!.add(count);
          }
        }

        // ✅ Calculate average per hour
        final Map<int, double> avg = {};
        final Map<int, int> counts = {};
        int totalReports = 0;

        for (final entry in hourlyRaw.entries) {
          counts[entry.key] = entry.value.length;
          totalReports += entry.value.length;
          if (entry.value.isEmpty) {
            avg[entry.key] = 0;
          } else {
            avg[entry.key] = entry.value
                    .reduce((a, b) => a + b) /
                entry.value.length;
          }
        }

        if (mounted) {
          setState(() {
            _hourlyAvg = avg;
            _hourlyCount = counts;
            _totalReportsToday = totalReports;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      cancelOnError: false,
    );
  }

  // ✅ Returns 0.0–1.0 bar height
  // Uses real data if available, fallback if not
  double _getBarHeight(int hour) {
    final hasRealData = _totalReportsToday > 0 &&
        (_hourlyCount[hour] ?? 0) > 0;

    if (hasRealData) {
      // ✅ Normalize: 0 = empty, 5 = moderate, 15 = busy
      // Max crowd count is 15, so divide by 15
      return (_hourlyAvg[hour] ?? 0) / 15.0;
    }
    return _defaultData[hour] ?? 0.2;
  }

  // ✅ Color based on crowd level
  Color _getBarColor(int hour) {
    final hasRealData = _totalReportsToday > 0 &&
        (_hourlyCount[hour] ?? 0) > 0;

    if (hasRealData) {
      final avg = _hourlyAvg[hour] ?? 0;
      if (avg <= 2) return Colors.green;       // Empty
      if (avg <= 8) return Colors.orange;      // Moderate
      return Colors.red;                        // Busy
    }

    final factor = _defaultData[hour] ?? 0.2;
    if (factor < 0.4) return Colors.green;
    if (factor < 0.7) return Colors.orange;
    return Colors.red;
  }

  // ✅ Current station crowd label
  String _getCurrentCrowdLabel() {
    if (_totalReportsToday == 0) return 'No reports yet today';
    final avg = _hourlyAvg[_currentHour] ?? 0;
    final count = _hourlyCount[_currentHour] ?? 0;
    if (count == 0) return 'No reports this hour';
    if (avg <= 2) return 'Currently Empty 🟢';
    if (avg <= 8) return 'Moderately Busy 🟡';
    return 'Very Busy 🔴';
  }

  String _getBestTime() {
    if (_totalReportsToday == 0) return '8 AM - 10 AM';
    double minAvg = double.infinity;
    int minHour = 8;
    for (final entry in _hourlyAvg.entries) {
      if ((_hourlyCount[entry.key] ?? 0) > 0 &&
          entry.value < minAvg) {
        minAvg = entry.value;
        minHour = entry.key;
      }
    }
    return '${_formatHour(minHour)} - ${_formatHour(minHour + 2)}';
  }

  String _getWorstTime() {
    if (_totalReportsToday == 0) return '6 PM - 8 PM';
    double maxAvg = 0;
    int maxHour = 18;
    for (final entry in _hourlyAvg.entries) {
      if ((_hourlyCount[entry.key] ?? 0) > 0 &&
          entry.value > maxAvg) {
        maxAvg = entry.value;
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
          const SizedBox(height: 2),
          Text(
            'Stations within ${widget.radiusKm.toInt()} km of you',
            style: const TextStyle(
                color: Colors.white70, fontSize: 12),
          ),

          // ✅ Current crowd status banner
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getCurrentCrowdLabel(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  _totalReportsToday > 0
                      ? '$_totalReportsToday report${_totalReportsToday == 1 ? '' : 's'} today'
                      : 'Based on estimates',
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── CHART OR LOADING ──
          if (_isLoading)
            const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
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
                    _yLabel('Busy'),
                    const SizedBox(height: 20),
                    _yLabel('Mod'),
                    const SizedBox(height: 20),
                    _yLabel('Empty'),
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
                            MainAxisAlignment
                                .spaceEvenly,
                        children:
                            _defaultData.keys.map((hour) {
                          final isNow =
                              hour == _currentHour;
                          final hasReport =
                              (_hourlyCount[hour] ?? 0) >
                                  0;
                          return Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: isNow ? 18 : 14,
                                height: 100 *
                                    _getBarHeight(hour)
                                        .clamp(0.05, 1.0),
                                decoration: BoxDecoration(
                                  color:
                                      _getBarColor(hour),
                                  borderRadius:
                                      BorderRadius
                                          .circular(4),
                                  border: isNow
                                      ? Border.all(
                                          color:
                                              Colors.white,
                                          width: 1.5)
                                      : null,
                                  // ✅ Dimmed if no real
                                  // data for this hour
                                  boxShadow: hasReport
                                      ? [
                                          BoxShadow(
                                            color: _getBarColor(
                                                    hour)
                                                .withValues(
                                                    alpha:
                                                        0.5),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                              if (isNow)
                                const Positioned(
                                  top: -14,
                                  child: Text('Now',
                                      style: TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize: 7,
                                          fontWeight:
                                              FontWeight
                                                  .bold)),
                                ),
                              // ✅ Show report count
                              // above bar if reported
                              if (hasReport && !isNow)
                                Positioned(
                                  top: -12,
                                  child: Text(
                                    '${_hourlyCount[hour]}',
                                    style: const TextStyle(
                                        color:
                                            Colors.white60,
                                        fontSize: 6),
                                  ),
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
                Text('6AM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('8AM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('10AM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('12PM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('2PM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('4PM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('6PM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('8PM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('10PM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
                Text('12AM',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 7)),
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

          // ✅ Data source note
          if (_totalReportsToday == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ No customer reports yet today — showing estimates. Visit a station and report the crowd!',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _yLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: Colors.white54, fontSize: 7));
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
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