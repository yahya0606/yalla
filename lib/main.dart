import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:louage/config/theme/app_theme.dart';
import 'package:louage/features/auth/presentation/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBQEzbs2K3M1fcuRJwJLYT6JFyGKb0iQI8',
      appId: '1:1075011933802:android:01d1717d68401b029f9c13',
      messagingSenderId: '1075011933802',
      projectId: 'louage-867a1',
      storageBucket: 'louage-867a1.firebasestorage.app',
    ),
  );
  runApp(const ProviderScope(child: LouageApp()));
}

class LouageApp extends ConsumerWidget {
  const LouageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Louage Tunisia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthScreen(),
    );
  }
}
