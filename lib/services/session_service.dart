import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  static const _keyUserId = 'user_id';
  static const _keyDisplayName = 'display_name';
  static const _keyEmail = 'email';
  static const _keyPhotoUrl = 'photo_url';
  static const _keyLastLogin = 'last_login';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.uid);
    await prefs.setString(_keyDisplayName, user.displayName ?? '');
    await prefs.setString(_keyEmail, user.email ?? '');
    await prefs.setString(_keyPhotoUrl, user.photoURL ?? '');
    await prefs.setInt(_keyLastLogin, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPhotoUrl);
    await prefs.remove(_keyLastLogin);
  }

  Future<Map<String, String>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    if (userId == null) return null;
    return {
      'userId': userId,
      'displayName': prefs.getString(_keyDisplayName) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'photoUrl': prefs.getString(_keyPhotoUrl) ?? '',
      'lastLogin': prefs.getInt(_keyLastLogin)?.toString() ?? '',
    };
  }

  Future<void> switchAccount() async {
    await clearSession();
    await _auth.signOut();
  }

  Future<bool> get hasSavedSession async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) != null;
  }
}