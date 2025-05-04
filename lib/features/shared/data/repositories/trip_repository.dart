import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/base_repository.dart';
import 'package:louage/features/shared/data/repositories/route_repository.dart' as route_repo;
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/providers/trip_providers.dart';

class TripRepository extends BaseRepository<TripModel> {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  TripRepository(this._firestore, this._ref) : super('trips');

  @override
  TripModel fromJson(Map<String, dynamic> json) {
    return TripModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(TripModel trip) {
    return trip.toJson();
  }

  TripModel _tripFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TripModel.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }

  @override
  Future<TripModel?> get(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection('trips')
          .doc(id)
          .get();
      if (!docSnapshot.exists) return null;
      return TripModel.fromJson({'id': docSnapshot.id, ...docSnapshot.data()!});
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  @override
  Future<List<TripModel>> getAll() async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map(_tripFromDoc).toList();
    } catch (e) {
      throw Exception('Failed to get all trips: $e');
    }
  }

  @override
  Stream<List<TripModel>> stream() {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map(_tripFromDoc).toList();
    });
  }

  @override
  Future<void> create(TripModel trip) async {
    try {
      await _firestore
          .collection('trips')
          .doc(trip.id)
          .set(toJson(trip));
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  @override
  Future<void> update(String id, TripModel trip) async {
    try {
      await _firestore
          .collection('trips')
          .doc(id)
          .update(toJson(trip));
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final trip = await get(id);
      if (trip != null) {
        await _firestore
            .collection('trips')
            .doc(id)
            .delete();
      }
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  Future<List<TripModel>> searchTrips({
    required String from,
    required String to,
    required DateTime date,
    String? preferredTime,
    bool isFlexible = false,
  }) async {
    try {
      final routeRepository = _ref.read(route_repo.routeRepositoryProvider);
      final allRoutes = await routeRepository.getAllRoutes();
      
      final matchingRoutes = <String>[];
      final fromLower = from.toLowerCase();
      final toLower = to.toLowerCase();

      for (final route in allRoutes) {
        final routeStops = [route.from.toLowerCase(), ...route.stops.map((s) => s.toLowerCase()), route.to.toLowerCase()];
        
        // Find indices of from and to in the route
        final fromIndex = routeStops.indexWhere((stop) => stop.contains(fromLower));
        final toIndex = routeStops.indexWhere((stop) => stop.contains(toLower));
        
        // If both stations are found and from comes before to
        if (fromIndex != -1 && toIndex != -1 && fromIndex < toIndex) {
          matchingRoutes.add(route.id);
        }
      }

      if (matchingRoutes.isEmpty) {
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all trips for the matching routes
      final snapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: TripStatus.scheduled.name)
          .where('routeId', whereIn: matchingRoutes)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      var trips = snapshot.docs.map((doc) => TripModel.fromJson(doc.data())).toList();

      // Filter by time if not flexible
      if (!isFlexible && preferredTime != null) {
        trips = trips.where((trip) => trip.time == preferredTime).toList();
      }

      return trips;
    } catch (e) {
      throw Exception('Error searching trips: $e');
    }
  }

  // Add a new method to get bookable trips (only queueNumber = 1)
  Future<List<TripModel>> getBookableTrips({
    required String from,
    required String to,
    required DateTime date,
    String? preferredTime,
    bool isFlexible = false,
  }) async {
    try {
      final allTrips = await searchTrips(
        from: from,
        to: to,
        date: date,
        preferredTime: preferredTime,
        isFlexible: isFlexible,
      );

      // Filter to only include trips where the driver is first in queue
      return allTrips.where((trip) => trip.queueNumber == 1).toList();
    } catch (e) {
      throw Exception('Error getting bookable trips: $e');
    }
  }

  Future<void> createTrip(TripModel trip) async {
    try {
      final driverAvailability =
      await _ref.read(driverAvailabilityRepositoryProvider).getByDriverId(trip.driverId);
      if (driverAvailability == null || !driverAvailability.isAvailableOnDate(trip.date)) {
        throw Exception('Driver is not available on this date');
      }

      await create(trip);
    } catch (e) {
      throw Exception('Error creating trip: $e');
    }
  }

  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    try {
      final trip = await get(tripId);
      if (trip == null) {
        throw Exception('Trip not found');
      }

      // Update trip status
      await _firestore.collection(collection).doc(tripId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == TripStatus.inProgress) {
        // When starting a trip:
        // 1. Remove driver from queue
        await _ref.read(driverAvailabilityRepositoryProvider).removeFromQueue(trip.driverId);
        
        // 2. Update user document to show they are on a trip
        await _firestore.collection('users').doc(trip.driverId).update({
          'isInQueue': false,
          'currentTripId': tripId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Update driver availability
        await _firestore.collection('driver_availability').doc(trip.driverId).update({
          'isInQueue': false,
          'currentTripId': tripId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (status == TripStatus.completed) {
        // When completing a trip:
        // 1. Mark driver arrival
        await _ref.read(driverAvailabilityRepositoryProvider).markDriverArrival(trip.driverId);
        
        // 2. Clear current trip from user and driver availability
        await _firestore.collection('users').doc(trip.driverId).update({
          'currentTripId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('driver_availability').doc(trip.driverId).update({
          'currentTripId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // 3. Handle post-trip completion (join inverse route queue)
        await _ref.read(driverAvailabilityRepositoryProvider).handlePostTripCompletion(
          driverId: trip.driverId,
          originalRouteId: trip.routeId,
          notifyDriver: (message) {
            print('Post-trip completion message: $message');
          },
        );
      }
    } catch (e) {
      throw Exception('Error updating trip status: $e');
    }
  }

  Future<void> updateAvailableSeats(String tripId, int seats) async {
    try {
      // seats can be positive (for booking) or negative (for cancellation)
      await _firestore.collection(collection).doc(tripId).update({
        'availableSeats': FieldValue.increment(seats),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating available seats: $e');
    }
  }

  Future<List<TripModel>> getTripsByDriver({required String driverId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: driverId)
          .orderBy('date')
          .get();
      return querySnapshot.docs.map(_tripFromDoc).toList();
    } catch (e) {
      print('Error getting trips by driver: $e');
      return [];
    }
  }

  Stream<List<TripModel>> getTripsByDriverStream({required String driverId}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_tripFromDoc).toList();
        });
  }

  Stream<List<TripModel>> getFutureTripsStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('trips')
        .where('status', isNotEqualTo: TripStatus.cancelled.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('date', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final trips = snapshot.docs.map(_tripFromDoc).toList();

      final filteredTrips = <TripModel>[];
      for (final trip in trips) {
        final driverAvailability = await _ref.read(driverAvailabilityRepositoryProvider).getByDriverId(trip.driverId);
        if (driverAvailability != null && driverAvailability.isAvailableOnDate(trip.date)) {
          filteredTrips.add(trip);
        }
      }
      return filteredTrips;
    });
  }

  Future<List<TripModel>> getAllTrips() async {
    try {
      final querySnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: TripStatus.scheduled.name)
          .get();

      return querySnapshot.docs.map((doc) => TripModel.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Error getting all trips: $e');
    }
  }
}

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(FirebaseFirestore.instance, ref);
});
