import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  const Sale({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double total;
  final DateTime? createdAt;

  factory Sale.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return Sale(
      id: document.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      unitPrice: (data['unitPrice'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
      total: (data['total'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  String toString() {
    return 'Sale(id: $id, userId: $userId, product: $productName, qty: $quantity, total: $total)';
  }
}