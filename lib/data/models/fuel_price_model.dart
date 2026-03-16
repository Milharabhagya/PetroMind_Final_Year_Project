import 'package:cloud_firestore/cloud_firestore.dart';

class FuelPriceModel {
  final String id;
  final String name;
  final double price;
  final String category; // 'retail' or 'industrial'
  final String effectiveDate;
  final DateTime updatedAt;

  FuelPriceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.effectiveDate,
    required this.updatedAt,
  });

  factory FuelPriceModel.fromMap(
      String id, Map<String, dynamic> map) {
    return FuelPriceModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      category: map['category'] ?? 'retail',
      effectiveDate: map['effectiveDate'] ?? '',
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'category': category,
        'effectiveDate': effectiveDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}