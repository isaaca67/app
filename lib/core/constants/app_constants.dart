class AppConstants {
  static const String appName = 'COV';

  /// Client ID de OAuth de Google para Web.
  ///
  /// Se puede sobrescribir en tiempo de compilación con `--dart-define=GOOGLE_CLIENT_ID=...`
  /// Valor por defecto: el Client ID del proyecto Firebase cov-app-71e00.
  /// // PEGA_TU_CLIENT_ID_AQUI si usas otro proyecto de Google Cloud.
  static const String googleClientId =
      '1004379594579-hgk4sag6jgq6u47h7btivql49h50vuim.apps.googleusercontent.com';

  static const int passwordMinLength = 6;
  static const int nameMinLength = 2;
}