import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stitch_cov_dark_mobile_login/services/auth_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/biometric_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/product_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/sale_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/session_service.dart';
import 'package:stitch_cov_dark_mobile_login/services/version_service.dart';

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
  late final BiometricService biometricService;
  late final SessionService sessionService;
  late final VersionService versionService;

  Future<void> initialize({String? googleClientId, String? appVersion}) async {
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
    googleSignIn = kIsWeb ? null : GoogleSignIn(serverClientId: googleClientId);
    authService = AuthService(
      auth: auth,
      firestore: firestore,
      googleSignIn: googleSignIn,
      googleClientId: googleClientId,
    );
    productService = ProductService(firestore: firestore);
    saleService = SaleService(firestore: firestore);
    biometricService = BiometricService();
    sessionService = SessionService();
    versionService = VersionService(
      appVersion: appVersion ?? '1.0.0',
      appBuildNumber: 1,
    );
  }

  void reset() {
    // Para testing
  }
}

final serviceLocator = ServiceLocator();