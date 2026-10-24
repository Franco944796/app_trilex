import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePref extends ChangeNotifier {
  static const key = 'trilexTheme';
  static const choices = ['auto', 'light', 'dark'];

  late SharedPreferences _prefs;
  String choice = 'auto';

  void load(SharedPreferences prefs) {
    _prefs = prefs;
    final saved = prefs.getString(key);
    choice = choices.contains(saved) ? saved! : 'auto';
  }

  ThemeMode get mode => switch (choice) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> set(String value) async {
    if (!choices.contains(value) || value == choice) return;
    choice = value;
    await _prefs.setString(key, value);
    notifyListeners();
  }
}
