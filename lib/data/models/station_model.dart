import 'package:cloud_firestore/cloud_firestore.dart';

class StationModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? stationName;
  final String? phone;
  final String? address;
  final Map<String, double>? fuelPrices;
  final Map<String, double>? stock;
  final Map<String, String>? operatingHours;
  final List<String>? services;
  final String? promotionMessage;
  final bool isOpen;
  final double averageRating;
  final double totalRevenue;
  final DateTime? createdAt;

  StationModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.stationName,
    this.phone,
    this.address,
    this.fuelPrices,
    this.stock,
    this.operatingHours,
    this.services,
    this.promotionMessage,
    this.isOpen = true,
    this.averageRating = 0.0,
    this.totalRevenue = 0.0,
    this.createdAt,
  });

  factory StationModel.fromMap(String uid, Map<String, dynamic> map) {
    return StationModel(
      uid: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'station',
      stationName: map['stationName'],
      phone: map['phone'],
      address: map['address'],
      fuelPrices: map['fuelPrices'] != null
          ? Map<String, double>.from(
              (map['fuelPrices'] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
      stock: map['stock'] != null
          ? Map<String, double>.from(
              (map['stock'] as Map).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
      operatingHours: map['operatingHours'] != null
          ? Map<String, String>.from(map['operatingHours'])
          : null,
      services: map['services'] != null
          ? List<String>.from(map['services'])
          : null,
      promotionMessage: map['promotionMessage'],
      isOpen: map['isOpen'] ?? true,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'stationName': stationName,
        'phone': phone,
        'address': address,
        'fuelPrices': fuelPrices,
        'stock': stock,
        'operatingHours': operatingHours,
        'services': services,
        'promotionMessage': promotionMessage,
        'isOpen': isOpen,
        'averageRating': averageRating,
        'totalRevenue': totalRevenue,
      };

  String get ownerName => '$firstName $lastName';
  String get displayName => stationName ?? '$firstName\'s Station';
}