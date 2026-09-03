import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';

class Sale {
  const Sale({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalVenta,
    required this.metodoPago,
    this.fecha,
  });

  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalVenta;
  final String metodoPago;
  final DateTime? fecha;

  // Propiedades de compatibilidad para código legacy
  double get total => totalVenta;
  DateTime? get createdAt => fecha;
  String get productId => items.isNotEmpty ? items.first.productId : '';
  String get productName => items.isNotEmpty ? items.first.productName : '';
  double get unitPrice => items.isNotEmpty ? items.first.unitPrice : 0;
  int get quantity => items.fold(0, (acc, item) => acc + item.quantity);

  factory Sale.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    final itemsData = data['items'] as List? ?? [];
    return Sale(
      id: document.id,
      userId: data['userId'] ?? '',
      items: itemsData.map((e) => CartItem.fromMap(e)).toList(),
      totalVenta: (data['totalVenta'] ?? 0).toDouble(),
      metodoPago: data['metodoPago'] ?? 'Efectivo',
      fecha: (data['fecha'] as Timestamp?)?.toDate(),
    );
  }

  @override
  String toString() => 'Sale(id: $id, items: ${items.length}, total: $totalVenta)';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalVenta': totalVenta,
      'metodoPago': metodoPago,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : FieldValue.serverTimestamp(),
    };
  }
}