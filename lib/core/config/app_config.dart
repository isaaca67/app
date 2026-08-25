import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:stitch_cov_dark_mobile_login/core/constants/app_constants.dart';

/// Configuración central de la aplicación.
///
/// Todas las conexiones externas (Firebase y Google OAuth) se pueden
/// sobreescribir en tiempo de compilación mediante variables de entorno
/// con `--dart-define`:
///
/// ```bash
/// flutter run --dart-define=FIREBASE_WEB_API_KEY=... \
///             --dart-define=GOOGLE_CLIENT_ID=... \
///             --dart-define=APP_ENV=production
/// ```
///
/// IMPORTANTE: `String.fromEnvironment` SOLO puede usarse en contexto `const`,
/// por eso cada variable se declara como `static const`. No se llama nunca en
/// tiempo de ejecución.
///
/// Los valores por defecto son literales seguros (claves públicas de cliente
/// de Firebase, identificadores de la app, no secretos), de modo que la app
/// arranca sin necesidad de flags en desarrollo local. La seguridad real la
/// garantizan las reglas de Firestore y Firebase App Check.
class AppConfig {
  AppConfig._();

  // --- Entorno ---
  /// 'development', 'staging' o 'production'.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';

  // --- Firebase: Web ---
  static const String _webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyDSnQ74yBb-lYPFrjvhf_m9xKoqT670DMw',
  );
  static const String _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:1004379594579:web:9c9ce66a86705d40c08ba6',
  );
  static const String _webSenderId = String.fromEnvironment(
    'FIREBASE_WEB_SENDER_ID',
    defaultValue: '1004379594579',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'cov-app-71e00',
  );
  static const String _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'cov-app-71e00.firebaseapp.com',
  );
  static const String _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: 'cov-app-71e00.firebasestorage.app',
  );
  static const String _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: 'G-T2K1LRB6F7',
  );

  // --- Firebase: Android ---
  static const String _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyACdumZYQ6F_rnrpfpP7pwSDO3oK8ihuh4',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:1004379594579:android:7048fc3af6abffa6c08ba6',
  );
  static const String _androidSenderId = String.fromEnvironment(
    'FIREBASE_ANDROID_SENDER_ID',
    defaultValue: '1004379594579',
  );
  static const String _androidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
    defaultValue: 'cov-app-71e00.firebasestorage.app',
  );

  // --- Google OAuth ---
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: AppConstants.googleClientId,
  );

  static const FirebaseOptions _webOptions = FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _webSenderId,
    projectId: _projectId,
    authDomain: _webAuthDomain,
    storageBucket: _webStorageBucket,
    measurementId: _webMeasurementId,
  );

  static const FirebaseOptions _androidOptions = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _androidSenderId,
    projectId: _projectId,
    storageBucket: _androidStorageBucket,
  );

  /// [FirebaseOptions] para la plataforma actual (Web o Android).
  static FirebaseOptions get firebaseOptions {
    if (kIsWeb) {
      return _webOptions;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidOptions;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('COV solo está configurado para Web y Android.');
    }
  }

  /// Client ID de Google para Web.
  ///
  /// En Android no se debe pasar: el plugin de Google Sign-In lee el client ID
  /// automáticamente desde `google-services.json`/los recursos de la app.
  static String? get googleSignInClientId => kIsWeb ? googleClientId : null;
}
