import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/data/services/auth_service.dart';
import 'package:louage/features/auth/domain/models/user_model.dart';
import 'package:louage/features/shared/data/repositories/user_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return null;
  
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.get(authState.uid);
}); 