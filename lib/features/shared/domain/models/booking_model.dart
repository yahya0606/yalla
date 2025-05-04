import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/auth/domain/models/user_model.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed
}

enum PaymentMethod {
  cash,
  online
}

class BookingModel {
  final String id;
  final String tripId;
  final String passengerId;
  final String passengerName;
  final String from;
  final String to;
  final int seats;
  final double totalPrice;
  final BookingStatus status;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRefundable;
  final TripModel? trip;
  final UserModel? passenger;

  BookingModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.passengerName,
    required this.from,
    required this.to,
    required this.seats,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isRefundable = false,
    this.trip,
    this.passenger,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      return BookingModel(
        id: json['id'] ?? '',
        tripId: json['tripId'] ?? '',
        passengerId: json['passengerId'] ?? '',
        passengerName: json['passengerName'] ?? '',
        from: json['from'] ?? '',
        to: json['to'] ?? '',
        seats: json['seats'] ?? 0,
        totalPrice: json['totalPrice'] ?? 0.0,
        status: BookingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BookingStatus.pending,
        ),
        paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == json['paymentMethod'],
          orElse: () => PaymentMethod.cash,
        ),
        isPaid: json['isPaid'] ?? false,
        date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRefundable: json['isRefundable'] as bool? ?? false,
        trip: json['trip'] != null
            ? TripModel.fromJson(json['trip'] as Map<String, dynamic>)
            : null,
        passenger: json['passenger'] != null
            ? UserModel.fromJson(json['passenger'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('Error creating BookingModel from json: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'from': from,
      'to': to,
      'seats': seats,
      'totalPrice': totalPrice,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isRefundable': isRefundable,
      if (trip != null) 'trip': trip!.toJson(),
      if (passenger != null) 'passenger': passenger!.toJson(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? tripId,
    String? passengerId,
    String? passengerName,
    String? from,
    String? to,
    int? seats,
    double? totalPrice,
    BookingStatus? status,
    PaymentMethod? paymentMethod,
    bool? isPaid,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRefundable,
    TripModel? trip,
    UserModel? passenger,
  }) {
    return BookingModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      from: from ?? this.from,
      to: to ?? this.to,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRefundable: isRefundable ?? this.isRefundable,
      trip: trip ?? this.trip,
      passenger: passenger ?? this.passenger,
    );
  }

  // Generate QR code data
  String getQrCodeData() {
    return {
      'bookingId': id,
      'tripId': tripId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'from': from,
      'to': to,
      'seats': seats,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod.name,
      'isPaid': isPaid,
      'date': date.toIso8601String(),
    }.toString();
  }
} 