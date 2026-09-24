import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  double _fontSize = 1.0;
  ThemeMode _themeMode = ThemeMode.system;

  double get fontSize => _fontSize;
  ThemeMode get themeMode => _themeMode;

  SettingsProvider() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _fontSize = p.getDouble('fontSize') ?? 1.0;
    _themeMode = ThemeMode.values[p.getInt('themeMode') ?? 0];
    notifyListeners();
  }

  Future<void> setFontSize(double v) async {
    _fontSize = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble('fontSize', v);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt('themeMode', m.index);
  }
}
