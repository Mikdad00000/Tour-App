import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5),
    brightness: Brightness.light,
  );
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5),
    brightness: Brightness.dark,
  );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
