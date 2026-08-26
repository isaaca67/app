import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    String? googleClientId,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = kIsWeb ? null : (googleSignIn ?? GoogleSignIn(clientId: googleClientId));

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
    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithRedirect(googleProvider);
  }

  Future<void> handleRedirectResult() async {
    if (!kIsWeb) return;
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        await _saveUserProfile(result.user);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'auth/cancelled-popup-request') {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'El inicio de sesión con Google fue cancelado.',
        );
      }
      rethrow;
    }
  }

  Future<void> _signInWithGoogleMobile() async {
    final account = await _googleSignIn!.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'El inicio de sesión con Google fue cancelado.',
      );
    }

    final authentication = await account.authentication;
    if (authentication.accessToken == null || authentication.idToken == null) {
      throw FirebaseAuthException(
        code: 'google-auth-tokens-null',
        message: 'No se pudieron obtener los tokens de Google. Verifica la configuración de OAuth.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken!,
      idToken: authentication.idToken!,
    );
    final result = await _auth.signInWithCredential(credential);
    await _saveUserProfile(result.user);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {
      // Ignoramos el error si el usuario no usó Google
    }
    await _auth.signOut();
  }

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