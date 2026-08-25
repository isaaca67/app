import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/utils/sale_receipt.dart';
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
  String? _selectedProductId;
  int _quantity = 1;
  bool _isSelling = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: widget.productService.watchProducts(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _SalesError();
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;
        if (products.isEmpty) {
          return const _NoProducts();
        }

        // Asegura que la selección siga siendo válida si cambia el catálogo.
        final selected = _selectedProductId == null
            ? products.first
            : products.firstWhere(
                (p) => p.id == _selectedProductId,
                orElse: () => products.first,
              );

        final total = selected.price * _quantity;
        final hasInsufficientStock = _quantity > selected.quantity;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Registro de venta',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecciona un producto y confirma la venta. El stock se descuenta automáticamente.',
              ),
              const SizedBox(height: 20),

              // --- Selector de producto ---
              DropdownButtonFormField<String>(
                initialValue: selected.id,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} — \$${p.priceLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedProductId = value),
              ),
              const SizedBox(height: 16),

              // --- Tarjeta con información del producto ---
              _SelectedProductCard(product: selected),
              const SizedBox(height: 20),

              // --- Cantidad a vender ---
              _QuantitySelector(
                quantity: _quantity,
                onChanged: (value) => setState(() => _quantity = value),
              ),
              const SizedBox(height: 20),

              // --- Alerta visual de stock insuficiente ---
              if (hasInsufficientStock) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stock insuficiente. Solo tienes ${selected.quantity} disponibles.',
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- Total ---
              Card(
                margin: EdgeInsets.zero,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSurface
                    : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total a cobrar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Botón principal rosa ---
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: (hasInsufficientStock || _isSelling)
                    ? null
                    : () => _confirmSale(selected, total),
                child: _isSelling
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmar Venta'),
              ),

              // --- Ventas recientes (con opción de compartir recibo) ---
              const SizedBox(height: 32),
              Text(
                'Ventas recientes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RecentSalesList(
                userId: widget.userId,
                saleService: widget.saleService,
                onShare: _shareReceipt,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSale(Product product, double total) async {
    setState(() => _isSelling = true);
    try {
      // Descuenta del inventario (delta negativo).
      await widget.productService.adjustStock(
        widget.userId,
        product.id,
        -_quantity,
      );
      // Registra la venta en el historial.
      await widget.saleService.recordSale(
        userId: widget.userId,
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: _quantity,
      );

      if (!mounted) return;

      final soldQuantity = _quantity;
      final sale = Sale(
        id: '',
        userId: widget.userId,
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: soldQuantity,
        total: total,
        createdAt: DateTime.now(),
      );

      setState(() => _quantity = 1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Venta confirmada: ${_quantityLabel(product.name, soldQuantity)} por \$${total.toStringAsFixed(2)}',
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Compartir recibo',
            textColor: Colors.white,
            onPressed: () => _shareReceipt(sale),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'No se pudo registrar la venta. Revisa tu conexión.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSelling = false);
    }
  }

  /// Abre la hoja de compartir (WhatsApp, correo, etc.) con el recibo
  /// en texto plano.
  Future<void> _shareReceipt(Sale sale) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: saleReceiptText(sale),
          subject: 'Recibo COV',
        ),
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'No se pudo compartir el recibo.',
          isError: true,
        );
      }
    }
  }

  String _quantityLabel(String productName, [int? quantity]) {
    final qty = quantity ?? _quantity;
    return '$qty x $productName';
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
}

class _SelectedProductCard extends StatelessWidget {
  const _SelectedProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stockColor = product.isOutOfStock
        ? AppTheme.errorColor
        : product.isLowStock
            ? AppTheme.warningColor
            : AppTheme.successColor;

    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
          child: product.photoUrl == null
              ? const Icon(Icons.inventory_2, color: AppTheme.primaryColor)
              : ClipOval(
                  child: Image.network(
                    product.photoUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.inventory_2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('\$${product.priceLabel} por unidad'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(stockColor == AppTheme.successColor
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded, size: 14, color: stockColor),
                const SizedBox(width: 4),
                Text(
                  product.isOutOfStock
                      ? 'Sin stock'
                      : 'Stock disponible: ${product.quantity}',
                  style: TextStyle(color: stockColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onChanged,
  });
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cantidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove),
              tooltip: 'Disminuir cantidad',
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => onChanged(quantity + 1),
              icon: const Icon(Icons.add),
              tooltip: 'Aumentar cantidad',
            ),
          ],
        ),
      ],
    );
  }
}

class _NoProducts extends StatelessWidget {
  const _NoProducts();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 72,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No tienes productos en el catálogo.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega productos desde la pestaña Catálogo.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _SalesError extends StatelessWidget {
  const _SalesError();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 56),
              SizedBox(height: 16),
              Text('No pudimos cargar los productos.'),
            ],
          ),
        ),
      );
}

/// Lista las últimas ventas con un botón para compartir el recibo.
class _RecentSalesList extends StatelessWidget {
  const _RecentSalesList({
    required this.userId,
    required this.saleService,
    required this.onShare,
  });

  final String userId;
  final SaleService saleService;
  final ValueChanged<Sale> onShare;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Sale>>(
      stream: saleService.watchSales(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('No pudimos cargar las ventas.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final recent = snapshot.data!.take(5).toList();
        if (recent.isEmpty) {
          return const Text('Aún no hay ventas registradas.');
        }

        return Column(
          children: [
            for (final sale in recent)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    sale.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${sale.quantity} unidad(es) · \$${sale.total.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Compartir recibo',
                    icon: const Icon(
                      Icons.share,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () => onShare(sale),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}