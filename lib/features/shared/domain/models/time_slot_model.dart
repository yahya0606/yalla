import 'package:flutter/material.dart';

class TimeSlot {
  final String id;
  final String label;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isSelected;

  TimeSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    this.isSelected = false,
  });

  TimeSlot copyWith({
    String? id,
    String? label,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isSelected,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      label: label ?? this.label,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Helper method to check if a given time falls within this slot
  bool containsTime(DateTime time) {
    final timeOfDay = TimeOfDay.fromDateTime(time);
    final timeInMinutes = timeOfDay.hour * 60 + timeOfDay.minute;
    final startInMinutes = startTime.hour * 60 + startTime.minute;
    final endInMinutes = endTime.hour * 60 + endTime.minute;
    return timeInMinutes >= startInMinutes && timeInMinutes < endInMinutes;
  }

  // Helper method to get the next available time slot
  static TimeSlot? getNextAvailableSlot(List<TimeSlot> slots, DateTime currentTime) {
    for (var slot in slots) {
      if (slot.startTime.hour * 60 + slot.startTime.minute > 
          currentTime.hour * 60 + currentTime.minute) {
        return slot;
      }
    }
    return null;
  }
}

// Predefined time slots
class TimeSlotData {
  static List<TimeSlot> getTimeSlots() {
    return [
      TimeSlot(
        id: '04-06',
        label: '4:00 - 6:00',
        startTime: const TimeOfDay(hour: 4, minute: 0),
        endTime: const TimeOfDay(hour: 6, minute: 0),
      ),
      TimeSlot(
        id: '06-08',
        label: '6:00 - 8:00',
        startTime: const TimeOfDay(hour: 6, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 0),
      ),
      TimeSlot(
        id: '08-10',
        label: '8:00 - 10:00',
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
      ),
      TimeSlot(
        id: '10-12',
        label: '10:00 - 12:00',
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      ),
      TimeSlot(
        id: '12-14',
        label: '12:00 - 14:00',
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 0),
      ),
      TimeSlot(
        id: '14-16',
        label: '14:00 - 16:00',
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
      ),
    ];
  }
} 