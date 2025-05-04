import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/providers/trip_providers.dart';

class DriverAvailabilityRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  DriverAvailabilityRepository(this._firestore, this._ref);

  Future<void> addToQueue(String driverId) async {
    try {
      // Get the driver's availability document
      final driverDoc = await _firestore
          .collection('driver_availability')
          .doc(driverId)
          .get();

      if (!driverDoc.exists) {
        throw Exception('Driver availability not found');
      }

      final driverData = driverDoc.data() as Map<String, dynamic>;
      final routeId = driverData['routeId'] as String?;

      if (routeId == null) {
        throw Exception('Driver has no assigned route');
      }

      // Get the route document to get the current queue length
      final routeDoc = await _firestore
          .collection('routes')
          .doc(routeId)
          .get();

      if (!routeDoc.exists) {
        throw Exception('Route not found');
      }

      final routeData = routeDoc.data() as Map<String, dynamic>;
      final currentQueueLength = routeData['queueLength'] as int? ?? 0;
      final newQueueNumber = currentQueueLength + 1;

      // Update driver's queue status
      await _firestore.collection('driver_availability').doc(driverId).update({
        'isInQueue': true,
        'queueNumber': newQueueNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user document
      await _firestore.collection('users').doc(driverId).update({
        'isInQueue': true,
        'queueNumber': newQueueNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update route's queue length
      await _firestore.collection('routes').doc(routeId).update({
        'queueLength': newQueueNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create trips for all drivers in the queue
      final allDriversInQueue = await _firestore
          .collection('driver_availability')
          .where('routeId', isEqualTo: routeId)
          .where('isInQueue', isEqualTo: true)
          .orderBy('queueNumber')
          .get();

      for (var i = 0; i < allDriversInQueue.docs.length; i++) {
        final driver = allDriversInQueue.docs[i];
        final isFirstInQueue = i == 0;
        await _createTripForDriver(
          driver.id,
          routeId,
          isAvailable: isFirstInQueue,
          queueNumber: i + 1,
        );
      }

      // Mark other trips for this driver as unavailable
      await _markOtherTripsUnavailable(driverId);
    } catch (e) {
      throw Exception('Failed to add driver to queue: $e');
    }
  }

  Future<void> _createTripForDriver(
    String driverId,
    String routeId, {
    bool isAvailable = true,
    int queueNumber = 1,
  }) async {
    try {
      // Get driver's availability information
      final driverDoc = await _firestore
          .collection('driver_availability')
          .doc(driverId)
          .get();

      if (!driverDoc.exists) {
        throw Exception('Driver availability not found');
      }

      final driverData = driverDoc.data() as Map<String, dynamic>;
      final startTime = driverData['startTime'] as String;
      final availableSeats = driverData['availableSeats'] as int? ?? 8;
      final totalSeats = driverData['totalSeats'] as int? ?? 8;

      // Always use a unique trip ID (driverId + timestamp)
      final tripId = driverId.isNotEmpty
        ? driverId
        : driverId;

      final trip = TripModel(
        id: tripId,
        driverId: driverId,
        routeId: routeId,
        date: DateTime.now(),
        time: startTime,
        availableSeats: availableSeats,
        totalSeats: totalSeats,
        status: TripStatus.scheduled,
        isAvailableForBooking: isAvailable,
        queueNumber: isAvailable ? queueNumber : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save trip directly in the trips collection using the unique trip ID
      await _firestore
          .collection('trips')
          .doc(tripId)
          .set(trip.toJson());
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  Future<void> _markOtherTripsUnavailable(String driverId) async {
    try {
      // Since we're using driverId as document ID, we can directly update the document
      await _firestore
          .collection('trips')
          .doc(driverId)
          .update({
            'isAvailableForBooking': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to mark other trips unavailable: $e');
    }
  }

  Future<void> _assignTripToDriver(DriverAvailabilityModel driver) async {
    try {
      final startDateTime = _parseStartTime(driver.startTime);
      final tripRepository = _ref.read(tripRepositoryProvider);

      final trips = await tripRepository.searchTrips(
        from: driver.routeId,
        to: driver.routeId,
        date: startDateTime,
      );

      if (trips.isNotEmpty) {
        final trip = trips.first;
        await _firestore.collection('trips').doc(trip.id).update({
          'driverId': driver.driverId,
          'status': TripStatus.scheduled.name,
        });
      }
    } catch (e) {
      print('Error assigning trip to driver: $e');
      rethrow;
    }
  }

  DateTime _parseStartTime(String startTime) {
    final parts = startTime.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> create(DriverAvailabilityModel driver) async {
    try {
      await _firestore
          .collection('driver_availability')
          .doc(driver.id)
          .set(driver.toJson());
    } catch (e) {
      print('Error creating driver availability: $e');
      rethrow;
    }
  }

  Future<void> update(String docId, DriverAvailabilityModel driver) async {
    try {
      await _firestore
          .collection('driver_availability')
          .doc(docId)
          .update(driver.toJson());
    } catch (e) {
      print('Error updating driver availability: $e');
      rethrow;
    }
  }

  Future<DriverAvailabilityModel?> getByDriverId(String driverId) async {
    try {
      final docSnapshot = await _firestore
          .collection('driver_availability')
          .doc(driverId)
          .get();

      if (!docSnapshot.exists) return null;

      final data = docSnapshot.data();
      if (data == null) return null;

      return DriverAvailabilityModel.fromJson({
        ...data,
        'id': driverId,
        'driverId': driverId,
      });
    } catch (e) {
      print('Error getting driver availability by ID: $e');
      rethrow;
    }
  }

  Stream<DriverAvailabilityModel?> streamByDriverId(String driverId) {
    return _firestore
        .collection('driver_availability')
        .doc(driverId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return DriverAvailabilityModel.fromJson({
        ...snapshot.data()!,
        'id': driverId,
        'driverId': driverId,
      });
    });
  }

  Stream<List<DriverAvailabilityModel>> getQueueStream(String routeId) {
    return _firestore
        .collection('driver_availability')
        .where('routeId', isEqualTo: routeId)
        .where('isInQueue', isEqualTo: true)
        .orderBy('queueNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DriverAvailabilityModel.fromJson(doc.data()))
        .toList());
  }

  Future<List<DriverAvailabilityModel>> getQueue(String routeId) async {
    final querySnapshot = await _firestore
        .collection('driver_availability')
        .where('routeId', isEqualTo: routeId)
        .where('isInQueue', isEqualTo: true)
        .orderBy('queueNumber')
        .get();

    return querySnapshot.docs
        .map((doc) => DriverAvailabilityModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> removeFromQueue(String driverId) async {
    try {
      // Get the driver's current queue position
      final driverDoc = await _firestore
          .collection('driver_availability')
          .doc(driverId)
          .get();

      if (!driverDoc.exists) return;

      final driverData = driverDoc.data()!;
      final queueNumber = driverData['queueNumber'] as int?;
      final routeId = driverData['routeId'] as String?;

      // Get the route document to get the current queue length
      final routeDoc = await _firestore
          .collection('routes')
          .doc(routeId)
          .get();

      if (!routeDoc.exists) {
        throw Exception('Route not found');
      }

      if (routeId == null) return;

      final routeData = routeDoc.data() as Map<String, dynamic>;
      final currentQueueLength = routeData['queueLength'] as int? ?? 0;
      final newQueueNumber = currentQueueLength - 1;

      // Update driver's queue status
      await _firestore.collection('driver_availability').doc(driverId).update({
        'isInQueue': false,
        'queueNumber': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update user document
      await _firestore.collection('users').doc(driverId).update({
        'isInQueue': false,
        'queueNumber': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update route's queue length
      await _firestore.collection('routes').doc(routeId).update({
        'queueLength': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove the driver from queue
      await _firestore
          .collection('driver_availability')
          .doc(driverId)
          .update({
        'isInQueue': false,
        'queueNumber': null,
      });

      // Update the user's document
      await _firestore.collection('users').doc(driverId).update({
        'isInQueue': false,
        'queueNumber': null,
      });

      // If this was the first driver in queue, create a trip for the next driver
      if (queueNumber == 1) {
        await _assignTripToNextDriver(routeId);
      }
    } catch (e) {
      print('Error removing driver from queue: $e');
      rethrow;
    }
  }

  Future<void> _assignTripToNextDriver(String routeId) async {
    try {
      // Get the next driver in queue
      final querySnapshot = await _firestore
          .collection('driver_availability')
          .where('routeId', isEqualTo: routeId)
          .where('isInQueue', isEqualTo: true)
          .orderBy('queueNumber')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final nextDriver = DriverAvailabilityModel.fromJson(querySnapshot.docs.first.data());
      
      // Create a trip for the next driver
      await _createTripForDriver(
        nextDriver.driverId,
        nextDriver.routeId,
        isAvailable: false,
        queueNumber: nextDriver.queueNumber ?? 1,
      );

      // Update queue numbers for remaining drivers
      await _updateQueueNumbers(routeId);
    } catch (e) {
      print('Error assigning trip to next driver: $e');
      rethrow;
    }
  }

  Future<void> _updateQueueNumbers(String routeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('driver_availability')
          .where('routeId', isEqualTo: routeId)
          .where('isInQueue', isEqualTo: true)
          .orderBy('queueNumber')
          .get();

      int newQueueNumber = 1;
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'queueNumber': newQueueNumber++,
        });
      }
    } catch (e) {
      print('Error updating queue numbers: $e');
      rethrow;
    }
  }

  Future<List<DriverAvailabilityModel>> getDriversByRoute(String routeId) async {
    final querySnapshot = await _firestore
        .collection('driver_availability')
        .where('routeId', isEqualTo: routeId)
        .get();

    return querySnapshot.docs
        .map((doc) => DriverAvailabilityModel.fromJson(doc.data()))
        .toList();
  }

  Future<void> markDriverArrival(String driverId) async {
    try {
      final docRef = _firestore.collection('driver_availability').doc(driverId);
      await docRef.update({
        'isInQueue': false,
        'lastArrivalTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking driver arrival: $e');
      rethrow;
    }
  }

  /// Handles post-trip-completion logic: join inverse route queue, assign next trip, and notify driver.
  Future<String?> handlePostTripCompletion({
    required String driverId,
    required String originalRouteId,
    required void Function(String message) notifyDriver,
  }) async {
    try {
      // 1. Compute inverse routeId (example: '1' -> '1-1' or '1-1' -> '1')
      final inverseRouteId = _getInverseRouteId(originalRouteId);

      // 2. Get the current queue length for the inverse route
      final routeDoc = await _firestore
          .collection('routes')
          .doc(inverseRouteId)
          .get();

      if (!routeDoc.exists) {
        throw Exception('Inverse route not found');
      }

      final routeData = routeDoc.data() as Map<String, dynamic>;
      final currentQueueLength = routeData['queueLength'] as int? ?? 0;
      final newQueueNumber = currentQueueLength + 1;

      // 3. Add driver to queue for inverse route
      await _firestore.collection('driver_availability').doc(driverId).update({
        'isInQueue': true,
        'queueNumber': FieldValue.increment(1),
        'routeId': inverseRouteId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Update route's queue length
      await _firestore.collection('routes').doc(inverseRouteId).update({
        'queueLength': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Fetch the updated document
      final docSnapshot = await _firestore
          .collection('routes')
          .doc(inverseRouteId)
          .get();

      // 3. Get the queueLength field
      int? queueLength;
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        queueLength = data?['queueLength']; // now you have it

        print('Current queueLength: $queueLength');
      } else {
        print('Document does not exist!');
      }

      await _firestore.collection('routes').doc(originalRouteId).update({
        'queueLength': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Update the trip document (using driverId as document ID)
      await _firestore.collection('trips').doc(driverId).update({
        'routeId': inverseRouteId,
        'status': TripStatus.scheduled.name,
        'queueNumber': queueLength,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 6. Update user document
      await _firestore.collection('users').doc(driverId).update({
        'routeId': inverseRouteId,
        'queueNumber': queueLength,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyDriver('You have been added to the queue for route $inverseRouteId!');
      return driverId;
    } catch (e) {
      notifyDriver('Error handling post-trip completion: $e');
      return null;
    }
  }

  // Helper: Compute inverse routeId
  String _getInverseRouteId(String routeId) {
    // Handle both directions:
    // '1' -> '1-1' (forward route to inverse route)
    // '1-1' -> '1' (inverse route back to forward route)
    if (routeId.contains('-1')) {
      // If it's an inverse route (e.g., '1-1'), remove the '-1' to get back to the original route
      return routeId.replaceAll('-1', '');
    } else {
      // If it's a forward route (e.g., '1'), add '-1' to get the inverse route
      return '$routeId-1';
    }
  }

  // Helper: Add driver to queue for a specific route
  Future<void> addToQueueForRoute(String driverId, String routeId) async {
    // Copy of addToQueue, but uses provided routeId
    try {
      // Get the route document to get the current queue length
      final routeDoc = await _firestore
          .collection('routes')
          .doc(routeId)
          .get();
      if (!routeDoc.exists) {
        throw Exception('Route not found');
      }
      final routeData = routeDoc.data() as Map<String, dynamic>;
      final currentQueueLength = routeData['queueLength'] as int? ?? 0;
      final newQueueNumber = currentQueueLength + 1;
      // Update driver's queue status
      await _firestore.collection('driver_availability').doc(driverId).update({
        'isInQueue': true,
        'queueNumber': newQueueNumber,
        'routeId': routeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Update user document
      await _firestore.collection('users').doc(driverId).update({
        'isInQueue': true,
        'queueNumber': newQueueNumber,
        'routeId': routeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Update route's queue length
      await _firestore.collection('routes').doc(routeId).update({
        'queueLength': newQueueNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add driver to queue for route: $e');
    }
  }

  // Helper: Get next available trip on a route
  Future<TripModel?> _getNextAvailableTripOnRoute(String routeId) async {
    final tripsSnapshot = await _firestore
        .collection('trips')
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: TripStatus.scheduled.name)
        .orderBy('date')
        .limit(1)
        .get();
    if (tripsSnapshot.docs.isEmpty) return null;
    return TripModel.fromJson(tripsSnapshot.docs.first.data());
  }

  // Helper: Assign driver to a trip on a route
  Future<void> _assignTripToDriverOnRoute(String driverId, String tripId, String routeId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'driverId': driverId,
      'status': TripStatus.scheduled.name,
      'routeId': routeId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// Riverpod provider
final driverAvailabilityRepositoryProvider = Provider<DriverAvailabilityRepository>((ref) {
  return DriverAvailabilityRepository(FirebaseFirestore.instance, ref);
});
