import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    const seed = Color(0xFF1B8F4B);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
