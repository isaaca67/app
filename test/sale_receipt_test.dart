import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_cov_dark_mobile_login/features/sales/utils/sale_receipt.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

void main() {
  test('el comprobante incluye producto, cantidad, precios, total y fecha', () {
    final sale = Sale(
      id: 'venta-1',
      userId: 'usuario-1',
      items: [const CartItem(productId: 'producto-1', productName: 'Café', unitPrice: 2.5, quantity: 3)],
      totalVenta: 7.5,
      metodoPago: 'Efectivo',
      fecha: DateTime(2026, 8, 26),
    );

    final receipt = saleReceiptText(sale);

    expect(receipt, contains('Café'));
    expect(receipt, contains('3'));
    expect(receipt, contains(r'$2.50'));
    expect(receipt, contains(r'$7.50'));
    expect(receipt, contains('Fecha: 26/08/2026'));
  });
}
