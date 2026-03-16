import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/station_repository.dart';

class StationProvider extends ChangeNotifier {
  Map<String, dynamic>? _stationData;
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get stationData => _stationData;
  Map<String, dynamic>? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream all stations
  Stream<QuerySnapshot> streamAllStations() {
    return StationRepository.streamAllStations();
  }

  // Stream single station
  Stream<DocumentSnapshot> streamStation(String stationId) {
    return StationRepository.streamStation(stationId);
  }

  // Load analytics
  Future<void> loadAnalytics(String stationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _analytics = await StationRepository.getAdminAnalytics(stationId);
    } catch (e) {
      _error = 'Failed to load analytics.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Update settings
  Future<void> updateSettings({
    required String stationId,
    String? stationName,
    String? phone,
    String? address,
    Map<String, String>? operatingHours,
    List<String>? services,
    String? promotionMessage,
    bool? isOpen,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await StationRepository.updateStationSettings(
        stationId: stationId,
        stationName: stationName,
        phone: phone,
        address: address,
        operatingHours: operatingHours,
        services: services,
        promotionMessage: promotionMessage,
        isOpen: isOpen,
      );
    } catch (e) {
      _error = 'Failed to update settings.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Update stock
  Future<void> updateStock({
    required String stationId,
    required String fuelType,
    required String type,
    required double amount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await StationRepository.updateStock(
        stationId: stationId,
        fuelType: fuelType,
        type: type,
        amount: amount,
      );
    } catch (e) {
      _error = 'Failed to update stock.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Record sale
  Future<void> recordSale({
    required String stationId,
    required String fuelType,
    required double liters,
    required double pricePerLiter,
    required String customerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await StationRepository.recordSale(
        stationId: stationId,
        fuelType: fuelType,
        liters: liters,
        pricePerLiter: pricePerLiter,
        customerId: customerId,
      );
    } catch (e) {
      _error = 'Failed to record sale.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Stream sales
  Stream<QuerySnapshot> streamSales(String stationId) {
    return StationRepository.streamSales(stationId);
  }

  // Stream stock logs
  Stream<QuerySnapshot> streamStockLogs(String stationId) {
    return StationRepository.streamStockLogs(stationId);
  }

  // Submit rating
  Future<void> submitRating({
    required String stationId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await StationRepository.submitRating(
        stationId: stationId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      _error = 'Failed to submit rating.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Stream ratings
  Stream<QuerySnapshot> streamRatings(String stationId) {
    return StationRepository.streamRatings(stationId);
  }

  // Broadcast notification
  Future<void> broadcastNotification({
    required String stationId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await StationRepository.broadcastNotification(
        stationId: stationId,
        title: title,
        message: message,
        type: type,
      );
    } catch (e) {
      _error = 'Failed to send notification.';
      notifyListeners();
    }
  }
}