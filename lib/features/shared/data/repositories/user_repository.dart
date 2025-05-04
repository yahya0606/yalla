import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/data/repositories/base_repository.dart';
import 'package:louage/features/auth/domain/models/user_model.dart';

class UserRepository extends BaseRepository<UserModel> {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore) : super('users');

  @override
  UserModel fromJson(Map<String, dynamic> json) {
    return UserModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(UserModel user) {
    return user.toJson();
  }

  @override
  Future<UserModel?> get(String id) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .doc(id)
          .get();
      return snapshot.exists ? fromJson(snapshot.data()!) : null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<List<UserModel>> getAll() async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .get();
      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  @override
  Stream<List<UserModel>> stream() {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.data()))
            .toList());
  }

  @override
  Future<void> create(UserModel user) async {
    try {
      await _firestore
          .collection(collection)
          .doc(user.uid)
          .set(toJson(user));
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<void> update(String id, UserModel user) async {
    try {
      await _firestore
          .collection(collection)
          .doc(id)
          .update(toJson(user));
    } catch (e) {
      throw Exception('Failed to update user: $e');
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
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<UserModel?> getByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('email', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
}); 