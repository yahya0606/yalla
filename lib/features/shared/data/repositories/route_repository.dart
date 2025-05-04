import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/base_repository.dart';
import 'package:louage/features/shared/domain/models/route_model.dart';

class RouteRepository extends BaseRepository<RouteModel> {
  final FirebaseFirestore _firestore;

  RouteRepository(this._firestore) : super('routes');

  @override
  RouteModel fromJson(Map<String, dynamic> json) {
    return RouteModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(RouteModel model) {
    return model.toJson();
  }

  @override
  Future<RouteModel?> get(String id) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .doc(id)
          .get();
      return snapshot.exists ? fromJson(snapshot.data()!) : null;
    } catch (e) {
      throw Exception('Failed to get route: $e');
    }
  }

  Future<RouteModel?> getRouteById(String id) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(id)
          .get();

      if (!doc.exists) return null;
      return fromJson(doc.data()!);
    } catch (e) {
      print('Error getting route by id: $e');
      return null;
    }
  }

  @override
  Future<List<RouteModel>> getAll() async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .get();
      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all routes: $e');
    }
  }

  Future<List<RouteModel>> getAllRoutes() async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .orderBy('from')
          .get();

      return querySnapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all routes: $e');
      return [];
    }
  }

  Stream<List<RouteModel>> getRoutesStream() {
    return _firestore
        .collection(collection)
        .orderBy('from')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.data()))
            .toList());
  }

  @override
  Future<void> create(RouteModel route) async {
    try {
      await _firestore
          .collection(collection)
          .doc(route.id)
          .set(toJson(route));
    } catch (e) {
      throw Exception('Failed to create route: $e');
    }
  }

  @override
  Future<void> update(String id, RouteModel route) async {
    try {
      await _firestore
          .collection(collection)
          .doc(id)
          .update(toJson(route));
    } catch (e) {
      throw Exception('Failed to update route: $e');
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
      throw Exception('Failed to delete route: $e');
    }
  }

  Future<List<RouteModel>> searchRoutes({
    required String from,
    required String to,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('from', isEqualTo: from)
          .where('to', isEqualTo: to)
          .get();

      return querySnapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching routes: $e');
      return [];
    }
  }
}

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(FirebaseFirestore.instance);
});