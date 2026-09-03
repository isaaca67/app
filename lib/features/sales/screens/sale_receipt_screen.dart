import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/utils/sale_receipt.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';

class SaleReceiptScreen extends StatelessWidget {
  const SaleReceiptScreen({super.key, required this.userId, required this.saleId});

  final String userId;
  final String saleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
            tooltip: 'Compartir recibo',
          ),
        ],
      ),
      body: StreamBuilder<List<Sale>>(
        stream: SaleService().watchSales(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar la factura.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final sale = snapshot.data!.firstWhere((s) => s.id == saleId);
          return _ReceiptContent(sale: sale);
        },
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final sale = await _findSale();
      if (sale != null) {
        await SharePlus.instance.share(
          ShareParams(text: saleReceiptText(sale), subject: 'Recibo COV'),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo compartir el recibo.')),
      );
    }
  }

  Future<Sale?> _findSale() async {
    final snapshot = await SaleService().watchSales(userId).first;
    for (final s in snapshot) {
      if (s.id == saleId) return s;
    }
    return null;
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReceiptHeader(sale: null),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: kIsWeb
                  ? _DataTableReceipt(sale: sale)
                  : _ListReceipt(sale: sale),
            ),
          ),
          const SizedBox(height: 24),
          _TotalCard(sale: sale),
        ],
      ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({this.sale});
  final Sale? sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'COV — Control de Ventas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Factura #${sale != null ? sale!.id.toUpperCase().substring(0, 8) : '-'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReceiptField(label: 'Método', value: sale?.metodoPago ?? '-'),
              _ReceiptField(
                label: 'Fecha',
                value: sale?.fecha != null
                    ? '${sale!.fecha!.day}/${sale!.fecha!.month}/${sale!.fecha!.year}'
                    : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _DataTableReceipt extends StatelessWidget {
  const _DataTableReceipt({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Producto')),
        DataColumn(label: Text('Cant.')),
        DataColumn(label: Text('P. Unit.')),
        DataColumn(label: Text('Subtotal')),
      ],
      rows: sale.items.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(item.productName)),
            DataCell(Text('${item.quantity}')),
            DataCell(Text('\$${item.unitPrice.toStringAsFixed(2)}')),
            DataCell(Text('\$${item.subtotal.toStringAsFixed(2)}')),
          ],
        );
      }).toList(),
    );
  }
}

class _ListReceipt extends StatelessWidget {
  const _ListReceipt({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in sale.items) ...[
          _ReceiptLineItem(item: item),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class _ReceiptLineItem extends StatelessWidget {
  const _ReceiptLineItem({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${item.unitPrice.toStringAsFixed(2)} c/u',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('\$${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total General',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${sale.totalVenta.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${sale.items.length} producto(s) · ${_totalQuantity(sale)} unidades · Método: ${sale.metodoPago}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

int _totalQuantity(Sale sale) => sale.items.fold<int>(0, (sum, item) => sum + item.quantity);