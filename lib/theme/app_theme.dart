import 'package:flutter/material.dart';

class AppTheme {
  // لون الأصل: أخضر Material
  static const _seed = Color(0xFF388E3C);

  static ThemeData lightTheme(double fontScale) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    textTheme: _scaledText(fontScale),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? const Color(0xFF388E3C) : null),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF388E3C),
      indicatorColor: Colors.white.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white, fontSize: 12)),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: Colors.white)),
    ),
  );

  static ThemeData darkTheme(double fontScale) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    textTheme: _scaledText(fontScale),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
  );

  static TextTheme _scaledText(double scale) {
    return TextTheme(
      bodyLarge: TextStyle(fontSize: 16 * scale),
      bodyMedium: TextStyle(fontSize: 14 * scale),
      bodySmall: TextStyle(fontSize: 12 * scale),
      titleMedium: TextStyle(fontSize: 16 * scale),
      labelLarge: TextStyle(fontSize: 14 * scale),
      labelMedium: TextStyle(fontSize: 12 * scale),
    );
  }
}
