import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String tripId;
  final String passengerId;
  final String driverId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.driverId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'passengerId': passengerId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] as String,
      tripId: map['tripId'] as String,
      passengerId: map['passengerId'] as String,
      driverId: map['driverId'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ReviewModel copyWith({
    String? id,
    String? tripId,
    String? passengerId,
    String? driverId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 