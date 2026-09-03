import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isEnrolled() async {
    if (kIsWeb) return false;
    try {
      final available = await _auth.canCheckBiometrics;
      if (!available) return false;
      final enrolled = await _auth.isDeviceSupported();
      return enrolled;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Autenticación requerida'}) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}