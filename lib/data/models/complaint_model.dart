import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String stationId;
  final String subject;
  final String message;
  final String status; // 'pending', 'reviewed', 'resolved'
  final double? rating;
  final DateTime? createdAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.subject,
    required this.message,
    required this.status,
    this.rating,
    this.createdAt,
  });

  factory ComplaintModel.fromMap(String id, Map<String, dynamic> map) {
    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      stationId: map['stationId'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      rating: (map['rating'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}