import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../shared/domain/models/booking_model.dart';
import '../../../shared/data/repositories/booking_repository.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleQRCode(barcode.rawValue!);
                  }
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Position the QR code within the frame to scan',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQRCode(String code) async {
    try {
      // Assuming the QR code contains the booking ID
      final booking = await ref.read(bookingRepositoryProvider).getBooking(code);
      if (booking != null) {
        if (!mounted) return;
        
        // Show booking details and confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Passenger: ${booking.passengerName}'),
                Text('Seats: ${booking.seats}'),
                Text('From: ${booking.from}'),
                Text('To: ${booking.to}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Update booking status
                  await ref.read(bookingRepositoryProvider).update(
                    booking.id,
                    booking.copyWith(status: BookingStatus.confirmed),
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Confirm Check-in'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
} 