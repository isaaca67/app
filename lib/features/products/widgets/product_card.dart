import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final baseBorder = isDark ? AppTheme.darkBorder : Colors.grey[300]!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        child: Card(
          margin: EdgeInsets.zero,
          color: isDark ? AppTheme.darkSurface : Colors.white,
          elevation: _isHovered ? 8 : 2,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered ? AppTheme.primaryColor : baseBorder,
            ),
          ),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            hoverColor: AppTheme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            onTap: () => widget.onEdit(product),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _ProductImage(product: product),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${product.priceLabel}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (product.barcode?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.barcode!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _StockBadge(product: product),
                      ],
                    ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opciones de producto',
                    onSelected: (value) => value == 'edit'
                        ? widget.onEdit(product)
                        : widget.onDelete(product),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppTheme.primaryColor,
        size: 28,
      ),
    );

    final photoUrl = product.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photoUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 56,
            height: 56,
            color: Colors.grey[300],
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    if (product.isOutOfStock) {
      color = AppTheme.errorColor;
      icon = Icons.block;
      label = 'Sin stock';
    } else if (product.isLowStock) {
      color = AppTheme.warningColor;
      icon = Icons.warning_amber_rounded;
      label = 'Stock bajo (${product.quantity})';
    } else {
      color = AppTheme.successColor;
      icon = Icons.check_circle_outline;
      label = 'Disponible (${product.quantity})';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
