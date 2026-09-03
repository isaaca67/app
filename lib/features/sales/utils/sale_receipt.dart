import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

String saleReceiptText(Sale sale) {
  final date = sale.fecha;
  final dateText = date == null
      ? ''
      : 'Fecha: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}\n';

  final buffer = StringBuffer();
  buffer.writeln('COV — Control de Ventas e Inventario');
  buffer.writeln('========================================');
  buffer.writeln('Factura: ${sale.id.toUpperCase().substring(0, sale.id.length > 8 ? 8 : sale.id.length)}');
  buffer.writeln('Método: ${sale.metodoPago}');
  buffer.writeln(dateText);
  buffer.writeln('');

  // Encabezado de tabla
  buffer.write('Producto'.padRight(20));
  buffer.write('Cant'.padLeft(5));
  buffer.write('P.Unit.'.padLeft(10));
  buffer.writeln('Subtotal'.padLeft(10));
  buffer.writeln('-' * 47);

  // Items
  for (final item in sale.items) {
    buffer.write(item.productName.padRight(20));
    buffer.write('${item.quantity}'.padLeft(5));
    buffer.write('\$${item.unitPrice.toStringAsFixed(2)}'.padLeft(10));
    buffer.writeln('\$${item.subtotal.toStringAsFixed(2)}'.padLeft(10));
  }

  buffer.writeln('-' * 47);
  buffer.writeln('TOTAL GENERAL: \$${sale.totalVenta.toStringAsFixed(2)}');
  buffer.writeln('========================================');
  buffer.writeln('Gracias por su compra!');

  return buffer.toString();
}