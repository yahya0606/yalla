import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final String from;
  final String to;
  final double price;
  final List<String> stops;
  final String carNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteModel({
    required this.id,
    required this.from,
    required this.to,
    required this.price,
    required this.stops,
    required this.createdAt,
    required this.updatedAt,
    required this.carNumber,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    try {
      return RouteModel(
        id: json['id'] as String? ?? '',
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        stops: List<String>.from(json['stops'] as List? ?? []),
        carNumber: json['carNumber'] as String? ?? '',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      //print('Error creating RouteModel from json: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'price': price,
      'stops': stops,
      'carNumber': carNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RouteModel copyWith({
    String? id,
    String? from,
    String? to,
    double? price,
    List<String>? stops,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteModel(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      price: price ?? this.price,
      stops: stops ?? this.stops,
      carNumber: carNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 