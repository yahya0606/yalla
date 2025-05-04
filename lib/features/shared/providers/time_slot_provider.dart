import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/time_slot_model.dart';

final timeSlotProvider = StateNotifierProvider<TimeSlotNotifier, List<TimeSlot>>((ref) {
  return TimeSlotNotifier();
});

class TimeSlotNotifier extends StateNotifier<List<TimeSlot>> {
  TimeSlotNotifier() : super(TimeSlotData.getTimeSlots());

  void toggleTimeSlot(String slotId) {
    state = state.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(isSelected: !slot.isSelected);
      }
      return slot;
    }).toList();
  }

  void clearSelection() {
    state = state.map((slot) => slot.copyWith(isSelected: false)).toList();
  }

  List<TimeSlot> getSelectedSlots() {
    return state.where((slot) => slot.isSelected).toList();
  }

  bool isSlotSelected(String slotId) {
    return state.any((slot) => slot.id == slotId && slot.isSelected);
  }
} 