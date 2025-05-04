import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/domain/models/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(FirebaseFirestore.instance);
});

class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  Future<ReviewModel> createReview(ReviewModel review) async {
    final docRef = _reviews.doc();
    final reviewWithId = review.copyWith(id: docRef.id);
    await docRef.set(reviewWithId.toMap());
    return reviewWithId;
  }

  Stream<List<ReviewModel>> getReviewsByDriver(String driverId) {
    return _reviews
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<ReviewModel>> getReviewsByTrip(String tripId) {
    return _reviews
        .where('tripId', isEqualTo: tripId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.data()))
            .toList());
  }

  Future<double> getAverageRatingForDriver(String driverId) async {
    final reviews = await _reviews
        .where('driverId', isEqualTo: driverId)
        .get();
    
    if (reviews.docs.isEmpty) return 0.0;
    
    final totalRating = reviews.docs.fold<double>(
      0,
      (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );
    
    return totalRating / reviews.docs.length;
  }

  Future<bool> hasReviewedTrip(String tripId, String passengerId) async {
    final review = await _reviews
        .where('tripId', isEqualTo: tripId)
        .where('passengerId', isEqualTo: passengerId)
        .get();
    
    return review.docs.isNotEmpty;
  }
} 