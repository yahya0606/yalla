import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/domain/models/trip_model.dart';
import '../../../shared/domain/models/passenger_count_model.dart';
import '../../../shared/domain/models/booking_model.dart';
import '../../../shared/data/repositories/booking_repository.dart';
import '../../../shared/data/repositories/passenger_count_repository.dart';
import '../../../shared/data/repositories/route_repository.dart';
import '../../../auth/providers/current_user_provider.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  final int seats;
  final double totalPrice;
  final PassengerCountModel? passengerCount;

  const BookingConfirmationScreen({
    super.key,
    required this.trip,
    required this.seats,
    required this.totalPrice,
    this.passengerCount,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if there are enough seats available
      if (widget.passengerCount != null &&
          widget.passengerCount!.availableSeats < widget.seats) {
        throw Exception('Not enough seats available');
      }

      // Get route information
      final route = await ref.read(routeRepositoryProvider).getRouteById(widget.trip.routeId);
      if (route == null) {
        throw Exception('Route not found');
      }

      final now = DateTime.now();
      final booking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: widget.trip.id,
        passengerId: user.uid,
        passengerName: user.name ?? 'Unknown',
        from: route.from,
        to: route.to,
        seats: widget.seats,
        totalPrice: widget.totalPrice,
        date: widget.trip.date,
        paymentMethod: _selectedPaymentMethod,
        isPaid: _selectedPaymentMethod == PaymentMethod.online,
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
        isRefundable: true,
        trip: widget.trip,
      );

      await ref.read(bookingRepositoryProvider).create(booking);

      // Update passenger count
      if (widget.passengerCount != null) {
        await ref
            .read(passengerCountRepositoryProvider)
            .incrementPassengerCount(widget.trip.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, booking);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = TimeOfDay.fromDateTime(widget.trip.date).format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: SingleChildScrollView(
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
                    Text(
                      'Trip Details',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeFormat,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (widget.passengerCount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.passengerCount!.isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: widget.passengerCount!.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.passengerCount!.currentPassengers}/${widget.passengerCount!.totalSeats}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: widget.passengerCount!.isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: ref.read(routeRepositoryProvider).getRouteById(widget.trip.routeId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final route = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${route.from} → ${route.to}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${widget.trip.time}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Price: ${route.price.toStringAsFixed(2)} TND',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Booking Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seats',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          widget.seats.toString(),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${widget.totalPrice.toStringAsFixed(2)} TND',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Cash'),
                      value: PaymentMethod.cash,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPaymentMethod = value);
                        }
                      },
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Online'),
                      value: PaymentMethod.online,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPaymentMethod = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 