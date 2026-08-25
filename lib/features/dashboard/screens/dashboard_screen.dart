import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';
import 'package:stitch_cov_dark_mobile_login/services/product_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.userId,
    required this.productService,
    required this.saleService,
  });

  final String userId;
  final ProductService productService;
  final SaleService saleService;

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: productService.watchProducts(userId),
      builder: (context, productsSnapshot) {
        return StreamBuilder<List<Sale>>(
          stream: saleService.watchSales(userId),
          builder: (context, salesSnapshot) {
            if (productsSnapshot.hasError || salesSnapshot.hasError) {
              return const _DashboardError();
            }
            if (!productsSnapshot.hasData || !salesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = productsSnapshot.data!;
            final sales = salesSnapshot.data!;

            final todaySales =
                sales.where((s) => _isToday(s.createdAt)).toList();
            final totalToday = todaySales.fold<double>(
              0,
              (sum, sale) => sum + sale.total,
            );

            final lowStock = products.where((p) => p.isLowStock).toList()
              ..sort((a, b) => a.quantity.compareTo(b.quantity));

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
            final borderColor =
                isDark ? AppTheme.darkBorder : Colors.grey[300]!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Resumen de hoy',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // --- Indicador grande: Total vendido en el día ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total vendido en el día',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '\$${totalToday.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        todaySales.length == 1
                            ? '1 venta registrada hoy'
                            : '${todaySales.length} ventas registradas hoy',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Sección de alertas ---
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Productos a punto de agotarse',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lowStock.isEmpty
                            ? AppTheme.successColor.withValues(alpha: 0.15)
                            : AppTheme.warningColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${lowStock.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: lowStock.isEmpty
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (lowStock.isEmpty)
                  _NoLowStockCard(cardColor: cardColor, borderColor: borderColor)
                else
                  ...lowStock.map(
                    (product) => _LowStockTile(product: product),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey[300]!;
    final isOut = product.isOutOfStock;
    final color = isOut ? AppTheme.errorColor : AppTheme.warningColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isOut ? Icons.remove_shopping_cart : Icons.inventory_2,
            color: color,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('\$${product.priceLabel} por unidad'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isOut ? 'Sin stock' : 'Quedan ${product.quantity}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoLowStockCard extends StatelessWidget {
  const _NoLowStockCard({required this.cardColor, required this.borderColor});
  final Color cardColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Todo en orden',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'No hay productos a punto de agotarse.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 56),
              SizedBox(height: 16),
              Text('No pudimos cargar el resumen.'),
            ],
          ),
        ),
      );
}