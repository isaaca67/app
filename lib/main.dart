import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/config/app_config.dart';
import 'package:stitch_cov_dark_mobile_login/core/constants/app_constants.dart';
import 'package:stitch_cov_dark_mobile_login/core/di/service_locator.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/screens/home_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/login_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/widgets/configuration_error_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;
  try {
    await Firebase.initializeApp(
      options: AppConfig.firebaseOptions,
    );
    // Habilita la caché local de Firestore para que la app funcione sin
    // conexión y se sincronice automáticamente al volver la red.
    _enableOfflinePersistence();
  } catch (error) {
    initializationError = error;
  }

  await serviceLocator.initialize(
    googleClientId: AppConfig.googleSignInClientId,
  );

  runApp(MyApp(
    initializationError: initializationError,
  ));
}

/// Activa la persistencia local de Firestore.
///
/// - En móvil (APK): caché en disco, la app puede leer/escribir sin conexión
///   y se sincroniza sola al volver el WiFi.
/// - En Web: usa el caché persistente de IndexedDB (multi-pestaña).
///
/// Debe configurarse antes de cualquier consulta.
void _enableOfflinePersistence() {
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      webPersistentTabManager: WebPersistentMultipleTabManager(),
    );
  } else {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initializationError});

  final Object? initializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: initializationError != null
          ? ConfigurationErrorScreen(
              error: initializationError,
              onRetry: () => runApp(const MyApp()),
            )
          : StreamBuilder<User?>(
              stream: serviceLocator.authService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (snapshot.hasData) {
                  return const HomeScreen();
                }

                return const LoginScreen();
              },
            ),
    );
  }
}