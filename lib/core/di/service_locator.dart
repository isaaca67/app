import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stitch_cov_dark_mobile_login/services/auth_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/product_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final GoogleSignIn? googleSignIn;
  late final AuthService authService;
  late final ProductService productService;
  late final SaleService saleService;

  Future<void> initialize({String? googleClientId}) async {
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    // Solo crear GoogleSignIn en móvil (no en web, usamos signInWithRedirect)
    googleSignIn = kIsWeb ? null : GoogleSignIn(clientId: googleClientId);
    authService = AuthService(
      auth: auth,
      firestore: firestore,
      googleSignIn: googleSignIn,
      googleClientId: googleClientId,
    );
    productService = ProductService(firestore: firestore);
    saleService = SaleService(firestore: firestore);
  }

  void reset() {
    // Para testing
  }
}

final serviceLocator = ServiceLocator();