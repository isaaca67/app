import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stitch_cov_dark_mobile_login/models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Subcolección de productos por usuario para mantener la seguridad
  /// de que cada usuario solo ve sus propios productos.
  CollectionReference<Map<String, dynamic>> _products(String userId) =>
      _firestore.collection('users').doc(userId).collection('productos');

  Stream<List<Product>> watchProducts(String userId) => _products(userId)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final products = snapshot.docs.map(Product.fromDocument).toList();
        products.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return products;
      });

  Future<void> createProduct({
    required String userId,
    required String name,
    required double price,
    required int quantity,
    String? barcode,
    String? photoUrl,
  }) => _products(userId).add({
    'userId': userId,
    'nombre': name.trim(),
    'precio': price,
    'cantidad': quantity,
    'codigoBarras': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
    'foto': photoUrl,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateProduct({
    required String userId,
    required Product product,
    required String name,
    required double price,
    required int quantity,
    String? barcode,
    String? photoUrl,
  }) => _products(userId).doc(product.id).update({
    'userId': userId,
    'nombre': name.trim(),
    'precio': price,
    'cantidad': quantity,
    'codigoBarras': barcode?.trim().isEmpty == true ? null : barcode?.trim(),
    'foto': photoUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Descuenta (o incrementa si es negativo) la cantidad vendida del stock.
  Future<void> adjustStock(String userId, String productId, int delta) async {
    final docRef = _products(userId).doc(productId);
    await docRef.update({
      'cantidad': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String userId, String productId) =>
      _products(userId).doc(productId).delete();
}
