import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth for User class
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/auth/data/services/auth_service.dart';
import 'package:louage/features/driver/presentation/screens/driver_availability_screen.dart';
import 'package:louage/features/driver/presentation/screens/qr_scanner_screen.dart';
import 'package:louage/features/shared/data/repositories/trip_repository.dart';
import 'package:louage/features/shared/domain/models/trip_model.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart' as repo;
import 'package:louage/features/shared/presentation/widgets/app_drawer.dart';
import 'package:louage/features/driver/presentation/widgets/driver_trip_card.dart';
import 'package:louage/features/driver/presentation/screens/driver_queue_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart'; // Import for SchedulerBinding
import 'package:louage/features/driver/presentation/screens/add_trip_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view trips'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Trips'),
            Tab(text: 'Queue'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Trip',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTripScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid) // Listen for the driver's availability document
                .snapshots(),
            builder: (context, availabilitySnapshot) {
              if (availabilitySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (availabilitySnapshot.hasError) {
                return Center(child: Text('Error: ${availabilitySnapshot.error}'));
              }

              final driverDoc = availabilitySnapshot.data;

              // Check if the document exists before accessing its fields
              if (driverDoc == null || !driverDoc.exists) {
                return const Center(child: Text('Driver profile not found.'));
              }

              final isInQueue = driverDoc.get('isInQueue') ?? false;

              // Show trips regardless of queue status
              return StreamBuilder<List<TripModel>>(
                stream: ref.watch(tripRepositoryProvider).getTripsByDriverStream(driverId: user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final trips = snapshot.data!;
                  if (trips.isEmpty) {
                    return const Center(child: Text('No trips for today'));
                  }

                  return Column(
                    children: [
                      if (!isInQueue)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.orange.withOpacity(0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You are not in the queue. Please set your availability to receive new trips.',
                                  style: TextStyle(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: trips.length,
                          itemBuilder: (context, index) {
                            final trip = trips[index];
                            return DriverTripCard(
                              trip: trip,
                              onStatusUpdate: (tripId, status) {
                                // Handle any additional logic after status update if needed
                                debugPrint('Trip $tripId status updated to $status');
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const DriverQueueScreen(),
        ],
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, availabilitySnapshot) {
          if (availabilitySnapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final driverDoc = availabilitySnapshot.data;

          // Check if the document exists before accessing its fields
          if (driverDoc == null || !driverDoc.exists) {
            return const CircularProgressIndicator();
          }

          bool isInQueue = driverDoc.get('isInQueue') ?? false;

          return FloatingActionButton(
            onPressed: () async {
              if (isInQueue) {
                await _leaveQueue(ref, user);
              } else {
                await _startWorking(ref, user);
              }
            },
            backgroundColor: isInQueue ? Colors.red : Colors.green,
            child: Icon(isInQueue ? Icons.exit_to_app : Icons.play_arrow),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Update trip status (progress/completed/cancelled)
  Future<void> _updateTripStatus(
      BuildContext context,
      WidgetRef ref,
      String tripId,
      TripStatus status,
      ) async {
    if (!mounted) return;
    try {
      await ref.read(tripRepositoryProvider).updateTripStatus(tripId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip ${status.name} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  // Starts the driver's work (adding them to queue)
  Future<void> _startWorking(WidgetRef ref, User user) async {
    try {
      print('▶️ Starting _startWorking for UID: ${user.uid}');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('Driver profile not found in users collection');
      }

      final userData = userDoc.data()!;
      final routeId = userData['routeId'] ?? '1';

      // Get the route document using the driver's routeId
      final routeDoc = await FirebaseFirestore.instance.collection('routes').doc(routeId).get();
      if (!routeDoc.exists) {
        throw Exception('Route with ID $routeId not found in routes collection');
      }

      // Add to the queue
      await ref.read(repo.driverAvailabilityRepositoryProvider).addToQueue(user.uid);

      // Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isInQueue': true,  // Mark as in queue
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ You are now in the queue.")),
        );
      }

      print('✅ Driver added to queue successfully');
    } catch (e) {
      print('❌ Error in _startWorking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to join queue: $e")),
        );
      }
    }
  }

  // Removes the driver from the queue
  Future<void> _leaveQueue(WidgetRef ref, User user) async {
    try {
      final driverDoc = await FirebaseFirestore.instance
          .collection('driver_availability')
          .doc(user.uid)
          .get();

      //if (driverDoc.exists) {
      //  await FirebaseFirestore.instance
      //      .collection('driver_availability')
      //      .doc(user.uid)
      //      .delete();
      //}

      await ref.read(repo.driverAvailabilityRepositoryProvider).removeFromQueue(user.uid);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isInQueue': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have left the queue.")),
        );
      }
    } catch (e) {
      print('❌ Error leaving queue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to leave queue: $e")),
        );
      }
    }
  }

  // Generate the available dates excluding holidays
  List<DateTime> _generateAvailableDates({
    required List<String> workingDays,
    required List<DateTime> holidayDates,
  }) {
    // Logic to generate available dates
    return [];
  }

  // Generate the available times based on start and end time
  List<String> _generateAvailableTimes({required String startTime, required String endTime}) {
    // Logic to generate available times
    return [];
  }
}
