import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/utils/sale_receipt.dart';
import 'package:stitch_cov_dark_mobile_login/features/scanner/screens/product_scanner_screen.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';
import 'package:stitch_cov_dark_mobile_login/services/product_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    required this.userId,
    required this.productService,
    required this.saleService,
  });

  final String userId;
  final ProductService productService;
  final SaleService saleService;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final List<CartItem> _cart = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSelling = false;
  String _metodoPago = 'Efectivo';
  bool _showCartSheet = false;

  double get _total => _cart.fold(0, (acc, item) => acc + item.subtotal);
  int get _totalItems => _cart.fold(0, (acc, item) => acc + item.quantity);
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _loadDefaultPayment();
  }

  Future<void> _loadDefaultPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('default_metodo_pago');
    const allowed = ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];
    if (saved != null && allowed.contains(saved) && mounted) {
      setState(() => _metodoPago = saved);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filteredProducts(List<Product> all) {
    if (_searchQuery.isEmpty) return all;
    return all.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.barcode?.toLowerCase().contains(q) == true;
    }).toList();
  }

  void _addToCart(Product product) {
    setState(() {
      final index = _cart.indexWhere((item) => item.productId == product.id);
      if (index != -1) {
        _cart[index] = _cart[index].copyWith(quantity: _cart[index].quantity + 1);
      } else {
        _cart.add(CartItem.fromProduct(product));
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    // En móvil, mostramos el BottomSheet del carrito al agregar
    if (_isMobile && !_showCartSheet) {
      _openCartSheet();
    }
  }

  void _removeFromCart(String productId) {
    setState(() => _cart.removeWhere((item) => item.productId == productId));
  }

  void _changeQuantity(String productId, int delta) {
    setState(() {
      final index = _cart.indexWhere((item) => item.productId == productId);
      if (index == -1) return;
      final newQty = _cart[index].quantity + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: newQty);
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _openCartSheet() {
    if (!_isMobile) return;
    setState(() => _showCartSheet = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartBottomSheet(
        cart: _cart,
        total: _total,
        totalItems: _totalItems,
        metodoPago: _metodoPago,
        isSelling: _isSelling,
        onQuantityChanged: _changeQuantity,
        onRemove: _removeFromCart,
        onClear: _clearCart,
        onConfirm: _confirmSale,
        onMetodoChanged: (v) => setState(() => _metodoPago = v!),
        onSheetClosed: () => setState(() => _showCartSheet = false),
      ),
    );
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) return;

    setState(() => _isSelling = true);
    try {
      final sale = await widget.saleService.recordSale(
        userId: widget.userId,
        items: List.from(_cart),
        metodoPago: _metodoPago,
      );

      if (!mounted) return;
      final totalVenta = sale.totalVenta;
      _clearCart();
      if (_isMobile) {
        Navigator.of(context).pop(); // Cerrar BottomSheet
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venta confirmada: $_totalItems items por \$${totalVenta.toStringAsFixed(2)}',
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Compartir',
            textColor: Colors.white,
            onPressed: () => _shareReceipt(sale),
          ),
        ),
      );
    } on InsufficientStockException catch (error) {
      if (mounted) {
        _showSnackBar(
          'Stock insuficiente para "${error.productName}". Solo quedan ${error.available} unidades.',
          isError: true,
        );
      }
    } on ProductNotFoundException {
      if (mounted) {
        _showSnackBar('Uno o más productos ya no existen.', isError: true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        final message = switch (error.code) {
          'failed-precondition' => 'Firestore no está configurada.',
          'permission-denied' => 'Sin permisos. Revisa las reglas de seguridad.',
          _ => 'No se pudo registrar la venta (${error.code}).',
        };
        _showSnackBar(message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Error al registrar la venta.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSelling = false);
    }
  }

  Future<void> _scanProduct() async {
    if (kIsWeb) {
      _showSnackBar('El escáner con cámara está disponible en la app móvil.', isError: false);
      return;
    }
    // Android / iOS: abrir escáner nativo
    final code = await openProductCodeScanner(context);
    if (code != null && mounted) {
      _searchController.text = code;
      setState(() => _searchQuery = code);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _shareReceipt(Sale sale) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: saleReceiptText(sale), subject: 'Recibo COV'),
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar('No se pudo compartir el recibo.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        actions: [
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart, size: 18, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Text(
                    '$_totalItems items',
                    style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _isMobile && _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openCartSheet,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Carrito ($_totalItems)'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: StreamBuilder<List<Product>>(
        stream: widget.productService.watchProducts(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _SalesError();
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allProducts = snapshot.data!;
          if (allProducts.isEmpty) return const _NoProducts();

          final products = _filteredProducts(allProducts);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = !_isMobile && constraints.maxWidth >= 700;

              if (isDesktop) {
                // WEB / DESKTOP: Layout de dos columnas
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ProductPanel(
                        products: products,
                        searchQuery: _searchQuery,
                        searchController: _searchController,
                        onSearchChanged: (v) => setState(() => _searchQuery = v),
                        onAddToCart: _addToCart,
                        onScan: _scanProduct,
                        selectedIds: _cart.map((c) => c.productId).toSet(),
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      flex: 2,
                      child: _CartPanel(
                        cart: _cart,
                        total: _total,
                        totalItems: _totalItems,
                        metodoPago: _metodoPago,
                        onQuantityChanged: _changeQuantity,
                        onRemove: _removeFromCart,
                        onClear: _clearCart,
                        onConfirm: _confirmSale,
                        isSelling: _isSelling,
                        onMetodoChanged: (v) => setState(() => _metodoPago = v!),
                        onViewReceipt: null,
                      ),
                    ),
                  ],
                );
              }

              // MÓVIL: Solo panel de productos, carrito en BottomSheet
              return _ProductPanel(
                products: products,
                searchQuery: _searchQuery,
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                onAddToCart: _addToCart,
                onScan: _scanProduct,
                selectedIds: _cart.map((c) => c.productId).toSet(),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// WIDGETS DEL PANEL DE PRODUCTOS
// ============================================================
class _ProductPanel extends StatelessWidget {
  const _ProductPanel({
    required this.products,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAddToCart,
    required this.onScan,
    required this.selectedIds,
  });

  final List<Product> products;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final void Function(Product) onAddToCart;
  final VoidCallback onScan;
  final Set<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar producto o escanear...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: onScan,
                    tooltip: 'Escanear código',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '${products.length} productos',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No se encontraron productos.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: products.length,
                  separatorBuilder: (a, b) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final inCart = selectedIds.contains(product.id);
                    return _ProductTile(
                      product: product,
                      inCart: inCart,
                      onAdd: () => onAddToCart(product),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.inCart,
    required this.onAdd,
  });

  final Product product;
  final bool inCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stockColor = product.isOutOfStock
        ? AppTheme.errorColor
        : product.isLowStock
            ? AppTheme.warningColor
            : AppTheme.successColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inCart
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : (isDark ? AppTheme.darkBorder : Colors.grey.shade200),
            width: inCart ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            child: product.photoUrl == null || product.photoUrl!.isEmpty
                ? const Icon(Icons.inventory_2, size: 22, color: AppTheme.primaryColor)
                : ClipOval(
                    child: Image.network(
                      product.photoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (a, b, c) =>
                          const Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 22),
                    ),
                  ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  '\$${product.priceLabel}',
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.inventory_2_outlined, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 2),
              Text(
                '${product.quantity}',
                style: TextStyle(fontSize: 11, color: stockColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: inCart
                ? IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppTheme.successColor),
                    onPressed: onAdd,
                    tooltip: 'Agregar otro',
                  )
                : OutlinedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                    label: const Text('Agregar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onPressed: product.isOutOfStock ? null : onAdd,
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CARRITO: BottomSheet para móvil, Panel lateral para Desktop
// ============================================================
class _CartBottomSheet extends StatelessWidget {
  const _CartBottomSheet({
    required this.cart,
    required this.total,
    required this.totalItems,
    required this.metodoPago,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onClear,
    required this.onConfirm,
    required this.onMetodoChanged,
    required this.onSheetClosed,
    required this.isSelling,
  });

  final List<CartItem> cart;
  final double total;
  final int totalItems;
  final String metodoPago;
  final bool isSelling;
  final void Function(String, int) onQuantityChanged;
  final void Function(String) onRemove;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final ValueChanged<String?> onMetodoChanged;
  final VoidCallback onSheetClosed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Carrito ($totalItems)',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (cart.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: onClear,
                      tooltip: 'Vaciar carrito',
                    ),
                ],
              ),
            ),
            // Lista de items
            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Agrega productos desde la lista',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return _CartItemTile(
                          item: item,
                          onQuantityChanged: (delta) => onQuantityChanged(item.productId, delta),
                          onRemove: (pid) => onRemove(pid),
                        );
                      },
                    ),
            ),
            // Resumen y confirmación
            _CartSummary(
              cart: cart,
              total: total,
              totalItems: totalItems,
              metodoPago: metodoPago,
              isSelling: isSelling,
              onQuantityChanged: onQuantityChanged,
              onRemove: onRemove,
              onClear: onClear,
              onConfirm: onConfirm,
              onMetodoChanged: onMetodoChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.total,
    required this.totalItems,
    required this.metodoPago,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onClear,
    required this.onConfirm,
    required this.isSelling,
    required this.onMetodoChanged,
    required this.onViewReceipt,
  });

  final List<CartItem> cart;
  final double total;
  final int totalItems;
  final String metodoPago;
  final void Function(String, int) onQuantityChanged;
  final void Function(String) onRemove;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final bool isSelling;
  final ValueChanged<String?> onMetodoChanged;
  final VoidCallback? onViewReceipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header del carrito
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carrito ($totalItems)',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: onClear,
                  tooltip: 'Vaciar carrito',
                ),
            ],
          ),
        ),

        // Lista de items
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Agrega productos desde la lista',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return _CartItemTile(
                      item: item,
                      onQuantityChanged: (delta) => onQuantityChanged(item.productId, delta),
                      onRemove: (pid) => onRemove(pid),
                    );
                  },
                ),
        ),

        // Resumen y confirmación
        _CartSummary(
          cart: cart,
          total: total,
          totalItems: totalItems,
          metodoPago: metodoPago,
          isSelling: isSelling,
          onQuantityChanged: onQuantityChanged,
          onRemove: onRemove,
          onClear: onClear,
          onConfirm: onConfirm,
          onMetodoChanged: onMetodoChanged,
        ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.cart,
    required this.total,
    required this.totalItems,
    required this.metodoPago,
    required this.isSelling,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onClear,
    required this.onConfirm,
    required this.onMetodoChanged,
  });

  final List<CartItem> cart;
  final double total;
  final int totalItems;
  final String metodoPago;
  final bool isSelling;
  final void Function(String, int) onQuantityChanged;
  final void Function(String) onRemove;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final ValueChanged<String?> onMetodoChanged;

  double get _subtotal => cart.fold(0, (acc, item) => acc + item.subtotal);
  double get _tax => total - _subtotal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cart.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de compra',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF212121),
                  ),
                ),
                if (cart.length > 1)
                  Text(
                    '${cart.length} artículos',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriceRow('Subtotal', _subtotal, isDark),
            const SizedBox(height: 6),
            _buildPriceRow('Impuesto', _tax, isDark),
            const SizedBox(height: 6),
            _buildPriceRow('Total', total, isDark, isTotal: true),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            initialValue: metodoPago,
            items: ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro']
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: onMetodoChanged,
            decoration: InputDecoration(
              labelText: 'Método de pago',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              elevation: 4,
            ),
            onPressed: isSelling || cart.isEmpty ? null : onConfirm,
            child: isSelling
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirmar Venta'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, bool isDark, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isDark ? Colors.white70 : Color(0xFF616161),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primaryColor : (isDark ? Colors.white70 : Color(0xFF424242)),
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onQuantityChanged, required this.onRemove});

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)} c/u',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _CircleButton(
                  icon: Icons.remove,
                  iconSize: 16,
                  onPressed: () => onQuantityChanged(-1),
                ),
                const SizedBox(width: 8),
                Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _CircleButton(
                  icon: Icons.add,
                  iconSize: 16,
                  onPressed: () => onQuantityChanged(1),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                  onPressed: () => onRemove(item.productId),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.iconSize,
    required this.onPressed,
  });

  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: AppTheme.primaryColor),
        onPressed: onPressed,
        splashRadius: 18,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ============================================================
// WIDGETS DE ERROR / EMPTY
// ============================================================
class _SalesError extends StatelessWidget {
  const _SalesError();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Error al cargar.'));
}

class _NoProducts extends StatelessWidget {
  const _NoProducts();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shopping_cart_outlined, size: 72, color: AppTheme.primaryColor),
        SizedBox(height: 16),
        Text('No tienes productos en el catálogo.'),
      ],
    ),
  );
}