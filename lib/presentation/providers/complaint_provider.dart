import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/complaint_repository.dart';

class ComplaintProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _submitted = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get submitted => _submitted;

  // Submit complaint
  Future<void> submitComplaint({
    required String userId,
    required String stationId,
    required String subject,
    required String message,
    double? rating,
  }) async {
    _isLoading = true;
    _error = null;
    _submitted = false;
    notifyListeners();
    try {
      await ComplaintRepository.submitComplaint(
        userId: userId,
        stationId: stationId,
        subject: subject,
        message: message,
        rating: rating,
      );
      _submitted = true;
    } catch (e) {
      _error = 'Failed to submit complaint.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // Stream user complaints
  Stream<QuerySnapshot> streamUserComplaints(String userId) {
    return ComplaintRepository.streamUserComplaints(userId);
  }

  // Stream station complaints
  Stream<QuerySnapshot> streamStationComplaints(String stationId) {
    return ComplaintRepository.streamStationComplaints(stationId);
  }

  // Update status
  Future<void> updateStatus({
    required String complaintId,
    required String status,
  }) async {
    try {
      await ComplaintRepository.updateStatus(
        complaintId: complaintId,
        status: status,
      );
    } catch (e) {
      _error = 'Failed to update status.';
      notifyListeners();
    }
  }

  void reset() {
    _submitted = false;
    _error = null;
    notifyListeners();
  }
}