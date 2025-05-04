import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/domain/models/trip_model.dart';
import '../../../shared/domain/models/passenger_count_model.dart';
import '../../../shared/data/repositories/passenger_count_repository.dart';
import '../../../shared/providers/trip_providers.dart';
import '../widgets/trip_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _isFlexible = false;
  List<TripModel> _trips = [];
  List<PassengerCountModel> _passengerCounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchTrips();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _searchTrips() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      print('\nSearching for trips:');
      print('From: ${_fromController.text}');
      print('To: ${_toController.text}');
      print('Date: ${_selectedDate.toString()}');
      print('Time: ${_selectedTime ?? 'Any'}');
      print('Flexible: $_isFlexible');

      // Ensure we're searching for the correct date
      final searchDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      // Get all trips for the selected date
      final trips = await ref.read(tripRepositoryProvider).searchTrips(
            from: _fromController.text,
            to: _toController.text,
            date: searchDate,
            preferredTime: _selectedTime,
            isFlexible: _isFlexible,
          );

      print('\nFound ${trips.length} trips');
      
      if (trips.isNotEmpty) {
        // Get passenger counts for all trips
        final passengerCountsStream = ref
            .read(passengerCountRepositoryProvider)
            .getPassengerCountsForTrips(trips.map((t) => t.id).toList());

        // Convert stream to list
        final passengerCounts = await passengerCountsStream.first;

        print('\nPassenger counts:');
        for (var count in passengerCounts) {
          print('Trip ${count.tripId}: ${count.currentPassengers}/${count.totalSeats} passengers');
        }

        setState(() {
          _trips = trips;
          _passengerCounts = passengerCounts;
        });
      } else {
        print('\nNo trips found');
        setState(() {
          _trips = [];
          _passengerCounts = [];
        });
      }
    } catch (e) {
      print('\nError searching trips: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _searchTrips();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _searchTrips();
    }
  }

  PassengerCountModel? _getPassengerCount(String tripId) {
    return _passengerCounts.firstWhere(
      (count) => count.tripId == tripId,
      orElse: () => PassengerCountModel(
        tripId: tripId,
        carNumber: '',
        currentPassengers: 0,
        totalSeats: 0,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trips'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onSubmitted: (_) => _searchTrips(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onSubmitted: (_) => _searchTrips(),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Time (Optional)',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _selectedTime ?? 'Any time',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isFlexible,
                      onChanged: (value) {
                        setState(() {
                          _isFlexible = value ?? false;
                        });
                        _searchTrips();
                      },
                    ),
                    const Text('Flexible with time'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchTrips,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No trips found for ${_fromController.text} to ${_toController.text}',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          final trip = _trips[index];
                          final passengerCount = _getPassengerCount(trip.id);
                          return TripCard(
                            trip: trip,
                            passengerCount: passengerCount,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 