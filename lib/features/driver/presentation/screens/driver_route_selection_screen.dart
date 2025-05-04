import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart';
import 'package:louage/features/shared/data/repositories/route_repository.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';

class DriverRouteSelectionScreen extends ConsumerStatefulWidget {
  const DriverRouteSelectionScreen({super.key});

  @override
  ConsumerState<DriverRouteSelectionScreen> createState() => _DriverRouteSelectionScreenState();
}

class _DriverRouteSelectionScreenState extends ConsumerState<DriverRouteSelectionScreen> {
  String? _selectedRouteId;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _updateRoute(String routeId, DriverAvailabilityModel? existingAvailability) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not found');

      final now = DateTime.now();
      final newAvailability = DriverAvailabilityModel(
        id: existingAvailability?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: user.uid,
        routeId: routeId,
        carNumber: existingAvailability?.carNumber ?? '',
        startTime: existingAvailability?.startTime ?? '08:00',
        endTime: existingAvailability?.endTime ?? '23:00',
        workingDays: existingAvailability?.workingDays ?? const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        holidayDates: existingAvailability?.holidayDates ?? [],
        createdAt: existingAvailability?.createdAt ?? now,
        availableDates: [DateTime(2025, 4, 25)],
        availableTimes: ["08:00","23:00"],
        updatedAt: now,
        isInQueue: false,
      );

      if (existingAvailability == null) {
        await ref.read(driverAvailabilityRepositoryProvider).create(newAvailability);
      } else {
        await ref.read(driverAvailabilityRepositoryProvider).update(existingAvailability.id, newAvailability);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'routeId': routeId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error updating route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating route: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Please log in to select a route'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Route'),
      ),
      body: FutureBuilder<DriverAvailabilityModel?>(
        future: ref.read(driverAvailabilityRepositoryProvider).getByDriverId(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final availability = snapshot.data;
          if (availability != null) {
            _selectedRouteId = availability.routeId;
          }

          return FutureBuilder<List<RouteModel>>(
            future: ref.read(routeRepositoryProvider).getAllRoutes(),
            builder: (context, routesSnapshot) {
              if (routesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (routesSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${routesSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final routes = routesSnapshot.data ?? [];
              if (routes.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No routes available'),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.shade100,
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _errorMessage = null),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Your Route',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRouteId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: routes.map((route) {
                                return DropdownMenuItem<String>(
                                  value: route.id,
                                  child: Text('${route.from} → ${route.to}'),
                                );
                              }).toList(),
                              onChanged: _isLoading ? null : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRouteId = value;
                                  });
                                  _updateRoute(value, availability);
                                }
                              },
                            ),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
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
} 