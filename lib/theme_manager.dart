import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  ThemeManager() {
    _loadTheme();
  }

  // Charger le thème sauvegardé
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('themeMode');

      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        // Premier démarrage - mode clair par défaut
        _themeMode = ThemeMode.light;
        await prefs.setInt('themeMode', _themeMode.index);
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement du thème: $e");
      _themeMode = ThemeMode.light;
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Sauvegarder le thème
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', _themeMode.index);
    } catch (e) {
      print("Erreur lors de la sauvegarde du thème: $e");
    }
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blueGrey,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
  );
}
