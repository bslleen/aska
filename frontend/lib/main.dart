
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'home_screen.dart';
import 'auth/auth_screen.dart';
import 'splash_screen.dart';

void main() {
  runApp(const AskaApp());
}

class AskaApp extends StatelessWidget {
  const AskaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreenWrapper(),
      ),
    );
  }
}

class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const SplashScreen(
            nextScreen: AuthWrapper(),
          );
        }

        return const AuthWrapper();
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user == null) {
      return const AuthScreen();
    }

    return const HomePage();
  }
}
