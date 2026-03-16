import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import 'station_detail_screen.dart';
import '../profile/profile_screen.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() =>
      _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController =
      TextEditingController();

  LatLng _currentLocation = const LatLng(6.9271, 79.8612);
  bool _locationLoaded = false;
  bool _loadingStations = false;
  List<Map<String, dynamic>> _nearbyStations = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationLoaded = true);
          _loadNearbyStations(_currentLocation);
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation =
              LatLng(position.latitude, position.longitude);
          _locationLoaded = true;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation, 14),
        );
        _loadNearbyStations(_currentLocation);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationLoaded = true);
        _loadNearbyStations(_currentLocation);
      }
    }
  }

  Future<void> _loadNearbyStations(LatLng location) async {
    if (!kIsWeb) return;
    setState(() => _loadingStations = true);
    try {
      final result = await js.context
          .callMethod('searchNearbyStations', [
        location.latitude,
        location.longitude,
      ]);
      final jsArray = result as js.JsArray;
      final List<Map<String, dynamic>> stations = [];
      for (int i = 0; i < jsArray.length; i++) {
        final item = jsArray[i] as js.JsObject;
        final isOpenRaw = item['isOpen'];
        bool? isOpen;
        if (isOpenRaw != null && isOpenRaw is bool) {
          isOpen = isOpenRaw;
        }
        stations.add({
          'name': item['name'] as String,
          'brand': _detectBrand(item['name'] as String),
          'address': item['address'] as String,
          'lat': (item['lat'] as num).toDouble(),
          'lng': (item['lng'] as num).toDouble(),
          'rating': (item['rating'] as num).toDouble(),
          'placeId': item['placeId'] as String,
          'isOpen': isOpen,
        });
      }
      if (mounted) {
        setState(() {
          _nearbyStations = stations;
          _loadingStations = false;
        });
        _buildAllMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStations = false);
        _buildAllMarkers();
      }
    }
  }

  String _detectBrand(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('laugfs')) return 'LAUGFS';
    if (lower.contains('shell')) return 'SHELL';
    if (lower.contains('sinopec')) return 'SINOPEC';
    if (lower.contains('ioc')) return 'IOC';
    if (lower.contains('ceypetco')) return 'CEYPETCO';
    if (lower.contains('caltex')) return 'CALTEX';
    return 'FUEL';
  }

  void _buildAllMarkers() {
    final Set<Marker> markers = {};

    // Blue marker for current location
    markers.add(Marker(
      markerId: const MarkerId('current_location'),
      position: _currentLocation,
      infoWindow: const InfoWindow(title: 'You are here'),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue),
      zIndex: 2,
    ));

    // Red markers for each station
    for (final station in _nearbyStations) {
      final dist =
          _getDistanceText(station['lat'], station['lng']);
      markers.add(Marker(
        markerId:
            MarkerId(station['placeId'] ?? station['name']),
        position: LatLng(station['lat'], station['lng']),
        infoWindow: InfoWindow(
          title: station['name'],
          snippet: dist,
          onTap: () => _openStationDetail(station),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed),
        zIndex: 1,
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  String _getDistanceText(
      double stationLat, double stationLng) {
    final meters = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      stationLat,
      stationLng,
    );
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km away';
  }

  String _getTimeEstimate(
      double stationLat, double stationLng) {
    final meters = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      stationLat,
      stationLng,
    );
    // Estimate ~30km/h average in city
    final minutes = (meters / 1000 / 30 * 60).round();
    if (minutes < 1) return '1 min';
    return '$minutes min';
  }

  void _openStationDetail(Map<String, dynamic> station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StationDetailScreen(
          stationName: station['name'],
          brand: station['brand'] ?? 'FUEL',
          address: station['address'],
          distance: _getDistanceText(
              station['lat'], station['lng']),
          time: _getTimeEstimate(
              station['lat'], station['lng']),
          lat: (station['lat'] as num).toDouble(),
          lng: (station['lng'] as num).toDouble(),
          userLat: _currentLocation.latitude,
          userLng: _currentLocation.longitude,
          rating: (station['rating'] as num).toDouble(),
          isOpen: station['isOpen'],
        ),
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    if (!kIsWeb) return;
    setState(() => _loadingStations = true);
    try {
      final result = await js.context
          .callMethod('geocodeAddress', [query]);
      final jsObj = result as js.JsObject;
      final lat = (jsObj['lat'] as num).toDouble();
      final lng = (jsObj['lng'] as num).toDouble();
      final newLocation = LatLng(lat, lng);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 14),
      );

      await _loadNearbyStations(newLocation);
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStations = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location not found. Try a different search.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text('Stations',
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
      body: Stack(
        children: [
          // ── GOOGLE MAP ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_locationLoaded) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                      _currentLocation, 14),
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),

          // ── SEARCH BAR ──
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(children: [
                const Icon(Icons.search,
                    color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText:
                          'Search city or location...',
                      border: InputBorder.none,
                      hintStyle:
                          TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: _searchLocation,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_loadingStations)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF8B0000),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.my_location,
                        color: Color(0xFF8B0000), size: 22),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Go to my location',
                  ),
              ]),
            ),
          ),

          // ── INITIAL LOADING ──
          if (!_locationLoaded)
            Container(
              color: Colors.white.withValues(alpha: 0.85),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: Color(0xFF8B0000)),
                    SizedBox(height: 12),
                    Text('Getting your location...',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                        'Please allow location access',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),

          // ── VIEW NEARBY STATIONS BUTTON ──
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                disabledBackgroundColor:
                    Colors.grey[400],
                padding: const EdgeInsets.symmetric(
                    vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.local_gas_station,
                  color: Colors.white),
              label: Text(
                _loadingStations
                    ? 'Searching stations...'
                    : _nearbyStations.isEmpty
                        ? 'No stations found nearby'
                        : 'View ${_nearbyStations.length} Nearby Stations',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: (_loadingStations ||
                      _nearbyStations.isEmpty)
                  ? null
                  : () => _showStationList(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showStationList(BuildContext context) {
    // Sort by distance
    final sorted =
        List<Map<String, dynamic>>.from(_nearbyStations)
          ..sort((a, b) {
            final dA = Geolocator.distanceBetween(
              _currentLocation.latitude,
              _currentLocation.longitude,
              a['lat'],
              a['lng'],
            );
            final dB = Geolocator.distanceBetween(
              _currentLocation.latitude,
              _currentLocation.longitude,
              b['lat'],
              b['lng'],
            );
            return dA.compareTo(dB);
          });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Nearby Fuel Stations',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            const SizedBox(height: 4),
            Text(
              '${sorted.length} stations found within 10km',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: sorted.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (_, i) {
                  final station = sorted[i];
                  final dist = _getDistanceText(
                      station['lat'], station['lng']);
                  final time = _getTimeEstimate(
                      station['lat'], station['lng']);
                  final rating =
                      (station['rating'] as num)
                          .toDouble();
                  final isOpen =
                      station['isOpen'] as bool?;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                            vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF8B0000)
                              .withValues(alpha: 0.1),
                      child: Icon(
                          Icons.local_gas_station,
                          color: _getBrandColor(
                              station['brand']),
                          size: 20),
                    ),
                    title: Text(station['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(station['address'],
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                        const SizedBox(height: 2),
                        Row(children: [
                          if (rating > 0) ...[
                            const Icon(Icons.star,
                                color: Colors.amber,
                                size: 12),
                            Text(
                                ' ${rating.toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontSize: 11)),
                            const SizedBox(width: 8),
                          ],
                          if (isOpen != null)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius:
                                    BorderRadius.circular(
                                        4),
                              ),
                              child: Text(
                                isOpen
                                    ? 'Open'
                                    : 'Closed',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isOpen
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight:
                                        FontWeight.bold),
                              ),
                            ),
                        ]),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(dist,
                            style: const TextStyle(
                                color: Color(0xFF8B0000),
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold)),
                        Text(time,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11)),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(station['lat'],
                              station['lng']),
                          16,
                        ),
                      );
                      _openStationDetail(station);
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
      case 'CEYPETCO':
        return Colors.purple[700]!;
      case 'CALTEX':
        return Colors.blue[600]!;
      default:
        return Colors.green[700]!;
    }
  }
}