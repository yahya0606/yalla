import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/route_repository.dart';
import '../../data/repositories/driver_availability_repository.dart';
import 'route_model.dart';
import 'driver_availability_model.dart';

enum TripStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

class TripModel {
  final String id;
  final String routeId;
  final String driverId;
  final DateTime date;
  final String time;
  final int availableSeats;
  final int totalSeats;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActiveDriver;
  final bool isAvailableForBooking;
  final int? queueNumber;

  TripModel({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.date,
    required this.time,
    required this.availableSeats,
    required this.totalSeats,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isActiveDriver = false,
    this.isAvailableForBooking = false,
    this.queueNumber,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      routeId: json['routeId'] ?? '',
      driverId: json['driverId'] ?? '',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: json['time'] ?? '',
      availableSeats: json['availableSeats'] ?? 0,
      totalSeats: json['totalSeats'] ?? 0,
      status: TripStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TripStatus.scheduled,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActiveDriver: json['isActiveDriver'] ?? false,
      isAvailableForBooking: json['isAvailableForBooking'] ?? false,
      queueNumber: (json['queueNumber'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'driverId': driverId,
      'date': Timestamp.fromDate(date),
      'time': time,
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActiveDriver': isActiveDriver,
      'isAvailableForBooking': isAvailableForBooking,
      'queueNumber': queueNumber,
    };
  }

  TripModel copyWith({
    String? id,
    String? routeId,
    String? driverId,
    DateTime? date,
    String? time,
    int? availableSeats,
    int? totalSeats,
    TripStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActiveDriver,
    bool? isAvailableForBooking,
    int? queueNumber,
  }) {
    return TripModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      date: date ?? this.date,
      time: time ?? this.time,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActiveDriver: isActiveDriver ?? this.isActiveDriver,
      isAvailableForBooking: isAvailableForBooking ?? this.isAvailableForBooking,
      queueNumber: queueNumber ?? this.queueNumber,
    );
  }

  String getTimeSlotId() {
    return '$routeId-${time.replaceAll(":", "")}';
  }

  String getFormattedTimeSlot() {
    return '$time';
  }

  bool isAvailable() {
    return status == TripStatus.scheduled && availableSeats > 0;
  }

  bool isOnDate(DateTime date) {
    return this.date.year == date.year &&
        this.date.month == date.month &&
        this.date.day == date.day;
  }

  bool isFillingUpFast() {
    return getFillPercentage() >= 80;
  }

  double getFillPercentage() {
    return (totalSeats - availableSeats) / totalSeats * 100;
  }

  Future<String> getFrom(WidgetRef ref) async {
    final routeRepository = ref.read(routeRepositoryProvider);
    final route = await routeRepository.getRouteById(routeId);
    return route?.from ?? 'Unknown';
  }

  Future<String> getTo(WidgetRef ref) async {
    final routeRepository = ref.read(routeRepositoryProvider);
    final route = await routeRepository.getRouteById(routeId);
    return route?.to ?? 'Unknown';
  }
}

// Provider for route
final tripRouteProvider = FutureProvider.family<RouteModel?, String>((ref, routeId) async {
  return ref.read(routeRepositoryProvider).getRouteById(routeId);
});

// Provider for driver availability
final tripDriverAvailabilityProvider = FutureProvider.family<DriverAvailabilityModel?, String>((ref, driverId) async {
  return ref.read(driverAvailabilityRepositoryProvider).getByDriverId(driverId);
});
