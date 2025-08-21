import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  final String key = "isDarkMode";
  late SharedPreferences _prefs;
  late bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;
  ThemeData get themeData => _isDarkMode ? ThemeData.dark() : ThemeData.light();

  ThemeNotifier() {
    _isDarkMode = false; // valeur par défaut = clair
    _loadFromPrefs();
  }

  toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    // Si rien dans SharedPreferences, utiliser false (clair)
    _isDarkMode = _prefs.getBool(key) ?? false;
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs.setBool(key, _isDarkMode);
  }
}
