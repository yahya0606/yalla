import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';

class DriverQueueScreen extends ConsumerWidget {
  const DriverQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Center(child: Text('Please log in to view queue status'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Status')),
      body: StreamBuilder<DriverAvailabilityModel?>(
        stream: ref.watch(driverAvailabilityRepositoryProvider).streamByDriverId(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(driverAvailabilityRepositoryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final driverAvailability = snapshot.data;
          if (driverAvailability == null) {
            return const Center(child: Text('No availability data found'));
          }

          if (!driverAvailability.isInQueue) {
            return FutureBuilder<DriverAvailabilityModel?>(
              future: ref.read(driverAvailabilityRepositoryProvider).getByDriverId(user.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${userSnapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(driverAvailabilityRepositoryProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!userSnapshot.hasData) {
                  return const Center(child: Text("Availability not found"));
                }

                final availability = userSnapshot.data!;
                final now = DateTime.now();
                final currentDay = _weekdayName(now.weekday);
                final currentTime = TimeOfDay.fromDateTime(now);

                final startTime = _convertToTimeOfDay(availability.startTime);
                final endTime = _convertToTimeOfDay(availability.endTime);
                final isWorkingDay = availability.workingDays.contains(currentDay);
                final isWithinTime = _isWithinTimeRange(currentTime, startTime, endTime);

                if (isWorkingDay && isWithinTime) {
                  // Show a button to join the queue
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.queue, size: 48, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          "You are available to join the queue.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await ref.read(driverAvailabilityRepositoryProvider).addToQueue(user.uid);
                            if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driver added to queue!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                            }
                          },
                          child: const Text('Join Queue'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Working Hours: ${availability.startTime} - ${availability.endTime}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        "You are not available to join the queue now.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Working Hours: ${availability.startTime} - ${availability.endTime}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          // If driver is in queue, show queue status
          return StreamBuilder<List<DriverAvailabilityModel>>(
            stream: ref.watch(driverAvailabilityRepositoryProvider).getQueueStream(driverAvailability.routeId),
            builder: (context, queueSnapshot) {
              if (queueSnapshot.hasError) {
                return Center(child: Text('Error: ${queueSnapshot.error}'));
              }

              if (!queueSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final queue = queueSnapshot.data!;
              queue.sort((a, b) {
                if (a.queueNumber != b.queueNumber) {
                  return (a.queueNumber ?? 0).compareTo(b.queueNumber ?? 0);
                }
                final aTime = a.lastArrivalTime ?? DateTime.now();
                final bTime = b.lastArrivalTime ?? DateTime.now();
                return aTime.compareTo(bTime);
              });

              return _buildQueueStatusPage(context, driverAvailability, queue);
            },
          );
        },
      ),
    );
  }

  Widget _buildQueueStatusPage(BuildContext context, DriverAvailabilityModel driver, List<DriverAvailabilityModel> queue) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQueueStatusCard(context, driver),
          const SizedBox(height: 24),
          const Text('Current Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final d = queue[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: d.queueNumber == 1 ? Colors.green : Colors.blue,
                    child: Text('${d.queueNumber ?? "?"}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('Car ${d.carNumber}'),
                  subtitle: Text('Available Seats: ${d.availableSeats ?? 0}'),
                  trailing: d.queueNumber == 1 ? const Icon(Icons.check_circle, color: Colors.green) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatusCard(BuildContext context, DriverAvailabilityModel availability) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          print('Queue card tapped!'); // Debug print
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Queue Position: ${availability.queueNumber ?? "-"}\nAvailable Seats: ${availability.availableSeats ?? 0}',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        },
        child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Queue Position',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.touch_app, color: Colors.blue.withOpacity(0.7)),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Position: ${availability.queueNumber ?? "-"}', style: const TextStyle(fontSize: 24)),
                Text('Seats: ${availability.availableSeats ?? 0}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (availability.lastArrivalTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Last Arrival: ${_formatDateTime(availability.lastArrivalTime!)}'),
              ),
          ],
          ),
        ),
      ),
    );
  }

  static String _weekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay _convertToTimeOfDay(String timeStr) {
    if (timeStr.isEmpty) {
      print("❌ Empty time string");
      return const TimeOfDay(hour: 0, minute: 0);
    }

    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) throw const FormatException("Invalid format");

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("❌ Failed to parse time '$timeStr': $e");
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  static bool _isWithinTimeRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // Helper function to generate available dates based on working days and holiday dates
  static List<DateTime> _generateAvailableDates(DriverAvailabilityModel availability) {
    List<DateTime> availableDates = [];
    DateTime currentDate = DateTime.now();

    // Loop through the working days and generate corresponding dates
    for (var day in availability.workingDays) {
      DateTime availableDate = _getDateForWeekday(day, currentDate);

      // Skip holidays
      if (!availability.holidayDates.contains(availableDate)) {
        availableDates.add(availableDate);
      }
    }

    return availableDates;
  }

  // Helper function to generate available times based on startTime and endTime
  static List<String> _generateAvailableTimes(DriverAvailabilityModel availability) {
    List<String> availableTimes = [];
    TimeOfDay start = _convertToTimeOfDay(availability.startTime);
    TimeOfDay end = _convertToTimeOfDay(availability.endTime);

    // Add start time
    availableTimes.add(_formatTimeOfDay(start));

    // Add 30-minute intervals until we reach or exceed end time
    TimeOfDay currentTime = start;
    while (true) {
      currentTime = _addTimeInterval(currentTime, 30);
      if (_isTimeBeforeOrEqual(currentTime, end)) {
        availableTimes.add(_formatTimeOfDay(currentTime));
      } else {
        break;
      }
    }

    return availableTimes;
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static bool _isTimeBeforeOrEqual(TimeOfDay time1, TimeOfDay time2) {
    final minutes1 = time1.hour * 60 + time1.minute;
    final minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 <= minutes2;
  }

  // Helper function to get the date for a specific weekday
  static DateTime _getDateForWeekday(String weekday, DateTime startDate) {
    int targetWeekday = _weekdayNameToIndex(weekday);
    int daysToAdd = (targetWeekday - startDate.weekday + 7) % 7;

    return startDate.add(Duration(days: daysToAdd));
  }

  // Convert weekday name to index (1 = Monday, 7 = Sunday)
  static int _weekdayNameToIndex(String weekday) {
    const weekdayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return weekdayMap[weekday] ?? 1;  // Default to Monday if the name is not valid
  }

  // Helper function to add a time interval (e.g., 30 minutes) to a TimeOfDay
  static TimeOfDay _addTimeInterval(TimeOfDay time, int minutes) {
    int totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }
}
