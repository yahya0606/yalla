import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseRepository<T> {
  final String collection;

  BaseRepository(this.collection);

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);

  Future<T?> get(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .get();
      return doc.exists ? fromJson(doc.data()!) : null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  Future<List<T>> getAll() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .get();
      return snapshot.docs
          .map((doc) => fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all items: $e');
    }
  }

  Stream<List<T>> stream() {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => fromJson(doc.data()))
            .toList());
  }

  Future<void> create(T item) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc((item as dynamic).id)
          .set(toJson(item));
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  Future<void> update(String id, T item) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .update(toJson(item));
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }
}

class FirestoreProvider {
  static final firestore = FirebaseFirestore.instance;
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirestoreProvider.firestore;
}); 