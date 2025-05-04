import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/route_model.dart'; // ✅ Added missing import
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:louage/features/shared/data/repositories/route_repository.dart';

final driverAvailabilityStreamProvider =
StreamProvider.family<DriverAvailabilityModel?, String>((ref, driverId) {
  return ref
      .read(driverAvailabilityRepositoryProvider)
      .streamByDriverId(driverId);
});

/// ✅ Updated this from StreamProvider to FutureProvider
final driverTripsProvider =
FutureProvider.family<List<TripModel>, String>((ref, driverId) {
  return ref.read(tripRepositoryProvider).getTripsByDriver(driverId: driverId);
});

final availableRoutesProvider = FutureProvider<List<RouteModel>>((ref) {
  return ref.read(routeRepositoryProvider).getAllRoutes();
});
