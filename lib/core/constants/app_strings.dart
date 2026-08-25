class AppStrings {
  // Auth
  static const String loginTitle = 'COV';
  static const String loginSubtitle =
      'Control de ventas e inventario para tu negocio.';
  static const String emailLabel = 'Correo electrónico';
  static const String passwordLabel = 'Contraseña';
  static const String nameLabel = 'Nombre';
  static const String loginButton = 'Iniciar sesión';
  static const String registerButton = 'Crear cuenta';
  static const String googleLoginButton = 'Continuar con Google';
  static const String registerLink = '¿No tienes una cuenta? Regístrate';
  static const String createAccountTitle = 'Comienza con COV';
  static const String createAccountSubtitle =
      'Crea tu cuenta para controlar tus ventas e inventario de forma segura.';

  // Validation
  static const String invalidEmail = 'Ingresa un correo electrónico válido.';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 6 caracteres.';
  static const String nameTooShort = 'Ingresa tu nombre.';

  // Errors
  static const String authErrorInvalidCredential =
      'Correo o contraseña incorrectos.';
  static const String authErrorInvalidEmail = 'Ingresa un correo válido.';
  static const String authErrorNetworkFailed =
      'Revisa tu conexión a internet. Verifica que Firebase Auth esté habilitado.';
  static const String authErrorApiKeyInvalid =
      'API Key inválida. Verifica la configuración de Firebase.';
  static const String authErrorAppNotAuthorized =
      'App no autorizada. Agrega SHA-1 en Firebase Console.';
  static const String authErrorGeneric = 'Error de autenticación. Intenta de nuevo.';
  static const String authErrorEmailInUse = 'Ese correo ya está registrado.';
  static const String authErrorWeakPassword = 'Usa una contraseña más segura.';
  static const String authErrorGoogleCancelled = 'Inicio de sesión con Google cancelado.';
  static const String authErrorGoogleTokensNull =
      'Error de configuración de Google. Verifica OAuth en Firebase Console.';
}