import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/domain/models/booking_model.dart';
import '../../../shared/data/repositories/booking_repository.dart';
import '../../../auth/providers/current_user_provider.dart';
import 'booking_qr_screen.dart';

class PassengerBookingsScreen extends ConsumerWidget {
  const PassengerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    print('=== PassengerBookingsScreen Started ===');
    print('User: ${user?.uid}');
    print('User name: ${user?.name}');

    if (user == null) {
      print('No user found, showing login message');
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your bookings'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: ref.read(bookingRepositoryProvider).getBookingsByUserStream(user.uid),
        builder: (context, snapshot) {
          print('=== StreamBuilder Update ===');
          print('Connection state: ${snapshot.connectionState}');
          print('Has error: ${snapshot.hasError}');
          print('Error: ${snapshot.error}');
          print('Has data: ${snapshot.hasData}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Waiting for data...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error in stream: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final bookings = snapshot.data ?? [];
          print('Number of bookings: ${bookings.length}');

          if (bookings.isEmpty) {
            print('No bookings found');
            return const Center(
              child: Text('No bookings found'),
            );
          }

          print('=== Bookings List ===');
          for (var booking in bookings) {
            print('Booking ID: ${booking.id}');
            print('Raw status from Firestore: ${booking.status}');
            print('Status enum value: ${booking.status.runtimeType}');
            print('Status name: ${booking.status.name}');
            print('Status name (lowercase): ${booking.status.name.toLowerCase()}');
            print('Is pending? ${booking.status.name.toLowerCase() == 'pending'}');
            print('From: ${booking.from}');
            print('To: ${booking.to}');
            print('Seats: ${booking.seats}');
            print('Total Price: ${booking.totalPrice}');
            print('---');
          }
          print('===================');

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              print('=== Building Booking Card ===');
              print('Booking ID: ${booking.id}');
              print('Status: ${booking.status}');
              print('Status name: ${booking.status.name}');
              print('Status type: ${booking.status.runtimeType}');
              print('Is pending? ${booking.status == BookingStatus.pending}');
              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      onTap: () {
                        print('=== Card Tapped ===');
                        print('Booking ID: ${booking.id}');
                        print('Status: ${booking.status}');
                        _showQrCode(context, booking);
                      },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking #${booking.id}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.from} → ${booking.to}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(booking.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Seats: ${booking.seats}'),
                              Text('Total Price: ${booking.totalPrice} TND'),
                            ],
                          ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: ElevatedButton.icon(
                              onPressed: () {
                          print('=== QR Code Button Pressed ===');
                          print('Booking ID: ${booking.id}');
                          print('Status: ${booking.status}');
                                _showQrCode(context, booking);
                              },
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Show QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                      ),
                      ),
                    ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQrCode(BuildContext context, BookingModel booking) {
    print('=== Showing QR Code ===');
    print('Booking ID: ${booking.id}');
    print('Status: ${booking.status}');
    print('Status name: ${booking.status.name}');
    try {
      print('Creating BookingQrScreen...');
      final qrScreen = BookingQrScreen(booking: booking);
      print('Navigating to QR code screen...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => qrScreen,
        ),
      );
      print('Navigation successful');
    } catch (e, stackTrace) {
      print('=== Error Showing QR Code ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error showing QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }
} 