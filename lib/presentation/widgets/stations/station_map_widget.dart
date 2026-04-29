import 'package:flutter/material.dart';
import '../../screens/stations/station_detail_screen.dart';
import '../../models/road_alert_model.dart';
import '../../services/road_alert_service.dart';
import '../report_alert_sheet.dart';

class StationMapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stations;
  final double height;
  final double userLat;
  final double userLng;

  const StationMapWidget({
    super.key,
    required this.stations,
    required this.userLat,
    required this.userLng,
    this.height = 300,
  });

  // ─── Coordinate conversion ───────────────────────────────────────────────────
  Offset _latLngToScreen(double lat, double lng, double width, double height) {
    const double minLat = 7.45;
    const double maxLat = 7.52;
    const double minLng = 80.32;
    const double maxLng = 80.42;

    final x = width * (lng - minLng) / (maxLng - minLng);
    final y = height * (1.0 - (lat - minLat) / (maxLat - minLat));
    return Offset(x, y);
  }

  // ─── Alert icon ──────────────────────────────────────────────────────────────
  IconData _alertIcon(String type) {
    switch (type) {
      case 'accident':
        return Icons.car_crash;
      case 'police':
        return Icons.local_police;
      case 'roadblock':
        return Icons.do_not_enter;
      case 'traffic':
        return Icons.traffic;
      default:
        return Icons.warning_amber;
    }
  }

  // ─── Alert color ─────────────────────────────────────────────────────────────
  Color _alertColor(String type) {
    switch (type) {
      case 'accident':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'roadblock':
        return Colors.orange;
      case 'traffic':
        return Colors.amber[700]!;
      default:
        return Colors.grey;
    }
  }

  // ─── Alert label ─────────────────────────────────────────────────────────────
  String _alertLabel(String type) {
    switch (type) {
      case 'accident':
        return 'Accident';
      case 'police':
        return 'Police';
      case 'roadblock':
        return 'Road Block';
      case 'traffic':
        return 'Traffic';
      default:
        return 'Alert';
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertService = RoadAlertService();

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final userPos = _latLngToScreen(userLat, userLng, w, h);

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: StreamBuilder<List<RoadAlert>>(
              stream: alertService.getNearbyAlerts(
                userLat: userLat,
                userLng: userLng,
              ),
              builder: (context, snapshot) {
                final alerts = snapshot.data ?? [];

                return Stack(
                  children: [
                    // ── Road background ──────────────────────────────────────
                    CustomPaint(
                      size: Size(w, h),
                      painter: _MapRoadPainter(),
                    ),

                    // ── Alert markers ────────────────────────────────────────
                    ...alerts.map((alert) {
                      final pos =
                          _latLngToScreen(alert.lat, alert.lng, w, h);
                      if (pos.dx < 0 ||
                          pos.dx > w ||
                          pos.dy < 0 ||
                          pos.dy > h) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        left: pos.dx - 20,
                        top: pos.dy - 48,
                        child: GestureDetector(
                          onTap: () =>
                              _showAlertDetail(context, alert, alertService),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _alertColor(alert.type),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _alertColor(alert.type)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_alertIcon(alert.type),
                                        color: Colors.white, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      _alertLabel(alert.type),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: _alertColor(alert.type),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // ── Station markers ──────────────────────────────────────
                    ...stations.map((station) {
                      final pos = _latLngToScreen(
                        (station['lat'] as num).toDouble(),
                        (station['lng'] as num).toDouble(),
                        w,
                        h,
                      );
                      if (pos.dx < 0 ||
                          pos.dx > w ||
                          pos.dy < 0 ||
                          pos.dy > h) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        left: pos.dx - 15,
                        top: pos.dy - 40,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StationDetailScreen(
                                stationName: station['name'],
                                brand: station['brand'],
                                address: station['address'],
                                distance: station['distance'],
                                time: station['time'],
                                lat: (station['lat'] as num).toDouble(),
                                lng: (station['lng'] as num).toDouble(),
                                userLat: userLat,
                                userLng: userLng,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: Text(
                                  station['brand'],
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _getBrandColor(station['brand']),
                                  ),
                                ),
                              ),
                              const Icon(Icons.location_on,
                                  color: Color(0xFF8B0000), size: 28),
                            ],
                          ),
                        ),
                      );
                    }),

                    // ── User location (blue dot) ─────────────────────────────
                    Positioned(
                      left: userPos.dx - 10,
                      top: userPos.dy - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),

                    // ── Report alert button ──────────────────────────────────
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ReportAlertSheet(
                            userLat: userLat,
                            userLng: userLng,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B0000),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Report Alert',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ─── Alert detail popup ──────────────────────────────────────────────────────
  void _showAlertDetail(
      BuildContext context, RoadAlert alert, RoadAlertService service) {
    final timeAgo = _timeAgo(alert.reportedAt);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_alertIcon(alert.type), color: _alertColor(alert.type)),
            const SizedBox(width: 8),
            Text(
              _alertLabel(alert.type),
              style: TextStyle(
                  color: _alertColor(alert.type),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alert.description != null &&
                alert.description!.isNotEmpty)
              Text(alert.description!,
                  style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(timeAgo,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.thumb_up_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${alert.upvotes} confirmations',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              service.upvoteAlert(alert.id);
              Navigator.pop(context);
            },
            child: const Text('👍 Confirm'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  Color _getBrandColor(String brand) {
    switch (brand) {
      case 'SINOPEC':
        return Colors.red;
      case 'SHELL':
        return Colors.orange[800]!;
      case 'IOC':
        return Colors.blue[800]!;
      case 'LAUGFS':
        return Colors.green[700]!;
      default:
        return const Color(0xFF8B0000);
    }
  }
}

class _MapRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final yellowRoadPaint = Paint()
      ..color = Colors.yellow[200]!
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.25),
        Offset(size.width, size.height * 0.25), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), yellowRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.6, size.height), yellowRoadPaint);
    canvas.drawLine(Offset(size.width * 0.8, 0),
        Offset(size.width * 0.8, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}