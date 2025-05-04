import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/providers/auth_provider.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/providers/trip_providers.dart' as trip_providers;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  const AddTripScreen({super.key});

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _seatsController = TextEditingController(text: '4');
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRouteId;
  DriverAvailabilityModel? _driverAvailability; // Track driver availability

  @override
  void initState() {
    super.initState();
    _loadDriverAvailability();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Load driver's availability info (car number)
  Future<void> _loadDriverAvailability() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      final availability = await ref.read(tripDriverAvailabilityProvider(user.uid).future);
      if (mounted) {
        setState(() {
          _driverAvailability = availability;
        });
      }
    }
  }

  // Date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  // Time picker
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  // Submit the trip form
  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final user = FirebaseFirestore.instance.collection('users').doc();
      final trip = TripModel(
        id: user.id,
        driverId: user.id, // TODO: Replace with actual driver ID
        date: _selectedDate!,
        routeId: '1',
        time: _timeController.text,
        totalSeats: int.parse(_seatsController.text),
        availableSeats: int.parse(_seatsController.text),
        status: TripStatus.scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(tripRepositoryProvider).createTrip(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating trip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // From Field
            TextFormField(
              controller: _fromController,
              decoration: const InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter starting point' : null,
            ),
            const SizedBox(height: 16),

            // To Field
            TextFormField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Enter destination' : null,
            ),
            const SizedBox(height: 16),

            // Date Picker
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please select a date';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Time Picker
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: _selectTime,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please select a time';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Number of Seats
            TextFormField(
              controller: _seatsController,
              decoration: const InputDecoration(
                labelText: 'Number of Seats',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter number of seats';
                final seats = int.tryParse(value);
                if (seats == null || seats <= 0) return 'Please enter a valid number of seats';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price Field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (TND)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter price';
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) return 'Enter valid price';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Car Number from Driver Availability
            if (_driverAvailability != null)
              Text(
                'Car Number: ${_driverAvailability!.carNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submitTrip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
