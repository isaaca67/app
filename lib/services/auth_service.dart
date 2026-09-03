import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    String? googleClientId,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = kIsWeb
           ? null
           : (googleSignIn ?? GoogleSignIn(serverClientId: googleClientId));

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn? _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await _saveUserProfile(credential.user, name: name.trim());
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _signInWithGoogleWeb();
    } else {
      await _signInWithGoogleMobile();
    }
  }

  Future<void> _signInWithGoogleWeb() async {
    // Redirect en lugar de popup: funciona aunque el navegador bloquee
    // ventanas emergentes. Al volver, main procesa getRedirectResult() y
    // authStateChanges lleva al home automáticamente.
    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithRedirect(googleProvider);
  }

  Future<void> _signInWithGoogleMobile() async {
    try {
      final account = await _googleSignIn!.signIn();
      if (account == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'El inicio de sesión con Google fue cancelado.',
        );
      }

      final authentication = await account.authentication;
      if (authentication.idToken == null) {
        throw FirebaseAuthException(
          code: 'google-auth-tokens-null',
          message:
              'No se pudieron obtener los tokens de Google. Verifica la configuración de OAuth.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: authentication.idToken!,
        accessToken: authentication.accessToken,
      );
      final result = await _auth.signInWithCredential(credential);
      await _saveUserProfile(result.user);
    } on PlatformException catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message:
            'Error en el inicio de sesión con Google (código: ${e.code}). ${e.message}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {
      // Ignoramos el error si el usuario no usó Google
    }
    await _auth.signOut();
  }

  /// Guarda/actualiza el perfil público del usuario en Firestore.
  /// Se usa tras un redirect de Google en Web, donde el resultado llega
  /// fuera de `signInWithGoogle()`.
  Future<void> saveUserProfile(User? user, {String? name}) =>
      _saveUserProfile(user, name: name);

  Future<void> _saveUserProfile(User? user, {String? name}) async {
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'name': name ?? user.displayName ?? 'Usuario COV',
      'email': user.email,
      'photoUrl': user.photoURL,
      'lastAccessAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
