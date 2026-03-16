import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _saved = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get saved => _saved;

  // Update user profile
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _error = null;
    _saved = false;
    notifyListeners();
    try {
      await FirestoreService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        photoUrl: photoUrl,
      );
      _saved = true;
    } catch (e) {
      _error = 'Failed to update profile.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Update station settings
  Future<void> updateStationSettings({
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
    _saved = false;
    notifyListeners();
    try {
      await FirestoreService.updateStationSettings(
        stationId: stationId,
        stationName: stationName,
        phone: phone,
        address: address,
        operatingHours: operatingHours,
        services: services,
        promotionMessage: promotionMessage,
        isOpen: isOpen,
      );
      _saved = true;
    } catch (e) {
      _error = 'Failed to update station settings.';
    }
    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _saved = false;
    _error = null;
    notifyListeners();
  }
}