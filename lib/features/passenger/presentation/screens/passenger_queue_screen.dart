import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/driver_availability_repository.dart';
import 'package:louage/features/shared/domain/models/driver_availability_model.dart';

class PassengerQueueScreen extends ConsumerWidget {
  final String routeId;
  final String preferredTime;

  const PassengerQueueScreen({
    super.key,
    required this.routeId,
    required this.preferredTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh queue status
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DriverAvailabilityModel>>(
        stream: ref.watch(driverAvailabilityRepositoryProvider).getQueueStream(routeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final queue = snapshot.data!;
          final estimatedWaitTime = _calculateEstimatedWaitTime(queue);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWaitTimeCard(context, estimatedWaitTime),
                const SizedBox(height: 24),
                _buildQueueList(context, queue),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaitTimeCard(BuildContext context, int estimatedWaitTime) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Wait Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${estimatedWaitTime} minutes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Icon(Icons.timer, size: 32),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Preferred Time: $preferredTime',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(BuildContext context, List<DriverAvailabilityModel> queue) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Queue',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final driver = queue[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: driver.isInQueue
                        ? Colors.green
                        : Colors.red,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('Car ${driver.carNumber}'),
                  subtitle: Text(
                    'Working Hours: ${driver.startTime} - ${driver.endTime}',
                  ),
                  trailing: driver.isInQueue
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateEstimatedWaitTime(List<DriverAvailabilityModel> queue) {
    // Simple estimation: 5 minutes per driver in queue
    return queue.length * 5;
  }
} 