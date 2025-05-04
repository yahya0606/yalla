import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/base_repository.dart';
import 'package:louage/features/shared/domain/models/booking_model.dart';

class BookingRepository extends BaseRepository<BookingModel> {
  final FirebaseFirestore _firestore;

  BookingRepository(this._firestore) : super('bookings');

  @override
  BookingModel fromJson(Map<String, dynamic> json) {
    return BookingModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(BookingModel booking) {
    return booking.toJson();
  }

  @override
  Future<BookingModel?> get(String id) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .doc(id)
          .get();
      return snapshot.exists ? fromJson(snapshot.data()!) : null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  @override
  Future<List<BookingModel>> getAll() async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .get();
      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all bookings: $e');
    }
  }

  @override
  Stream<List<BookingModel>> stream() {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.data()))
            .toList());
  }

  @override
  Future<void> create(BookingModel booking) async {
    try {
      await _firestore
          .collection(collection)
          .doc(booking.id)
          .set(toJson(booking));
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  @override
  Future<void> update(String id, BookingModel booking) async {
    try {
      await _firestore
          .collection(collection)
          .doc(id)
          .update(toJson(booking));
    } catch (e) {
      throw Exception('Failed to update booking: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _firestore
          .collection(collection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }

  Future<List<BookingModel>> getBookingsByPassenger(String passengerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('passengerId', isEqualTo: passengerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting bookings by passenger: $e');
      return [];
    }
  }

  Future<List<BookingModel>> getBookingsByDriver(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error getting bookings by driver: $e');
    }
  }

  Future<List<BookingModel>> getBookingsByTrip(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('tripId', isEqualTo: tripId)
          .get();

      return querySnapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting bookings by trip: $e');
      return [];
    }
  }

  Stream<List<BookingModel>> getBookingsByTripStream(String tripId) {
    return _firestore
        .collection(collection)
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.data()))
            .toList());
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore
          .collection(collection)
          .doc(bookingId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentMethod(String bookingId, PaymentMethod method) async {
    await _firestore.collection(collection).doc(bookingId).update({
      'paymentMethod': method.toString(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<bool> hasActiveBooking(String passengerId) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('passengerId', isEqualTo: passengerId)
        .where('status', whereIn: [
          BookingStatus.pending.toString(),
          BookingStatus.confirmed.toString(),
        ])
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createBooking({
    required String tripId,
    required String passengerId,
    required String passengerName,
    required BookingStatus status,
    required PaymentMethod paymentMethod,
    required bool isPaid,
    required String fromCity,
    required String toCity,
    required int seats,
    required double totalPrice,
  }) async {
    final trip = await get(tripId);
    if (trip == null) throw Exception('Trip not found');

    final booking = BookingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      passengerId: passengerId,
      passengerName: passengerName,
      from: fromCity,
      to: toCity,
      seats: seats,
      totalPrice: totalPrice,
      status: status,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await create(booking);
  }

  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('passengerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      rethrow;
    }
  }

  Stream<List<BookingModel>> getBookingsByUserStream(String userId) {
    return _firestore
        .collection(collection)
        .where('passengerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    }).handleError((error) {
      print('Error in getBookingsByUserStream: $error');
      // If the index is not ready, return an empty list
      if (error.toString().contains('index')) {
        return Stream.value([]);
      }
      // For other errors, rethrow
      throw error;
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore
          .collection(collection)
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  Future<BookingModel?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection(collection).doc(bookingId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return fromJson(data);
    } catch (e) {
      print('Error getting booking: $e');
      rethrow;
    }
  }

  Future<bool> isBookingRefundable(String bookingId) async {
    final booking = await getBooking(bookingId);
    if (booking == null) return false;

    // Check if booking is within refund window (e.g., 24 hours before departure)
    final now = DateTime.now();
    final departureTime = booking.date;
    final refundWindow = const Duration(hours: 24);

    return departureTime.difference(now) > refundWindow;
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(FirebaseFirestore.instance);
}); 