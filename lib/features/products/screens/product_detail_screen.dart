import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: product.photoUrl != null && product.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          product.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _PlaceholderIcon(),
                        ),
                      )
                    : const _PlaceholderIcon(),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '\$${product.priceLabel}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Stock actual',
              value: '${product.quantity}',
              color: product.isOutOfStock
                  ? AppTheme.errorColor
                  : product.isLowStock
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
            ),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.qr_code_scanner,
              label: 'Código de barras',
              value: product.barcode ?? 'Sin código',
              color: Colors.white,
            ),
            if (product.barcode != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                icon: Icons.qr_code_2,
                label: 'ID del producto',
                value: product.id,
                color: Colors.white,
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del stock',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _StockBar(
                      percentage: product.isOutOfStock
                          ? 0
                          : (product.quantity / 100).clamp(0, 1),
                      label: product.isOutOfStock
                          ? 'AGOTADO'
                          : product.isLowStock
                              ? 'STOCK BAJO'
                              : 'DISPONIBLE',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      );
}

class _StockBar extends StatelessWidget {
  final double percentage;
  final String label;

  const _StockBar({required this.percentage, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = percentage <= 0
        ? AppTheme.errorColor
        : percentage < 0.2
            ? AppTheme.warningColor
            : AppTheme.successColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}