import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/data/services/auth_service.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/presentation/widgets/app_drawer.dart';
import 'package:louage/features/passenger/presentation/screens/trip_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:louage/features/passenger/presentation/screens/passenger_queue_screen.dart';
import 'package:louage/core/theme/app_theme.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<TripModel> _trips = [];

  // City list and filtered list for suggestions
  final List<String> cities = [
    'Tunis', 'Sfax', 'Sousse', 'Kairouan', 'Gabès', 'Bizerte', 'Nabeul',
    'Béja', 'Mahdia', 'Tataouine', 'Monastir', 'La Marsa', 'Ariana',
    'Gafsa', 'Jendouba', 'Tozeur', 'Kasserine', 'Kébili', 'Medenine',
    'Siliana', 'Zaghouan', 'Ben Arous', 'Kef', 'Moknine', 'Rades',
    'El Kef', 'Sidi Bouzid', 'Douz'
  ];
  List<String> filteredCities = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _searchTrips() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final from = _fromController.text.trim().toLowerCase();
        final to = _toController.text.trim().toLowerCase();

        // Get all matching trips
        final allTrips = await ref.read(tripRepositoryProvider).searchTrips(
          from: from,
          to: to,
          date: _selectedDate,
        );

        setState(() {
          _trips = allTrips;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error searching trips: $e')),
          );
        }
      }
    }
  }

  void _filterCities(String query) {
    setState(() {
      filteredCities = cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Widget _buildCitySuggestions(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: _filterCities,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        if (filteredCities.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: filteredCities.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(filteredCities[index]),
                onTap: () {
                  controller.text = filteredCities[index];
                  setState(() {
                    filteredCities.clear();
                  });
                },
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trips'),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchForm(),
            const SizedBox(height: 24),
            Expanded(
              child: _trips.isEmpty
                  ? const Center(
                child: Text('No trips found'),
              )
                  : ListView.builder(
                itemCount: _trips.length,
                itemBuilder: (context, index) {
                  final trip = _trips[index];
                  return _buildTripCard(trip);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCitySuggestions('From', _fromController),
          _buildCitySuggestions('To', _toController),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchTrips,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    return FutureBuilder<DriverAvailabilityModel?>(
      future: ref.read(tripDriverAvailabilityProvider(trip.driverId).future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final driverAvailability = snapshot.data;
        if (driverAvailability == null) {
          return const Text('Driver information not available');
        }

        return FutureBuilder<RouteModel?>(
          future: ref.read(tripRouteProvider(trip.routeId).future),
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
                    Row(
                      children: [
                        // Car Number
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Car: ${driverAvailability.carNumber}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Available Seats
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${driverAvailability.availableSeats}/${driverAvailability.availableSeats} seats',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Price
                    if (route.price > 0)
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
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: trip.queueNumber == 1
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TripDetailsScreen(trip: trip),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: trip.queueNumber == 1 ? AppColors.primary : AppColors.textSecondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Book Now'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TripDetailsScreen(trip: trip),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: AppColors.primary),
                            ),
                            child: Text(
                              'Details',
                              style: TextStyle(color: AppColors.primary),
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
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _showQueueScreen(BuildContext context, TripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerQueueScreen(
          routeId: trip.routeId,
          preferredTime: trip.time,
        ),
      ),
    );
  }
}
