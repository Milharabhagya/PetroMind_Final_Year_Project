// lib/services/location_service.dart
//
// ✅ SINGLE SOURCE OF TRUTH FOR GPS — used by every screen.
//
// HOW IT WORKS:
//   1. App starts → LocationService.init() is called ONCE (from main.dart or
//      home_screen initState).
//   2. The first successful GPS fix is stored in _position and NEVER replaced
//      unless you explicitly call init(force: true).
//   3. Every subsequent call to getCurrentLocation() returns the cached fix
//      instantly — NO new GPS request, NO drift, NO inconsistency.
//
// EXISTING API — all callers compile with zero changes:
//   LocationService.getCurrentLocation()   ← home_screen, auto_crowd_service
//   LocationService.distanceKm(...)        ← crowd_chart_widget
//
// SINGLETON API — used by chatbot:
//   await LocationService.instance.init()
//   LocationService.instance.hasLocation
//   LocationService.instance.contextString

import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationService {
  // ─── SINGLETON ──────────────────────────────────────────────────────────────
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cached;           // locked after first successful fix
  bool      _fetching = false; // guard against parallel calls
  Future<Position?>? _inflight; // single shared future while fetching

  // ── Accessors ────────────────────────────────────────────────────────────────
  Position? get position    => _cached;
  double?   get lat         => _cached?.latitude;
  double?   get lng         => _cached?.longitude;
  bool      get hasLocation => _cached != null;

  /// Human-readable GPS context string for the AI system prompt.
  String get contextString {
    if (_cached != null) {
      return 'GPS Coordinates: '
          'Latitude ${_cached!.latitude.toStringAsFixed(5)}, '
          'Longitude ${_cached!.longitude.toStringAsFixed(5)}. '
          'This is in Sri Lanka. Use these to find the nearest city/town '
          'and nearby fuel stations from the stations list.';
    }
    return 'Location not yet available — do not ask the user for their location.';
  }

  // ── init() — call once from home_screen or main.dart ─────────────────────────
  /// Fetches GPS and caches it permanently for this app session.
  /// Safe to call multiple times — subsequent calls return immediately.
  Future<void> init({bool force = false}) async {
    if (_cached != null && !force) return; // already have a fix
    if (_inflight != null) { await _inflight; return; } // fetch in progress

    _inflight = _fetchOnce();
    final pos = await _inflight;
    _inflight = null;
    if (pos != null) _cached = pos;
  }

  // ─── STATIC METHODS (backward-compatible) ────────────────────────────────────

  /// Returns the cached GPS fix (or fetches it if not yet available).
  /// Subsequent calls return the SAME position — no GPS drift.
  ///
  /// Used by: home_screen.dart, auto_crowd_service.dart
  static Future<Position?> getCurrentLocation() async {
    // If already cached, return immediately — no new GPS request
    if (instance._cached != null) return instance._cached;

    // Otherwise fetch once and cache
    await instance.init();
    return instance._cached;
  }

  /// Straight-line distance in km between two lat/lng points (Haversine).
  /// Used by: crowd_chart_widget.dart
  static double distanceKm(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  // ─── PRIVATE ─────────────────────────────────────────────────────────────────
  static Future<Position?> _fetchOnce() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      }
    } catch (_) {}
    return null;
  }

  static double _rad(double deg) => deg * math.pi / 180;
}