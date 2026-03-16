import 'package:flutter/material.dart';
import '../../screens/stations/station_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth,
                      constraints.maxHeight),
                  painter: _MapRoadPainter(),
                ),
                ...stations.map((station) {
                  final x = constraints.maxWidth *
                      (station['lng'] as double);
                  final y = constraints.maxHeight *
                      (station['lat'] as double);
                  return Positioned(
                    left: x - 15,
                    top: y - 40,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StationDetailScreen(
                            stationName: station['name'],
                            brand: station['brand'],
                            address: station['address'],
                            distance: station['distance'],
                            time: station['time'],
                            lat: (station['lat'] as num)
                                .toDouble(),
                            lng: (station['lng'] as num)
                                .toDouble(),
                            userLat: userLat,
                            userLng: userLng,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                          alpha: 0.2),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: Text(
                              station['brand'],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _getBrandColor(
                                    station['brand']),
                              ),
                            ),
                          ),
                          const Icon(Icons.location_on,
                              color: Color(0xFF8B0000),
                              size: 28),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
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
        Offset(size.width, size.height * 0.5),
        yellowRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.6, size.height),
        yellowRoadPaint);
    canvas.drawLine(Offset(size.width * 0.8, 0),
        Offset(size.width * 0.8, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}