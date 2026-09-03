import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_cov_dark_mobile_login/core/constants/app_strings.dart';
import 'package:stitch_cov_dark_mobile_login/core/di/service_locator.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/auth/screens/register_screen.dart';
import 'package:stitch_cov_dark_mobile_login/features/auth/utils/auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _authService = serviceLocator.authService;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await _runAuthAction(
      () => _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _signInWithGoogle() =>
      _runAuthAction(_authService.signInWithGoogle);

  Future<void> _signInWithBiometrics() async {
    if (kIsWeb) return;
    if (!mounted) return;
    setState(() => _isBiometricLoading = true);
    try {
      final localAuth = LocalAuthentication();
      final available = await localAuth.canCheckBiometrics;
      if (!available) {
        _showMessage('Biometría no disponible.', isError: true);
        return;
      }
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Inicia sesión con tu huella o rostro',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!authenticated) {
        _showMessage('Autenticación cancelada.', isError: true);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        final email = prefs.getString('email') ?? '';
        final password = prefs.getString('password') ?? '';
        if (email.isNotEmpty && password.isNotEmpty) {
          await _runAuthAction(() => _authService.signInWithEmail(
                email: email,
                password: password,
              ));
        } else {
          _showMessage('Sesión biométrica activa.', isError: false);
        }
      } else {
        _showMessage('No hay sesión guardada. Inicia sesión primero.', isError: true);
      }
    } catch (_) {
      _showMessage('Error en la autenticación biométrica.', isError: true);
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error), isError: true);
    } catch (e) {
      if (e.toString().contains('Canceled') ||
          e.toString().contains('popup_closed_by_user')) {
        return;
      }
      _showMessage(AppStrings.authErrorNetworkFailed, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return AppStrings.authErrorInvalidCredential;
      case 'invalid-email':
        return AppStrings.authErrorInvalidEmail;
      case 'network-request-failed':
        return AppStrings.authErrorNetworkFailed;
      case 'api-key-not-valid':
        return AppStrings.authErrorApiKeyInvalid;
      case 'app-not-authorized':
        return AppStrings.authErrorAppNotAuthorized;
      case 'google-sign-in-cancelled':
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return AppStrings.authErrorGoogleCancelled;
      case 'google-auth-tokens-null':
        return AppStrings.authErrorGoogleTokensNull;
      case 'google-sign-in-failed':
        return AppStrings.authErrorGoogleFailed;
      case 'popup-blocked':
        return AppStrings.authErrorPopupBlocked;
      case 'unauthorized-domain':
        return AppStrings.authErrorUnauthorizedDomain;
      case 'operation-not-supported-in-this-environment':
        return AppStrings.authErrorOperationNotSupported;
      default:
        return '${AppStrings.authErrorGeneric} (${error.code})';
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Theme(
        data: AppTheme.darkTheme,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 8 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  color: AppTheme.darkSurface,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 12 : 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 68,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.loginTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: AppStrings.emailLabel,
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: AuthValidators.email,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _signInWithEmail(),
                            decoration: InputDecoration(
                              labelText: AppStrings.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: AuthValidators.password,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    AppStrings.loginButton,
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.googleLoginButton,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          if (!kIsWeb) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithBiometrics,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isBiometricLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : const Icon(Icons.fingerprint, size: 28, color: AppTheme.primaryColor),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Entrar con huella/rostro',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                            child: const Text(AppStrings.registerLink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
