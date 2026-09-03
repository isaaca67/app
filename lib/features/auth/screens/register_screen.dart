import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/constants/app_constants.dart';
import 'package:stitch_cov_dark_mobile_login/core/constants/app_strings.dart';
import 'package:stitch_cov_dark_mobile_login/core/di/service_locator.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/auth/utils/auth_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final _authService = serviceLocator.authService;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'email-already-in-use'
          ? AppStrings.authErrorEmailInUse
          : error.code == 'weak-password'
          ? AppStrings.authErrorWeakPassword
          : error.code == 'network-request-failed'
          ? AppStrings.authErrorNetworkFailed
          : error.code == 'api-key-not-valid'
          ? AppStrings.authErrorApiKeyInvalid
          : error.message ?? 'No fue posible crear la cuenta.';
      _showError(message);
    } catch (_) {
      _showError('No fue posible crear la cuenta. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerButton)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.createAccountTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(AppStrings.createAccountSubtitle),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: AppStrings.nameLabel,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: AuthValidators.name,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                      decoration: InputDecoration(
                        labelText: AppStrings.passwordLabel,
                        helperText:
                            'Mínimo ${AppConstants.passwordMinLength} caracteres',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
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
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.registerButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
