import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../profile/profile_screen.dart';

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
  });

  @override
  State<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState
    extends State<StationDetailScreen> {
  GoogleMapController? _mapController;

  // ✅ Pre-calculate bounds to avoid inline ternary errors
  LatLngBounds _getBounds() {
    final minLat = widget.userLat < widget.lat
        ? widget.userLat
        : widget.lat;
    final maxLat = widget.userLat > widget.lat
        ? widget.userLat
        : widget.lat;
    final minLng = widget.userLng < widget.lng
        ? widget.userLng
        : widget.lng;
    final maxLng = widget.userLng > widget.lng
        ? widget.userLng
        : widget.lng;
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('user'),
        position: LatLng(widget.userLat, widget.userLng),
        infoWindow:
            const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue),
        zIndex: 2,
      ),
      Marker(
        markerId: const MarkerId('station'),
        position: LatLng(widget.lat, widget.lng),
        infoWindow:
            InfoWindow(title: widget.stationName),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed),
        zIndex: 1,
      ),
    };
  }

  Set<Polyline> _buildRoute() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(widget.userLat, widget.userLng),
          LatLng(widget.lat, widget.lng),
        ],
        color: Colors.blue[700]!,
        width: 4,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      ),
    };
  }

  void _fitBounds() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(_getBounds(), 60),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BRAND HEADER ──
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.05),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                          widget.isOpen! ? 'Open' : 'Closed',
                          style: TextStyle(
                            color: widget.isOpen!
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── MAIN CARD ──
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Station info
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
                            child: Text(widget.address,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          _infoChip(
                              Icons.directions_car,
                              widget.distance),
                          const SizedBox(width: 8),
                          _infoChip(
                              Icons.access_time,
                              widget.time),
                          if (widget.rating > 0) ...[
                            const SizedBox(width: 8),
                            _infoChip(
                                Icons.star,
                                widget.rating
                                    .toStringAsFixed(1),
                                color: Colors.amber),
                          ],
                        ]),
                      ],
                    ),
                  ),

                  // ── IN-APP GOOGLE MAP ──
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16),
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition:
                                CameraPosition(
                              target: LatLng(
                                (widget.userLat +
                                        widget.lat) /
                                    2,
                                (widget.userLng +
                                        widget.lng) /
                                    2,
                              ),
                              zoom: 12,
                            ),
                            markers: _buildMarkers(),
                            polylines: _buildRoute(),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              Future.delayed(
                                const Duration(
                                    milliseconds: 500),
                                _fitBounds,
                              );
                            },
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: true,
                            mapType: MapType.normal,
                          ),

                          // Time badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _mapBadge(
                              Icons.access_time,
                              widget.time,
                              Colors.white,
                              const Color(0xFF8B0000),
                            ),
                          ),

                          // Distance badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _mapBadge(
                              Icons.navigation,
                              widget.distance,
                              const Color(0xFF8B0000),
                              Colors.white,
                            ),
                          ),

                          // Fit bounds button
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _fitBounds,
                              child: Container(
                                padding:
                                    const EdgeInsets.all(
                                        6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(
                                              alpha: 0.15),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                    Icons.fit_screen,
                                    color:
                                        Color(0xFF8B0000),
                                    size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── STOCK INFO ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Row(children: [
                      _stockCard('92', 'In Stock',
                          Colors.green,
                          Colors.green[50]!),
                      const SizedBox(width: 8),
                      _stockCard('95 Low', 'Low Stock',
                          Colors.orange,
                          Colors.orange[50]!),
                      const SizedBox(width: 8),
                      _stockCard('Diesel', 'Out of Stock',
                          Colors.grey, Colors.grey[100]!),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // ── SERVICES ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Row(children: [
                      _serviceCard(Icons.tire_repair,
                          'Air Pump', 'Busy',
                          Colors.orange),
                      const SizedBox(width: 8),
                      _serviceCard(
                          Icons.star,
                          'Rating',
                          widget.rating > 0
                              ? '${widget.rating.toStringAsFixed(1)} / 5.0'
                              : 'No ratings yet',
                          Colors.amber),
                    ]),
                  ),
                  const SizedBox(height: 16),
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
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

  Widget _mapBadge(IconData icon, String label,
      Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: textColor),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor)),
      ]),
    );
  }

  Color _getBrandColor() {
    switch (widget.brand) {
      case 'LAUGFS':
        return Colors.green[700]!;
      case 'SHELL':
        return Colors.orange[700]!;
      case 'SINOPEC':
        return Colors.red[700]!;
      case 'IOC':
        return Colors.blue[700]!;
      case 'CEYPETCO':
        return Colors.purple[700]!;
      case 'CALTEX':
        return Colors.blue[600]!;
      default:
        return const Color(0xFF8B0000);
    }
  }

  Widget _stockCard(String fuel, String status,
      Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle,
                      color: textColor, size: 8),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(fuel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
            Text(status,
                style: TextStyle(
                    color: textColor, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(IconData icon, String title,
      String sub, Color subColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                Text(sub,
                    style: TextStyle(
                        color: subColor, fontSize: 10)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}