import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import '../profile/profile_screen.dart';
import '../../../data/repositories/crowd_repository.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationName;
  final String brand;
  final String address;
  final String distance;
  final String time;
  final double lat;
  final double lng;
  final double userLat;
  final double userLng;
  final double rating;
  final bool? isOpen;
  final bool hasPetrol;
  final bool hasDiesel;
  final bool hasOctane98;

  const StationDetailScreen({
    super.key,
    required this.stationName,
    required this.brand,
    required this.address,
    required this.distance,
    required this.time,
    required this.lat,
    required this.lng,
    required this.userLat,
    required this.userLng,
    this.rating = 0,
    this.isOpen,
    this.hasPetrol = true,
    this.hasDiesel = true,
    this.hasOctane98 = false,
  });

  @override
  State<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState
    extends State<StationDetailScreen> {
  bool _reportingCrowd = false;
  bool _crowdReported = false;
  bool _loadingRoute = false;
  String _routeDistance = '';
  String _routeTime = '';

  // ✅ Live crowd data for THIS station today
  String _currentCrowdLabel = 'Loading...';
  Color _currentCrowdColor = Colors.grey;
  int _reportsThisHour = 0;
  bool _loadingCrowd = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
    _listenToThisStationCrowd();
  }

  // ✅ Listen to real-time crowd reports
  // for THIS specific station only
  void _listenToThisStationCrowd() {
    final stationId = widget.stationName
        .toLowerCase()
        .replaceAll(' ', '_');
    final currentHour = DateTime.now().hour;

    CrowdRepository.streamTodayCrowdData().listen(
      (snapshot) {
        final List<int> thisHourReports = [];

        for (final doc in snapshot.docs) {
          final data =
              doc.data() as Map<String, dynamic>;
          final docStationId =
              data['stationId'] as String? ?? '';
          final hour = data['hour'] as int? ?? 0;
          final count =
              data['crowdCount'] as int? ?? 0;

          if (docStationId == stationId &&
              hour == currentHour) {
            thisHourReports.add(count);
          }
        }

        if (mounted) {
          setState(() {
            _loadingCrowd = false;
            _reportsThisHour = thisHourReports.length;

            if (thisHourReports.isEmpty) {
              _currentCrowdLabel = 'No reports yet';
              _currentCrowdColor = Colors.grey;
            } else {
              final avg = thisHourReports.reduce(
                      (a, b) => a + b) /
                  thisHourReports.length;
              if (avg <= 2) {
                _currentCrowdLabel = 'Empty';
                _currentCrowdColor = Colors.green;
              } else if (avg <= 8) {
                _currentCrowdLabel = 'Moderate';
                _currentCrowdColor = Colors.orange;
              } else {
                _currentCrowdLabel = 'Busy';
                _currentCrowdColor = Colors.red;
              }
            }
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _loadingCrowd = false;
            _currentCrowdLabel = 'Unavailable';
            _currentCrowdColor = Colors.grey;
          });
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _fetchRoute() async {
    if (!kIsWeb) return;
    setState(() => _loadingRoute = true);
    try {
      final result =
          await js.context.callMethod('getRoute', [
        widget.userLat,
        widget.userLng,
        widget.lat,
        widget.lng,
      ]);
      final r = result as js.JsObject;
      if (mounted) {
        setState(() {
          _routeDistance = '${r['distanceKm']} km';
          _routeTime = '${r['durationMin']} min';
          _loadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeDistance = widget.distance;
          _routeTime = widget.time;
          _loadingRoute = false;
        });
      }
    }
  }

  void _openNavigation() {
    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${widget.userLat},${widget.userLng}'
        '&destination=${widget.lat},${widget.lng}'
        '&travelmode=driving';
    js.context.callMethod('open', [url, '_blank']);
  }

  Future<void> _reportCrowd(int crowdLevel) async {
    setState(() => _reportingCrowd = true);
    try {
      await CrowdRepository.logCrowdCount(
        stationId: widget.stationName
            .toLowerCase()
            .replaceAll(' ', '_'),
        crowdCount: crowdLevel,
        stationLat: widget.lat,
        stationLng: widget.lng,
      );
      if (mounted) {
        setState(() {
          _reportingCrowd = false;
          _crowdReported = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Crowd level reported! Chart will update.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reportingCrowd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to report.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCrowdReportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How busy is this station right now?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your report updates the live chart for everyone',
              style: TextStyle(
                  color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(children: [
              // ✅ Empty
              _crowdOption(
                icon: Icons.sentiment_very_satisfied,
                label: 'Empty',
                sub: '0–5 cars',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _reportCrowd(1);
                },
              ),
              const SizedBox(width: 8),
              // ✅ Moderate
              _crowdOption(
                icon: Icons.sentiment_neutral,
                label: 'Moderate',
                sub: '5–15 cars',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _reportCrowd(8);
                },
              ),
              const SizedBox(width: 8),
              // ✅ Busy
              _crowdOption(
                icon: Icons.sentiment_very_dissatisfied,
                label: 'Busy',
                sub: '15+ cars',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _reportCrowd(15);
                },
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _crowdOption({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(
                color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            Text(sub,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Station Detail',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius:
                      BorderRadius.circular(8)),
              child: const Icon(Icons.person,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const ProfileScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ── BRAND HEADER ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: Colors.grey[200]!),
                borderRadius:
                    BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.05),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getBrandColor()
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      Icons.local_gas_station,
                      color: _getBrandColor(),
                      size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(widget.stationName,
                          style: TextStyle(
                              color: _getBrandColor(),
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold)),
                      const Text('FUEL STATION',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                    ],
                  ),
                ),
                if (widget.isOpen != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isOpen!
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isOpen!
                            ? Colors.green[300]!
                            : Colors.red[300]!,
                      ),
                    ),
                    child: Text(
                      widget.isOpen!
                          ? 'Open'
                          : 'Closed',
                      style: TextStyle(
                        color: widget.isOpen!
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),

            // ✅ LIVE CROWD STATUS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _loadingCrowd
                    ? Colors.grey[100]
                    : _currentCrowdColor
                        .withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: _loadingCrowd
                      ? Colors.grey[300]!
                      : _currentCrowdColor
                          .withValues(alpha: 0.3),
                ),
              ),
              child: Row(children: [
                Icon(
                  _currentCrowdLabel == 'Empty'
                      ? Icons.sentiment_very_satisfied
                      : _currentCrowdLabel ==
                              'Moderate'
                          ? Icons.sentiment_neutral
                          : _currentCrowdLabel ==
                                  'Busy'
                              ? Icons
                                  .sentiment_very_dissatisfied
                              : Icons.people_outline,
                  color: _loadingCrowd
                      ? Colors.grey
                      : _currentCrowdColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text(
                          'Current Crowd: ',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          _loadingCrowd
                              ? 'Loading...'
                              : _currentCrowdLabel,
                          style: TextStyle(
                            color: _loadingCrowd
                                ? Colors.grey
                                : _currentCrowdColor,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ]),
                      Text(
                        _reportsThisHour == 0
                            ? 'No customer reports this hour yet'
                            : '$_reportsThisHour customer report${_reportsThisHour == 1 ? '' : 's'} this hour',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── MAIN CARD ──
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(widget.stationName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on,
                              color: Colors.white60,
                              size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(
                                  widget.address,
                                  style: const TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize: 12))),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          _infoChip(
                              Icons.directions_car,
                              _loadingRoute
                                  ? '...'
                                  : _routeDistance),
                          const SizedBox(width: 8),
                          _infoChip(
                              Icons.access_time,
                              _loadingRoute
                                  ? '...'
                                  : _routeTime),
                          if (widget.rating > 0) ...[
                            const SizedBox(width: 8),
                            _infoChip(Icons.star,
                                widget.rating
                                    .toStringAsFixed(1),
                                color: Colors.amber),
                          ],
                        ]),
                      ],
                    ),
                  ),

                  // ── FUEL AVAILABILITY ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Row(children: [
                      _stockCard(
                        'Petrol',
                        widget.hasPetrol
                            ? 'Available'
                            : 'Unknown',
                        widget.hasPetrol
                            ? Colors.green
                            : Colors.grey,
                        widget.hasPetrol
                            ? Colors.green[50]!
                            : Colors.grey[100]!,
                      ),
                      const SizedBox(width: 8),
                      _stockCard(
                        'Diesel',
                        widget.hasDiesel
                            ? 'Available'
                            : 'Unknown',
                        widget.hasDiesel
                            ? Colors.blue
                            : Colors.grey,
                        widget.hasDiesel
                            ? Colors.blue[50]!
                            : Colors.grey[100]!,
                      ),
                      const SizedBox(width: 8),
                      _stockCard(
                        'Super',
                        widget.hasOctane98
                            ? 'Available'
                            : 'Unknown',
                        widget.hasOctane98
                            ? Colors.orange
                            : Colors.grey,
                        widget.hasOctane98
                            ? Colors.orange[50]!
                            : Colors.grey[100]!,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ── NAVIGATE BUTTON ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          shape:
                              RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              12)),
                        ),
                        icon: const Icon(
                            Icons.navigation,
                            color: Color(0xFF8B0000)),
                        label: Text(
                          _loadingRoute
                              ? 'Calculating route...'
                              : 'Navigate  •  $_routeDistance  •  $_routeTime',
                          style: const TextStyle(
                              color: Color(0xFF8B0000),
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        onPressed: _loadingRoute
                            ? null
                            : _openNavigation,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ REPORT CROWD BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              _crowdReported
                                  ? Colors.green[700]
                                  : Colors.white
                                      .withValues(
                                          alpha: 0.15),
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 14),
                          shape:
                              RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              12)),
                        ),
                        icon: _reportingCrowd
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ))
                            : Icon(
                                _crowdReported
                                    ? Icons
                                        .check_circle
                                    : Icons.people,
                                color: Colors.white),
                        label: Text(
                          _crowdReported
                              ? 'Thanks for reporting! 🎉'
                              : 'Report Current Crowd',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        onPressed: (_reportingCrowd ||
                                _crowdReported)
                            ? null
                            : _showCrowdReportSheet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Hint text under button
                  if (!_crowdReported)
                    const Padding(
                      padding: EdgeInsets.only(
                          bottom: 12),
                      child: Text(
                        'Your report updates the chart in real time for all users',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label,
      {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),
    );
  }

  Color _getBrandColor() {
    switch (widget.brand) {
      case 'LAUGFS': return Colors.green[700]!;
      case 'SHELL': return Colors.orange[700]!;
      case 'SINOPEC': return Colors.red[700]!;
      case 'IOC': return Colors.blue[700]!;
      case 'CEYPETCO': return Colors.purple[700]!;
      case 'CALTEX': return Colors.blue[600]!;
      default: return const Color(0xFF8B0000);
    }
  }

  Widget _stockCard(String fuel, String status,
      Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station,
                color: textColor, size: 16),
            const SizedBox(height: 4),
            Text(fuel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
            Text(status,
                style: TextStyle(
                    color: textColor, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}