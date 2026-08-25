import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';

void main() {
  group('Product.priceLabel', () {
    test('formatea el precio sin los decimales .00', () {
      expect(
        const Product(
              id: '1',
              userId: 'user-1',
              name: 'Camisa',
              price: 12.50,
              quantity: 10,
            )
            .priceLabel,
        '12.50',
      );
      expect(
        const Product(
              id: '2',
              userId: 'user-1',
              name: 'Pantalón',
              price: 25.00,
              quantity: 5,
            )
            .priceLabel,
        '25',
      );
    });
  });

  group('Product stock helpers', () {
    test('isOutOfStock es true cuando la cantidad es cero', () {
      const product = Product(
        id: '1',
        userId: 'user-1',
        name: 'Agotado',
        price: 10,
        quantity: 0,
      );
      expect(product.isOutOfStock, isTrue);
      expect(product.isLowStock, isTrue);
    });

    test('isLowStock es true cuando la cantidad es menor o igual a 5', () {
      const product = Product(
        id: '2',
        userId: 'user-1',
        name: 'Casi agotado',
        price: 10,
        quantity: 5,
      );
      expect(product.isLowStock, isTrue);
      expect(product.isOutOfStock, isFalse);
    });

    test('no marca stock bajo cuando la cantidad es mayor a 5', () {
      const product = Product(
        id: '3',
        userId: 'user-1',
        name: 'Disponible',
        price: 10,
        quantity: 20,
      );
      expect(product.isLowStock, isFalse);
      expect(product.isOutOfStock, isFalse);
    });
  });
}