import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key, required this.userId, required this.saleService});

  final String userId;
  final SaleService saleService;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Sale>>(
        stream: saleService.watchSales(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el historial.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = snapshot.data!;
          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes ventas registradas.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _SaleCard(sale: sale, isDark: isDark, onTap: () => _showDetailBottomSheet(context, sale, isDark));
            },
          );
        },
      ),
    );
  }

  void _showDetailBottomSheet(BuildContext context, Sale sale, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaleDetailBottomSheet(sale: sale, isDark: isDark),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final bool isDark;
  final VoidCallback onTap;

  const _SaleCard({required this.sale, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shadowColor: Colors.black26,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Factura #${sale.id.toUpperCase().substring(0, sale.id.length > 8 ? 8 : sale.id.length)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${sale.totalVenta.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(
                  icon: Icons.calendar_today_outlined,
                  label: sale.fecha != null
                      ? '${sale.fecha!.day}/${sale.fecha!.month}/${sale.fecha!.year} · ${_formatHour(sale.fecha!)}'
                      : 'Sin fecha',
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.payment_outlined,
                  label: sale.metodoPago,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.shopping_bag_outlined,
                  label: '${sale.items.length} producto(s)',
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (sale.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${sale.items.first.productName}${sale.items.length > 1 ? ' +${sale.items.length - 1} más' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  String _formatHour(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SaleDetailBottomSheet extends StatelessWidget {
  final Sale sale;
  final bool isDark;

  const _SaleDetailBottomSheet({required this.sale, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final date = sale.fecha;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Factura #${sale.id.toUpperCase().substring(0, sale.id.length > 8 ? 8 : sale.id.length)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${sale.totalVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Meta info chips
              Row(
                children: [
                  _DetailChip(
                    icon: Icons.calendar_today_outlined,
                    label: date != null
                        ? '${date.day}/${date.month}/${date.year} · ${_formatHour(date)}'
                        : 'Sin fecha',
                  ),
                  const SizedBox(width: 8),
                  _DetailChip(
                    icon: Icons.payment_outlined,
                    label: sale.metodoPago,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Items header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Productos (${sale.items.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '\$${sale.totalVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Items list
              ...sale.items.map((item) => _SaleDetailItem(item: item)),
              const SizedBox(height: 16),
              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total General',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${sale.totalVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHour(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SaleDetailItem extends StatelessWidget {
  final CartItem item;

  const _SaleDetailItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'x${item.quantity} · \$${item.unitPrice.toStringAsFixed(2)} c/u',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ],
  );
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppTheme.primaryColor),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}