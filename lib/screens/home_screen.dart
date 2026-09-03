import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_cov_dark_mobile_login/screens/login_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/privacy_policy_screen.dart';
import 'package:stitch_cov_dark_mobile_login/core/di/service_locator.dart';
import 'package:stitch_cov_dark_mobile_login/core/providers/app_update_service.dart';
import 'package:stitch_cov_dark_mobile_login/core/providers/language_provider.dart';
import 'package:stitch_cov_dark_mobile_login/core/providers/theme_provider.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/dashboard/screens/dashboard_screen.dart';
import 'package:stitch_cov_dark_mobile_login/features/layout/widgets/responsive_shell.dart';
import 'package:stitch_cov_dark_mobile_login/features/products/widgets/product_editor_dialog.dart';
import 'package:stitch_cov_dark_mobile_login/features/products/widgets/products_tab.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/screens/sales_screen.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/screens/sales_history_screen.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = serviceLocator.productService;
  final _saleService = serviceLocator.saleService;
  final _authService = serviceLocator.authService;
  var _selectedIndex = 0;
  bool _isSigningOut = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _openProductEditor({Product? product}) async {
    final draft = await showDialog<ProductDraft>(
      context: context,
      builder: (_) => ProductEditorDialog(product: product),
    );
    if (draft == null || _user == null) return;

    try {
      if (product == null) {
        await _productService.createProduct(
          userId: _user!.uid,
          name: draft.name,
          price: draft.price,
          quantity: draft.quantity,
          barcode: draft.barcode,
          photoUrl: draft.photoUrl,
        );
        _showMessage('Producto creado correctamente.');
      } else {
        await _productService.updateProduct(
          userId: _user!.uid,
          product: product,
          name: draft.name,
          price: draft.price,
          quantity: draft.quantity,
          barcode: draft.barcode,
          photoUrl: draft.photoUrl,
        );
        _showMessage('Producto actualizado.');
      }
    } catch (_) {
      _showMessage(
        'No se pudo guardar el producto. Revisa tu conexión.',
        isError: true,
      );
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || _user == null) return;
    try {
      await _productService.deleteProduct(_user!.uid, product.id);
      _showMessage('Producto eliminado.');
    } catch (_) {
      _showMessage('No se pudo eliminar el producto.', isError: true);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await serviceLocator.sessionService.clearSession();
      // Cierra Firebase y, en móvil, también la sesión nativa de Google.
      await _authService.signOut();
    } catch (_) {
      _showMessage('No se pudo cerrar la sesión.', isError: true);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
    if (!mounted) return;
    // Limpia el historial y vuelve al login aunque el listener tarde.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _switchAccount() async {
    try {
      await serviceLocator.sessionService.switchAccount();
      if (!mounted) return;
      _showMessage('Cuenta cambiada. Inicia sesión de nuevo.', isError: false);
    } catch (_) {
      _showMessage('No se pudo cambiar de cuenta.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
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
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const titles = [
      'Dashboard',
      'Catálogo',
      'Ventas',
      'Historial',
      'Mi perfil',
      'Ajustes',
    ];
    const destinations = [
      ShellDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Inicio',
      ),
      ShellDestination(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Catálogo',
      ),
      ShellDestination(
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale,
        label: 'Ventas',
      ),
      ShellDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Historial',
      ),
      ShellDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Perfil',
      ),
      ShellDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Ajustes',
      ),
    ];

    return ResponsiveShell(
      destinations: destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (value) => setState(() => _selectedIndex = value),
      title: titles[_selectedIndex],
      tabs: [
        DashboardScreen(
          userId: user.uid,
          productService: _productService,
          saleService: _saleService,
        ),
        ProductsTab(
          userId: user.uid,
          productService: _productService,
          onEdit: (product) => _openProductEditor(product: product),
          onDelete: _confirmDelete,
        ),
        SalesScreen(
          userId: user.uid,
          productService: _productService,
          saleService: _saleService,
        ),
        SalesHistoryScreen(userId: user.uid, saleService: _saleService),
        _ProfileTab(user: user),
        _SettingsTab(
          isSigningOut: _isSigningOut,
          onSignOut: _signOut,
          onSwitchAccount: _switchAccount,
        ),
      ],
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              onPressed: _openProductEditor,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo producto'),
            )
          : null,
    );
  }
}

/// Métodos de pago válidos en el punto de venta.
const _kSalePaymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];

/// Diálogo REAL para cambiar la contraseña con re-autenticación.
///
/// Maneja `requires-recent-login` pidiendo cerrar sesión y volver a entrar.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty == true) return 'Requerido';
                if (value!.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty == true) return 'Requerido';
                if (value != newPasswordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(context);
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) throw Exception('Usuario no autenticado');

              final credential = EmailAuthProvider.credential(
                email: user.email!,
                password: currentPasswordController.text,
              );
              await user.reauthenticateWithCredential(credential);
              await user.updatePassword(newPasswordController.text);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contraseña actualizada correctamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } on FirebaseAuthException catch (e) {
              if (!context.mounted) return;
              String message = 'Error al cambiar contraseña';
              if (e.code == 'requires-recent-login') {
                message = 'Por seguridad, cierra sesión y vuelve a entrar '
                    'para cambiar la contraseña.';
              } else if (e.code == 'wrong-password') {
                message = 'La contraseña actual es incorrecta.';
              } else if (e.code == 'weak-password') {
                message = 'La nueva contraseña es muy débil. Mínimo 6 caracteres.';
              } else {
                message = 'Error: ${e.message}';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error inesperado: $e'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Cambiar'),
        ),
      ],
    ),
  );
}

String _biometricTypeNames(List<BiometricType> types) {
  if (types.isEmpty) return 'ninguno enrolado';
  return types.map((t) {
    switch (t) {
      case BiometricType.face:
        return 'Rostro';
      case BiometricType.fingerprint:
        return 'Huella dactilar';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometría segura';
      case BiometricType.weak:
        return 'Biometría básica';
    }
  }).join(', ');
}

/// Muestra el estado REAL de la biometría del dispositivo.
Future<void> showBiometricStatusDialog(BuildContext context) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La biometría solo está disponible en la app móvil.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  bool available = false;
  List<BiometricType> types = [];
  try {
    final localAuth = LocalAuthentication();
    available = await localAuth.canCheckBiometrics;
    if (available) {
      types = await localAuth.getAvailableBiometrics();
    }
  } catch (_) {
    available = false;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Autenticación biométrica'),
      content: Text(
        available
            ? 'Disponible en este dispositivo.\nMétodos: ${_biometricTypeNames(types)}.'
            : 'No hay biometría disponible. Enrola tu huella o rostro en '
                'los ajustes del sistema para usarla.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Muestra la información REAL de seguridad de la cuenta.
Future<void> showAccountSecurityDialog(BuildContext context, User user) async {
  bool bioAvailable = false;
  if (!kIsWeb) {
    try {
      bioAvailable = await LocalAuthentication().canCheckBiometrics;
    } catch (_) {
      bioAvailable = false;
    }
  }
  final providers = user.providerData.map((p) => p.providerId).join(', ');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Seguridad y acceso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SecurityRow(
            label: 'Proveedor',
            value: providers.isEmpty ? 'Desconocido' : providers,
          ),
          _SecurityRow(label: 'UID', value: user.uid),
          _SecurityRow(
            label: 'Correo verificado',
            value: user.emailVerified ? 'Sí' : 'No',
          ),
          _SecurityRow(
            label: 'Biometría en este equipo',
            value: bioAvailable ? 'Disponible' : 'No disponible',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

/// Hoja para elegir el método de pago predeterminado (persistido).
Future<void> showSalePreferencesSheet(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('default_metodo_pago') ?? 'Efectivo';
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Método de pago predeterminado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          RadioGroup<String>(
            groupValue: saved,
            onChanged: (value) async {
              if (value == null) return;
              await prefs.setString('default_metodo_pago', value);
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Método predeterminado: $value'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final method in _kSalePaymentMethods)
                  RadioListTile<String>(
                    title: Text(method),
                    value: method,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});
  final User user;

  bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _isWeb ? 600 : double.infinity),
        child: ListView(
          padding: EdgeInsets.all(_isWeb ? 32 : 24),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: _isWeb ? 60 : 50,
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.15,
                  ),
                  backgroundImage: user.photoURL == null
                      ? null
                      : NetworkImage(user.photoURL!),
                  child: user.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: _isWeb ? 60 : 50,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : 'Usuario COV',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'Sin correo registrado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _SectionCard(
              title: 'Información de la cuenta',
              icon: Icons.badge_outlined,
              children: [
                _ProfileOptionTile(
                  icon: Icons.person_outline,
                  title: 'Editar perfil',
                  subtitle: 'Nombre, foto y datos personales',
                  onTap: () => _showEditProfileDialog(context),
                ),
                _ProfileOptionTile(
                  icon: Icons.lock_outline,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualizar credenciales de acceso',
                  onTap: () => showChangePasswordDialog(context),
                ),
                _ProfileOptionTile(
                  icon: Icons.security_outlined,
                  title: 'Seguridad y acceso',
                  subtitle: 'Proveedor, verificación y biometría',
                  onTap: () => showAccountSecurityDialog(context, user),
                ),
                _ProfileOptionTile(
                  icon: Icons.notifications_outlined,
                  title: 'Preferencias de venta',
                  subtitle: 'Método de pago predeterminado',
                  onTap: () => showSalePreferencesSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Estado de la cuenta',
              icon: Icons.verified_user_outlined,
              children: [
                _InfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Cuenta protegida',
                  subtitle: 'Tus productos solo son visibles para tu cuenta.',
                ),
                _InfoTile(
                  icon: Icons.sync_outlined,
                  title: 'Sincronización en tiempo real',
                  subtitle:
                      'Los cambios se guardan automáticamente en la nube.',
                ),
                _InfoTile(
                  icon: Icons.cloud_outlined,
                  title: 'Respaldo automático',
                  subtitle: 'Tus datos están seguros en Firebase.',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionCard(
              title: 'Acerca de',
              icon: Icons.info_outline,
              children: [
                _InfoTile(
                  icon: Icons.app_registration_outlined,
                  title: 'Versión de la app',
                  subtitle: 'v1.0.0 (Build 1)',
                ),
                _InfoTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  subtitle: 'Políticas de uso y privacidad',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: user.displayName ?? '');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.currentUser?.updateDisplayName(
                  newName,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perfil actualizado correctamente'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.message}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({
    required this.isSigningOut,
    required this.onSignOut,
    this.onSwitchAccount,
  });
  final bool isSigningOut;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchAccount;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool get _isWeb => kIsWeb;

  bool _pushEnabled = true;
  bool _emailEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
      _emailEnabled = prefs.getBool('notif_email_enabled') ?? false;
    });
  }

  Future<void> _togglePush(bool value) async {
    setState(() => _pushEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_push_enabled', value);
    if (value && !kIsWeb) {
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (_) {
        // Sin FCM disponible; la preferencia local queda guardada.
      }
    }
  }

  Future<void> _toggleEmail(bool value) async {
    setState(() => _emailEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_email_enabled', value);
  }

  void _showLanguageSheet(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final currentCode = languageProvider.locale.languageCode;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Idioma / Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            RadioGroup<String>(
              groupValue: currentCode,
              onChanged: (value) => _selectLanguage(sheetContext, value),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('Español'),
                    value: 'es',
                  ),
                  RadioListTile<String>(
                    title: Text('English'),
                    value: 'en',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext sheetContext, String? code) async {
    if (code == null) return;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    await languageProvider.setLanguage(code);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!mounted) return;
    await context.setLocale(
      code == 'en' ? const Locale('en', 'US') : const Locale('es', 'ES'),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      trailing: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDangerSection() {
    final isSigningOut = widget.isSigningOut;
    final onSignOut = widget.onSignOut;
    return _buildSectionCard(
      title: 'Zona de peligro',
      icon: Icons.warning_amber_outlined,
      children: [
        _buildActionTile(
          icon: Icons.logout,
          title: 'Cerrar sesión',
          subtitle: 'Finalizar sesión actual',
          color: AppTheme.errorColor,
          isLoading: isSigningOut,
          onTap: isSigningOut ? null : onSignOut,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _isWeb ? 600 : double.infinity),
        child: ListView(
          padding: EdgeInsets.all(_isWeb ? 32 : 16),
          children: [
            // Sección: Información de la app
            _buildSectionCard(
              title: 'Aplicación',
              icon: Icons.apps_outlined,
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  title: 'COV - Control de Ventas',
                  subtitle:
                      'v1.0.0 (Build 1) · Control de Operaciones y Ventas',
                ),
                _InfoTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  subtitle: 'Políticas de uso y privacidad',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
                _InfoTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de privacidad',
                  subtitle: 'Cómo protegemos tus datos',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección: Apariencia
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    return _buildSectionCard(
                      title: 'Apariencia',
                      icon: Icons.palette_outlined,
                      children: [
                        _InfoTile(
                          icon: Icons.brightness_6_outlined,
                          title: 'Tema Oscuro / Claro',
                          subtitle: themeProvider.themeMode == ThemeMode.system
                              ? 'Sigue la configuración del sistema'
                              : themeProvider.themeMode == ThemeMode.dark
                              ? 'Tema oscuro activado'
                              : 'Tema claro activado',
                          trailing: Switch(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            onChanged: (_) {
                              if (themeProvider.themeMode == ThemeMode.system) {
                                themeProvider.setThemeMode(ThemeMode.dark);
                              } else if (themeProvider.themeMode ==
                                  ThemeMode.dark) {
                                themeProvider.setThemeMode(ThemeMode.light);
                              } else {
                                themeProvider.setThemeMode(ThemeMode.system);
                              }
                            },
                            activeThumbColor: AppTheme.primaryColor,
                          ),
                        ),
                        _InfoTile(
                          icon: Icons.language_outlined,
                          title: 'Idioma',
                          subtitle: languageProvider.currentLanguageName,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showLanguageSheet(context),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Sección: Notificaciones
            _SectionCard(
              title: 'Notificaciones',
              icon: Icons.notifications_outlined,
              children: [
                _InfoTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notificaciones push',
                  subtitle: _pushEnabled
                      ? 'Activas en este dispositivo'
                      : 'Desactivadas',
                  trailing: Switch(
                    value: _pushEnabled,
                    onChanged: _togglePush,
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ),
                _InfoTile(
                  icon: Icons.email_outlined,
                  title: 'Reportes por email',
                  subtitle: 'Resumen diario y alertas de stock',
                  trailing: Switch(
                    value: _emailEnabled,
                    onChanged: _toggleEmail,
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección: Cuenta
            _SectionCard(
              title: 'Cuenta y seguridad',
              icon: Icons.account_circle_outlined,
              children: [
                if (widget.onSwitchAccount != null)
                  _ActionTile(
                    icon: Icons.swap_horiz,
                    title: 'Cambiar cuenta',
                    subtitle: 'Iniciar sesión con otra cuenta de Google',
                    color: AppTheme.primaryColor,
                    onTap: widget.onSwitchAccount!,
                  ),
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualizar credenciales de acceso',
                  color: AppTheme.primaryColor,
                  onTap: () => showChangePasswordDialog(context),
                ),
                _ActionTile(
                  icon: Icons.security_outlined,
                  title: 'Autenticación biométrica',
                  subtitle: 'Huella digital / Face ID para acceso rápido',
                  color: AppTheme.primaryColor,
                  onTap: () => showBiometricStatusDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección: Actualizaciones
            Consumer<AppUpdateService>(
              builder: (context, updateService, _) {
                return _SectionCard(
                  title: 'Actualizaciones',
                  icon: Icons.system_update_outlined,
                  children: [
                    _InfoTile(
                      icon: Icons.system_update_outlined,
                      title: 'Buscar actualizaciones',
                      subtitle: updateService.isChecking
                          ? 'Buscando...'
                          : updateService.updateAvailable
                          ? 'Disponible v${updateService.latestVersion}'
                          : 'Estás en la última versión (${updateService.currentVersion.split('+').first})',
                      trailing: updateService.isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : updateService.updateAvailable
                          ? FilledButton.tonal(
                              onPressed: () => updateService.openUpdateUrl(),
                              child: const Text('Actualizar'),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () => updateService.checkForUpdate(),
                              tooltip: 'Buscar actualizaciones',
                            ),
                      onTap: updateService.isChecking
                          ? null
                          : () => updateService.checkForUpdate(),
                    ),
                    if (updateService.updateAvailable &&
                        updateService.releaseNotes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          left: 56,
                          right: 16,
                          bottom: 8,
                        ),
                        child: Text(
                          'Novedades: ${updateService.releaseNotes}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Sección: Peligro
            _buildDangerSection(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS AUXILIARES PARA PERFIL Y AJUSTES
// ============================================================
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.grey.shade600,
        ),
      ),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  }) : isLoading = false;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      trailing: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
