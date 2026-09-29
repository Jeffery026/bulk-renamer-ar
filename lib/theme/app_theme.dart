import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════
// الثيمات المتاحة
// ═══════════════════════════════════════════════════════
enum AppThemeType {
  // فاتح
  blue,        // Blue (تلجرام)
  arcticBlue,  // Arctic Blue (تلجرام)
  teal,        // Teal — Solid Explorer
  purple,      // Purple — Solid Explorer
  crimson,     // Crimson Red
  // داكن
  darkBlue,    // Dark Blue (تلجرام)
  darkTeal,    // Dark Teal
  carbon,      // Carbon Dark
  midnight,    // Midnight
}

class AppThemeConfig {
  final String name;
  final Color primary;
  final Color? background;
  final Color? surface;
  final bool isDark;

  const AppThemeConfig({
    required this.name,
    required this.primary,
    this.background,
    this.surface,
    this.isDark = false,
  });
}

const Map<AppThemeType, AppThemeConfig> kThemes = {
  // ── فاتح ────────────────────────────────────────────
  AppThemeType.blue: AppThemeConfig(
    name: 'Blue',
    primary: Color(0xFF2294D9),
  ),
  AppThemeType.arcticBlue: AppThemeConfig(
    name: 'Arctic Blue',
    primary: Color(0xFF1F8DD6),
  ),
  AppThemeType.teal: AppThemeConfig(
    name: 'Teal',
    primary: Color(0xFF00897B),
  ),
  AppThemeType.purple: AppThemeConfig(
    name: 'Purple',
    primary: Color(0xFF7B1FA2),
  ),
  AppThemeType.crimson: AppThemeConfig(
    name: 'Crimson',
    primary: Color(0xFFD32F2F),
  ),
  // ── داكن ────────────────────────────────────────────
  AppThemeType.darkBlue: AppThemeConfig(
    name: 'Dark Blue',
    primary: Color(0xFF64B5EF),
    background: Color(0xFF1D2733),
    surface: Color(0xFF242D39),
    isDark: true,
  ),
  AppThemeType.darkTeal: AppThemeConfig(
    name: 'Dark Teal',
    primary: Color(0xFF4DB6AC),
    background: Color(0xFF1A2328),
    surface: Color(0xFF212D33),
    isDark: true,
  ),
  AppThemeType.carbon: AppThemeConfig(
    name: 'Carbon',
    primary: Color(0xFF78909C),
    background: Color(0xFF1C1C1E),
    surface: Color(0xFF2C2C2E),
    isDark: true,
  ),
  AppThemeType.midnight: AppThemeConfig(
    name: 'Midnight',
    primary: Color(0xFF9C89E0),
    background: Color(0xFF12121A),
    surface: Color(0xFF1E1E2E),
    isDark: true,
  ),
};

class AppTheme {
  static ThemeData build(AppThemeType type, double fontScale) {
    final cfg = kThemes[type]!;

    final cs = cfg.isDark
        ? ColorScheme.fromSeed(
            seedColor: cfg.primary,
            brightness: Brightness.dark,
          ).copyWith(
            surface: cfg.surface ?? const Color(0xFF1E1E1E),
          )
        : ColorScheme.fromSeed(seedColor: cfg.primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cfg.isDark
          ? (cfg.background ?? const Color(0xFF121212))
          : null,
      textTheme: _text(fontScale),
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
      listTileTheme: const ListTileThemeData(dense: true),
    );
  }

  static TextTheme _text(double scale) => TextTheme(
    bodyLarge: TextStyle(fontSize: 16 * scale),
    bodyMedium: TextStyle(fontSize: 14 * scale),
    bodySmall: TextStyle(fontSize: 12 * scale),
    titleMedium: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(fontSize: 14 * scale),
    labelMedium: TextStyle(fontSize: 12 * scale),
  );

  // للتوافق مع main.dart القديم
  static ThemeData lightTheme(double s) => build(AppThemeType.blue, s);
  static ThemeData darkTheme(double s) => build(AppThemeType.darkBlue, s);
}
