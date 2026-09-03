import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_cov_dark_mobile_login/core/config/app_config.dart';
import 'package:stitch_cov_dark_mobile_login/core/constants/app_constants.dart';
import 'package:stitch_cov_dark_mobile_login/core/di/service_locator.dart';
import 'package:stitch_cov_dark_mobile_login/core/providers/app_update_service.dart';
import 'package:stitch_cov_dark_mobile_login/core/providers/language_provider.dart';
import 'package:stitch_cov_dark_mobile_login/core/providers/theme_provider.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/onboarding/onboarding_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/auth_wrapper.dart';
import 'package:stitch_cov_dark_mobile_login/screens/widgets/configuration_error_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  Object? initializationError;
  try {
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    _enableOfflinePersistence();
    await serviceLocator.initialize(
      googleClientId: AppConfig.googleSignInClientId,
    );
    await _setupFirebaseMessaging();
  } catch (error) {
    initializationError = error;
  }

  final themeProvider = ThemeProvider();
  final languageProvider = LanguageProvider();
  final appUpdateService = AppUpdateService();

  await themeProvider.loadThemeMode();
  await languageProvider.loadLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: appUpdateService),
      ],
      child: EasyLocalization(
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('es', 'ES'),
        child: MyApp(
          initializationError: initializationError,
          themeProvider: themeProvider,
          languageProvider: languageProvider,
          appUpdateService: appUpdateService,
        ),
      ),
    ),
  );
}

Future<void> _setupFirebaseMessaging() async {
  if (kIsWeb) return;
  try {
    final fcm = FirebaseMessaging.instance;
    final settings = await fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await fcm.getToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
    }
    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        // Mostrar notificación en pantalla
      }
    });
  } catch (_) {
    // FCM no disponible
  }
}

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
  const MyApp({
    super.key,
    this.initializationError,
    required this.themeProvider,
    required this.languageProvider,
    required this.appUpdateService,
  });

  final Object? initializationError;
  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;
  final AppUpdateService appUpdateService;

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, LanguageProvider, AppUpdateService>(
      builder: (context, themeProvider, languageProvider, appUpdateService, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('es', 'ES'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: context.localizationDelegates,
          navigatorKey: OnboardingScreen.navigatorKey,
          home: initializationError != null
              ? ConfigurationErrorScreen(
                  error: initializationError!,
                  onRetry: () {
                    runApp(MyApp(
                      themeProvider: ThemeProvider(),
                      languageProvider: LanguageProvider(),
                      appUpdateService: AppUpdateService(),
                    ));
                  },
                )
              : _AppInitializer(
                  themeProvider: themeProvider,
                  languageProvider: languageProvider,
                  appUpdateService: appUpdateService,
                ),
        );
      },
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer({
    required this.themeProvider,
    required this.languageProvider,
    required this.appUpdateService,
  });

  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;
  final AppUpdateService appUpdateService;

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _onboardingCompleted = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await widget.themeProvider.loadThemeMode();
    await widget.languageProvider.loadLanguage();
    await widget.appUpdateService.checkForUpdate();
    await _checkAppState();
  }

  Future<void> _checkAppState() async {
    try {
      if (kIsWeb) {
        try {
          final redirectResult =
              await FirebaseAuth.instance.getRedirectResult();
          // Al volver del redirect de Google, guardar el perfil en Firestore
          // y marcar la sesión de inmediato (redirección forzada post-login).
          await serviceLocator.authService
              .saveUserProfile(redirectResult.user);
          if (redirectResult.user != null && mounted) {
            setState(() => _isAuthenticated = true);
          }
        } catch (_) {
          // Sin redirect pendiente
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final biometricAvailable = await _checkBiometricAuth();

      if (!mounted) return;
      setState(() {
        _isAuthenticated = user != null;
        _onboardingCompleted = onboardingCompleted;
        _biometricAvailable = biometricAvailable;
      });

      if (_isAuthenticated && _onboardingCompleted && _biometricAvailable) {
        await _authenticateWithBiometrics();
      }
    } catch (_) {
      // Ignore errors
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _checkBiometricAuth() async {
    if (kIsWeb) return false;
    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final supported = await localAuth.isDeviceSupported();
      if (!supported) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (kIsWeb) return;
    try {
      final localAuth = LocalAuthentication();
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Autenticación requerida para acceder a COV',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!mounted) return;
      if (!authenticated) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    // La navegación la decide AuthWrapper con el stream en vivo:
    // waiting -> Splash, null -> Login, usuario -> Onboarding/Home.
    return AuthWrapper(
      onboardingCompleted: _onboardingCompleted,
      onOnboardingComplete: _handleOnboardingComplete,
    );
  }

  void _handleOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    setState(() => _onboardingCompleted = true);
  }
}