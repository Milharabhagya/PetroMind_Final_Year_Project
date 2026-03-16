import 'package:flutter/material.dart';
import '../../data/repositories/fuel_price_repository.dart';

class FuelPriceProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _allPrices = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get allPrices => _allPrices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, dynamic>> get retailPrices =>
      _allPrices
          .where((p) => p['category'] == 'retail')
          .toList();

  List<Map<String, dynamic>> get industrialPrices =>
      _allPrices
          .where((p) => p['category'] == 'industrial')
          .toList();

  // Stream all prices in real-time
  Stream<List<Map<String, dynamic>>> streamAllPrices() {
    return FuelPriceRepository.streamAllPrices();
  }

  // Update a single fuel price
  Future<void> updatePrice({
    required String id,
    required double price,
    required String effectiveDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await FuelPriceRepository.updatePrice(
        id: id,
        price: price,
        effectiveDate: effectiveDate,
      );
    } catch (e) {
      _error = 'Failed to update price.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Initialize default prices
  Future<void> initializeDefaults() async {
    try {
      await FuelPriceRepository.initializeDefaultPrices();
    } catch (e) {
      _error = 'Failed to initialize prices.';
      notifyListeners();
    }
  }
}