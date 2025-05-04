import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/passenger_count_model.dart';

final passengerCountRepositoryProvider = Provider<PassengerCountRepository>((ref) {
  return PassengerCountRepository(FirebaseFirestore.instance);
});

class PassengerCountRepository {
  final FirebaseFirestore _firestore;
  static const String collection = 'passenger_counts';

  PassengerCountRepository(this._firestore);

  Stream<List<PassengerCountModel>> getPassengerCountsForTrips(List<String> tripIds) {
    return _firestore
        .collection(collection)
        .where('tripId', whereIn: tripIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PassengerCountModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> updatePassengerCount(String tripId, int currentPassengers) async {
    await _firestore.collection(collection).doc(tripId).set({
      'tripId': tripId,
      'currentPassengers': currentPassengers,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementPassengerCount(String tripId) async {
    await _firestore.collection(collection).doc(tripId).update({
      'currentPassengers': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> decrementPassengerCount(String tripId) async {
    await _firestore.collection(collection).doc(tripId).update({
      'currentPassengers': FieldValue.increment(-1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
} 