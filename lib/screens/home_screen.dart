import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/di/service_locator.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/dashboard/screens/dashboard_screen.dart';
import 'package:stitch_cov_dark_mobile_login/features/layout/widgets/responsive_shell.dart';
import 'package:stitch_cov_dark_mobile_login/features/products/widgets/product_editor_dialog.dart';
import 'package:stitch_cov_dark_mobile_login/features/products/widgets/products_tab.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/screens/sales_screen.dart';
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
            style: FilledButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
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
      await _authService.signOut();
    } catch (_) {
      _showMessage('No se pudo cerrar la sesión.', isError: true);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppTheme.errorColor
            : AppTheme.successColor,
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

    const titles = ['Dashboard', 'Catálogo', 'Ventas', 'Mi perfil', 'Ajustes'];
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
      onDestinationSelected: (value) =>
          setState(() => _selectedIndex = value),
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
        _ProfileTab(user: user),
        _SettingsTab(isSigningOut: _isSigningOut, onSignOut: _signOut),
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: user.photoURL == null
                  ? null
                  : NetworkImage(user.photoURL!),
              child: user.photoURL == null
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName?.isNotEmpty == true
                ? user.displayName!
                : 'Usuario COV',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(user.email ?? 'Sin correo registrado', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Cuenta protegida'),
            subtitle: const Text('Tus productos solo son visibles para tu cuenta.'),
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Sincronización en tiempo real'),
            subtitle: const Text('Los cambios se guardan automáticamente.'),
          ),
        ],
      );
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.isSigningOut, required this.onSignOut});
  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('COV'),
            subtitle: const Text('Control de Operaciones y Ventas'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text('Cerrar sesión'),
            enabled: !isSigningOut,
            onTap: onSignOut,
            trailing: isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ],
      );
}