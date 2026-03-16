import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String fuelType;
  final double targetPrice;
  final String stationId;
  final bool isActive;
  final DateTime? createdAt;

  AlertModel({
    required this.id,
    required this.fuelType,
    required this.targetPrice,
    required this.stationId,
    required this.isActive,
    this.createdAt,
  });

  factory AlertModel.fromMap(String id, Map<String, dynamic> map) {
    return AlertModel(
      id: id,
      fuelType: map['fuelType'] ?? '',
      targetPrice: (map['targetPrice'] as num).toDouble(),
      stationId: map['stationId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}