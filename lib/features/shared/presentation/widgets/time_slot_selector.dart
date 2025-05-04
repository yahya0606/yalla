import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/time_slot_provider.dart';

class TimeSlotSelector extends ConsumerWidget {
  final Function(String)? onSlotSelected;

  const TimeSlotSelector({
    super.key,
    this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlots = ref.watch(timeSlotProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slots',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            final isSelected = slot.isSelected;
            return FilterChip(
              label: Text(slot.label),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(timeSlotProvider.notifier).toggleTimeSlot(slot.id);
                if (selected) {
                  onSlotSelected?.call(slot.id);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
} 