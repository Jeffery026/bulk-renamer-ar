import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  double _fontSize = 1.0;
  AppThemeType _theme = AppThemeType.blue;

  double get fontSize => _fontSize;
  AppThemeType get themeType => _theme;
  bool get isDark => kThemes[_theme]!.isDark;

  SettingsProvider() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _fontSize = p.getDouble('fontSize') ?? 1.0;
    final ti = p.getInt('themeIndex') ?? 0;
    _theme = AppThemeType.values[ti.clamp(0, AppThemeType.values.length - 1)];
    notifyListeners();
  }

  Future<void> setFontSize(double v) async {
    _fontSize = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setDouble('fontSize', v);
  }

  Future<void> setTheme(AppThemeType t) async {
    _theme = t;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt('themeIndex', t.index);
  }
}
