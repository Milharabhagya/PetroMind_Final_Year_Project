import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Submit complaint
  static Future<void> submitComplaint({
    required String userId,
    required String stationId,
    required String subject,
    required String message,
    double? rating,
  }) async {
    await _db.collection('complaints').add({
      'userId': userId,
      'stationId': stationId,
      'subject': subject,
      'message': message,
      'rating': rating,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream complaints for a user
  static Stream<QuerySnapshot> streamUserComplaints(String userId) {
    return _db
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Stream complaints for a station (for station owner to view)
  static Stream<QuerySnapshot> streamStationComplaints(String stationId) {
    return _db
        .collection('complaints')
        .where('stationId', isEqualTo: stationId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update complaint status
  static Future<void> updateStatus({
    required String complaintId,
    required String status, // 'pending', 'reviewed', 'resolved'
  }) async {
    await _db.collection('complaints').doc(complaintId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}