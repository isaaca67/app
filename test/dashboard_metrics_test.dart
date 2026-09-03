import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_cov_dark_mobile_login/features/dashboard/utils/dashboard_metrics.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

void main() {
  const products = [
    Product(id: 'a', userId: 'u1', name: 'Producto A', price: 50, quantity: 8),
    Product(id: 'b', userId: 'u1', name: 'Producto B', price: 25, quantity: 10),
    Product(id: 'c', userId: 'u1', name: 'Producto C', price: 10, quantity: 4),
  ];

  final sales = [
    Sale(
      id: 's1',
      userId: 'u1',
      items: [const CartItem(productId: 'a', productName: 'Producto A', unitPrice: 50, quantity: 2)],
      totalVenta: 100,
      metodoPago: 'Efectivo',
      fecha: DateTime(2026, 8, 31, 10),
    ),
    Sale(
      id: 's2',
      userId: 'u1',
      items: [const CartItem(productId: 'b', productName: 'Producto B', unitPrice: 25, quantity: 1)],
      totalVenta: 25,
      metodoPago: 'Efectivo',
      fecha: DateTime(2026, 8, 30, 18),
    ),
    Sale(
      id: 's3',
      userId: 'u1',
      items: [const CartItem(productId: 'a', productName: 'Producto A', unitPrice: 50, quantity: 1)],
      totalVenta: 50,
      metodoPago: 'Efectivo',
      fecha: DateTime(2026, 8, 10, 12),
    ),
  ];

  test('calcula ingresos de día, semana y mes desde el snapshot mensual', () {
    final metrics = DashboardMetrics.from(
      products: products,
      monthlySales: sales,
      now: DateTime(2026, 8, 31, 15),
    );

    expect(metrics.todayRevenue, 100);
    expect(metrics.weekRevenue, 100);
    expect(metrics.monthRevenue, 175);
    expect(metrics.dayPoints[10].value, 100);
    expect(metrics.weekPoints[0].value, 100);
    expect(metrics.monthPoints[29].value, 25);
  });

  test('ordena los productos más y menos vendidos e incluye ventas cero', () {
    final metrics = DashboardMetrics.from(
      products: products,
      monthlySales: sales,
      now: DateTime(2026, 8, 31, 15),
    );

    expect(metrics.topProducts.first.productId, 'a');
    expect(metrics.topProducts.first.unitsSold, 3);
    expect(metrics.leastProducts.first.productId, 'c');
    expect(metrics.leastProducts.first.unitsSold, 0);
  });
}
