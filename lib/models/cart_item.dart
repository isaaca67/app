import 'package:stitch_cov_dark_mobile_login/models/product.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  /// Crea un CartItem a partir de un Product con cantidad
  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
    );
  }

  /// Crea un CartItem desde un mapa denormalizado de Firestore
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          other.productId == productId;

  @override
  int get hashCode => productId.hashCode;

  @override
  String toString() => 'CartItem($productName x$quantity)';
}