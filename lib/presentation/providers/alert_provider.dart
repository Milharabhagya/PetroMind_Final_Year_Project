import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/alert_repository.dart';

class AlertProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stream alerts for user
  Stream<QuerySnapshot> streamAlerts(String userId) {
    return AlertRepository.streamAlerts(userId);
  }

  // Stream notifications
  Stream<QuerySnapshot> streamNotifications() {
    return AlertRepository.streamNotifications();
  }

  // Create alert
  Future<void> createAlert({
    required String userId,
    required String fuelType,
    required double targetPrice,
    required String stationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await AlertRepository.createAlert(
        userId: userId,
        fuelType: fuelType,
        targetPrice: targetPrice,
        stationId: stationId,
      );
    } catch (e) {
      _error = 'Failed to create alert.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Delete alert
  Future<void> deleteAlert({
    required String userId,
    required String alertId,
  }) async {
    try {
      await AlertRepository.deleteAlert(
          userId: userId, alertId: alertId);
    } catch (e) {
      _error = 'Failed to delete alert.';
      notifyListeners();
    }
  }

  // Toggle alert
  Future<void> toggleAlert({
    required String userId,
    required String alertId,
    required bool isActive,
  }) async {
    try {
      await AlertRepository.toggleAlert(
        userId: userId,
        alertId: alertId,
        isActive: isActive,
      );
    } catch (e) {
      _error = 'Failed to toggle alert.';
      notifyListeners();
    }
  }

  // Mark notification read
  Future<void> markRead(String notificationId) async {
    try {
      await AlertRepository.markRead(notificationId);
    } catch (e) {
      _error = 'Failed to mark as read.';
      notifyListeners();
    }
  }
}