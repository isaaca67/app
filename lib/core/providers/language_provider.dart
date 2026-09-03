import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'language_code';

  Locale _locale = const Locale('es', 'ES');

  Locale get locale => _locale;

  LanguageProvider() {
    loadLanguage();
  }

  static Locale _fullLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'es':
      default:
        return const Locale('es', 'ES');
    }
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey) ?? 'es';
    _locale = _fullLocale(languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = _fullLocale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }

  void toggleLanguage() {
    final newCode = _locale.languageCode == 'es' ? 'en' : 'es';
    setLanguage(newCode);
  }

  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }

  List<String> get supportedLanguages => ['es', 'en'];
}