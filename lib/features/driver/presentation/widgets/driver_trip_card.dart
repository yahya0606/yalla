import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/providers/trip_providers.dart' as trip_providers;
import 'package:louage/core/theme/app_theme.dart';

class DriverTripCard extends ConsumerStatefulWidget {
  final TripModel trip;
  final Function(String tripId, TripStatus status)? onStatusUpdate;

  const DriverTripCard({
    super.key,
    required this.trip,
    this.onStatusUpdate,
  });

  @override
  ConsumerState<DriverTripCard> createState() => _DriverTripCardState();
}

class _DriverTripCardState extends ConsumerState<DriverTripCard> {
  Future<void> _updateSeats(int change) async {
    if (!mounted) return;
    try {
      await ref.read(trip_providers.tripRepositoryProvider).updateAvailableSeats(
        widget.trip.id,
        change,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating seats: $e')),
        );
      }
    }
  }

  Future<void> _updateTripStatus(TripStatus status) async {
    if (!mounted) return;
    try {
      await ref.read(trip_providers.tripRepositoryProvider).updateTripStatus(
        widget.trip.id,
        status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip ${status.name} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      widget.onStatusUpdate?.call(widget.trip.id, status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating trip status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RouteModel?>(
      future: ref.read(trip_providers.tripRouteProvider(widget.trip.routeId).future),
      builder: (context, routeSnapshot) {
        if (routeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (routeSnapshot.hasError) {
          return Text('Error: ${routeSnapshot.error}');
        }

        final route = routeSnapshot.data;
        if (route == null) {
          return const Text('Route information not available');
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Text(
                  '${route.from} → ${route.to}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${route.price.toStringAsFixed(2)} TND',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Available Seats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.trip.availableSeats}/${widget.trip.totalSeats} seats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.trip.availableSeats < widget.trip.totalSeats
                              ? () => _updateSeats(1)
                              : null,
                          icon: const Icon(Icons.add),
                          color: AppColors.success,
                        ),
                        IconButton(
                          onPressed: widget.trip.availableSeats > 0
                              ? () => _updateSeats(-1)
                              : null,
                          icon: const Icon(Icons.remove),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Trip Status and Actions
                Row(
                  children: [
                    if (widget.trip.status == TripStatus.scheduled)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateTripStatus(TripStatus.inProgress),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Start Trip'),
                        ),
                      ),
                    if (widget.trip.status == TripStatus.inProgress)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateTripStatus(TripStatus.completed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Complete Trip'),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (widget.trip.status != TripStatus.completed && widget.trip.status != TripStatus.cancelled)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateTripStatus(TripStatus.cancelled),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: Text(
                            'Cancel Trip',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 