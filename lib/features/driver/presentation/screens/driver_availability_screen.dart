import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:louage/features/shared/data/repositories/route_repository.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/shared/presentation/widgets/app_drawer.dart';

class DriverAvailabilityScreen extends ConsumerStatefulWidget {
  const DriverAvailabilityScreen({super.key});

  @override
  ConsumerState<DriverAvailabilityScreen> createState() =>
      _DriverAvailabilityScreenState();
}

class _DriverAvailabilityScreenState
    extends ConsumerState<DriverAvailabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carNumberController = TextEditingController();
  String? _selectedRouteId;
  List<String> _selectedWorkingDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  List<DateTime> _holidayDates = [];
  bool _isLoading = false;
  List<RouteModel> _availableRoutes = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableRoutes();
    _loadDriverAvailability();
  }

  @override
  void dispose() {
    _carNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableRoutes() async {
    try {
      final routes = await ref.read(routeRepositoryProvider).getAllRoutes();
      setState(() => _availableRoutes = routes);
    } catch (e) {
      _showError('Error loading routes: $e');
    }
  }

  Future<void> _loadDriverAvailability() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      // Fetch availability from the 'driver_availability' collection
      final doc = await FirebaseFirestore.instance
          .collection('driver_availability')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // If no availability exists, set default values
        setState(() {
          _selectedRouteId = null;
          _carNumberController.text = '';
          _selectedWorkingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
          _startTime = const TimeOfDay(hour: 8, minute: 0);
          _endTime = const TimeOfDay(hour: 18, minute: 0);
          _holidayDates = [];
        });
        return;
      }

      final data = doc.data()!;
      final savedRouteId = data['routeId'];
      
      // Only set the route ID if it exists in available routes
      if (savedRouteId != null && _availableRoutes.any((route) => route.id == savedRouteId)) {
        _selectedRouteId = savedRouteId;
      } else {
        _selectedRouteId = null;
      }

      setState(() {
        _carNumberController.text = data['carNumber'] ?? '';
        _selectedWorkingDays = List<String>.from(data['workingDays'] ?? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);
        _startTime = _parseTimeString(data['startTime'] ?? '08:00');
        _endTime = _parseTimeString(data['endTime'] ?? '18:00');
        _holidayDates = (data['holidayDates'] as List<dynamic>? ?? [])
            .map((e) => e is Timestamp ? e.toDate() : DateTime.parse(e.toString()))
            .toList();
      });
    } catch (e) {
      _showError('Error loading availability: $e');
    }
  }

  TimeOfDay _parseTimeString(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _saveAvailability() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not found');

      final availabilityData = {
        'routeId': _selectedRouteId!,
        'carNumber': _carNumberController.text.trim(),
        'workingDays': _selectedWorkingDays,
        'startTime': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'endTime': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'holidayDates': _holidayDates.map((date) => Timestamp.fromDate(date)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save the availability data in the 'driver_availability' collection
      await FirebaseFirestore.instance
          .collection('driver_availability')
          .doc(user.uid)
          .set(availabilityData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error saving availability: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(context: context, initialTime: _startTime);
    if (time != null) setState(() => _startTime = time);
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(context: context, initialTime: _endTime);
    if (time != null) setState(() => _endTime = time);
  }

  Future<void> _addHoliday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _holidayDates.add(date));
    }
  }

  void _removeHoliday(DateTime date) {
    setState(() {
      _holidayDates.removeWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Availability')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonFormField<String>(
              value: _selectedRouteId,
              decoration: const InputDecoration(labelText: 'Select Route', prefixIcon: Icon(Icons.route)),
              items: _availableRoutes.map((route) {
                return DropdownMenuItem(
                  value: route.id,
                  child: Text('${route.from} → ${route.to}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRouteId = value);
                }
              },
              validator: (value) => value == null ? 'Please select a route' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carNumberController,
              decoration: const InputDecoration(labelText: 'Car Number', prefixIcon: Icon(Icons.directions_car)),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter car number' : null,
            ),
            const SizedBox(height: 16),
            const Text('Working Days'),
            Wrap(
              spacing: 8,
              children: [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ].map((day) {
                return FilterChip(
                  label: Text(day),
                  selected: _selectedWorkingDays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      selected ? _selectedWorkingDays.add(day) : _selectedWorkingDays.remove(day);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Start Time', prefixIcon: Icon(Icons.access_time)),
                      child: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.access_time)),
                      child: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Holidays'),
                ElevatedButton.icon(
                  onPressed: _addHoliday,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Holiday'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _holidayDates.map((date) {
                return Chip(
                  label: Text(DateFormat('MMM dd, yyyy').format(date)),
                  onDeleted: () => _removeHoliday(date),
                  deleteIcon: const Icon(Icons.close),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAvailability,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Availability'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
