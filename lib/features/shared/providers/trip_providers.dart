import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:louage/features/shared/data/repositories/route_repository.dart';
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(FirebaseFirestore.instance, ref);
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(FirebaseFirestore.instance);
});

final driverAvailabilityRepositoryProvider = Provider<DriverAvailabilityRepository>((ref) {
  final tripRepository = ref.read(tripRepositoryProvider); // Read the TripRepository from the provider
  return DriverAvailabilityRepository(FirebaseFirestore.instance, ref); // Pass both parameters to the repository
});


final tripRouteProvider = FutureProvider.family<RouteModel?, String>((ref, routeId) async {
  return ref.read(routeRepositoryProvider).getRouteById(routeId);
});

final tripDriverAvailabilityProvider = FutureProvider.family<DriverAvailabilityModel?, String>((ref, driverId) async {
  return ref.read(driverAvailabilityRepositoryProvider).getByDriverId(driverId);
});

final driverTripsStreamProvider = StreamProvider.family<List<TripModel>, String>((ref, driverId) {
  return ref.read(tripRepositoryProvider).getTripsByDriverStream(driverId: driverId);
});

final availableRoutesProvider = FutureProvider<List<RouteModel>>((ref) async {
  return ref.read(routeRepositoryProvider).getAllRoutes();
});