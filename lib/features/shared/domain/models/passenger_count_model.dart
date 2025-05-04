import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerCountModel {
  final String tripId;
  final String carNumber;
  final int currentPassengers;
  final int totalSeats;
  final DateTime lastUpdated;

  PassengerCountModel({
    required this.tripId,
    required this.carNumber,
    required this.currentPassengers,
    required this.totalSeats,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'carNumber': carNumber,
      'currentPassengers': currentPassengers,
      'totalSeats': totalSeats,
      'lastUpdated': lastUpdated,
    };
  }

  factory PassengerCountModel.fromMap(Map<String, dynamic> map) {
    return PassengerCountModel(
      tripId: map['tripId'] as String,
      carNumber: map['carNumber'] as String,
      currentPassengers: map['currentPassengers'] as int,
      totalSeats: map['totalSeats'] as int,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  bool get isAvailable => currentPassengers < totalSeats;
  int get availableSeats => totalSeats - currentPassengers;
} 