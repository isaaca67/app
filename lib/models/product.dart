import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.quantity,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final double price;
  final int quantity;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// El precio como texto, por ejemplo "$12.50".
  String get priceLabel {
    final value = price.toStringAsFixed(2);
    return value.endsWith('.00') ? value.replaceFirst('.00', '') : value;
  }

  /// Indica si el stock está bajo (<= 5 unidades).
  bool get isLowStock => quantity <= 5;

  bool get isOutOfStock => quantity <= 0;

  factory Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return Product(
      id: document.id,
      userId: data['userId'] ?? '',
      name: data['nombre'] ?? data['name'] ?? '',
      price: (data['precio'] ?? data['price'] ?? 0).toDouble(),
      quantity: (data['cantidad'] ?? data['quantity'] ?? 0).toInt(),
      photoUrl: data['foto'] ?? data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombre': name,
      'precio': price,
      'cantidad': quantity,
      'foto': photoUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    double? price,
    int? quantity,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          price == other.price &&
          quantity == other.quantity &&
          photoUrl == other.photoUrl &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      photoUrl.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, userId: $userId, name: $name, price: $price, quantity: $quantity)';
  }
}