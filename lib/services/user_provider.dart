import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _stationData;
  Map<String, dynamic>? _adminAnalytics;
  bool _isLoading = false;

  Map<String, dynamic>? get userData => _userData;
  Map<String, dynamic>? get stationData => _stationData;
  Map<String, dynamic>? get adminAnalytics => _adminAnalytics;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  String get firstName => _userData?['firstName'] ?? 'User';
  String get fullName =>
      '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim();
  String get stationName =>
      _stationData?['stationName'] ?? 'My Station';
  String get stationOwnerName =>
      '${_stationData?['firstName'] ?? ''} ${_stationData?['lastName'] ?? ''}'.trim();

  // ── LOAD CUSTOMER ──
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();
    _userData = await FirestoreService.getUserData();
    _isLoading = false;
    notifyListeners();
  }

  // ── LOAD STATION ──
  Future<void> loadStationData() async {
    _isLoading = true;
    notifyListeners();
    _stationData = await FirestoreService.getStationData();
    _isLoading = false;
    notifyListeners();
  }

  // ── LOAD ADMIN ANALYTICS ──
  Future<void> loadAdminAnalytics() async {
    if (currentUid == null) return;
    _isLoading = true;
    notifyListeners();
    _adminAnalytics = await FirestoreService.getAdminAnalytics(currentUid!);
    _isLoading = false;
    notifyListeners();
  }

  // ── UPDATE STATION SETTINGS ──
  Future<void> updateStationSettings({
    String? stationName,
    String? phone,
    String? address,
    Map<String, String>? operatingHours,
    List<String>? services,
    String? promotionMessage,
    bool? isOpen,
  }) async {
    if (currentUid == null) return;
    await FirestoreService.updateStationSettings(
      stationId: currentUid!,
      stationName: stationName,
      phone: phone,
      address: address,
      operatingHours: operatingHours,
      services: services,
      promotionMessage: promotionMessage,
      isOpen: isOpen,
    );
    await loadStationData();
  }

  // ── UPDATE FUEL PRICES ──
  Future<void> updateFuelPrices(Map<String, double> prices) async {
    if (currentUid == null) return;
    await FirestoreService.updateFuelPrices(
      stationId: currentUid!,
      prices: prices,
    );
    await loadStationData();
  }

  // ── SIGN OUT ──
  Future<void> signOut() async {
    await AuthService.signOut();
    _userData = null;
    _stationData = null;
    _adminAnalytics = null;
    notifyListeners();
  }
}