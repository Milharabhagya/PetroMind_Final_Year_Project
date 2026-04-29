import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js;
import 'dart:async';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'station_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../../../data/models/road_alert_model.dart';
import '../../../data/services/road_alert_service.dart';
import '../../widgets/report_alert_sheet.dart'; // ✅ FIXED

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() =>
      _StationsScreenState();
}

class _StationsScreenState
    extends State<StationsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  double _currentLat = 7.4818;
  double _currentLng = 80.3609;
  bool _locationLoaded = false;
  bool _loadingStations = false;
  List<Map<String, dynamic>> _nearbyStations = [];

  // ✅ Road alert fields
  final RoadAlertService _alertService =
      RoadAlertService();
  StreamSubscription<List<RoadAlert>>?
      _alertSubscription;
  List<RoadAlert> _activeAlerts = [];

  static const String _mapId =
      'petromind-leaflet-map';
  static bool _mapRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerMap();
    _getCurrentLocation();
  }

  // ✅ Start listening to nearby alerts from Firestore
  void _startAlertListener() {
    _alertSubscription?.cancel();
    _alertSubscription = _alertService
        .getNearbyAlerts(
          userLat: _currentLat,
          userLng: _currentLng,
        )
        .listen((alerts) {
      if (mounted) {
        setState(() => _activeAlerts = alerts);
        _updateAlertMarkersOnMap(alerts);
      }
    });
  }

  // ✅ Add alert markers to Leaflet map
  void _updateAlertMarkersOnMap(
      List<RoadAlert> alerts) {
    if (!kIsWeb) return;

    // Clear existing alert markers
    js.context.callMethod('eval', ['''
      if (window._alertMarkers) {
        window._alertMarkers.forEach(function(m) {
          window._leafletMap.removeLayer(m);
        });
      }
      window._alertMarkers = [];
    ''']);

    // Add new alert markers
    for (final alert in alerts) {
      final emoji = _alertEmoji(alert.type);
      final label = _alertLabel(alert.type);
      final color = _alertColorHex(alert.type);
      final timeAgo = _timeAgo(alert.reportedAt);
      final lat = alert.lat;
      final lng = alert.lng;
      final desc = (alert.description ?? '')
          .replaceAll("'", "\\'")
          .replaceAll('"', '\\"');

      js.context.callMethod('eval', ['''
        (function() {
          if (!window._leafletMap) return;
          var alertIcon = L.divIcon({
            html: '<div style="background:$color;color:white;font-size:18px;width:36px;height:36px;border-radius:50%;border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.4);display:flex;align-items:center;justify-content:center;line-height:36px;text-align:center;">$emoji</div>',
            iconSize: [36, 36],
            iconAnchor: [18, 18],
            className: ""
          });
          var popup = "<b style='color:$color'>$label</b><br>${desc.isNotEmpty ? desc + '<br>' : ''}<small>$timeAgo · ${alert.upvotes} confirmations</small>";
          var marker = L.marker([$lat, $lng], { icon: alertIcon })
            .addTo(window._leafletMap)
            .bindPopup(popup);
          window._alertMarkers.push(marker);
        })();
      ''']);
    }
  }

  String _alertEmoji(String type) {
    switch (type) {
      case 'accident': return '🚨';
      case 'police': return '🚔';
      case 'roadblock': return '🚧';
      case 'traffic': return '🚦';
      default: return '⚠️';
    }
  }

  String _alertLabel(String type) {
    switch (type) {
      case 'accident': return 'Accident';
      case 'police': return 'Police Checkpoint';
      case 'roadblock': return 'Road Block';
      case 'traffic': return 'Heavy Traffic';
      default: return 'Alert';
    }
  }

  String _alertColorHex(String type) {
    switch (type) {
      case 'accident': return '#D32F2F';
      case 'police': return '#1565C0';
      case 'roadblock': return '#E65100';
      case 'traffic': return '#F9A825';
      default: return '#616161';
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  void _registerMap() {
    if (!kIsWeb || _mapRegistered) return;
    _mapRegistered = true;

    ui.platformViewRegistry.registerViewFactory(
      _mapId,
      (int viewId) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0';

        final mapDiv = html.DivElement()
          ..id = _mapId
          ..style.width = '100%'
          ..style.height = '100%';

        container.append(mapDiv);

        Future.delayed(
            const Duration(milliseconds: 600), () {
          _initLeaflet();
        });

        return container;
      },
    );
  }

  void _initLeaflet() {
    if (!kIsWeb) return;

    js.context.callMethod('eval', ['''
      window._initPetroMap = function() {
        if (window._leafletMap) return true;
        var el = document.getElementById('$_mapId');
        if (!el) return false;
        try {
          var map = L.map(el, {
            zoomControl: true,
            attributionControl: false,
          }).setView([${_currentLat}, ${_currentLng}], 14);

          L.tileLayer(
            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            { maxZoom: 19 }
          ).addTo(map);

          window._leafletMap = map;
          window._leafletMarkers = [];
          window._alertMarkers = [];
          window._routeLine = null;

          var userIcon = L.divIcon({
            html: '<div style="background:#1565C0;width:16px;height:16px;border-radius:50%;border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.4)"></div>',
            iconSize: [16, 16],
            iconAnchor: [8, 8],
            className: ""
          });

          window._userMarker = L.marker(
            [${_currentLat}, ${_currentLng}],
            { icon: userIcon }
          ).addTo(map).bindPopup("You are here");

          console.log("PetroMind map initialized!");
          return true;
        } catch(e) {
          console.error("Map init error:", e);
          return false;
        }
      };

      (function tryInit(attempt) {
        if (attempt > 10) return;
        var success = window._initPetroMap();
        if (!success) {
          setTimeout(function() {
            tryInit(attempt + 1);
          }, 300 * attempt);
        }
      })(1);
    ''']);
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }
      if (permission ==
          LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationLoaded = true);
          _loadNearbyStations(
              _currentLat, _currentLng);
          _startAlertListener(); // ✅
        }
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _locationLoaded = true;
        });
        _moveMapTo(_currentLat, _currentLng);
        _updateUserMarker(_currentLat, _currentLng);
        _loadNearbyStations(_currentLat, _currentLng);
        _startAlertListener(); // ✅
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationLoaded = true);
        _loadNearbyStations(_currentLat, _currentLng);
        _startAlertListener(); // ✅
      }
    }
  }

  void _moveMapTo(double lat, double lng,
      {int zoom = 14}) {
    if (!kIsWeb) return;
    js.context.callMethod('eval', [
      'if(window._leafletMap){window._leafletMap.setView([$lat,$lng],$zoom);}'
    ]);
  }

  void _updateUserMarker(double lat, double lng) {
    if (!kIsWeb) return;
    js.context.callMethod('eval', [
      'if(window._userMarker){window._userMarker.setLatLng([$lat,$lng]);}'
    ]);
  }

  Future<List<Map<String, dynamic>>> _callJsAsync(
      String fn, List<dynamic> args) async {
    final completer =
        Completer<List<Map<String, dynamic>>>();
    final callbackId =
        'cb_${DateTime.now().millisecondsSinceEpoch}';
    final errorId = 'err_$callbackId';

    js.context[callbackId] =
        js.allowInterop((dynamic result) {
      final List<Map<String, dynamic>> stations = [];
      try {
        final jsArray = result as js.JsArray;
        for (int i = 0; i < jsArray.length; i++) {
          try {
            final item = jsArray[i] as js.JsObject;
            String name = 'Fuel Station';
            String address = 'Sri Lanka';
            double itemLat = _currentLat;
            double itemLng = _currentLng;
            double rating = 0;
            String placeId = 'unknown_$i';

            try { name = item['name']?.toString() ?? 'Fuel Station'; } catch (_) {}
            try { address = item['address']?.toString() ?? 'Sri Lanka'; } catch (_) {}
            try { itemLat = (item['lat'] as num).toDouble(); } catch (_) {}
            try { itemLng = (item['lng'] as num).toDouble(); } catch (_) {}
            try { rating = (item['rating'] as num).toDouble(); } catch (_) {}
            try { placeId = item['placeId']?.toString() ?? 'unknown_$i'; } catch (_) {}

            if (itemLat != _currentLat ||
                itemLng != _currentLng) {
              stations.add({
                'name': name,
                'brand': _detectBrand(name),
                'address': address,
                'lat': itemLat,
                'lng': itemLng,
                'rating': rating,
                'placeId': placeId,
                'isOpen': null,
                'hasPetrol': true,
                'hasDiesel': true,
                'hasOctane98': false,
              });
            }
          } catch (e) {}
        }
      } catch (e) {
        print('❌ Parse error: $e');
      }

      print('✅ Parsed ${stations.length} stations');
      if (!completer.isCompleted) {
        completer.complete(stations);
      }
      js.context.deleteProperty(callbackId);
    });

    js.context[errorId] =
        js.allowInterop((dynamic err) {
      print('❌ JS error: $err');
      if (!completer.isCompleted) {
        completer.complete([]);
      }
      js.context.deleteProperty(errorId);
    });

    final argStr = args
        .map((a) => a is String ? '"$a"' : '$a')
        .join(', ');

    js.context.callMethod('eval', ['''
      (async function() {
        try {
          var result = await $fn($argStr);
          if (window["$callbackId"]) {
            window["$callbackId"](result);
          }
        } catch(e) {
          console.error("JS call error:", e);
          if (window["$errorId"]) {
            window["$errorId"](e.toString());
          }
        }
      })();
    ''']);

    return completer.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () {
        print('⏰ Station search timed out');
        if (!completer.isCompleted) {
          completer.complete([]);
        }
        return [];
      },
    );
  }

  Future<void> _loadNearbyStations(
      double lat, double lng) async {
    if (!kIsWeb) return;
    setState(() => _loadingStations = true);

    try {
      final stations = await _callJsAsync(
          'searchNearbyStations', [lat, lng]);
      print('✅ Got ${stations.length} stations');
      if (mounted) {
        setState(() {
          _nearbyStations = stations;
          _loadingStations = false;
        });
        if (stations.isNotEmpty) {
          _addStationMarkers(stations);
        }
      }
    } catch (e) {
      print('❌ _loadNearbyStations error: $e');
      if (mounted) {
        setState(() => _loadingStations = false);
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _loadingStations = true);
    try {
      final geocodeCompleter =
          Completer<Map<String, double>>();
      final cbId =
          'geocb_${DateTime.now().millisecondsSinceEpoch}';

      js.context[cbId] =
          js.allowInterop((dynamic result) {
        try {
          final jsObj = result as js.JsObject;
          final lat =
              (jsObj['lat'] as num).toDouble();
          final lng =
              (jsObj['lng'] as num).toDouble();
          if (!geocodeCompleter.isCompleted) {
            geocodeCompleter
                .complete({'lat': lat, 'lng': lng});
          }
        } catch (e) {
          if (!geocodeCompleter.isCompleted) {
            geocodeCompleter.complete({
              'lat': _currentLat,
              'lng': _currentLng
            });
          }
        }
        js.context.deleteProperty(cbId);
      });

      js.context.callMethod('eval', ['''
        (async function() {
          try {
            var r = await geocodeAddress("${query.replaceAll('"', '\\"')}");
            if (window["$cbId"]) window["$cbId"](r);
          } catch(e) {
            if (window["$cbId"]) window["$cbId"]({lat:${_currentLat},lng:${_currentLng}});
          }
        })();
      ''']);

      final coords = await geocodeCompleter.future
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            {'lat': _currentLat, 'lng': _currentLng},
      );

      _moveMapTo(coords['lat']!, coords['lng']!);
      await _loadNearbyStations(
          coords['lat']!, coords['lng']!);
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStations = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location not found. Try again.')),
        );
      }
    }
  }

  void _addStationMarkers(
      List<Map<String, dynamic>> stations) {
    if (!kIsWeb) return;

    js.context.callMethod('eval', ['''
      (function() {
        if (!window._leafletMap) return;
        if (window._leafletMarkers) {
          window._leafletMarkers.forEach(function(m) {
            window._leafletMap.removeLayer(m);
          });
        }
        window._leafletMarkers = [];
      })();
    ''']);

    for (final s in stations) {
      final lat = s['lat'];
      final lng = s['lng'];
      final name = (s['name'] as String)
          .replaceAll("'", "\\'")
          .replaceAll('"', '\\"')
          .replaceAll('\n', ' ');
      final dist = _getDistanceText(
          s['lat'] as double, s['lng'] as double);
      final color =
          _getBrandColorHex(s['brand'] as String);

      js.context.callMethod('eval', ['''
        (function() {
          if (!window._leafletMap) return;
          var icon = L.divIcon({
            html: '<div style="background:$color;width:14px;height:14px;border-radius:50%;border:2px solid white;box-shadow:0 2px 4px rgba(0,0,0,0.4)"></div>',
            iconSize: [14, 14],
            iconAnchor: [7, 7],
            className: ""
          });
          var marker = L.marker([$lat, $lng],
              { icon: icon })
            .addTo(window._leafletMap)
            .bindPopup("<b>$name</b><br>$dist");
          window._leafletMarkers.push(marker);
        })();
      ''']);
    }
  }

  String _getBrandColorHex(String brand) {
    switch (brand.toUpperCase()) {
      case 'LAUGFS': return '#2E7D32';
      case 'SHELL': return '#E65100';
      case 'SINOPEC': return '#C62828';
      case 'IOC': return '#1565C0';
      case 'CEYPETCO': return '#6A1B9A';
      case 'CALTEX': return '#1976D2';
      default: return '#8B0000';
    }
  }

  void _drawRouteOnMap(double toLat, double toLng) {
    if (!kIsWeb) return;
    js.context.callMethod('eval', ['''
      (async function() {
        try {
          if (!window._leafletMap) return;
          if (window._routeLine) {
            window._leafletMap.removeLayer(
                window._routeLine);
            window._routeLine = null;
          }
          const route = await getRoute(
            ${_currentLat}, ${_currentLng},
            $toLat, $toLng
          );
          const latlngs = route.coords.map(
            function(c) { return [c.lat, c.lng]; }
          );
          window._routeLine = L.polyline(latlngs, {
            color: "#1565C0",
            weight: 5,
            opacity: 0.9,
            dashArray: "10,6"
          }).addTo(window._leafletMap);
          window._leafletMap.fitBounds(
            window._routeLine.getBounds(),
            { padding: [60, 60] }
          );
          var destIcon = L.divIcon({
            html: '<div style="background:#8B0000;width:18px;height:18px;border-radius:50%;border:3px solid white;box-shadow:0 2px 6px rgba(0,0,0,0.5)"></div>',
            iconSize: [18, 18],
            iconAnchor: [9, 9],
            className: ""
          });
          L.marker([$toLat, $toLng], {icon: destIcon})
            .addTo(window._leafletMap)
            .bindPopup("Destination")
            .openPopup();
        } catch(e) {
          console.error("Route draw error:", e);
        }
      })();
    ''']);
  }

  void _showStationInfoPanel(
      Map<String, dynamic> station) {
    final dist = _getDistanceText(
        station['lat'] as double,
        station['lng'] as double);
    final time = _getTimeEstimate(
        station['lat'] as double,
        station['lng'] as double);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getBrandColor(
                          station['brand'] as String)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    Icons.local_gas_station,
                    color: _getBrandColor(
                        station['brand'] as String),
                    size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      station['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      station['address'] as String,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _infoChipDark(
                  Icons.directions_car, dist),
              const SizedBox(width: 8),
              _infoChipDark(
                  Icons.access_time, time),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _fuelChip('Petrol', Colors.green),
              _fuelChip('Diesel', Colors.blue),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFF8B0000)),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                10)),
                  ),
                  icon: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF8B0000),
                      size: 18),
                  label: const Text('Details',
                      style: TextStyle(
                          color: Color(0xFF8B0000),
                          fontWeight:
                              FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StationDetailScreen(
                          stationName:
                              station['name']
                                  as String,
                          brand: station['brand']
                                  as String? ??
                              'FUEL',
                          address:
                              station['address']
                                  as String,
                          distance: dist,
                          time: time,
                          lat: station['lat']
                              as double,
                          lng: station['lng']
                              as double,
                          userLat: _currentLat,
                          userLng: _currentLng,
                          rating: station['rating']
                              as double,
                          isOpen: station['isOpen']
                              as bool?,
                          hasPetrol:
                              station['hasPetrol']
                                      as bool? ??
                                  true,
                          hasDiesel:
                              station['hasDiesel']
                                      as bool? ??
                                  true,
                          hasOctane98: station[
                                      'hasOctane98']
                                  as bool? ??
                              false,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF8B0000),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                10)),
                  ),
                  icon: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 18),
                  label: const Text('Navigate',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                            '🗺️ Route to ${station['name']} shown on map!'),
                        duration: const Duration(
                            seconds: 2),
                        backgroundColor:
                            const Color(0xFF8B0000),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoChipDark(
      IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF8B0000)
                .withValues(alpha: 0.3)),
      ),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: const Color(0xFF8B0000),
                size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8B0000),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ]),
    );
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

  String _getDistanceText(
      double sLat, double sLng) {
    final meters = Geolocator.distanceBetween(
        _currentLat, _currentLng, sLat, sLng);
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _getTimeEstimate(
      double sLat, double sLng) {
    final meters = Geolocator.distanceBetween(
        _currentLat, _currentLng, sLat, sLng);
    final minutes =
        (meters / 1000 / 30 * 60).round();
    return minutes < 1 ? '1 min' : '$minutes min';
  }

  @override
  void dispose() {
    _alertSubscription?.cancel(); // ✅
    _searchController.dispose();
    if (kIsWeb) {
      js.context.callMethod('eval', ['''
        if (window._leafletMap) {
          window._leafletMap.remove();
          window._leafletMap = null;
          window._userMarker = null;
          window._leafletMarkers = [];
          window._alertMarkers = [];
          window._routeLine = null;
        }
      ''']);
      _mapRegistered = false;
    }
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
            child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Stations',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
        actions: [
          // ✅ Alert count badge
          if (_activeAlerts.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(right: 4),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.warning_amber,
                        color: Color(0xFF8B0000)),
                    onPressed: () =>
                        _showAlertsList(context),
                    tooltip: 'Road Alerts',
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.all(3),
                      decoration:
                          const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_activeAlerts.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (kIsWeb)
            Positioned.fill(
              child: HtmlElementView(
                  viewType: _mapId),
            )
          else
            const Positioned.fill(
              child: Center(
                  child: Text(
                      'Map available on web only')),
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
                borderRadius:
                    BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.1),
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
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Search city or location...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                          color: Colors.grey),
                    ),
                    onSubmitted: _searchLocation,
                    textInputAction:
                        TextInputAction.search,
                  ),
                ),
                if (_loadingStations)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF8B0000),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(
                        Icons.my_location,
                        color: Color(0xFF8B0000),
                        size: 22),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Go to my location',
                  ),
              ]),
            ),
          ),

          // ── LOADING OVERLAY ──
          if (!_locationLoaded)
            Container(
              color: Colors.white
                  .withValues(alpha: 0.9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: Color(0xFF8B0000)),
                    SizedBox(height: 12),
                    Text(
                        'Getting your location...',
                        style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
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

          // ── BOTTOM BUTTONS ──
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Report Alert button
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor:
                        Colors.transparent,
                    builder: (_) => ReportAlertSheet(
                      userLat: _currentLat,
                      userLng: _currentLng,
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 12),
                    margin: const EdgeInsets.only(
                        bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(
                              0xFF8B0000),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.1),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber,
                            color:
                                Color(0xFF8B0000),
                            size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Report Road Alert',
                          style: TextStyle(
                            color:
                                Color(0xFF8B0000),
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // View Stations button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF8B0000),
                    disabledBackgroundColor:
                        Colors.grey[400],
                    minimumSize: const Size(
                        double.infinity, 50),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                12)),
                  ),
                  icon: const Icon(
                      Icons.local_gas_station,
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
                      : () =>
                          _showStationList(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Show active alerts list
  void _showAlertsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Active Road Alerts Nearby',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._activeAlerts.map((alert) {
              return ListTile(
                leading: Text(
                    _alertEmoji(alert.type),
                    style: const TextStyle(
                        fontSize: 24)),
                title: Text(
                    _alertLabel(alert.type),
                    style: const TextStyle(
                        fontWeight:
                            FontWeight.bold)),
                subtitle: Text(
                  '${_timeAgo(alert.reportedAt)} · ${alert.upvotes} confirmations'
                  '${alert.description != null ? '\n${alert.description}' : ''}',
                ),
                trailing: TextButton(
                  onPressed: () {
                    _alertService
                        .upvoteAlert(alert.id);
                    Navigator.pop(context);
                  },
                  child: const Text('👍 Confirm'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showStationList(BuildContext context) {
    final sorted =
        List<Map<String, dynamic>>.from(
            _nearbyStations)
          ..sort((a, b) {
            final dA = Geolocator.distanceBetween(
                _currentLat,
                _currentLng,
                a['lat'] as double,
                a['lng'] as double);
            final dB = Geolocator.distanceBetween(
                _currentLat,
                _currentLng,
                b['lat'] as double,
                b['lng'] as double);
            return dA.compareTo(dB);
          });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StationListPage(
          stations: sorted,
          currentLat: _currentLat,
          currentLng: _currentLng,
          onStationTap: (station) {
            Navigator.pop(context);
            _drawRouteOnMap(
                station['lat'] as double,
                station['lng'] as double);
            Future.delayed(
                const Duration(
                    milliseconds: 300), () {
              if (mounted) {
                _showStationInfoPanel(station);
              }
            });
          },
        ),
      ),
    );
  }

  Widget _fuelChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getBrandColor(String brand) {
    switch (brand) {
      case 'SINOPEC': return Colors.red;
      case 'SHELL': return Colors.orange[800]!;
      case 'IOC': return Colors.blue[800]!;
      case 'CEYPETCO': return Colors.purple[700]!;
      case 'CALTEX': return Colors.blue[600]!;
      default: return Colors.green[700]!;
    }
  }
}

// ── SEPARATE FULL SCREEN STATION LIST PAGE ──
class _StationListPage extends StatelessWidget {
  final List<Map<String, dynamic>> stations;
  final double currentLat;
  final double currentLng;
  final void Function(Map<String, dynamic>)
      onStationTap;

  const _StationListPage({
    required this.stations,
    required this.currentLat,
    required this.currentLng,
    required this.onStationTap,
  });

  String _getDistanceText(
      double sLat, double sLng) {
    final meters = Geolocator.distanceBetween(
        currentLat, currentLng, sLat, sLng);
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _getTimeEstimate(
      double sLat, double sLng) {
    final meters = Geolocator.distanceBetween(
        currentLat, currentLng, sLat, sLng);
    final minutes =
        (meters / 1000 / 30 * 60).round();
    return minutes < 1 ? '1 min' : '$minutes min';
  }

  Color _getBrandColor(String brand) {
    switch (brand) {
      case 'SINOPEC': return Colors.red;
      case 'SHELL': return Colors.orange[800]!;
      case 'IOC': return Colors.blue[800]!;
      case 'CEYPETCO': return Colors.purple[700]!;
      case 'CALTEX': return Colors.blue[600]!;
      default: return Colors.green[700]!;
    }
  }

  Widget _fuelChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${stations.length} Nearby Stations',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: stations.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = stations[i];
          final dist = _getDistanceText(
              s['lat'] as double,
              s['lng'] as double);
          final time = _getTimeEstimate(
              s['lat'] as double,
              s['lng'] as double);
          final isOpen = s['isOpen'] as bool?;

          return GestureDetector(
            onTap: () => onStationTap(s),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getBrandColor(
                            s['brand'] as String)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      Icons.local_gas_station,
                      color: _getBrandColor(
                          s['brand'] as String),
                      size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] as String,
                        style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s['address'] as String,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        _fuelChip('Petrol',
                            Colors.green),
                        _fuelChip(
                            'Diesel', Colors.blue),
                        if (s['hasOctane98'] == true)
                          _fuelChip('Super',
                              Colors.orange),
                        if (isOpen != null) ...[
                          const SizedBox(width: 2),
                          _fuelChip(
                            isOpen
                                ? 'Open'
                                : 'Closed',
                            isOpen
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(dist,
                        style: const TextStyle(
                            color:
                                Color(0xFF8B0000),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold)),
                    Text(time,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF8B0000),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(Icons.navigation,
                              color: Colors.white,
                              size: 12),
                          SizedBox(width: 3),
                          Text('Go',
                              style: TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight
                                          .bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}