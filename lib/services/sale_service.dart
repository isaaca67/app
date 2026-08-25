import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stitch_cov_dark_mobile_login/models/sale.dart';

class SaleService {
  SaleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Subcolección de ventas por usuario para mantener la seguridad
  /// de que cada usuario solo ve sus propias ventas.
  CollectionReference<Map<String, dynamic>> _sales(String userId) =>
      _firestore.collection('users').doc(userId).collection('ventas');

  Stream<List<Sale>> watchSales(String userId) =>
      _sales(userId)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final sales = snapshot.docs.map(Sale.fromDocument).toList();
        sales.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return sales;
      });

  Future<void> recordSale({
    required String userId,
    required String productId,
    required String productName,
    required double unitPrice,
    required int quantity,
  }) async {
    final total = unitPrice * quantity;
    await _sales(userId).add({
      'userId': userId,
      'productId': productId,
      'productName': productName.trim(),
      'unitPrice': unitPrice,
      'quantity': quantity,
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}