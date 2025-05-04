import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/auth/domain/models/user_model.dart';
import 'package:louage/features/auth/presentation/screens/login_screen.dart';
import 'package:louage/features/passenger/presentation/screens/passenger_home_screen.dart';
import 'package:louage/features/driver/presentation/screens/driver_home_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.watch(currentUserProvider);

    return userModel.when(
      data: (model) {
        if (model == null) {
          return const LoginScreen();
        }

        switch (model.role) {
          case UserRole.passenger:
            return const PassengerHomeScreen();
          case UserRole.driver:
            return const DriverHomeScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
} 