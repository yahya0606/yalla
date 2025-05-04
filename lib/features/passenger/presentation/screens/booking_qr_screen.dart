import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:louage/features/shared/domain/models/booking_model.dart';

class BookingQrScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingQrScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking QR Code'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: booking.id,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        errorStateBuilder: (context, error) => Center(
                          child: Text(
                            'Error generating QR code: $error',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Booking #${booking.id}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Booking Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Passenger', booking.passengerName),
                        _buildDetailRow('From', booking.from),
                        _buildDetailRow('To', booking.to),
                        _buildDetailRow('Seats', booking.seats.toString()),
                        _buildDetailRow('Total Price', '${booking.totalPrice} TND'),
                        _buildDetailRow(
                          'Payment',
                          '${booking.paymentMethod.name} ${booking.isPaid ? '(Paid)' : '(Cash on Board)'}',
                        ),
                        _buildDetailRow(
                          'Date',
                          '${booking.date.day}/${booking.date.month}/${booking.date.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Show this QR code to the driver for check-in',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 