import 'package:cloud_firestore/cloud_firestore.dart';

class DriverAvailabilityModel {
  final String id;
  final String driverId;
  final String routeId;
  final String carNumber;
  final String startTime;
  final String endTime;
  final List<String> workingDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? queueNumber;
  final DateTime? lastArrivalTime;
  final bool isInQueue;
  final int availableSeats;
  final List<DateTime> holidayDates;
  final List<DateTime> availableDates; // These are dates the driver is available
  final List<String> availableTimes; // Example: ['08:00', '14:00']

  DriverAvailabilityModel({
    required this.id,
    required this.driverId,
    required this.routeId,
    required this.carNumber,
    required this.startTime,
    required this.endTime,
    required this.workingDays,
    required this.createdAt,
    required this.updatedAt,
    this.queueNumber,
    this.lastArrivalTime,
    this.isInQueue = false,
    this.availableSeats = 8,
    required this.holidayDates,
    required this.availableDates,
    required this.availableTimes,
  });

  bool isAvailableOnDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return availableDates.any((availableDate) =>
    availableDate.year == day.year &&
        availableDate.month == day.month &&
        availableDate.day == day.day);
  }

  bool isAvailableForBooking(String preferredTime, bool isFlexible) {
    if (isFlexible) {
      return true; // If flexible, any available time is acceptable
    }
    if (preferredTime.isEmpty) {
      return true; // If no preferred time, accept any
    }
    return availableTimes.contains(preferredTime);
  }

  factory DriverAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DriverAvailabilityModel(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      routeId: json['routeId']?.toString() ?? '',
      carNumber: json['carNumber']?.toString() ?? '',
      startTime: json['startTime'] ?? '00:00',
      endTime: json['endTime'] ?? '23:59',
      workingDays: List<String>.from(json['workingDays'] ?? []),
      holidayDates: (json['holidayDates'] as List<dynamic>? ?? [])
          .map((e) => (e as Timestamp).toDate())
          .toList(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastArrivalTime: (json['lastArrivalTime'] as Timestamp?)?.toDate(),
      isInQueue: json['isInQueue'] ?? false,
      availableSeats: json['availableSeats'] ?? 8,
      queueNumber: json['queueNumber'],
      availableDates: (json['availableDates'] as List<dynamic>?)
          ?.map((e) => (e as Timestamp).toDate())
          .toList() ?? [],
      availableTimes: List<String>.from(json['availableTimes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'routeId': routeId,
      'carNumber': carNumber,
      'startTime': startTime,
      'endTime': endTime,
      'workingDays': workingDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'queueNumber': queueNumber,
      'lastArrivalTime': lastArrivalTime != null
          ? Timestamp.fromDate(lastArrivalTime!)
          : null,
      'isInQueue': isInQueue,
      'availableSeats': availableSeats,
      'holidayDates': holidayDates.map((d) => Timestamp.fromDate(d)).toList(),
      'availableDates': availableDates.map((d) => Timestamp.fromDate(d)).toList(),
      'availableTimes': availableTimes,
    };
  }

  DriverAvailabilityModel copyWith({
    String? id,
    String? driverId,
    String? routeId,
    String? carNumber,
    String? startTime,
    String? endTime,
    List<String>? workingDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? queueNumber,
    DateTime? lastArrivalTime,
    bool? isInQueue,
    int? availableSeats,
    List<DateTime>? holidayDates,
    List<DateTime>? availableDates,
    List<String>? availableTimes,
  }) {
    return DriverAvailabilityModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      routeId: routeId ?? this.routeId,
      carNumber: carNumber ?? this.carNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workingDays: workingDays ?? this.workingDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      queueNumber: queueNumber ?? this.queueNumber,
      lastArrivalTime: lastArrivalTime ?? this.lastArrivalTime,
      isInQueue: isInQueue ?? this.isInQueue,
      availableSeats: availableSeats ?? this.availableSeats,
      holidayDates: holidayDates ?? this.holidayDates,
      availableDates: availableDates ?? this.availableDates,
      availableTimes: availableTimes ?? this.availableTimes,
    );
  }
}
