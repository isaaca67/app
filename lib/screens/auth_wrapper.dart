import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/features/onboarding/onboarding_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/home_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/login_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/widgets/splash_screen.dart';

/// Puerta de autenticación reactiva (Web y Android).
///
/// No decide con un booleano capturado una sola vez: escucha
/// `authStateChanges()` y muestra carga mientras el stream está en
/// `ConnectionState.waiting`. En Web el primer evento puede ser `null`
/// mientras se restaura la sesión desde IndexedDB; solo cuando el stream
/// está activo y sin usuario se muestra el Login.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({
    super.key,
    required this.onboardingCompleted,
    required this.onOnboardingComplete,
  });

  final bool onboardingCompleted;
  final VoidCallback onOnboardingComplete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        if (!onboardingCompleted) {
          return OnboardingScreen(
            onOnboardingComplete: onOnboardingComplete,
          );
        }
        return const HomeScreen();
      },
    );
  }
}
