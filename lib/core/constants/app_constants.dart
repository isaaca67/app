class AppConstants {
  static const String appName = 'COV';

  /// Client ID de OAuth de Google para Web (nuevo proyecto cov-app-5d4b2).
  ///
  /// Se puede sobrescribir en tiempo de compilación con `--dart-define=GOOGLE_CLIENT_ID=...`
  /// OBTÉNLO EN: Google Cloud Console > Credentials > OAuth 2.0 Client ID (Web)
  static const String googleClientId =
      '55959964226-u11f6j7u72jqutfgnkm0fv17k6v6tj0g.apps.googleusercontent.com';

  static const int passwordMinLength = 6;
  static const int nameMinLength = 2;
}