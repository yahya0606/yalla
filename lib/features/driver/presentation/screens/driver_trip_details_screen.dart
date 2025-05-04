import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/data/repositories/route_repository.dart';
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:intl/intl.dart';

class DriverTripDetailsScreen extends ConsumerWidget {
  final TripModel trip;

  const DriverTripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRouteInfo(ref, context),
            const SizedBox(height: 16),
            _buildDriverInfo(ref, context),
            const SizedBox(height: 16),
            _buildTripInfo(ref, context),
          ],
        ),
      ),
    );
  }

  // Route info card
  Widget _buildRouteInfo(WidgetRef ref, BuildContext context) {
    return FutureBuilder<RouteModel?>(
      future: ref.read(routeRepositoryProvider).getRouteById(trip.routeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final route = snapshot.data;
        if (route == null) {
          return const Text('Route not found');
        }
        return _buildCard(
          title: 'Route',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From: ${route.from}'),
              Text('To: ${route.to}'),
              Text('Price: ${route.price} TND'),
            ],
          ),
          context: context,
        );
      },
    );
  }

  // Driver info card
  Widget _buildDriverInfo(WidgetRef ref, BuildContext context) {
    return FutureBuilder<DriverAvailabilityModel?>(
      future: ref.read(driverAvailabilityRepositoryProvider).getByDriverId(trip.driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final availability = snapshot.data;
        if (availability == null) {
          return const Text('Driver information not available');
        }
        return _buildCard(
          title: 'Driver Information',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Car Number: ${availability.carNumber}'),
              Text('Working Hours: ${availability.startTime} - ${availability.endTime}'),
              Text('Working Days: ${availability.workingDays.join(", ")}'),
            ],
          ),
          context: context,
        );
      },
    );
  }

  // Trip info card with buttons for status updates
  Widget _buildTripInfo(WidgetRef ref, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(trip.date)}'),
            Text('Time: ${DateFormat('HH:mm').format(trip.date)}'),
            Text('Available Seats: ${trip.availableSeats}/${trip.totalSeats}'),
            Text('Status: ${trip.status.name}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: trip.status == TripStatus.scheduled
                      ? () => _updateTripStatus(context, ref, trip.id, TripStatus.inProgress)
                      : null,
                  child: const Text('Start Trip'),
                ),
                ElevatedButton(
                  onPressed: trip.status == TripStatus.inProgress
                      ? () => _updateTripStatus(context, ref, trip.id, TripStatus.completed)
                      : null,
                  child: const Text('Complete Trip'),
                ),
                ElevatedButton(
                  onPressed: trip.status == TripStatus.scheduled
                      ? () => _updateTripStatus(context, ref, trip.id, TripStatus.cancelled)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Cancel Trip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building a card
  Widget _buildCard({required String title, required Widget content, required BuildContext context}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Future<void> _updateTripStatus(
      BuildContext context,
      WidgetRef ref,
      String tripId,
      TripStatus newStatus,
      ) async {
    try {
      await ref.read(tripRepositoryProvider).updateTripStatus(tripId, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trip status updated to ${newStatus.name}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating trip status: $e')),
        );
      }
    }
  }
}
