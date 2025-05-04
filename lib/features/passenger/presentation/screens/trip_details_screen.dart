import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/shared/data/repositories/booking_repository.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:louage/features/shared/domain/models/booking_model.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:intl/intl.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  int _seats = 1;
  bool _isLoading = false;

  Future<void> _bookTrip() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not found');
      }

      // First, update the available seats
      await ref.read(tripRepositoryProvider).updateAvailableSeats(
        widget.trip.id,
        _seats,
      );

      // Get route information
      final route = await ref.read(tripRouteProvider(widget.trip.routeId).future);
      if (route == null) {
        throw Exception('Route not found');
      }

      // Then create the booking
      final booking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: widget.trip.id,
        passengerId: user.uid,
        passengerName: user.name ?? 'Unknown',
        from: route.from,
        to: route.to,
        seats: _seats,
        totalPrice: route.price * _seats,
        status: BookingStatus.pending,
        paymentMethod: PaymentMethod.cash,
        isPaid: false,
        date: widget.trip.date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        trip: widget.trip,
      );

      await ref.read(bookingRepositoryProvider).create(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(tripRouteProvider(widget.trip.routeId));
    final driverAvailabilityAsync = ref.watch(tripDriverAvailabilityProvider(widget.trip.driverId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      routeAsync.when(
                        data: (route) => route != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${route.from} → ${route.to}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${DateFormat('MMM dd, yyyy').format(widget.trip.date)}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    'Time: ${DateFormat('HH:mm').format(widget.trip.date)}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  driverAvailabilityAsync.when(
                                    data: (driverAvailability) => driverAvailability != null
                                        ? Text(
                                            'Car Number: ${driverAvailability.carNumber}',
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          )
                                        : const Text('Driver information not available'),
                                    loading: () => const CircularProgressIndicator(),
                                    error: (error, stack) => Text('Error: $error'),
                                  ),
                                  Text(
                                    'Price: ${route.price.toStringAsFixed(2)} TND',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    'Available Seats: ${widget.trip.availableSeats}/${widget.trip.totalSeats}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  if (route.stops.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Stops: ${route.stops.join(", ")}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                  if (widget.trip.isFillingUpFast())
                                    const Text(
                                      'Filling up fast!',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              )
                            : const Text('Route not found'),
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error: $error'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Seats Selection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Number of Seats'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _seats > 1
                                    ? () {
                                        setState(() {
                                          _seats--;
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '$_seats',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _seats < widget.trip.availableSeats
                                    ? () {
                                        setState(() {
                                          _seats++;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      routeAsync.when(
                        data: (route) => route != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Price'),
                                  Text(
                                    '${(route.price * _seats).toStringAsFixed(2)} TND',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                ],
                              )
                            : const Text('Route not found'),
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error: $error'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookTrip,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 