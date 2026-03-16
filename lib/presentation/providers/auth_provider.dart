import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

class AppAuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, dynamic>> registerCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await AuthRepository.registerCustomer(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    if (!result['success']) _error = result['error'];
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> registerStation({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await AuthRepository.registerStation(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    if (!result['success']) _error = result['error'];
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> loginCustomer({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await AuthRepository.loginCustomer(
      email: email,
      password: password,
    );
    if (!result['success']) _error = result['error'];
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> loginStation({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await AuthRepository.loginStation(
      email: email,
      password: password,
    );
    if (!result['success']) _error = result['error'];
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await AuthRepository.sendPasswordReset(email);
    if (!result['success']) _error = result['error'];
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await AuthRepository.signOut();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}