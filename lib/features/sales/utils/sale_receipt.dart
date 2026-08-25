import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

/// Genera el texto plano del recibo de una venta para compartir
/// (WhatsApp, correo, etc.).
String saleReceiptText(Sale sale) {
  final date = sale.createdAt;
  final dateText = date == null
      ? ''
      : 'Fecha: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}\n';

  return 'COV — Control de Ventas e Inventario\n'
      '================================\n'
      'Venta: ${sale.productName}\n'
      'Cantidad: ${sale.quantity}\n'
      'Precio unitario: \$${sale.unitPrice.toStringAsFixed(2)}\n'
      'Total: \$${sale.total.toStringAsFixed(2)}\n'
      '$dateText'
      '================================';
}