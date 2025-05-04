import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/services/auth_service.dart';
import 'package:louage/features/auth/domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:louage/features/shared/data/repositories/user_repository.dart';  // Ensure this is imported

// Modify the authServiceProvider to pass the required arguments to AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = FirebaseAuth.instance; // Getting the FirebaseAuth instance
  final userRepository = ref.read(userRepositoryProvider); // Assuming you have this provider
  return AuthService();  // Inject dependencies into AuthService
});

// Modify the authProvider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final userModel = await _authService.getCurrentUserModel(); // ✅ This fetches full user data from Firestore
    if (userModel != null) {
      state = AuthState.authenticated(userModel); // ✅ This expects a UserModel
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = AuthState.loading();
      final user = await _authService.signIn(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      state = AuthState.loading();
      await _authService.signOut();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final UserModel? currentUser;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.error,
    this.currentUser,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: true,
      isAuthenticated: false,
    );
  }

  factory AuthState.loading() {
    return AuthState(
      isLoading: true,
      isAuthenticated: false,
    );
  }

  factory AuthState.authenticated(UserModel user) {
    return AuthState(
      isLoading: false,
      isAuthenticated: true,
      currentUser: user,
    );
  }

  factory AuthState.unauthenticated() {
    return AuthState(
      isLoading: false,
      isAuthenticated: false,
    );
  }

  factory AuthState.error(String error) {
    return AuthState(
      isLoading: false,
      isAuthenticated: false,
      error: error,
    );
  }
}
