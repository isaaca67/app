import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stitch_cov_dark_mobile_login/models/cart_item.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

class InsufficientStockException implements Exception {
  const InsufficientStockException(this.available, this.productName);

  final int available;
  final String productName;
}

class ProductNotFoundException implements Exception {
  const ProductNotFoundException();
}

class SaleService {
  SaleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sales(String userId) =>
      _firestore.collection('users').doc(userId).collection('ventas');

  Stream<List<Sale>> watchSales(String userId) => _sales(userId)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final sales = snapshot.docs.map(Sale.fromDocument).toList();
        sales.sort(
          (a, b) => (b.fecha ?? DateTime(0)).compareTo(
            (a.fecha ?? DateTime(0)),
          ),
        );
        return sales;
      });

  Stream<List<Sale>> watchSalesForPeriod(
    String userId, {
    required DateTime start,
    required DateTime end,
  }) =>
      _sales(userId)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('fecha', isLessThan: Timestamp.fromDate(end))
          .orderBy('fecha', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Sale.fromDocument).toList());

  Future<Sale> recordSale({
    required String userId,
    required List<CartItem> items,
    String metodoPago = 'Efectivo',
  }) async {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'El carrito no puede estar vacío.');
    }

    final saleRef = _sales(userId).doc();
    double totalVenta = 0;

    for (final item in items) {
      totalVenta += item.unitPrice * item.quantity;
    }

    final List<DocumentReference> productRefs = [];
    final List<DocumentSnapshot<Map<String, dynamic>>> productSnapshots = [];

    for (final item in items) {
      final productRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('productos')
          .doc(item.productId);
      productRefs.add(productRef);
      final productSnapshot = await productRef.get();
      if (!productSnapshot.exists || productSnapshot.data() == null) {
        throw ProductNotFoundException();
      }
      productSnapshots.add(productSnapshot);
    }

    for (var i = 0; i < items.length; i++) {
      final available = (productSnapshots[i].data()!['cantidad'] as num?)?.toInt() ?? 0;
      if (available < items[i].quantity) {
        throw InsufficientStockException(
          available,
          items[i].productName,
        );
      }
    }

    final batch = FirebaseFirestore.instance.batch();

    for (var i = 0; i < items.length; i++) {
      final available = (productSnapshots[i].data()!['cantidad'] as num?)?.toInt() ?? 0;
      batch.update(productRefs[i], {
        'cantidad': available - items[i].quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(saleRef, {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalVenta': totalVenta,
      'metodoPago': metodoPago,
      'fecha': Timestamp.fromDate(DateTime.now()),
    });

    try {
      await batch.commit();
    } catch (e) {
      rethrow;
    }

    return Sale(
      id: saleRef.id,
      userId: userId,
      items: items,
      totalVenta: totalVenta,
      metodoPago: metodoPago,
      fecha: DateTime.now(),
    );
  }
}