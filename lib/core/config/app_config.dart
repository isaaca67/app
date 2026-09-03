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
    defaultValue: 'AIzaSyBbFl6PViR5WB9KykwlS3HMJx0qKxa3hU0',
  );
  static const String _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:55959964226:web:a31cf8b8c9cd8d52973bdb',
  );
  static const String _webSenderId = String.fromEnvironment(
    'FIREBASE_WEB_SENDER_ID',
    defaultValue: '55959964226',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'cov-app-5d4b2',
  );
  static const String _webAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: 'cov-app-5d4b2.firebaseapp.com',
  );
  static const String _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: 'cov-app-5d4b2.firebasestorage.app',
  );
  static const String _webMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: '',
  );

  // --- Firebase: Android ---
  static const String _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyBB4qdxqCnymorkFT4YwXt10m48jVLQOo8',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:55959964226:android:4e19c2a005ae7c2a973bdb',
  );
  static const String _androidSenderId = String.fromEnvironment(
    'FIREBASE_ANDROID_SENDER_ID',
    defaultValue: '55959964226',
  );
  static const String _androidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
    defaultValue: 'cov-app-5d4b2.firebasestorage.app',
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

  /// Client ID web usado por Firebase Auth y como `serverClientId` en Android.
  ///
  /// Se pasa explícitamente en Android para que Google Sign-In no dependa del
  /// recurso `default_web_client_id`, que puede ser eliminado al optimizar el APK.
  static String get googleSignInClientId => googleClientId;
}
