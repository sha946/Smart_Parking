import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager with ChangeNotifier {
  Locale _currentLocale = const Locale('fr', 'FR');

  Locale get currentLocale => _currentLocale;

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);

    notifyListeners();
  }

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode') ?? 'fr';
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      _currentLocale = const Locale('fr', 'FR');
      print("Erreur lors du chargement de la langue: $e");
    }
  }

  Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('languageCode');
      _currentLocale = const Locale('fr', 'FR');
      notifyListeners();
    } catch (e) {
      print("Erreur lors de la réinitialisation de la langue: $e");
    }
  }

  String getCurrentLanguageName() {
    switch (_currentLocale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Français';
    }
  }

  bool isLanguageActive(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }

  Map<String, String> getSupportedLanguages() {
    return {'fr': 'Français', 'en': 'English', 'es': 'Español'};
  }
}
